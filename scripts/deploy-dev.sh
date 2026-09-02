#!/bin/bash
set -euo pipefail

ENV_NAME=${1:-dev}

echo "=========================================="
echo "Deploying environment: $ENV_NAME"
echo "=========================================="

# 1. Get ACR from Terraform
echo "=== Retrieving Terraform outputs ==="

cd "terraform/environments/$ENV_NAME"

REGISTRY=$(terraform output -raw acr_login_server)

cd ../../..

echo "ACR: $REGISTRY"

# 2. Unique Git tag
TAG=$(git rev-parse --short HEAD)

echo "Image tag: $TAG"

# 3. Login to ACR
echo "=== Logging into ACR ==="

ACR_NAME="${REGISTRY%%.*}"

az acr login --name "$ACR_NAME"

# 4. Build & Push Backend
echo "=== Build & Push Backend ==="

docker buildx build \
  --platform linux/amd64 \
  --tag "$REGISTRY/shortlytics-backend:$TAG" \
  --push \
  ./backend

# 5. Build & Push Frontend
echo "=== Build & Push Frontend ==="

docker buildx build \
  --platform linux/amd64 \
  --tag "$REGISTRY/shortlytics-frontend:$TAG" \
  --push \
  ./frontend

# 6. Verify images
echo "=== Verifying pushed images ==="

docker buildx imagetools inspect \
  "$REGISTRY/shortlytics-backend:$TAG"

docker buildx imagetools inspect \
  "$REGISTRY/shortlytics-frontend:$TAG"

# 7. Update GitOps
echo "=== Updating GitOps manifests ==="

VALUES_FILE="gitops-manifests/shortlytics/values-${ENV_NAME}.yaml"

if [ ! -f "$VALUES_FILE" ]; then
  echo "ERROR: $VALUES_FILE not found"
  exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' \
    "s/tag: \".*\"/tag: \"$TAG\"/g" \
    "$VALUES_FILE"
else
  sed -i \
    "s/tag: \".*\"/tag: \"$TAG\"/g" \
    "$VALUES_FILE"
fi

# 8. Git commit
echo "=== Committing GitOps changes ==="

CURRENT_BRANCH=$(git branch --show-current)

git add "$VALUES_FILE"

if git diff --cached --quiet; then
  echo "No GitOps changes detected."
else
  git commit \
    -m "chore(gitops): update $ENV_NAME image tags to $TAG"

  git push origin "$CURRENT_BRANCH"
fi

echo "=========================================="
echo "Deployment completed successfully."
echo "ArgoCD will synchronize the new images."
echo "=========================================="