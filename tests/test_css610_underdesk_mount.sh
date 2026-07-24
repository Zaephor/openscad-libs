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

# --- hole-void regression (Task 2 review, #59 Finding 2) ---
# A real bug was caught manually during Task 2: the brief's countersink cone
# offset left a 1mm solid floor blocking a wood-screw hole from ever opening
# through the flange -- a bug that neither asserts.scad's numeric-position
# checks (hole coords land inside leg/flange bounds) nor the STL bbox check
# above (blind to internal voids) would catch. Regression-lock it: probe
# each hole's expected through-location with a small box and require the
# rendered intersection with the bracket be EMPTY (OpenSCAD prints "Current
# top level object is empty." and writes no STL) -- a real void, not just
# numerically-placed dead space. Positive controls (same idiom, off-hole
# material) prove the probes are actually discriminating, not just too
# small/misplaced to ever hit anything.
mod="$proj/css610-underdesk-mount.scad"

probe_empty() {  # $1 = probe .scad body (intersection block), $2 = description
  rm -f "$tmp/p.stl"
  cat > "$tmp/p.scad" <<EOF
use <$mod>;
intersection() {
    css610_underdesk_bracket();
    $1
}
EOF
  out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p.stl" "$tmp/p.scad" 2>&1)"
  if [ -f "$tmp/p.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
    echo "FAIL: $2 -- expected empty (real void), got material:"; echo "$out"; fail=1
  fi
}

probe_solid() {  # $1 = probe .scad body (intersection block), $2 = description
  rm -f "$tmp/p.stl"
  cat > "$tmp/p.scad" <<EOF
use <$mod>;
intersection() {
    css610_underdesk_bracket();
    $1
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p.stl" "$tmp/p.scad" >/dev/null 2>&1
  [ -s "$tmp/p.stl" ] || { echo "FAIL: $2 -- expected solid material, got empty (probe miscalibrated)"; fail=1; }
}

# 4x M3 leg holes (X spans the full leg_thickness=3, so a probe centered in
# X and within the hole's Y/Z radius must be empty all the way through).
for hyz in "9.5 9.5" "9.5 34.5" "34.5 9.5" "34.5 34.5"; do
  set -- $hyz
  probe_empty "translate([1, $1 - 1, $2 - 1]) cube([1, 2, 2]);" \
    "leg M3 hole at Y=$1,Z=$2 does not open through"
done
# Positive control: leg material away from any hole (corner, Y=1,Z=1).
probe_solid "translate([1, 0, 0]) cube([1, 2, 2]);" \
  "leg off-hole material (Y=0,Z=0) unexpectedly empty"

# 2x flange wood-screw holes (X0=leg_thickness+flange_len/2=15.5; probe the
# FULL flange Z-thickness [43.1,47.1] to catch exactly the caught bug class:
# a solid floor at one end of that span while the rest is void).
for fy in 13.2 30.8; do
  probe_empty "translate([14.5, $fy - 1, 43.0]) cube([2, 2, 4.2]);" \
    "flange wood-screw hole at Y=$fy does not open through"
done
# Positive control: flange material away from any hole (Y=1, same Z-band).
probe_solid "translate([0, 0, 45]) cube([2, 2, 2]);" \
  "flange off-hole material (Y=0) unexpectedly empty"

[ "$fail" -eq 0 ] && echo ok || exit 1
