#!/usr/bin/env bash
set -Eeuo pipefail
ENVIRONMENT="${1:?Usage: rollback-gitops.sh <dev|prod> <known-good-full-sha>}"
KNOWN_GOOD_TAG="${2:?Usage: rollback-gitops.sh <dev|prod> <known-good-full-sha>}"

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Environment must be dev or prod." >&2
  exit 2
fi
if [[ ! "$KNOWN_GOOD_TAG" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Rollback target must be a full Git commit SHA." >&2
  exit 2
fi

REGISTRY="$(yq -r '.global.imageRegistry' "gitops-manifests/shortlytics/values-$ENVIRONMENT.yaml")"
for component in backend frontend; do
  docker buildx imagetools inspect "$REGISTRY/shortlytics-$component:$KNOWN_GOOD_TAG" >/dev/null
done

IMAGE_TAG="$KNOWN_GOOD_TAG" REGISTRY="$REGISTRY" \
  yq -i '.backend.image.tag = strenv(IMAGE_TAG) | .frontend.image.tag = strenv(IMAGE_TAG)' \
  "gitops-manifests/shortlytics/values-$ENVIRONMENT.yaml"

echo "GitOps values updated. Commit and push this change to let Argo CD reconcile."
