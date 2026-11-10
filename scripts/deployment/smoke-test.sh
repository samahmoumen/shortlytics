#!/usr/bin/env bash
set -Eeuo pipefail
NAMESPACE="${1:?Usage: smoke-test.sh <namespace> <frontend-base-url>}"
BASE_URL="${2:?Usage: smoke-test.sh <namespace> <frontend-base-url>}"
BASE_URL="${BASE_URL%/}"

echo "Checking frontend..."
curl --fail --silent --show-error --retry 10 --retry-connrefused --retry-delay 3 "$BASE_URL/" >/dev/null

BACKEND_SERVICE="$(kubectl get services -n "$NAMESPACE" -l app.kubernetes.io/name=backend \
  -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$BACKEND_SERVICE" ]]; then
  echo "Backend service not found in namespace $NAMESPACE." >&2
  exit 1
fi

LOCAL_PORT=18080
kubectl port-forward -n "$NAMESPACE" "service/$BACKEND_SERVICE" "$LOCAL_PORT:8080" >/tmp/shortlytics-port-forward.log 2>&1 &
PORT_FORWARD_PID=$!
# shellcheck disable=SC2317
cleanup() {
  kill "$PORT_FORWARD_PID" 2>/dev/null || true
}
trap cleanup EXIT

attempt=0
while (( attempt < 20 )); do
  attempt=$((attempt + 1))
  if curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/actuator/health" >/dev/null; then
    echo "Backend actuator health is UP."
    exit 0
  fi
  sleep 1
done

cat /tmp/shortlytics-port-forward.log
echo "Backend health endpoint did not become ready." >&2
exit 1
