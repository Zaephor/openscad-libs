#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1

cleanup() { rm -rf libraries/_tlib projects/_tsingle projects/_tmulti libraries/_t-lib projects/_t-proj; }
cleanup

bash scripts/new-lib.sh _tlib || { echo "new-lib failed"; cleanup; exit 1; }
test -f libraries/_tlib/_tlib.scad || { echo "lib scad not renamed"; cleanup; exit 1; }
grep -q '__NAME__' -r libraries/_tlib && { echo "placeholder left in lib"; cleanup; exit 1; }
grep -q 'module _tlib_placeholder' libraries/_tlib/_tlib.scad || { echo "missing placeholder role"; cleanup; exit 1; }
grep -q 'module _tlib_holes' libraries/_tlib/_tlib.scad || { echo "missing holes role"; cleanup; exit 1; }
jq -e '.name=="_tlib"' libraries/_tlib/lib.json >/dev/null || { echo "lib.json name not substituted"; cleanup; exit 1; }

# Refuses to overwrite.
if bash scripts/new-lib.sh _tlib 2>/dev/null; then echo "did not refuse existing"; cleanup; exit 1; fi

bash scripts/new-project.sh _tsingle || { echo "new-project failed"; cleanup; exit 1; }
test -f projects/_tsingle/_tsingle.scad || { echo "project scad not renamed"; cleanup; exit 1; }

bash scripts/new-project.sh _tmulti --multipart || { echo "multipart failed"; cleanup; exit 1; }
test -f projects/_tmulti/assembly.scad || { echo "no assembly.scad"; cleanup; exit 1; }
test -f projects/_tmulti/parts/body.scad || { echo "no parts/body.scad"; cleanup; exit 1; }
grep -q '__NAME__' -r projects/_tmulti && { echo "placeholder left in project"; cleanup; exit 1; }

# --- Hyphenated name: identifiers must be underscored, paths/metadata stay hyphenated. ---
osc() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

bash scripts/new-lib.sh _t-lib || { echo "hyphen new-lib failed"; cleanup; exit 1; }
# Literal name preserved (hyphenated) in filename, lib.json, README use-path:
test -f libraries/_t-lib/_t-lib.scad            || { echo "hyphen lib scad not renamed"; cleanup; exit 1; }
jq -e '.name=="_t-lib"' libraries/_t-lib/lib.json >/dev/null || { echo "hyphen lib.json name wrong"; cleanup; exit 1; }
grep -q 'use <_t-lib/_t-lib.scad>' libraries/_t-lib/README.md || { echo "hyphen use-path wrong"; cleanup; exit 1; }
# Identifiers underscored, NOT hyphenated:
grep -q 'module _t_lib_placeholder' libraries/_t-lib/_t-lib.scad || { echo "ident not underscored"; cleanup; exit 1; }
grep -q 'function _t_lib_width'      libraries/_t-lib/_t-lib.scad || { echo "fn ident not underscored"; cleanup; exit 1; }
grep -qE '(module|function) _t-lib'  libraries/_t-lib/_t-lib.scad && { echo "hyphenated identifier present"; cleanup; exit 1; }
# No placeholder tokens left:
grep -qrE '__NAME__|__IDENT__' libraries/_t-lib && { echo "placeholder token left in lib"; cleanup; exit 1; }
# It must actually parse/render in OpenSCAD (the real bug):
out="$(osc libraries/_t-lib/_t-lib.scad)"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' && { echo "hyphen lib fails to parse:"; echo "$out"; cleanup; exit 1; }

# Sweep: single-part project with a hyphenated name must also parse.
bash scripts/new-project.sh _t-proj || { echo "hyphen new-project failed"; cleanup; exit 1; }
test -f projects/_t-proj/_t-proj.scad || { echo "hyphen project scad not renamed"; cleanup; exit 1; }
grep -q 'module _t_proj' projects/_t-proj/_t-proj.scad || { echo "project ident not underscored"; cleanup; exit 1; }
out="$(osc projects/_t-proj/_t-proj.scad)"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' && { echo "hyphen project fails to parse:"; echo "$out"; cleanup; exit 1; }

cleanup
echo ok
