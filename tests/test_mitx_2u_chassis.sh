#!/usr/bin/env bash
# Verifies the mitx-2u-chassis project (Task 1 scope: faceplate ears + IO
# cutout + button + PCIe aperture/bracket keep-out + board + fit-asserts)
# renders + its fit-asserts pass at defaults, that the two negative controls
# genuinely abort, and that the IO/PCIe/button cutouts are real voids
# (OpenSCAD exit code unreliable for asserts -- grep stderr, per repo idiom).
# Walls/floor/rear/vents are Task 2-3 scope, not covered here yet.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/mitx-2u-chassis"
mod="$proj/mitx-2u-chassis.scad"
run() { # <stl-out> <scad> [extra -D args...]
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default must render clean (Step 2 of the plan brief).
out="$(run "$tmp/default.stl" "$mod")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: default mitx-2u-chassis.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/default.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# tests/asserts.scad (default params + independent contract checks) must
# also render clean.
out="$(run "$tmp/asserts.stl" "$proj/tests/asserts.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/asserts.stl" ] || { echo "FAIL: tests/asserts.scad produced no/empty STL"; fail=1; }

# --- Negative control 1: lp_card_h=90 must abort the LP-card-too-tall-for-2U
# fit-assert (standoff_h + mobo_thickness() + lp_card_h > _int_h()).
out="$(run "$tmp/neg_card_h.stl" "$mod" -D "lp_card_h=90")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: lp_card_h=90 did NOT abort -- 2U LP-card-height fit-assert broken:"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_card_h.stl" ] && { echo "FAIL: lp_card_h=90 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Negative control 2: lp_card_len=250 must abort the LP-card-collides-rear
# fit-assert (lp_card_len > _usable_depth()).
out="$(run "$tmp/neg_card_len.stl" "$mod" -D "lp_card_len=250")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: lp_card_len=250 did NOT abort -- LP-card-rear-collision fit-assert broken:"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_card_len.stl" ] && { echo "FAIL: lp_card_len=250 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Board-vs-side-wall collision guard (ported from #42's final-review
# finding): a board_offset that shoves the board into a side wall must abort,
# even though every OTHER fit-assert (IO/button/PCIe vs. the outer panel)
# still passes.
out="$(run "$tmp/neg_board_wall.stl" "$mod" -D "board_offset=90")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: board_offset=90 did NOT abort -- board-vs-side-wall collision guard broken:"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_board_wall.stl" ] && { echo "FAIL: board_offset=90 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Task 2 negative control: fan_size=80 must abort the NEW rear-wall-width
# fit-assert (abs(_fan_cx())+fan_size/2 > _clear_w()/2-wall). fan_size=80 is
# a real fan_known_sizes() entry and passes every earlier assert (gusset
# clearance is guaranteed by _rear_flank_cx()'s own construction; rear-wall
# HEIGHT still fits at 80mm, _wall_top_z()=88.11) -- isolates this one assert.
out="$(run "$tmp/neg_fan_width.stl" "$mod" -D "fan_size=80")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: fan_size=80 did NOT abort -- rear-wall-width fit-assert broken:"
  echo "$out"; fail=1
fi
if ! echo "$out" | grep -qi 'exceeds the rear wall width'; then
  echo "FAIL: fan_size=80 aborted on the WRONG assert (expected 'exceeds the rear wall width'):"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_fan_width.stl" ] && { echo "FAIL: fan_size=80 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Task 2 negative control: lp_card_len=220 must abort the NEW LP-card-vs-
# rear-gusset-zone fit-assert (220 <= _usable_depth()=225, so the Task 1
# rear-collision assert still PASSES -- isolates the Task 2 assert, which
# has a tighter threshold: _tongue_y()-wall-_gusset_size()=210.6).
out="$(run "$tmp/neg_card_gusset.stl" "$mod" -D "lp_card_len=220")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: lp_card_len=220 did NOT abort -- LP-card-vs-rear-gusset-zone fit-assert broken:"
  echo "$out"; fail=1
fi
if ! echo "$out" | grep -qi 'rear gusset/tongue zone'; then
  echo "FAIL: lp_card_len=220 aborted on the WRONG assert (expected 'rear gusset/tongue zone'):"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_card_gusset.stl" ] && { echo "FAIL: lp_card_len=220 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Hole-void regression: the IO cutout, PCIe slot aperture, and button
# hole must be REAL voids through the faceplate (not just numerically-placed
# dead space) -- same probe idiom as mitx-1u-chassis's own test. Positive
# controls (off-cutout material) prove the probes are actually discriminating.
# Numeric literals below match the default geometry: _board_x()=-65,
# _io_x0()=-67.62, _io_x1()=91.13 (Z=[8,52.45]); _pcie_slot_x0()=91.13,
# _pcie_slot_x1()=103.13 (Z=[7,19]); _button_x()=-97.31 (Z mid=44.055).
probe_empty() { # $1 = probe .scad body (intersection block), $2 = description
  rm -f "$tmp/p.stl"
  cat > "$tmp/p.scad" <<EOF
use <$mod>;
intersection() {
    mitx_2u_chassis();
    $1
}
EOF
  out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p.stl" "$tmp/p.scad" 2>&1)"
  if [ -f "$tmp/p.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
    echo "FAIL: $2 -- expected empty (real void), got material:"; echo "$out"; fail=1
  fi
}
probe_solid() { # $1 = probe .scad body (intersection block), $2 = description
  rm -f "$tmp/p.stl"
  cat > "$tmp/p.scad" <<EOF
use <$mod>;
intersection() {
    mitx_2u_chassis();
    $1
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p.stl" "$tmp/p.scad" >/dev/null 2>&1
  [ -s "$tmp/p.stl" ] || { echo "FAIL: $2 -- expected solid material, got empty (probe miscalibrated)"; fail=1; }
}

# IO cutout: low edge, mid, near high edge.
probe_empty "translate([-66, -4, 20]) cube([2,5,2]);" "IO cutout near low edge does not open through"
probe_empty "translate([10, -4, 20]) cube([2,5,2]);"  "IO cutout mid-span does not open through"
probe_empty "translate([88, -4, 20]) cube([2,5,2]);"  "IO cutout near high edge does not open through"
# PCIe slot aperture (12mm wide, X=[91.13,103.13], Z=[7,19]).
probe_empty "translate([96, -4, 12]) cube([2,5,2]);"  "PCIe slot cutout does not open through"
# Button hole.
probe_empty "translate([-98.31, -4, 43.055]) cube([2,5,2]);" "button hole does not open through"
# Positive controls: faceplate material clear of any cutout/hole.
probe_solid "translate([0, -4, 4]) cube([2,5,2]);"     "below-IO faceplate material unexpectedly empty"
probe_solid "translate([-115, -4, 60]) cube([2,5,2]);" "left-ear faceplate material unexpectedly empty"
probe_solid "translate([115, -4, 60]) cube([2,5,2]);"  "right-of-PCIe faceplate material unexpectedly empty"
# pcie_bracket_mount_holes() correction (CORRECTION 2026-07-31): Task 1 does
# NOT cut a mount hole into the faceplate at all (that's a Z-axis floor/rail
# fastener, Task 2's job) -- material directly above the PCIe slot cutout
# (same X band, just outside the slot's own Z=[7,19] span) must still be
# solid, unperforated faceplate.
probe_solid "translate([96, -4, 25]) cube([2,5,2]);"   "faceplate above the PCIe slot unexpectedly voided (mount-hole regression)"

# --- Task 2: walls/floor/rear DC-in/fan/#40 tongue + PCIe floor mount hole.
# Numeric literals below match the default geometry: _tongue_y()=228,
# rear wall material Y=[225.6,228]; _rear_center_z()=44.055; _fan_cx()=-62,
# _dc_cx()=62 (fan_size=60 -> _rear_flank_cx()=_gusset_x()+_gusset_xw()/2+
# max(60,11)/2+2 = 25+5+30+2 = 62); _pcie_slot_cx()=97.13,
# _pcie_screw_y_lp()=8.65 (floor mount hole).

# Fan bore + DC-in must be REAL voids clean through the rear wall.
probe_empty "translate([-63, 226, 43]) cube([2,2,2]);" "fan bore does not open through the rear wall"
probe_empty "translate([61, 226, 43]) cube([2,2,2]);"  "DC-in hole does not open through the rear wall"
# Positive control: plain rear wall material clear of the fan/DC-in/gussets.
probe_solid "translate([0, 226, 43]) cube([2,2,2]);"   "rear wall material between fan and DC-in unexpectedly empty"

# The #40 tongue must be REAL material (not just numerically placed dead
# space), well past the rear wall.
probe_solid "translate([-1, 233, 5]) cube([2,2,2]);" "#40 tongue is not real material"
# Buttress regression: the tongue's underside must be solidly supported by
# the tray's own floor for its full engagement reach (no unsupported
# overhang) -- rack-support's own README "Buttressing" consumer contract.
probe_solid "translate([-0.4, 233.6, 0.1]) cube([0.8,0.8,0.8]);" "no floor/buttress under the #40 tongue -- unsupported overhang"

# PCIe bracket foot mount hole (CORRECTION 2026-07-31): must be a REAL void
# through the FLOOR (Z=[0,floor_th]) at the bracket foot's landing X/Y --
# NOT at the Task 1 keep-out preview's floor_th+standoff_h (board/card-slot
# height, which was tried first and confirmed empirically to leave the hole
# floating above the floor, cutting nothing -- see mitx-2u-chassis.scad's
# _pcie_mount_depth() comment). Probe is inset 0.4-0.6mm off the hole's own
# 1.98mm radius/floor bounds to avoid a coincident-face non-manifold
# artifact at the exact boundary (verified during implementation: an
# uninset probe touching the floor's own top face returns a degenerate
# zero-volume non-manifold result, neither cleanly empty nor solid).
probe_empty "translate([96.5, 8, 0.4]) cube([1.3,1.3,1.2]);" "PCIe floor mount hole does not open through the floor"
# Positive control: floor material away from the mount hole.
probe_solid "translate([50, 8, 0.5]) cube([1.3,1.3,1.5]);" "floor material away from the PCIe mount hole unexpectedly empty"
# Positive control: no stray void at the OLD (wrong) preview Z-datum near the
# same X/Y -- confirms the hole is cut ONLY at the floor, not also
# (incorrectly) up at card-slot height.
probe_solid "translate([96.5, 8, 7.5]) cube([1.3,1.3,1]);" "unexpected void at the old card-height Z near the PCIe mount hole X/Y"

[ "$fail" -eq 0 ] && echo ok || exit 1
