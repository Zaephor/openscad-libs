#!/usr/bin/env bash
# Verifies the interior-mounted rear exhaust fan (Task 4) clears the board's
# rear edge (Task 5 fix).
#
# Bug: params.scad's old `fan_plenum = 12.0;` literal was hand-picked, not
# derived from the library's actual fan depth. For the only fan_size that
# fits a 1U chassis (40mm, fan_default_thickness(40)=10mm) with
# wall=2.4, this put the fan's interior-mounted inner face 0.4mm INSIDE the
# board: GAP = (rear_wall_y()-wall) - fan_default_thickness(fan_size) -
# board_d() = -0.4. Fixed by deriving fan_plenum from
# fan_default_thickness(fan_size) + wall + fan_board_gap, and guarded by a
# new params.scad depth-clearance assert that fires (names the numbers) on
# any future under-clearance.
#
# Discriminator: probes a scalar (echo "GAP=...") via stderr and an assert
# failure message, not STL geometry -- fully deterministic, no `cmp` on STL
# bytes (see test_bpir4_tray_params.sh's header for why STL cmp is banned).
#
# `-D` override note: unlike a MODULE PARAMETER (tray()/lid()'s enable_exhaust
# etc., which `use`-scope isolation defeats -- see test_bpir4_tray_params.sh),
# fan_board_gap is a plain top-level `include`d global, and empirically
# (verified against this repo's OpenSCAD build) a `-D` override on such a
# global wins over a later plain re-assignment of the SAME name later in the
# same include chain -- so `-D fan_board_gap=<n>` is a valid, real way to
# force the pre-fix plenum value here without editing any file.
#
# #76 update: fan_plenum now also adds _rear_media_protrusion() (2.3mm, the
# inserted microSD's rear overhang), so GAP = fan_board_gap +
# _rear_media_protrusion() rather than GAP = fan_board_gap alone. Forcing
# fan_board_gap=-2.7 (was -0.4 pre-#76) reproduces the SAME historical
# GAP=-0.4mm / fan_plenum=12.0 case: -2.7 + 2.3 = -0.4.
#
# #79 update: fan_plenum now derives from _fan_thickness_eff() (the declared
# fan_thickness, falling back to the library's size-keyed default) rather
# than from fan_default_thickness(fan_size) directly. Case (2)'s GAP identity
# is unaffected because the thickness term cancels: GAP = fan_board_gap +
# _rear_media_protrusion().
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"

# probe must live under projects/bpir4-1u-chassis/ so its relative
# `include <params.scad>` resolves (mirrors test_bpir4_tray_params.sh's
# render_consumer() reasoning).
probe="$proj/_t5_fan_clearance_probe.scad"
cleanup() { rm -f "$probe" "$proj/_t79_fan_thickness_probe.scad" "$proj/_t79_sentinel_probe.scad"; }
trap cleanup EXIT

cat > "$probe" <<'EOF'
enable_exhaust=true; fan_size=40; fan_count=2; ear_hole_type="slot";
include <params.scad>;
use <fans/fans.scad>;
echo(str("GAP=", (rear_wall_y()-wall)-fan_default_thickness(fan_size)-board_d()));
EOF

# Probe 2 (#79): declares an explicit fan_thickness the way every entry file
# now does, and reports BOTH the derived plenum and the gap measured against
# that DECLARED thickness -- not against the library's size-keyed constant.
# Probe 1 above deliberately still uses the library constant so the
# historical GAP identity it reproduces stays comparable.
probe2="$proj/_t79_fan_thickness_probe.scad"
cat > "$probe2" <<'EOF'
enable_exhaust=true; fan_size=40; fan_count=2; ear_hole_type="slot";
fan_thickness=20;
include <params.scad>;
echo(str("PLENUM=", fan_plenum));
echo(str("REAL_GAP=", (rear_wall_y(true)-wall)-fan_thickness-board_d()));
EOF

# Probe 3 (#79): the sentinel path. fan_thickness<0 must reproduce the
# pre-#79 library-default behaviour EXACTLY, so any consumer that does not
# opt in is unchanged.
probe3="$proj/_t79_sentinel_probe.scad"
cat > "$probe3" <<'EOF'
enable_exhaust=true; fan_size=40; fan_count=2; ear_hole_type="slot";
fan_thickness=-1;
include <params.scad>;
echo(str("PLENUM=", fan_plenum));
EOF

fail=0
gap_of() { grep -oE 'GAP=-?[0-9.]+' "$1" | head -1 | sed 's/GAP=//'; }

# --- (1) GREEN: fixed params.scad (fan_board_gap=1.5 as committed) -> GAP
# must be positive (the fan clears the board). ---
fixed_out="$("$osc" --export-format stl -o /dev/null "$probe" 2>&1)"
fixed_gap="$(echo "$fixed_out" | grep -oE 'GAP=-?[0-9.]+' | head -1 | sed 's/GAP=//')"
echo "GREEN (fixed params.scad): GAP=$fixed_gap"
if [ -z "$fixed_gap" ]; then
  echo "FAIL: fixed render produced no GAP echo:"; echo "$fixed_out"; fail=1
elif ! awk -v g="$fixed_gap" 'BEGIN{exit !(g>0)}'; then
  echo "FAIL: fixed GAP ($fixed_gap) must be > 0 (fan must clear the board)"
  fail=1
else
  echo "ok: fixed GAP ($fixed_gap) > 0 -- interior fan clears the board"
fi

# --- (2) RED reproduction + negative test with teeth: force the historical
# fan_plenum=12.0 value via -D fan_board_gap=-2.7 (12.4 + -2.7 + 2.3 = 12.0,
# the exact old literal -- see the #76 `-D` override note above). The new
# depth-clearance assert must FIRE (render aborts) and its message must name
# the actual numbers, including the historical -0.4mm gap. ---
old_out="$("$osc" -D "fan_board_gap=-2.7" --export-format stl -o /dev/null "$probe" 2>&1)"
echo "RED (forced fan_board_gap=-2.7, i.e. old fan_plenum=12.0):"
echo "$old_out" | grep -iE 'Assertion .* failed' | sed 's/^/  /'
if ! echo "$old_out" | grep -qiE 'Assertion .* failed'; then
  echo "FAIL: forcing the pre-fix plenum (fan_board_gap=-2.7) should ABORT the render on the new depth-clearance assert, but did not:"
  echo "$old_out"
  fail=1
elif ! echo "$old_out" | grep -q 'intrudes into the board'; then
  echo "FAIL: an assertion fired, but not the expected depth-clearance assert (wrong assert tripped?):"
  echo "$old_out"
  fail=1
elif ! echo "$old_out" | grep -q -- '-0.4mm'; then
  echo "FAIL: assert message does not name the expected historical -0.4mm gap:"
  echo "$old_out"
  fail=1
else
  echo "ok: depth-clearance assert fires on the pre-fix plenum, naming the numbers (gap -0.4mm)"
fi

# --- (3) #79: a declared fan_thickness must actually drive the plenum. ---
# Pre-#79 this FAILED: params.scad ignored fan_thickness entirely, so
# PLENUM stayed 16.2 (sized for the library's 10mm constant) while a real
# 20mm fan's inner face landed 6.2mm INSIDE the board -- a silent collision
# that rendered clean, sliced clean, and only showed up at assembly.
t79_out="$("$osc" --export-format stl -o /dev/null "$probe2" 2>&1)"
t79_plenum="$(echo "$t79_out" | grep -oE 'PLENUM=-?[0-9.]+' | head -1 | sed 's/PLENUM=//')"
t79_gap="$(echo "$t79_out" | grep -oE 'REAL_GAP=-?[0-9.]+' | head -1 | sed 's/REAL_GAP=//')"
echo "20mm fan: PLENUM=$t79_plenum REAL_GAP=$t79_gap"
if [ -z "$t79_plenum" ] || [ -z "$t79_gap" ]; then
  echo "FAIL: 20mm-fan probe produced no PLENUM/REAL_GAP echo:"; echo "$t79_out"; fail=1
else
  if awk -v p="$t79_plenum" 'BEGIN{exit !(p > 26.19 && p < 26.21)}'; then
    echo "ok: fan_thickness=20 drives fan_plenum to $t79_plenum (was 16.2 for the 10mm default)"
  else
    echo "FAIL: fan_thickness=20 gave fan_plenum=$t79_plenum, expected 26.2 -- fan_thickness is not reaching the derivation"
    fail=1
  fi
  if awk -v g="$t79_gap" 'BEGIN{exit !(g>0)}'; then
    echo "ok: 20mm fan clears the board (REAL_GAP=$t79_gap)"
  else
    echo "FAIL: 20mm fan OVERLAPS the board by $(awk -v g="$t79_gap" 'BEGIN{printf "%.2f", -g}')mm (REAL_GAP=$t79_gap)"
    fail=1
  fi
fi

# --- (4) #79: the sentinel must be exactly backward-compatible. ---
sent_out="$("$osc" --export-format stl -o /dev/null "$probe3" 2>&1)"
sent_plenum="$(echo "$sent_out" | grep -oE 'PLENUM=-?[0-9.]+' | head -1 | sed 's/PLENUM=//')"
echo "sentinel (fan_thickness=-1): PLENUM=$sent_plenum"
if [ -z "$sent_plenum" ]; then
  echo "FAIL: sentinel probe produced no PLENUM echo:"; echo "$sent_out"; fail=1
elif awk -v p="$sent_plenum" 'BEGIN{exit !(p > 16.19 && p < 16.21)}'; then
  echo "ok: fan_thickness<0 falls back to the library default (PLENUM=$sent_plenum)"
else
  echo "FAIL: sentinel gave PLENUM=$sent_plenum, expected the pre-#79 16.2"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "ok (fixed GAP=$fixed_gap > 0; pre-fix plenum reproduction aborts with a numbered assert)"
exit "$fail"
