#!/usr/bin/env bash
# Headless-render a project's entry file to a PNG in its renders/ dir.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
proj="${1:?Usage: render.sh <project>}"
dir="$ROOT/projects/$proj"
entry="$dir/assembly.scad"
[ -f "$entry" ] || entry="$dir/$proj.scad"
[ -f "$entry" ] || { echo "No entry file for project $proj" >&2; exit 1; }
mkdir -p "$dir/renders"
"$ROOT/scripts/openscad.sh" \
  --colorscheme=Tomorrow \
  --imgsize=1024,768 \
  --autocenter --viewall \
  -o "$dir/renders/$proj.png" \
  "$entry"
echo "Rendered $dir/renders/$proj.png"
