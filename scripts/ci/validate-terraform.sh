#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
for directory in terraform/bootstrap terraform/environments/dev terraform/environments/prod; do
  echo "==> Validating $directory"
  terraform -chdir="$ROOT_DIR/$directory" init -backend=false -input=false
  terraform -chdir="$ROOT_DIR/$directory" validate
done
