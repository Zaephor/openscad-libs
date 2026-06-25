#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1

for f in templates/library/lib.json templates/library/README.md templates/library/__NAME__.scad \
         templates/project-single/__NAME__.scad templates/project-single/README.md templates/project-single/PRINTING.md \
         templates/project-multipart/assembly.scad templates/project-multipart/parts/body.scad \
         templates/project-multipart/README.md templates/project-multipart/PRINTING.md; do
  [ -f "$f" ] || { echo "missing $f"; exit 1; }
done

grep -q '__NAME__' templates/library/lib.json || { echo "lib.json missing placeholder"; exit 1; }
grep -q 'explode = 0; *// *\[0:0.01:1\]' templates/project-multipart/assembly.scad || { echo "assembly missing explode slider"; exit 1; }
grep -q 'show_body = true;' templates/project-multipart/assembly.scad || { echo "assembly missing part bool"; exit 1; }
jq -e '.name and .description and .version and (.sources|type=="array")' templates/library/lib.json >/dev/null || { echo "lib.json bad shape"; exit 1; }
echo ok
