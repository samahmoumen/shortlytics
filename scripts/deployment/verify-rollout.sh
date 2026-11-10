#!/usr/bin/env bash
set -Eeuo pipefail
NAMESPACE="${1:?Usage: verify-rollout.sh <namespace> [timeout]}"
TIMEOUT="${2:-300s}"

mapfile -t deployments < <(
  kubectl get deployments -n "$NAMESPACE" -l 'app.kubernetes.io/name in (backend,frontend)' \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
)
if [[ "${#deployments[@]}" -eq 0 ]]; then
  echo "No shortlytics backend/frontend deployments found in namespace $NAMESPACE." >&2
  exit 1
fi
for deployment in "${deployments[@]}"; do
  kubectl rollout status "deployment/$deployment" -n "$NAMESPACE" --timeout="$TIMEOUT"
done
kubectl get pods -n "$NAMESPACE" -o wide
