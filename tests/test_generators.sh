#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1

cleanup() { rm -rf libraries/_tlib projects/_tsingle projects/_tmulti; }
cleanup

bash scripts/new-lib.sh _tlib || { echo "new-lib failed"; cleanup; exit 1; }
test -f libraries/_tlib/_tlib.scad || { echo "lib scad not renamed"; cleanup; exit 1; }
grep -q '__NAME__' -r libraries/_tlib && { echo "placeholder left in lib"; cleanup; exit 1; }
jq -e '.name=="_tlib"' libraries/_tlib/lib.json >/dev/null || { echo "lib.json name not substituted"; cleanup; exit 1; }

# Refuses to overwrite.
if bash scripts/new-lib.sh _tlib 2>/dev/null; then echo "did not refuse existing"; cleanup; exit 1; fi

bash scripts/new-project.sh _tsingle || { echo "new-project failed"; cleanup; exit 1; }
test -f projects/_tsingle/_tsingle.scad || { echo "project scad not renamed"; cleanup; exit 1; }

bash scripts/new-project.sh _tmulti --multipart || { echo "multipart failed"; cleanup; exit 1; }
test -f projects/_tmulti/assembly.scad || { echo "no assembly.scad"; cleanup; exit 1; }
test -f projects/_tmulti/parts/body.scad || { echo "no parts/body.scad"; cleanup; exit 1; }
grep -q '__NAME__' -r projects/_tmulti && { echo "placeholder left in project"; cleanup; exit 1; }

cleanup
echo ok
