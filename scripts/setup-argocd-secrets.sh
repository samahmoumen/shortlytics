#!/bin/bash
set -e

# Configuration variables
RESOURCE_GROUP="shortlytics-dev-rg"
ACR_NAME="shortlyticsdevacrkrcx"
NAMESPACE="argocd"
GIT_REPO="https://github.com/samahmoumen/shortlytics.git"
GIT_USER="samahmoumen"

echo "=== 1. Ensuring namespace '$NAMESPACE' exists ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -



echo "=== 3. Creating Git Credentials Secret ==="
# Check if GITHUB_PAT environment variable is set, otherwise prompt securely
if [ -z "$GITHUB_PAT" ]; then
  echo -n "Enter your GitHub Personal Access Token (PAT): "
  read -rs GITHUB_PAT
  echo
fi

kubectl delete secret generic git-credentials -n "$NAMESPACE" --ignore-not-found
kubectl create secret generic git-credentials \
  --namespace "$NAMESPACE" \
  --from-literal=url="$GIT_REPO" \
  --from-literal=username="$GIT_USER" \
  --from-literal=password="$GITHUB_PAT"

echo "Successfully created 'git-credentials'."
echo "=== All ArgoCD Image Updater secrets configured successfully! ==="