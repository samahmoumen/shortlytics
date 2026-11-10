#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_NAME="${1:-dev}"
if [[ "$ENV_NAME" != "dev" ]]; then
  echo "This helper deploys development only. Promote production with .github/workflows/promote-prod.yml." >&2
  exit 2
fi

VALUES_FILE="gitops-manifests/shortlytics/values-dev.yaml"
REGISTRY="$(terraform -chdir=terraform/environments/dev output -raw acr_login_server)"
IMAGE_TAG="$(git rev-parse HEAD)"
ACR_NAME="${REGISTRY%%.*}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree must be clean before building and committing GitOps changes." >&2
  exit 1
fi

az acr login --name "$ACR_NAME"
./scripts/deployment/publish-images.sh "$REGISTRY" "$IMAGE_TAG"
for component in backend frontend; do
  az acr repository update --name "$ACR_NAME" \
    --image "shortlytics-$component:$IMAGE_TAG" \
    --write-enabled false --delete-enabled false
done

./scripts/deployment/update-gitops-images.sh dev "$REGISTRY" "$IMAGE_TAG"

git config user.name "${GIT_AUTHOR_NAME:-Shortlytics deploy}"
git config user.email "${GIT_AUTHOR_EMAIL:-shortlytics-deploy@users.noreply.github.com}"
git add "$VALUES_FILE"
git commit -m "chore(gitops): deploy development $IMAGE_TAG"
git push origin HEAD:"$(git branch --show-current)"

echo "Development image tags updated. Argo CD will reconcile the GitOps commit."
