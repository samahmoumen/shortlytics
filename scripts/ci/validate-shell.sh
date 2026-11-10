#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
command -v shellcheck >/dev/null || { echo "Install ShellCheck first." >&2; exit 1; }
find "$ROOT_DIR/scripts" -type f -name '*.sh' -print0 | xargs -0 -r shellcheck
