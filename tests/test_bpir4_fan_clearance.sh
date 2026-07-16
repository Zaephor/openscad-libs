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
# force the pre-fix plenum value here (12.4+(-0.4) = 12.0, exactly the old
# literal) without editing any file.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"

# probe must live under projects/bpir4-1u-chassis/ so its relative
# `include <params.scad>` resolves (mirrors test_bpir4_tray_params.sh's
# render_consumer() reasoning).
probe="$proj/_t5_fan_clearance_probe.scad"
cleanup() { rm -f "$probe"; }
trap cleanup EXIT

cat > "$probe" <<'EOF'
enable_exhaust=true; fan_size=40; fan_count=2; ear_hole_type="slot";
include <params.scad>;
use <fans/fans.scad>;
echo(str("GAP=", (rear_wall_y()-wall)-fan_default_thickness(fan_size)-board_d()));
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
# fan_plenum=12.0 value via -D fan_board_gap=-0.4 (12.4 + -0.4 = 12.0, the
# exact old literal). The new depth-clearance assert must FIRE (render
# aborts) and its message must name the actual numbers, including the
# historical -0.4mm gap. ---
old_out="$("$osc" -D "fan_board_gap=-0.4" --export-format stl -o /dev/null "$probe" 2>&1)"
echo "RED (forced fan_board_gap=-0.4, i.e. old fan_plenum=12.0):"
echo "$old_out" | grep -iE 'Assertion .* failed' | sed 's/^/  /'
if ! echo "$old_out" | grep -qiE 'Assertion .* failed'; then
  echo "FAIL: forcing the pre-fix plenum (fan_board_gap=-0.4) should ABORT the render on the new depth-clearance assert, but did not:"
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

[ "$fail" -eq 0 ] && echo "ok (fixed GAP=$fixed_gap > 0; pre-fix plenum reproduction aborts with a numbered assert)"
exit "$fail"
