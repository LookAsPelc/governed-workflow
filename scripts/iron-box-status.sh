#!/usr/bin/env bash
set -euo pipefail
# read-only status: the helper never invokes a client or network.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec python3 "$root/scripts/iron_box.py" status "$@"
