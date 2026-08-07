#!/usr/bin/env bash
# Verifies the sbc library asserts via OpenSCAD stderr (exit code unreliable;
# --export-format echo swallows assert failures on OpenSCAD 2021.01).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/sbc/tests/sbc_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "sbc_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/bad_test.scad" <<'EOF'
use <sbc/sbc.scad>;
assert(sbc_size("pi4b") == [1, 1], "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

cat > "$tmp/bad_board.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_size("bogus");
EOF
out="$(run "$tmp/bad_board.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown board:"; echo "$out"; exit 1
fi

# Multi-role board, UNFILTERED access -> must emit the role-categories warning.
#
# Task 2 classified bpir4's 16 holes into 2 real role categories
# ("component-mount" x12, "structural-mount" x4 — see libraries/sbc/
# RESEARCH.md "bpi-r4 hole roles", incl. its "Follow-up re-review" section:
# a first pass found 0 structural-mount / 2 keep-out, then a follow-up
# review (requested after the first pass) upgraded 4 edge-inset holes —
# including the original 2 keep-out ones — to structural-mount, landing on
# 0 keep-out / 12 component-mount / 4 structural-mount. The warning only
# cares about the *count* of distinct roles present (2), not which ones, so
# this test is unaffected by that reclassification. This replaces the
# Task-1-era placeholder block (see git history) that stood in for this
# exact assertion while bpir4 was still provisionally single-role — this is
# now the genuine end-to-end positive control the plan originally called
# for.
cat > "$tmp/warn_bpir4.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4");   // role omitted -> undef; bpir4 now spans 2 roles
EOF
out="$(run "$tmp/warn_bpir4.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  || { echo "expected multi-role warning for unfiltered bpir4 access (bpir4 is classified into >1 role as of Task 2)"; echo "$out"; exit 1; }

cat > "$tmp/warn_mechanism.scad" <<'EOF'
present = ["structural-mount", "component-mount"];
x = let (_warn = len(present) > 1
        ? echo(str("WARNING: sbc 'synthetic' holes span ", len(present),
                   " role categories ", present,
                   "; no role filter selected — returning all. ",
                   "Pass a role (e.g. \"structural-mount\") or \"all\" to silence."))
        : undef) present;
EOF
out="$(run "$tmp/warn_mechanism.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  || { echo "warning mechanism (echo-in-let) failed to emit expected text"; echo "$out"; exit 1; }

# Explicit "all" -> must NOT warn.
cat > "$tmp/nowarn.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4", "all");
EOF
out="$(run "$tmp/nowarn.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "explicit all-role access must not warn"; echo "$out"; exit 1; } || true

# Unknown role -> must assert.
cat > "$tmp/badrole.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4", "bogus");
EOF
out="$(run "$tmp/badrole.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "unknown role must assert"; echo "$out"; exit 1; }

# SP2 connector_size() adoption — source-level regression guard.
#
# Task 3 rewired 21 "same"-verdict connector rows in sbc.scad (per the
# verdict table in libraries/sbc/RESEARCH.md, "SP2 connector reconcile —
# Task 1") to source their [w,d,h] from connectors.scad's connector_size()
# instead of a hardcoded literal. For 8 of those rows the adopted catalog
# value is numerically IDENTICAL to the literal it replaced (Δ=0,0,0:
# pi3b/pi3bplus usb2_1+rj45, pi4b usb2+hdmi_1+hdmi_2, pi5 hdmi_1+hdmi_2) —
# a numeric assert in sbc_test.scad can't tell "wired to connector_size()"
# apart from "reverted to the same-valued literal", so it has no teeth
# against that regression. This block greps sbc.scad's own source text
# instead: each entry below ties a connector row's name to the specific
# connector_size("<type>") call it must still make, with the exact count
# of same-named/typed rows expected (boards that share identical position+
# type text collapse to one pattern matching >1 line — the count is what
# catches a single reverted row dropping out of that group). gpio is
# shared via the _sbc_gpio() helper (pi3b/pi3bplus/pi4b/pi5) plus two
# explicit inline rows (pizero, pizero2w) — checked separately below.
sbcscad="$root/libraries/sbc/sbc.scad"
# pattern -> expected occurrence count -> description (rows covered)
sp2_checks=(
  '^\s*function _sbc_gpio\(\) =.*connector_size\("gpio_2x20"\)|1|_sbc_gpio() shared helper (pi3b/pi3bplus/pi4b/pi5 gpio)'
  '^\s*\["gpio",.*connector_size\("gpio_2x20"\)|2|pizero+pizero2w inline gpio rows'
  '^\s*\["usb2_1",.*connector_size\("usb_a_stack2_shielded"\)|2|pi3b+pi3bplus usb2_1'
  '^\s*\["rj45",.*connector_size\("rj45_shallow"\)|2|pi3b+pi3bplus rj45'
  '^\s*\["hdmi",.*connector_size\("hdmi"\)|2|pi3b+pi3bplus hdmi'
  '^\s*\["usb2",.*connector_size\("usb_a_stack2_shielded"\)|1|pi4b usb2'
  '^\s*\["usbc_pwr",.*connector_size\("usb_c"\)|2|pi4b+pi5 usbc_pwr'
  '^\s*\["hdmi_1",.*connector_size\("micro_hdmi"\)|2|pi4b+pi5 hdmi_1'
  '^\s*\["hdmi_2",.*connector_size\("micro_hdmi"\)|2|pi4b+pi5 hdmi_2'
  '^\s*\["usb3",.*connector_size\("usb_a_stack2_shielded"\)|1|pi5 usb3'
  '^\s*\["minihdmi",.*connector_size\("mini_hdmi"\)|1|pizero minihdmi'
)
for c in "${sp2_checks[@]}"; do
  IFS='|' read -r pat expected desc <<< "$c"
  actual="$(grep -cE "$pat" "$sbcscad")"
  if [ "$actual" != "$expected" ]; then
    echo "SP2 connector_size() adoption regression: $desc"
    echo "  expected $expected match(es) of /$pat/ in $sbcscad, found $actual"
    echo "  (a 'same'-verdict row was reverted away from connector_size(), or its count drifted)"
    exit 1
  fi
done

# "bottom" edge port cutout — positive control. Task 2 added the "bottom"
# edge (mpcie_1/mpcie_2/m2_ssd_1 on bpir4) with a dedicated branch in
# sbc_port_cutout(); confirm it renders (doesn't hit the "bad edge" assert).
cat > "$tmp/bottom_edge.scad" <<'EOF'
use <sbc/sbc.scad>;
sbc_port_cutout("bpir4", "mpcie_1");
EOF
out="$(run "$tmp/bottom_edge.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "bottom-edge connector (mpcie_1) unexpectedly failed sbc_port_cutout:"; echo "$out"; exit 1
fi

# Round-2 (#62) Task 2: front-connector +2mm protrusion — rendered-geometry
# positive control. sbc_placeholder("bpir4")'s 9 front-panel connector bodies
# (usb_1/sfp_1/sfp_2/rj45_1..4/dc_power_1/usbc_pwr_1) are shifted -2mm in Y by
# SBC_FRONT_PROTRUSION, so the whole board's rendered STL bbox must reach
# y=-2.0 (not just y=0, flush) — every other stored row's y stays within
# [0, board depth], so this shift is the only thing that can make the
# overall bbox go negative. A same-shaped check on a non-bpir4 board (no
# protrusion mechanism applies there) confirms the flush board stays >= 0,
# i.e. this isn't just generic STL/export slop.
cat > "$tmp/bpir4_placeholder.scad" <<'EOF'
use <sbc/sbc.scad>;
sbc_placeholder("bpir4");
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/bpir4_placeholder.stl" "$tmp/bpir4_placeholder.scad" 2>/dev/null
python3 - "$tmp/bpir4_placeholder.stl" <<'PY' || { echo "bpir4 placeholder front-connector protrusion (min Y) not ~ -2.0mm"; exit 1; }
import struct, sys
d = open(sys.argv[1], 'rb').read(); n = struct.unpack('<I', d[80:84])[0]; off = 84
ymin = min(struct.unpack('<3f', d[off+i*50+12+v*12: off+i*50+12+v*12+12])[1]
           for i in range(n) for v in range(3))
sys.exit(0 if abs(ymin - (-2.0)) < 0.05 else 1)
PY

cat > "$tmp/pi4b_placeholder.scad" <<'EOF'
use <sbc/sbc.scad>;
sbc_placeholder("pi4b");
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/pi4b_placeholder.stl" "$tmp/pi4b_placeholder.scad" 2>/dev/null
python3 - "$tmp/pi4b_placeholder.stl" <<'PY' || { echo "pi4b placeholder (no protrusion mechanism) unexpectedly has a negative min Y"; exit 1; }
import struct, sys
d = open(sys.argv[1], 'rb').read(); n = struct.unpack('<I', d[80:84])[0]; off = 84
ymin = min(struct.unpack('<3f', d[off+i*50+12+v*12: off+i*50+12+v*12+12])[1]
           for i in range(n) for v in range(3))
sys.exit(0 if ymin > -0.05 else 1)
PY

# Unknown connector name -> sbc_connector()'s own assert must fire.
cat > "$tmp/bad_connector.scad" <<'EOF'
use <sbc/sbc.scad>;
sbc_port_cutout("bpir4", "bogus_connector");
EOF
out="$(run "$tmp/bad_connector.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown connector name:"; echo "$out"; exit 1
fi

# --- top_clearance (#85) ---
# top_clearance must raise a cutout's height WITHOUT widening it in X, so a
# consumer can give a port more room for its mating plug without eating the
# gap walls between neighbouring connectors.
cat > "$tmp/tc.scad" <<'EOS'
use <sbc/sbc.scad>;
a = _sbc_cutout_inflate([0,0,0], [10,5,8], "ymin", 0.4, 0);
b = _sbc_cutout_inflate([0,0,0], [10,5,8], "ymin", 0.4, 0.5);
echo(str("BASE_W=", a[1][0], " BASE_H=", a[1][2]));
echo(str("TOPC_W=", b[1][0], " TOPC_H=", b[1][2]));
EOS
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/tc.stl" "$tmp/tc.scad" 2>&1)"
if ! echo "$out" | grep -q "BASE_W=10.8 BASE_H=8.4"; then
  echo "baseline inflate changed (expected W=10.8 H=8.4):"; echo "$out"; exit 1
fi
if ! echo "$out" | grep -q "TOPC_W=10.8 TOPC_H=8.9"; then
  echo "top_clearance must add height only (expected W=10.8 H=8.9):"; echo "$out"; exit 1
fi

# top_clearance defaults to 0 and MUST leave every pre-#85 caller's geometry
# unchanged. Render a real board's faceplate cutouts with the default and
# compare against an explicit top_clearance=0.
#
# The comparison is on the SORTED facet/vertex lines, not on the raw bytes:
# OpenSCAD's ASCII STL facet ORDER is not reproducible -- two renders of one
# unmodified file differ (verified: byte-diff at char 4163 of an identical
# 10035-byte export). Sorting is order-insensitive, verified stable across
# repeat renders of the same input, and verified to still discriminate a real
# change (top_clearance=0.5 does not compare equal). A raw `cmp` here would be
# a permanently-red test, not a stricter one.
stlnorm() { grep -E 'vertex|facet normal' "$1" | tr -s ' ' | sed 's/^ *//' | LC_ALL=C sort; }
cat > "$tmp/nc_a.scad" <<'EOS'
use <sbc/sbc.scad>;
sbc_faceplate_cutouts("bpir4", "ymin", depth = 5, clearance = 0.4);
EOS
cat > "$tmp/nc_b.scad" <<'EOS'
use <sbc/sbc.scad>;
sbc_faceplate_cutouts("bpir4", "ymin", depth = 5, clearance = 0.4, top_clearance = 0);
EOS
"$root/scripts/openscad.sh" --export-format stl -o "$tmp/nc_a.stl" "$tmp/nc_a.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format stl -o "$tmp/nc_b.stl" "$tmp/nc_b.scad" 2>/dev/null
if ! cmp -s <(stlnorm "$tmp/nc_a.stl") <(stlnorm "$tmp/nc_b.stl"); then
  echo "top_clearance default is not geometrically identical to explicit 0"; exit 1
fi

# --- usbc_pwr_1 regression fix (#87) ---
# #65 replaced #62's correct 137.3/8.7 with 139.3/6.7 -- the 6.7 is the
# connector's DEPTH transposed into the width slot. Three independent
# measurements (#62 caliper, 2026-08-07 caliper, and the generic USB-C
# datasheet width #65 explicitly discarded) agree on w=8.7.
fail=0
cat > "$tmp/uc87.scad" <<'EOS'
use <sbc/sbc.scad>;
c = sbc_connector("bpir4", "usbc_pwr_1");
echo(str("UC_X=", c[1][0], " UC_W=", c[2][0], " UC_D=", c[2][1], " UC_H=", c[2][2]));
echo(str("UC_RIGHT=", c[1][0] + c[2][0]));
EOS
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/uc87.stl" "$tmp/uc87.scad" 2>&1)"
# Trailing space is load-bearing: "UC_X=137.2" alone would also prefix-match a
# hypothetical 137.25 (see the WALL_DC_USBC prefix-grep lesson).
if ! echo "$out" | grep -q 'UC_X=137.2 UC_W=8.7 UC_D=6.7 UC_H=3'; then
  echo "FAIL: usbc_pwr_1 row not corrected (want x=137.2 w=8.7 d=6.7 h=3)"
  echo "$out"; fail=1
fi
# Closure check against the board's own width: the user measured the right
# wall 2.2mm in from the 148mm board edge => right edge 145.8. We adopt
# x=137.2 (midpoint of #62's 137.3 and the derived 137.1), so the right edge
# lands at 145.9 -- within 0.1 of the measurement.
if ! echo "$out" | grep -q 'UC_RIGHT=145.9'; then
  echo "FAIL: usbc_pwr_1 right edge should be 145.9"; echo "$out"; fail=1
fi
if [ "$fail" = 1 ]; then
  exit 1
fi

echo ok
