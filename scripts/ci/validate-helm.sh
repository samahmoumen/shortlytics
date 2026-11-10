#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="$ROOT_DIR/gitops-manifests/shortlytics"
helm dependency build "$CHART"
helm lint "$CHART" --values "$CHART/values-dev.yaml"
helm lint "$CHART" --values "$CHART/values-prod.yaml"
helm template shortlytics-dev "$CHART" --namespace shortlytics-dev --values "$CHART/values-dev.yaml" > /tmp/shortlytics-dev.yaml
helm template shortlytics-prod "$CHART" --namespace shortlytics-prod --values "$CHART/values-prod.yaml" > /tmp/shortlytics-prod.yaml
