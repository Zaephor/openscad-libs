#!/usr/bin/env bash
# Verifies the drive-tray project renders clean at defaults, that the
# tests/asserts.scad / tests/asserts_depth.scad negative controls genuinely
# abort the width/depth fit-asserts, that the default grid stamps the
# expected total bottom-hole count, that the rear #40 support tongue is
# present and correctly placed (Task 2), and that the per-cell honeycomb
# floor vents (Task 3) are present and self-supporting (OpenSCAD exit code
# unreliable for asserts -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/drive-tray"

run() { # <stl-out> <scad> [extra -D args...]
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default (#44: 2x hdd35) must render clean.
out="$(run "$tmp/dt.stl" "$proj/drive-tray.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: default drive-tray.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/dt.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# Honeycomb floor vents (Task 3): the module's own self-support regression
# guard (see honeycomb.scad) echoes HONEYCOMB_WORST_SPAN=<N> -- must stay
# <=5mm (design-for-print's bridging ceiling) or the library's own assert()
# would already have aborted the render above; re-check the echoed number
# directly too (belt-and-suspenders, same idiom the library's own comment
# describes for its test).
span="$(echo "$out" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*' | head -1 | cut -d= -f2)"
if [ -z "$span" ]; then
  echo "FAIL: no HONEYCOMB_WORST_SPAN echo in default render -- floor vents missing?"; fail=1
elif ! awk -v s="$span" 'BEGIN{exit !(s <= 5)}'; then
  echo "FAIL: HONEYCOMB_WORST_SPAN=$span > 5mm -- self-support ceiling violated"; fail=1
fi

# Honeycomb floor vents (Task 3): facet count must jump well past a
# no-vent floor's own facet count (896, the pre-Task-3 tongue/wall/faceplate
# geometry measured against 74e60f0's own drive-tray.scad) -- confirms the
# per-cell hex fields are actually present in the render, not silently
# skipped. Threshold (1500) sits well clear of both the no-vent baseline
# (896) and the with-vent default (~3100), so it only trips if the vent
# cutters stop being applied.
facets="$(echo "$out" | grep -o 'Facets:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
if [ -z "$facets" ]; then
  echo "FAIL: no CGAL 'Facets:' summary in default render output"; fail=1
elif [ "$facets" -le 1500 ]; then
  echo "FAIL: default render facet count $facets <= 1500 -- honeycomb floor vents missing?"; fail=1
fi

# Negative control: tests/asserts.scad overrides cols=9 -- MUST abort the
# grid-width fit-assert. A silent pass here means the fit-assert regressed.
out="$(run "$tmp/neg.stl" "$proj/tests/asserts.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts.scad (cols=9) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg.stl" ]; then
  echo "FAIL: tests/asserts.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control (Task 2): tests/asserts_depth.scad overrides rows=20 --
# MUST abort the grid-depth fit-assert (_usable_depth()). A silent pass here
# means the depth fit-assert regressed.
out="$(run "$tmp/negdepth.stl" "$proj/tests/asserts_depth.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_depth.scad (rows=20) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/negdepth.stl" ]; then
  echo "FAIL: tests/asserts_depth.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Hole-count check: the default grid (cols=2, rows=1, drive_type=hdd35) must
# stamp exactly cols*rows*len(drive_bottom_holes(drive_type)) bottom holes.
# Proxy (same idiom as test_bay_enclosure.sh's check_side_holes): render just
# the cutter geometry through the project's OWN _dt_device_frame() transform
# (single source of truth for cell placement, not a duplicated offset
# formula) as a bare union with no difference(). CGAL's own render-summary
# "Volumes:" line counts N disjoint solids as N+1 -- so (Volumes - 1) must
# equal the drives-lib-computed EXPECT, which the probe echoes itself rather
# than hardcoding, so a future drives-lib data change updates both sides of
# the comparison together.
probe="$tmp/holes.scad"
cat > "$probe" <<EOF
use <drives/drives.scad>;
use <$proj/drive-tray.scad>;
device_type = "hdd35"; // mirrors drive-tray.scad's own default drive_type (use-scope: not importable)
cols = 2; rows = 1;    // mirrors drive-tray.scad's own default cols/rows (use-scope: not importable)
echo(str("EXPECT=", cols*rows*len(drive_bottom_holes(device_type))));
for (c = [0:cols-1]) for (r = [0:rows-1])
    _dt_device_frame(c, r) drive_holes(device_type, faces = "bottom", depth = 5);
EOF
out="$(run "$tmp/holes.stl" "$probe")"
expect="$(echo "$out" | grep -o 'EXPECT=[0-9]*' | tail -1 | cut -d= -f2)"
volumes="$(echo "$out" | grep -o 'Volumes:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
if [ -z "$expect" ] || [ -z "$volumes" ]; then
  echo "FAIL: hole-count probe produced no EXPECT/Volumes -- can't verify hole count:"; echo "$out"; fail=1
elif [ "$((volumes - 1))" -ne "$expect" ]; then
  echo "FAIL: default grid hole count $((volumes - 1)) != expected $expect"
  fail=1
fi


# Task 2 (#44/#45): rear #40 support-tongue presence/placement. Per
# rack-support's consumer-contract placement formula (_reach() in
# drive-tray.scad), the tongue's tip must land exactly at
# rack10_rear_post_y("labrax")=240 (rack_support_plate()'s own mounting
# plane) -- so the default tray's overall Y-max must be 240. A floor/tongue
# that stops short (or overshoots) would fail to mate with the rear
# rack_support_plate(). Same STL-bbox idiom as test_bay_enclosure.sh's own
# rear-tongue check (that sibling #41 consumer of the same rack-support
# library).
python3 - "$tmp/dt.stl" <<'PY' || { echo "FAIL: rear Y-max != rack10_rear_post_y(\"labrax\")=240 -- tongue missing/misplaced"; fail=1; }
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

# Task 4 (#45): the second LOCKED preset (drive_type="ssd25_9", cols=3,
# rows=2, drive_gap=2.0 -- #44's hdd35/2x1 preset is already the default,
# checked above) must render clean -- via -D command-line overrides directly
# against drive-tray.scad, same idiom as bay-enclosure's own Task 4 preset
# checks (tests/test_bay_enclosure.sh): drive-tray.scad is rendered DIRECTLY
# here (not through a `use`d/`include`d wrapper), so -D reliably overrides
# its own top-level Customizer vars (the
# use-scope -D caveat in reference_openscad_gotchas is about threading
# params INTO `use`d library files, not about overriding the directly-
# rendered project file's own top-level vars). drive_gap must drop to 2.0
# here -- at the file's 4.0 default, this 3-wide ssd25_9 grid overshoots
# labrax's usable width by 0.35mm and the width fit-assert aborts (see
# drive-tray.scad's header comment); 2.0 is the same gap Task 3 already
# verified the honeycomb vent placement against for this preset shape.
out="$(run "$tmp/ssd.stl" "$proj/drive-tray.scad" -D 'drive_type="ssd25_9"' -D 'cols=3' -D 'rows=2' -D 'drive_gap=2.0')"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: #45 preset (ssd25_9 3x2 @ drive_gap=2.0) errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/ssd.stl" ] || { echo "FAIL: #45 preset (ssd25_9 3x2 @ drive_gap=2.0) produced no/empty STL"; fail=1; }

# Task 4 (#45): hole-count check for the #45 preset. Can't reuse the
# _dt_device_frame()-based probe idiom above unmodified: that module is
# `use`d, and per reference_openscad_gotchas a `use`d module's free
# variables (cols/rows/drive_type/drive_gap -- read implicitly, not
# threaded as args) resolve against drive-tray.scad's OWN top-level scope,
# i.e. always its hdd35/2x1/4.0 DEFAULTS, regardless of anything set here or
# passed via -D. (Fixing that with `include`-then-override, per asserts.scad's
# idiom, also unconditionally re-executes drive-tray.scad's own trailing
# `drive_tray();` call -- confirmed empirically that a bare union of
# _dt_device_frame() cutters added alongside that DOESN'T separate out as
# extra CGAL volumes, i.e. Volumes stays flat rather than going to N+2, so
# that combination can't be used as an exact hole-count discriminator.) So
# this probe instead reimplements just the small cell-offset/rotation
# transform inline (_cell_xy()'s formula + _dt_device_frame()'s rotate)
# against real drives.scad accessors (drive_size()/drive_bottom_holes(),
# called with an explicit type arg -- not affected by use-scope) -- no
# device DATA is duplicated, only this test-harness-only arithmetic, needed
# solely because _dt_device_frame() itself has no way to be pointed at a
# non-default preset from outside its own file.
probe="$tmp/holes_ssd25_9.scad"
cat > "$probe" <<EOF
use <drives/drives.scad>;
device_type = "ssd25_9";
cols = 3; rows = 2; drive_gap = 2.0; // mirrors the -D overrides above
dsz = drive_size(device_type);
dlen = dsz[0]; // along Y (depth) -- see drive-tray.scad's _dlen() comment
dw   = dsz[1]; // across X (width) -- see drive-tray.scad's _dw() comment
grid_w = cols*dw + (cols-1)*drive_gap;
echo(str("EXPECT=", cols*rows*len(drive_bottom_holes(device_type))));
for (c = [0:cols-1]) for (r = [0:rows-1])
    translate([-grid_w/2 + c*(dw + drive_gap) + dw, r*(dlen + drive_gap), 0])
        rotate([0, 0, 90])
        drive_holes(device_type, faces = "bottom", depth = 5);
EOF
out="$(run "$tmp/holes45.stl" "$probe")"
expect="$(echo "$out" | grep -o 'EXPECT=[0-9]*' | tail -1 | cut -d= -f2)"
volumes="$(echo "$out" | grep -o 'Volumes:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
if [ -z "$expect" ] || [ -z "$volumes" ]; then
  echo "FAIL: #45 hole-count probe produced no EXPECT/Volumes -- can't verify hole count:"; echo "$out"; fail=1
elif [ "$((volumes - 1))" -ne "$expect" ]; then
  echo "FAIL: #45 grid hole count $((volumes - 1)) != expected $expect"
  fail=1
fi

# Faceplate bbox (Task 2): X-span == rack10_panel_width("labrax")=254,
# Z-span == rack10_device_height(1)=43.66 -- same idiom as
# test_bay_enclosure.sh's faceplate bbox check.
python3 - "$tmp/dt.stl" <<'PY' || { echo "FAIL: faceplate bbox != panel_width(254) x device_height(1)=43.66"; fail=1; }
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


# --- rack_support_plate() interference probe (#63 Task 5) ---
# drive_tray() deliberately omits a rear buttress shelf under the tongue's
# engagement span (see the "NO rear buttress shelf" comment above _dt_faceplate's
# union() in drive-tray.scad) specifically because one would collide with
# rack_support_plate()'s envelope -- confirm that omission actually keeps this
# consumer clean against the plate at the SAME placement (rack10_rear_post_y)
# both parts use. Measured directly (this task, before any change): 24
# triangles in the exported STL, all vertices at Y=228 (==
# rack10_rear_post_y("labrax") - rack_support_engagement_depth() = 240-12) or
# Z=0, signed-tetra volume sum ~1.3e-5mm^3 -- floating-point noise around an
# EXACT 0.00mm^3, not residual interference. This is the same coincident-face
# TOUCH artifact class test_bay_enclosure.sh's own keepout probe documents (a
# non-manifold sliver: facets present, zero volume) -- NOT OpenSCAD's literal
# CGAL "is empty" result, so this probe can't use the is-empty text idiom the
# way tests/test_rack_support_lib.sh's minimal reference-stub probe does; it
# checks volume instead, same as test_bay_enclosure.sh's real-consumer probe.
# The 1.0mm^3 bound below is pure headroom above the measured ~1.3e-5, not a
# load-bearing threshold -- still ~5 orders of magnitude below the ~960mm^3 a
# real buttress-shelf collision measures at (see drive-tray.scad's comment).
#
# CRITICAL: scripts/openscad.sh only sets OPENSCADPATH to libraries/, so a
# probe .scad that `use`s drive-tray.scad by bare libname would silently fail
# to resolve it -- OpenSCAD prints "WARNING: Ignoring unknown module/function"
# per undefined symbol and happily renders an empty/undef model, which still
# prints plausible Simple/Facets/Volumes lines and would pass a naive check
# (this exact trap produced false results earlier in this plan, see
# test_bay_enclosure.sh). `use <$proj/...>` below is an ABSOLUTE path
# (bypasses OPENSCADPATH lookup entirely), and stderr is grepped for the
# failure signatures regardless.
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

cat > "$tmp/plate_interference.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
use <$proj/drive-tray.scad>;
standard = "labrax";
rpy = rack10_rear_post_y(standard);
intersection() {
    translate([0, rpy, 0]) rack_support_plate(standard, 1);
    drive_tray();
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/plate_interference.stl" "$tmp/plate_interference.scad" 2>&1)"
if echo "$out" | grep -qiE 'Ignoring unknown|Can.t open library'; then
  echo "FAIL: plate interference probe failed to resolve drive-tray.scad (undef-poisoned model):"
  echo "$out"; fail=1
else
  vol="$(stl_volume "$tmp/plate_interference.stl")"
  awk -v v="$vol" 'BEGIN { exit !(v < 1.0) }' \
    || { echo "FAIL: drive_tray() interferes with rack_support_plate() -- volume ${vol}mm^3 (want ~0, a real buttress-shelf collision measures ~960mm^3)"; fail=1; }
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
