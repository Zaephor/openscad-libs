#!/usr/bin/env bash
# Verifies the css610-underdesk-mount project renders + data asserts pass
# (OpenSCAD exit code unreliable; grep stderr).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/css610-underdesk-mount"
run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

fail=0

# Data asserts must pass.
out="$(run "$proj/tests/asserts.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "asserts.scad failed"; echo "$out"; fail=1; } || true

# Task 2 (#59): bracket must render clean, and the STL bbox must confirm the
# flush-flange contract (mesh-derived, not just formula-derived -- the source
# formula check lives in tests/asserts.scad, but only an actual render catches
# a geometry bug like the gusset-overshoot fixed during Task 2 review: the
# original brief's gusset polygon poked 4mm above the flange top, which only
# showed up as a wrong STL Z-max, not a broken assert).
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/br.stl" "$proj/css610-underdesk-mount.scad" 2>&1)"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: default css610-underdesk-mount.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/br.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

python3 - "$tmp/br.stl" <<'PY' || { echo "FAIL: bracket STL bbox mismatch (expect X 0..28, Y 0..44, Z 0..47.1)"; fail=1; }
import struct, sys
d = open(sys.argv[1], "rb").read()
n = struct.unpack("<I", d[80:84])[0]; off = 84
xs = []; ys = []; zs = []
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        x, y, z = struct.unpack("<3f", d[b:b+12])
        xs.append(x); ys.append(y); zs.append(z)
xspan = (min(xs), max(xs)); yspan = (min(ys), max(ys)); zspan = (min(zs), max(zs))
# X: leg_thickness(3) + flange_len(25) = 28. Y: leg_len = 34.5+9.5 = 44.
# Z: flush-flange contract, top == H+standoff == 47.1 (gusset must not exceed it).
ok = (abs(xspan[0] - 0) < 0.05 and abs(xspan[1] - 28) < 0.05 and
      abs(yspan[0] - 0) < 0.05 and abs(yspan[1] - 44) < 0.05 and
      abs(zspan[0] - 0) < 0.05 and abs(zspan[1] - 47.1) < 0.05)
sys.exit(0 if ok else 1)
PY

[ "$fail" -eq 0 ] && echo ok || exit 1
