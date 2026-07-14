#!/usr/bin/env bash
# Render every examples/*.scad to images/<name>.png via the repo's headless
# (no-GL) renderer. Regenerates the glossary/guidance illustrations.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
renderer="$root/.claude/skills/verify-scad-geometry/render_stl.py"
mkdir -p "$here/images"
for f in "$here"/examples/*.scad; do
  n="$(basename "$f" .scad)"
  python3 "$renderer" "$f" --out "$here/images/$n.png"
done
echo "rendered $(ls "$here"/examples/*.scad | wc -l) images"
