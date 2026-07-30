#!/usr/bin/env bash
# Verifies rack10-device-tray's T1 scaffold + T2 faceplate/port/secure-hole
# + T3 honeycomb-vent/rear-#40-tongue additions: default (GS308) preset
# renders clean, the RLA-PS1 preset (wider AND deeper envelope) also
# renders clean, secure_holes=[] (GS308T, desktop-mount-only) renders clean
# and its facet count is measurably lower than the default's (proving the
# default's countersunk holes are actually cut, not silently skipped), the
# default's honeycomb floor vent is present/self-supporting and its rear
# #40 tongue is present and correctly placed against rack_support_plate(),
# and five negative controls (device too tall for 1U; a secure_holes entry
# outside the device footprint; a port cutout clipping the #70 chamfered
# panel corner; a countersink dia not exceeding its own hole dia; a
# countersink cone taller than floor_th) genuinely abort their respective
# fit-asserts (OpenSCAD exit code alone is not always reliable for asserts
# under some export paths -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/rack10-device-tray"

run() { # <stl-out> <scad>
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" 2>&1
}

facets() { echo "$1" | grep -o 'Facets:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$'; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default (GS308) must render clean.
out="$(run "$tmp/default.stl" "$proj/rack10-device-tray.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: default rack10-device-tray.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/default.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# T3: honeycomb_vent()'s own self-support regression guard (see
# honeycomb.scad) echoes HONEYCOMB_WORST_SPAN=<N> -- must stay <=5mm
# (design-for-print's bridging ceiling) or the library's own assert() would
# already have aborted the render above; re-check the echoed number
# directly too (belt-and-suspenders, same idiom tests/test_drive_tray.sh
# uses for its own honeycomb floor vents).
span="$(echo "$out" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*' | head -1 | cut -d= -f2)"
if [ -z "$span" ]; then
  echo "FAIL: no HONEYCOMB_WORST_SPAN echo in default render -- floor vent missing?"; fail=1
elif ! awk -v s="$span" 'BEGIN{exit !(s <= 5)}'; then
  echo "FAIL: HONEYCOMB_WORST_SPAN=$span > 5mm -- self-support ceiling violated"; fail=1
fi

# T3: facet count must jump well past the pre-T3 (no vent, no tongue)
# baseline -- 514, measured directly against this file at HEAD~1 (T2's own
# commit, before this change). The post-T3 default measures 2538; 1200 sits
# comfortably between the two, so it only trips if the honeycomb cutter or
# the tongue's own geometry stop being applied.
f_default="$(facets "$out")"
if [ -z "$f_default" ]; then
  echo "FAIL: no CGAL 'Facets:' summary in default render output"; fail=1
elif [ "$f_default" -le 1200 ]; then
  echo "FAIL: default render facet count $f_default <= 1200 -- honeycomb floor vent/rear tongue missing?"; fail=1
fi

# T3: rear #40 support-tongue presence/placement. Per rack-support's
# consumer-contract placement formula (_reach() in rack10-device-tray.scad),
# the tongue's tip must land exactly at rack10_rear_post_y("labrax")=240
# (rack_support_plate()'s own mounting plane) -- so the default tray's
# overall Y-max must be 240. Same STL-bbox idiom
# tests/test_drive_tray.sh/test_bay_enclosure.sh use for their own rear
# tongues.
python3 - "$tmp/default.stl" <<'PY' || { echo "FAIL: rear Y-max != rack10_rear_post_y(\"labrax\")=240 -- tongue missing/misplaced"; fail=1; }
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

# --- rack_support_plate() interference probe (T3, #63 consumer contract) ---
# rack10_device_tray() deliberately leaves the tongue's own engagement span
# (Y in [_reach(), rack10_rear_post_y(standard)]) unfilled -- that volume
# belongs to rack_support_plate()'s own bearing floor -- and relies on the
# rear wall (already built full-width, retention_height tall at _reach()) to
# anchor the tongue instead of a buttress shelf reaching the rear post
# plane; see the tongue-union comment in rack10-device-tray.scad. Confirm
# that omission actually keeps this consumer clean against the plate at the
# SAME placement (rack10_rear_post_y) both parts use. Measured directly
# (this task): 24 triangles, all vertices at Y~=228 (==
# rack10_rear_post_y("labrax") - rack_support_engagement_depth() = 240-12)
# or Z=0, signed-tetra volume sum ~1.3e-5mm^3 -- floating-point noise around
# an EXACT 0.00mm^3 coincident-face TOUCH (a non-manifold sliver: facets
# present, zero volume), not residual interference -- the identical artifact
# class tests/test_drive_tray.sh's own plate-interference probe measures for
# the same "no buttress shelf" design (drive-tray: ~1.3e-5mm^3 too). The
# 1.0mm^3 bound below is pure headroom above that measured ~1.3e-5, not a
# load-bearing threshold -- still ~5 orders of magnitude below the ~960mm^3
# a real buttress-shelf collision measures at (see rack-support/README.md's
# Consumer contract and drive-tray.scad's own comment for that reference
# figure).
#
# CRITICAL: scripts/openscad.sh only sets OPENSCADPATH to libraries/, so a
# probe .scad that `use`s rack10-device-tray.scad by bare libname would
# silently fail to resolve it -- OpenSCAD prints "WARNING: Ignoring unknown
# module/function" per undefined symbol and happily renders an empty/undef
# model, which still prints plausible Simple/Facets/Volumes lines and would
# pass a naive check. `use <$proj/...>` below is an ABSOLUTE path (bypasses
# OPENSCADPATH lookup entirely), and stderr is grepped for the failure
# signatures regardless.
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
use <$proj/rack10-device-tray.scad>;
standard = "labrax";
rpy = rack10_rear_post_y(standard);
intersection() {
    translate([0, rpy, 0]) rack_support_plate(standard, 1);
    rack10_device_tray();
}
EOF
out_pi="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/plate_interference.stl" "$tmp/plate_interference.scad" 2>&1)"
if echo "$out_pi" | grep -qiE 'Ignoring unknown|Can.t open library'; then
  echo "FAIL: plate interference probe failed to resolve rack10-device-tray.scad (undef-poisoned model):"
  echo "$out_pi"; fail=1
else
  vol="$(stl_volume "$tmp/plate_interference.stl")"
  awk -v v="$vol" 'BEGIN { exit !(v < 1.0) }' \
    || { echo "FAIL: rack10_device_tray() interferes with rack_support_plate() -- volume ${vol}mm^3 (want ~0, a real buttress-shelf collision measures ~960mm^3)"; fail=1; }
fi

# Positive control: RLA-PS1 preset (wider AND deeper than the default) must
# also render clean -- tests/rla_ps1.scad overrides device_size.
out="$(run "$tmp/rla_ps1.stl" "$proj/tests/rla_ps1.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: tests/rla_ps1.scad (RLA-PS1 preset) errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/rla_ps1.stl" ] || { echo "FAIL: RLA-PS1 preset render produced no/empty STL"; fail=1; }

# T3 spot-check: RLA-PS1's own honeycomb vent must also stay self-supporting
# (wider device -> wider vent field -- confirm it doesn't regress the
# bridging ceiling).
span_rla="$(echo "$out" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*' | head -1 | cut -d= -f2)"
if [ -z "$span_rla" ]; then
  echo "FAIL: no HONEYCOMB_WORST_SPAN echo in RLA-PS1 render -- floor vent missing?"; fail=1
elif ! awk -v s="$span_rla" 'BEGIN{exit !(s <= 5)}'; then
  echo "FAIL: RLA-PS1 HONEYCOMB_WORST_SPAN=$span_rla > 5mm -- self-support ceiling violated"; fail=1
fi

# Negative control: tests/asserts_height.scad overrides device_size to
# [158,102,45] -- MUST abort the 1U-height fit-assert. A silent pass here
# means the fit-assert regressed.
out="$(run "$tmp/neg_height.stl" "$proj/tests/asserts_height.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_height.scad (device_size height=45) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_height.stl" ]; then
  echo "FAIL: tests/asserts_height.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control: tests/asserts_holes.scad overrides secure_holes with an
# entry whose x lands outside the device footprint -- MUST abort the
# per-hole fit-assert.
out="$(run "$tmp/neg_holes.stl" "$proj/tests/asserts_holes.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_holes.scad (secure hole outside footprint) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_holes.stl" ]; then
  echo "FAIL: tests/asserts_holes.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Positive control (T2): secure_holes=[] (GS308T, desktop-mount-only) must
# render clean -- tests/no_secure_holes.scad overrides secure_holes. Proves
# the countersunk-hole cutter loop and its guarding asserts tolerate an
# empty list.
out_noholes="$(run "$tmp/no_secure_holes.stl" "$proj/tests/no_secure_holes.scad")"
if echo "$out_noholes" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: tests/no_secure_holes.scad (secure_holes=[]) errored:"; echo "$out_noholes"; fail=1
fi
[ -s "$tmp/no_secure_holes.stl" ] || { echo "FAIL: no_secure_holes.scad render produced no/empty STL"; fail=1; }

# T2 proof-of-cut: the default preset's 2 countersunk secure holes must
# actually remove material -- its facet count must exceed the otherwise-
# identical secure_holes=[] render's facet count. Facet-count alone isn't a
# generic geometry oracle, but a strict decrease-to-increase here can only
# come from the hole cutters being applied (same idiom as
# tests/test_drive_tray.sh's honeycomb-vent facet-count-jump check).
out_default="$(run "$tmp/default2.stl" "$proj/rack10-device-tray.scad")"
f_default="$(facets "$out_default")"
f_noholes="$(facets "$out_noholes")"
if [ -z "$f_default" ] || [ -z "$f_noholes" ]; then
  echo "FAIL: could not read CGAL Facets: count from default and/or no-holes render"; fail=1
elif [ "$f_default" -le "$f_noholes" ]; then
  echo "FAIL: default render facets ($f_default) <= secure_holes=[] render facets ($f_noholes) -- countersunk secure holes missing?"
  fail=1
fi

# Positive control (T4): GS308T preset (device_size=[158,101,30],
# secure_holes=[]) -- a RESEARCHED NEGATIVE, not a placeholder (see
# README.md's Presets section) -- must render clean and stamp 0
# countersunk holes. device_size[1]/[2] (depth/height) don't affect any
# drawn geometry (floor/walls run to _reach() regardless of device depth;
# retention_height, not device height, sets wall height; the device
# fit-viz box is preview-only, excluded from export), so its facet count
# must match the no_secure_holes.scad baseline exactly.
out_gs308t="$(run "$tmp/gs308t.stl" "$proj/tests/gs308t.scad")"
if echo "$out_gs308t" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: tests/gs308t.scad errored:"; echo "$out_gs308t"; fail=1
fi
[ -s "$tmp/gs308t.stl" ] || { echo "FAIL: tests/gs308t.scad render produced no/empty STL"; fail=1; }
f_gs308t="$(facets "$out_gs308t")"
if [ -z "$f_gs308t" ]; then
  echo "FAIL: could not read CGAL Facets: count from gs308t render"; fail=1
elif [ "$f_gs308t" != "$f_noholes" ]; then
  echo "FAIL: gs308t render facets ($f_gs308t) != secure_holes=[] baseline facets ($f_noholes) -- expected 0 countersunk holes"
  fail=1
fi

# Negative control (T2): tests/asserts_port.scad overrides port_cutout so
# its top edge lands in the #70 panel's top chamfer band and clips the
# corner -- MUST abort the port-in-panel fit-assert.
out="$(run "$tmp/neg_port.stl" "$proj/tests/asserts_port.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_port.scad (port clips chamfered corner) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_port.stl" ]; then
  echo "FAIL: tests/asserts_port.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control (T2): tests/asserts_csk_positive.scad overrides
# secure_holes with a hole dia >= csk_dia -- MUST abort the positive-
# countersink-cone-height fit-assert.
out="$(run "$tmp/neg_csk_pos.stl" "$proj/tests/asserts_csk_positive.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_csk_positive.scad (hole dia >= csk_dia) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_csk_pos.stl" ]; then
  echo "FAIL: tests/asserts_csk_positive.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control (T2): tests/asserts_csk_breach.scad overrides csk_dia
# large enough that the countersink cone would rise taller than floor_th
# -- MUST abort the no-top-face-breach fit-assert.
out="$(run "$tmp/neg_csk_breach.stl" "$proj/tests/asserts_csk_breach.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_csk_breach.scad (countersink cone taller than floor_th) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_csk_breach.stl" ]; then
  echo "FAIL: tests/asserts_csk_breach.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
