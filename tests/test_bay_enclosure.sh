#!/usr/bin/env bash
# Verifies the bay-enclosure project renders clean at defaults, and that the
# tests/asserts.scad negative control genuinely aborts the height fit-assert
# (OpenSCAD exit code unreliable for asserts -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bay-enclosure"

run() { # <stl-out> <scad> [extra -D args...]
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default (bay525_hh, device_u=1) must render clean.
out="$(run "$tmp/be.stl" "$proj/bay-enclosure.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: default bay-enclosure.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/be.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# Faceplate bbox: X-span == rack10_panel_width("labrax")=254, Z-span ==
# rack10_device_height(1)=43.66 (the front panel itself -- the % ghost
# preview of drive_placeholder() is excluded from STL export).
python3 - "$tmp/be.stl" <<'PY' || { echo "FAIL: faceplate bbox != panel_width(254) x device_height(1)=43.66"; fail=1; }
import struct, sys
d = open(sys.argv[1], "rb").read()
n = struct.unpack("<I", d[80:84])[0]; off = 84
xs = []; zs = []
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        x, y, z = struct.unpack("<3f", d[b:b+12])
        xs.append(x); zs.append(z)
xspan = max(xs) - min(xs); zspan = max(zs) - min(zs)
ok = abs(xspan - 254) < 0.05 and abs(zspan - 43.66) < 0.05
sys.exit(0 if ok else 1)
PY

# Task 3 (#41): rear #40 support-tongue presence/placement. Per
# rack-support's consumer-contract placement formula, the tongue's tip must
# land exactly at rack10_rear_post_y("labrax")=240 (rack_support_plate()'s
# own mounting plane) -- so the tray's overall Y-max must be 240. A floor/
# tongue that stops short (or overshoots) would fail to mate with the rear
# rack_support_plate().
python3 - "$tmp/be.stl" <<'PY' || { echo "FAIL: rear Y-max != rack10_rear_post_y(\"labrax\")=240 -- tongue missing/misplaced"; fail=1; }
import struct, sys
d = open(sys.argv[1], "rb").read()
n = struct.unpack("<I", d[80:84])[0]; off = 84
ys = []
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        x, y, z = struct.unpack("<3f", d[b:b+12])
        ys.append(y)
ok = abs(max(ys) - 240) < 0.05
sys.exit(0 if ok else 1)
PY

# Negative control: tests/asserts.scad overrides device_type=bay525_fh
# (full-height, 82.55mm) at device_u=1 -- MUST abort the height fit-assert.
# A silent-pass here means the fit-assert regressed.
out="$(run "$tmp/neg.stl" "$proj/tests/asserts.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts.scad (bay525_fh @ 1U) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg.stl" ]; then
  echo "FAIL: tests/asserts.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Device-type guard: an unknown / non-block device_type must also abort (the
# drive_known_types()+drive_family()=="block" guard at the top of the file).
out="$(run "$tmp/badtype.stl" "$proj/bay-enclosure.scad" -D 'device_type="m2_2280"')"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: card-family device_type (m2_2280) did NOT abort the block-drive guard:"
  echo "$out"; fail=1
fi

# Task 4 (#41): the two remaining LOCKED presets (bay525_hh@1U is already the
# default, checked above) must render clean -- via -D command-line overrides
# directly against bay-enclosure.scad, same idiom as the device-type-guard
# check above (no separate include-and-override .scad file needed: unlike
# tests/asserts.scad, these are plain positive-control renders, not
# alternate-top-level-variable negative controls, so there's nothing that
# needs a second file just to get a second value in scope).
out="$(run "$tmp/fh2.stl" "$proj/bay-enclosure.scad" -D 'device_type="bay525_fh"' -D 'device_u=2')"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: bay525_fh@2U preset errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/fh2.stl" ] || { echo "FAIL: bay525_fh@2U preset produced no/empty STL"; fail=1; }
python3 - "$tmp/fh2.stl" <<'PY' || { echo "FAIL: bay525_fh@2U bbox Z-span != rack10_device_height(2)=88.11"; fail=1; }
import struct, sys
d = open(sys.argv[1], "rb").read()
n = struct.unpack("<I", d[80:84])[0]; off = 84
zs = []
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        zs.append(struct.unpack("<3f", d[b:b+12])[2])
sys.exit(0 if abs((max(zs) - min(zs)) - 88.11) < 0.05 else 1)
PY

out="$(run "$tmp/b35.stl" "$proj/bay-enclosure.scad" -D 'device_type="bay35"' -D 'device_u=1')"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: bay35@1U preset errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/b35.stl" ] || { echo "FAIL: bay35@1U preset produced no/empty STL"; fail=1; }
python3 - "$tmp/b35.stl" <<'PY' || { echo "FAIL: bay35@1U bbox Z-span != rack10_device_height(1)=43.66"; fail=1; }
import struct, sys
d = open(sys.argv[1], "rb").read()
n = struct.unpack("<I", d[80:84])[0]; off = 84
zs = []
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        zs.append(struct.unpack("<3f", d[b:b+12])[2])
sys.exit(0 if abs((max(zs) - min(zs)) - 43.66) < 0.05 else 1)
PY

# Task 4 (#41): confirm each of the three LOCKED presets' device_type
# actually stamps len(drive_side_holes(type))*2 side-mount holes -- i.e. BOTH
# walls get cut (drive_holes(...,"side",...) cuts one cylinder per side-hole
# entry at EACH of the drive's two Y-faces, see drives.scad). Proxy (same
# idiom as test_keystone_faceplate.sh's facet-count check): render just the
# cutter geometry via the exact same drive_holes(type, faces="side", depth)
# call bay_enclosure() itself makes (single source of truth, no duplicated
# hole data) as a bare union with no difference(); CGAL's own render-summary
# "Volumes:" line counts N disjoint solids as N+1 (verified empirically: a
# union of 4 non-touching cylinders reports "Volumes: 5") -- so
# (Volumes - 1) must equal the drives-lib-computed EXPECT, which the probe
# echoes itself rather than hardcoding, so a future drives-lib data change
# updates both sides of the comparison together.
check_side_holes() { # <device_type>
  local type="$1"
  local probe="$tmp/holes_${type}.scad"
  cat > "$probe" <<EOF
use <drives/drives.scad>;
device_type = "$type";
echo(str("EXPECT=", len(drive_side_holes(device_type)) * 2));
drive_holes(device_type, faces = "side", depth = 6.8); // depth mirrors bay-enclosure.scad's own 2*wall+2 at wall=2.4
EOF
  local out
  out="$(run "$tmp/holes_${type}.stl" "$probe")"
  local expect volumes
  expect="$(echo "$out" | grep -o 'EXPECT=[0-9]*' | tail -1 | cut -d= -f2)"
  volumes="$(echo "$out" | grep -o 'Volumes:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
  if [ -z "$expect" ] || [ -z "$volumes" ]; then
    echo "FAIL: $type side-hole probe produced no EXPECT/Volumes -- can't verify hole count:"; echo "$out"; fail=1
    return
  fi
  if [ "$((volumes - 1))" -ne "$expect" ]; then
    echo "FAIL: $type side-hole cutter count $((volumes - 1)) != expected $expect (both walls)"
    fail=1
  fi
}
check_side_holes "bay525_hh"
check_side_holes "bay525_fh"
check_side_holes "bay35"

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
