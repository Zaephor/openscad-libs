#!/usr/bin/env bash
# Verifies the mitx-2u-chassis project (Tasks 1-3: faceplate ears + IO cutout
# + button + PCIe aperture/bracket keep-out + board + walls/floor/rear DC-in/
# fan/#40 tongue + honeycomb vents) renders + its fit-asserts pass at
# defaults, that the negative controls genuinely abort, and that the IO/PCIe/
# button/vent cutouts are real voids (OpenSCAD exit code unreliable for
# asserts -- grep stderr, per repo idiom).
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

# Honeycomb vents (Task 3): three fields (2 side intake + 1 rear fan-flanking)
# each self-recompute + echo HONEYCOMB_WORST_SPAN inside honeycomb.scad --
# same idiom as tests/test_mitx_1u_chassis.sh / test_fan_grille.sh. Facet
# count is a real-teeth proxy that the fields are actual hex-prism arrays cut
# through the walls, not dead/solid space (pre-Task-3 baseline was ~1401
# facets at this project's own defaults; the worst-span values below are the
# actual self-support regression guard).
span_lines="$(echo "$out" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*')"
n_spans="$(echo "$span_lines" | grep -c . || true)"
if [ "$n_spans" -lt 3 ]; then
  echo "FAIL: expected 3 HONEYCOMB_WORST_SPAN echoes (2 side vents + 1 rear vent), got $n_spans:"
  echo "$span_lines"; fail=1
fi
while IFS= read -r line; do
  [ -z "$line" ] && continue
  span="$(echo "$line" | cut -d= -f2)"
  if ! awk -v s="$span" 'BEGIN{exit !(s <= 5.000001)}'; then
    echo "FAIL: $line exceeds the 5mm self-support ceiling"; fail=1
  fi
done <<< "$span_lines"

facets=0
if [ -s "$tmp/default.stl" ]; then
  facets=$(python3 - "$tmp/default.stl" <<'PYEOF'
import struct, sys
with open(sys.argv[1], "rb") as f:
    data = f.read()
print(struct.unpack("<I", data[80:84])[0])
PYEOF
)
  if [ "$facets" -lt 2000 ]; then
    echo "FAIL: default chassis STL has only $facets facets -- too few for 3 honeycomb vent fields (expected 2000+)"
    fail=1
  fi
fi

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

# --- Task 3 negative control: fan_size=70 must abort the NEW fan-flanking-
# vent fit-assert. fan_size=70 passes every earlier assert (known size;
# gusset clearance is guaranteed by _rear_flank_cx()'s own construction;
# rear-wall width 30+fan_size/2+fan_size/2=100<=108.6 still passes -- that's
# the Task 2 assert fan_size=80 isolates; rear-wall height and teardrop
# flat-span both still fit) but shrinks the gap between the fan's outboard
# edge and the side wall's inner face (K-fan_size=76.6-70=6.6mm) below the
# vent's fixed 12mm width -- isolates this one new assert.
out="$(run "$tmp/neg_fan_vent.stl" "$mod" -D "fan_size=70")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: fan_size=70 did NOT abort -- fan-flanking-vent fit-assert broken:"
  echo "$out"; fail=1
fi
if ! echo "$out" | grep -qi 'does not fit between the side wall inner face'; then
  echo "FAIL: fan_size=70 aborted on the WRONG assert (expected 'does not fit between the side wall inner face'):"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_fan_vent.stl" ] && { echo "FAIL: fan_size=70 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Task 3 negative control: lp_card_h=72 must abort the NEW right-side-
# vent-headroom fit-assert. lp_card_h=72 still passes the Task 1
# standoff+board+LP-card-height fit-assert (<= _int_h()=86.11) but pushes the
# LP-card keep-out top (_card_top_z()) high enough that the right wall's
# above-the-card vent band shrinks below one honeycomb cell -- isolates this
# one new assert.
out="$(run "$tmp/neg_vent_headroom.stl" "$mod" -D "lp_card_h=72")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: lp_card_h=72 did NOT abort -- right-side-vent-headroom fit-assert broken:"
  echo "$out"; fail=1
fi
if ! echo "$out" | grep -qi 'too tight for cell'; then
  echo "FAIL: lp_card_h=72 aborted on the WRONG assert (expected 'too tight for cell'):"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_vent_headroom.stl" ] && { echo "FAIL: lp_card_h=72 negative control produced a non-empty STL (should have aborted)"; fail=1; }

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

# --- Honeycomb vent void regression (Task 3): each of the 3 vent fields must
# be a REAL void through the wall at a hex hole it actually draws, not just a
# numerically-placed dead space. Probe centers are exact hex centers,
# independently re-derived from honeycomb_vent()'s own col_pitch/row_pitch
# math (cell=8, hc_wall=1.2 defaults) and each field's world transform
# (verified empirically during implementation), NOT guessed -- a naive probe
# could easily land on the solid web between hexes instead of a hole.
# Left side wall (sx=-1, full-height band z0=6, h=76.11): hex at local
# (col x=28.8, row y=36.5769) -> world (-109.8, 44.8, 42.5769).
probe_empty "translate([-110.3, 44.3, 42.0769]) cube([1,1,1]);" "left side intake vent does not open through the wall"
probe_solid "translate([-110.3, 7.5, 42.0769]) cube([1,1,1]);" "left side wall material before the vent's own Y-range unexpectedly empty"
# Right side wall (sx=+1, LP-card-constrained band z0=73.97, h=11.14): hex at
# local (col x=14.4, row y=4.0641) -> world (109.8, 30.4, 78.034).
probe_empty "translate([109.3, 29.9, 77.534]) cube([1,1,1]);" "right side intake vent does not open through the wall"
probe_solid "translate([109.3, 7.5, 77.534]) cube([1,1,1]);" "right side wall material before the vent's own Y-range unexpectedly empty"
# Rear vent flanking the fan (local col x=7.2, row y=32.5128, rotate([-90,0,0])
# reverses local Y onto world Z) -> world (-100.4, 226.8, 49.597).
probe_empty "translate([-100.9, 226.3, 49.097]) cube([1,1,1]);" "rear fan-flanking vent does not open through the wall"
probe_solid "translate([-100.9, 226.3, 3]) cube([1,1,1]);" "rear wall material below the fan-flanking vent's own Z-band unexpectedly empty"

[ "$fail" -eq 0 ] && echo ok || exit 1
