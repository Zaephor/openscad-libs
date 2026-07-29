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

# --- rack_support_plate_keepout() interference test (#63 Task 4) ---
# The real shipped consumer, differenced against rack_support_plate_keepout()
# (published in Task 2), must not solid-solid interfere with
# rack_support_plate() at the SAME placement (rack10_rear_post_y) both parts
# use -- the actual bug this fix exists for (measured 3554.86mm^3 of real
# interference before it, reduced to 1333.51mm^3 by Task 1's gusset-narrowing
# alone). Unlike the minimal reference stub tray probed in
# tests/test_rack_support_lib.sh (which achieves a true CGAL "is empty"
# result), this probe measures an EXACT 0.0mm^3 (verified directly: all 24
# triangle vertices in the resulting STL sit at Y=rpy identically, i.e. the
# result is a flat, zero-thickness sheet, not a 3D solid) with 24 facets and
# a CGAL non-manifold warning -- a coincident-face TOUCH, not residual
# interference.
#
# CAUSE (measured; an earlier revision of this comment blamed the keep-out
# wedge's margin-fixed corner vertex, which the geometry rules out -- the
# sheet's facets span |X| 30.601 to 75.425 and Z 0 to 43.66, i.e. the side
# walls, and the wedge never exceeds |X| 30.601 / Z 12.201, so it cannot be
# producing them): rack_support_plate_keepout() deliberately OMITS the
# plate's panel-internal portion, Y in [0,thickness] (documented at
# rack-support.scad's keep-out doc), so the keep-out's rearmost bound IS the
# mounting-face plane, Y=rpy. bay_enclosure()'s own floor and side walls also
# run exactly to Y=rpy, and the plate has material there, so the two solids
# share that entire plane -- every vertex of the 24 facets sits at Y=240.0000
# exactly. margin cannot help: it has no +Y component at all (see the
# keep-out doc), so no margin value opens a gap at the mounting face.
#
# This is also why the minimal stub tray in tests/test_rack_support_lib.sh
# reaches a true CGAL "is empty" while this real consumer does not: the
# plate's cavity cut runs through the panel, so the stub tray's only material
# at Y=rpy lies inside the cavity band where the plate is void, whereas
# bay_enclosure() has walls and a full-width floor outside that band. Same
# artifact class as the plate x drive_tray() coincident touch this plan's own
# Task 5 documents (24 facets, 0.00mm^3, at Y=rpy/Z=0) -- a known, accepted
# non-manifold-touch signature in this codebase, not a defect.
#
# The check below still uses a volume
# threshold (< 1.0mm^3) rather than the is-empty text idiom, since this
# real-consumer geometry's coincident touch is a non-manifold sliver (some
# facets, zero volume) rather than OpenSCAD's literal empty-result case; the
# 1.0mm^3 bound is pure headroom above the measured-exact 0.0, not a
# load-bearing threshold -- still 3+ orders of magnitude below the pre-fix
# 1333.51mm^3 figure.
#
# CRITICAL: scripts/openscad.sh only sets OPENSCADPATH to libraries/, so a
# probe .scad that `use`s bay-enclosure.scad by bare libname would silently
# fail to resolve it -- OpenSCAD prints "WARNING: Ignoring unknown module/
# function" per undefined symbol and happily renders an empty/undef model,
# which still prints plausible Simple/Facets/Volumes lines and would pass a
# naive check (this exact trap produced two false results during the
# original investigation of this bug). `use <$proj/...>` below is an
# ABSOLUTE path (bypasses OPENSCADPATH lookup entirely -- same idiom
# tests/test_keystone_faceplate.sh already uses to reach a projects/ file),
# and stderr is grepped for the failure signatures regardless.
stl_volume() {
  python3 - "$1" <<'PY'
import struct, sys
try:
    d = open(sys.argv[1], "rb").read()
except FileNotFoundError:
    print(0.0); sys.exit(0)
n = struct.unpack("<I", d[80:84])[0]; off = 84
vol = 0.0
for i in range(n):
    pts = []
    for v in range(3):
        b = off + i*50 + 12 + v*12
        pts.append(struct.unpack("<3f", d[b:b+12]))
    x1,y1,z1 = pts[0]; x2,y2,z2 = pts[1]; x3,y3,z3 = pts[2]
    vol += (x1*(y2*z3-y3*z2) - y1*(x2*z3-x3*z2) + z1*(x2*y3-x3*y2)) / 6.0
print(abs(vol))
PY
}

cat > "$tmp/keepout_interference.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
use <$proj/bay-enclosure.scad>;
standard = "labrax";
rpy = rack10_rear_post_y(standard);
intersection() {
    translate([0, rpy, 0]) rack_support_plate(standard, 1);
    bay_enclosure();
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/keepout_interference.stl" "$tmp/keepout_interference.scad" 2>&1)"
if echo "$out" | grep -qiE 'Ignoring unknown|Can.t open library'; then
  echo "FAIL: keepout interference probe failed to resolve bay-enclosure.scad (undef-poisoned model):"
  echo "$out"; fail=1
else
  vol="$(stl_volume "$tmp/keepout_interference.stl")"
  awk -v v="$vol" 'BEGIN { exit !(v < 1.0) }' \
    || { echo "FAIL: bay_enclosure() still interferes with rack_support_plate() -- volume ${vol}mm^3 (want ~0, was 3554.86 before the keepout fix)"; fail=1; }
fi

# PAIRED -- the consumer's own rear tongue survives the keepout subtraction,
# checked by volume (same technique as tests/test_rack_support_lib.sh's Task
# 2 paired check): an over-broad keepout that also erodes the channel cavity
# would still pass the interference check above by silently deleting
# bay_enclosure()'s own tongue. Intersect the real consumer with the
# tongue's own bounding band (accessor-derived, not a hardcoded literal) and
# require its volume equal the SAME band intersected with a lone reference
# rack_support_tongue() at the documented placement, rendered separately.
cat > "$tmp/keepout_tongue_survives.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
use <$proj/bay-enclosure.scad>;
standard = "labrax";
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rs  = rack_support_rail_size();
ed  = rack_support_engagement_depth();
slack = 0.1;
intersection() {
    bay_enclosure();
    translate([-rs[0]/2 - slack, rpy - ed, ft])
        cube([rs[0] + 2 * slack, ed, rs[1]]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/keepout_tongue_survives.stl" "$tmp/keepout_tongue_survives.scad" 2>&1)"
if echo "$out" | grep -qiE 'Ignoring unknown|Can.t open library'; then
  echo "FAIL: tongue-survival probe failed to resolve bay-enclosure.scad (undef-poisoned model):"
  echo "$out"; fail=1
fi

cat > "$tmp/tongue_reference.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rs  = rack_support_rail_size();
ed  = rack_support_engagement_depth();
reach = rpy - ed;
slack = 0.1;
intersection() {
    translate([0, reach, 0]) rack_support_tongue();
    translate([-rs[0]/2 - slack, rpy - ed, ft])
        cube([rs[0] + 2 * slack, ed, rs[1]]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tongue_reference.stl" "$tmp/tongue_reference.scad" 2>/dev/null

actual_vol="$(stl_volume "$tmp/keepout_tongue_survives.stl")"
want_vol="$(stl_volume "$tmp/tongue_reference.stl")"
awk -v a="$actual_vol" -v w="$want_vol" 'BEGIN { d = a - w; if (d < 0) d = -d; exit !(w > 0 && d < 1.0) }' \
  || { echo "FAIL: keepout eroded bay_enclosure()'s own tongue (paired assertion) -- actual ${actual_vol}mm^3 vs reference ${want_vol}mm^3"; fail=1; }

# CONNECTIVITY -- the tongue must still be ATTACHED, not merely present. The
# volume assertion above cannot see this: the keep-out's cavity exclusion
# preserves the tongue's volume exactly by design, so a tongue floating free
# of the body measures identical to a properly anchored one. And it really can
# float: the keep-out necessarily deletes this project's ramp+shelf over the
# tongue's whole engagement span (that volume belongs to rack_support_plate()'s
# own bearing floor), leaving only a sub-layer eps film there. What holds the
# tongue on is the 45deg root gusset forward of the root -- measured 40.0000mm^3
# of solid in X +-20 / Y [227,228] / Z [2,3], and a full 16.0000mm^3 (40 x 2 x
# 0.2) across the tongue's first printed layer band, i.e. a real in-layer
# anchor.
#
# Worth recording precisely because the naive reading of this check is wrong:
# this project reported a single solid BEFORE the gusset existed too, but only
# because _be_yz_wedge()'s hull() spheres (r=0.001) left a 0.0000mm^3,
# sub-micron ridge at the ramp apex bridging the severed region -- verified by
# probing it directly. So "Volumes: 2" here was, pre-gusset, held up by an
# artifact no slicer would ever emit; it is now held up by real material. That
# also means this check is a regression guard for THIS consumer, not a probe of
# rack_support_plate_keepout()'s margin contract -- tests/test_rack_support_lib.sh
# checks (c)/(d) own that, and (d) is the one with teeth against the moat.
#
# CGAL counts the unbounded outer volume, so one solid reports "Volumes: 2"
# (same convention the side-hole counter above relies on).
cat > "$tmp/connectivity.scad" <<EOF
use <$proj/bay-enclosure.scad>;
bay_enclosure();
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/connectivity.stl" "$tmp/connectivity.scad" 2>&1)"
if echo "$out" | grep -qiE 'Ignoring unknown|Can.t open library'; then
  echo "FAIL: connectivity probe failed to resolve bay-enclosure.scad (undef-poisoned model):"
  echo "$out"; fail=1
else
  volumes="$(echo "$out" | grep -o 'Volumes:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
  if [ -z "$volumes" ]; then
    echo "FAIL: bay_enclosure() render produced no CGAL Volumes: line -- cannot verify it is a single solid:"
    echo "$out"; fail=1
  elif [ "$volumes" -ne 2 ]; then
    echo "FAIL: bay_enclosure() is not a single solid -- CGAL reports Volumes: $volumes (want 2). The rear tongue has most likely been detached from the body; check the 45deg root gusset and rack_support_plate_keepout()'s margin."
    fail=1
  fi
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
