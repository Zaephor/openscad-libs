#!/usr/bin/env bash
# Launch OpenSCAD with OPENSCADPATH pointed at this repo's libraries/.
# All other scripts go through this so the library path is always correct.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export OPENSCADPATH="$ROOT/libraries"
echo "OPENSCADPATH=$OPENSCADPATH" >&2
exec openscad "$@"
