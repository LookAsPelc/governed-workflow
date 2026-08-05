#!/usr/bin/env bash
set -euo pipefail
# Apply defaults to a dry-run; --apply is required for writes.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec python3 "$root/scripts/iron_box.py" apply "$@"
