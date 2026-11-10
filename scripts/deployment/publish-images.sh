#!/usr/bin/env bash
set -Eeuo pipefail

REGISTRY="${1:?Usage: publish-images.sh <acr-login-server> <full-git-sha>}"
IMAGE_TAG="${2:?Usage: publish-images.sh <acr-login-server> <full-git-sha>}"

if [[ ! "$IMAGE_TAG" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Image tag must be a full Git commit SHA." >&2
  exit 2
fi

for component in backend frontend; do
  IMAGE="$REGISTRY/shortlytics-$component:$IMAGE_TAG"
  CONTEXT="$component"
  echo "==> Building $IMAGE"
  docker buildx build --pull --platform linux/amd64 --tag "$IMAGE" --load "./$CONTEXT"
  echo "==> Scanning $IMAGE"
  trivy image --ignore-unfixed --exit-code 1 --severity HIGH,CRITICAL "$IMAGE"
  echo "==> Pushing $IMAGE"
  docker push "$IMAGE"
  docker buildx imagetools inspect "$IMAGE"
done
