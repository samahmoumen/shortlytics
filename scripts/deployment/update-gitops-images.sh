#!/usr/bin/env bash
set -Eeuo pipefail

ENVIRONMENT="${1:?Usage: update-gitops-images.sh <dev|prod> <registry> <full-git-sha>}"
REGISTRY="${2:?Usage: update-gitops-images.sh <dev|prod> <registry> <full-git-sha>}"
IMAGE_TAG="${3:?Usage: update-gitops-images.sh <dev|prod> <registry> <full-git-sha>}"

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Environment must be dev or prod." >&2
  exit 2
fi
if [[ ! "$IMAGE_TAG" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Image tag must be a full Git commit SHA." >&2
  exit 2
fi

VALUES_FILE="gitops-manifests/shortlytics/values-$ENVIRONMENT.yaml"
[[ -f "$VALUES_FILE" ]] || { echo "Missing $VALUES_FILE" >&2; exit 1; }
command -v yq >/dev/null || { echo "Mike Farah yq v4 is required." >&2; exit 1; }
export REGISTRY IMAGE_TAG

yq -i '
  .global.imageRegistry = strenv(REGISTRY) |
  .backend.image.tag = strenv(IMAGE_TAG) |
  .frontend.image.tag = strenv(IMAGE_TAG) |
  .backend.image.pullPolicy = "IfNotPresent" |
  .frontend.image.pullPolicy = "IfNotPresent"
' "$VALUES_FILE"

if [[ "$ENVIRONMENT" == "prod" ]]; then
  : "${PROD_TENANT_ID:?PROD_TENANT_ID is required for production promotion}"
  : "${PROD_KEY_VAULT:?PROD_KEY_VAULT is required for production promotion}"
  : "${PROD_WORKLOAD_CLIENT_ID:?PROD_WORKLOAD_CLIENT_ID is required for production promotion}"
  yq -i '
    .global.azure.tenantId = strenv(PROD_TENANT_ID) |
    .global.azure.keyVaultName = strenv(PROD_KEY_VAULT) |
    .global.azure.workloadIdentityClientId = strenv(PROD_WORKLOAD_CLIENT_ID)
  ' "$VALUES_FILE"
fi

echo "Updated $VALUES_FILE to image tag $IMAGE_TAG"
