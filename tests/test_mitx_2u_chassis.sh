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

# --- Negative control: standoff_h=7 must abort the 2U-ceiling assert against
# the REAL bracket height (pcie_bracket_size("low-profile")[0]=79.2), not the
# shorter //VERIFY lp_card_h envelope. standoff_h=7 passes every other assert
# -- heatsink (7+1.57+55=63.57), LP-card envelope (7+1.57+64.4=72.97) and the
# card-span assert all still fit under _int_h()=86.11 -- so it isolates this
# one. Before this assert existed, exactly this bump pushed the actual bracket
# through the ceiling with every fit-assert still green.
out="$(run "$tmp/neg_bracket_ceiling.stl" "$mod" -D "standoff_h=7")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: standoff_h=7 did NOT abort -- real-bracket-height ceiling assert broken:"
  echo "$out"; fail=1
fi
if ! echo "$out" | grep -qi 'the real 79.2mm bracket'; then
  echo "FAIL: standoff_h=7 aborted on the WRONG assert (expected 'the real 79.2mm bracket'):"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_bracket_ceiling.stl" ] && { echo "FAIL: standoff_h=7 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Negative control: lp_card_h=70 must abort the bracket-spans-its-card
# assert. 70 still passes the Task 1 2U-card-height assert (6+1.57+70=77.57 <=
# 86.11) but puts the card's top (20.82+70=90.82) above the bracket's own top
# edge (87.2) -- i.e. a card whose upper ports would sit above both the
# bracket and the aperture cut from it. Isolates the fold-datum lower bound.
out="$(run "$tmp/neg_card_span.stl" "$mod" -D "lp_card_h=70")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: lp_card_h=70 did NOT abort -- bracket-spans-card assert broken:"
  echo "$out"; fail=1
fi
if ! echo "$out" | grep -qi 'does not span the card it carries'; then
  echo "FAIL: lp_card_h=70 aborted on the WRONG assert (expected 'does not span the card it carries'):"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_card_span.stl" ] && { echo "FAIL: lp_card_h=70 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Hole-void regression: the IO cutout, PCIe slot aperture, and button
# hole must be REAL voids through the faceplate (not just numerically-placed
# dead space) -- same probe idiom as mitx-1u-chassis's own test. Positive
# controls (off-cutout material) prove the probes are actually discriminating.
# Numeric literals below match the default geometry: _board_x()=-65,
# _io_x0()=-67.62, _io_x1()=91.13 (Z=[8,52.45]); the PCIe card aperture is the
# bracket's own window at X=[91.14,103.12], Z=[25.82,69.38] (fold datum 8.0 +
# pcie_bracket_window("low-profile")); _button_x()=-97.31 (Z mid=44.055).
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
# PCIe card aperture, cut from pcie_bracket_window() (NOT mobo_pcie_cutout(),
# which models the board-side edge-connector slot at Z=[7,19] and left a real
# card's ports facing solid faceplate).
probe_empty "translate([96, -4, 46]) cube([2,5,2]);"  "PCIe card aperture does not open through"
# Button hole.
probe_empty "translate([-98.31, -4, 43.055]) cube([2,5,2]);" "button hole does not open through"
# Positive controls: faceplate material clear of any cutout/hole.
probe_solid "translate([0, -4, 4]) cube([2,5,2]);"     "below-IO faceplate material unexpectedly empty"
probe_solid "translate([-115, -4, 60]) cube([2,5,2]);" "left-ear faceplate material unexpectedly empty"
probe_solid "translate([115, -4, 60]) cube([2,5,2]);"  "right-of-PCIe faceplate material unexpectedly empty"
# The old (wrong) cutter's band must now be SOLID: mobo_pcie_cutout() put a
# 12mm hole at Z=[7,19], which is nowhere near the card's real I/O window.
probe_solid "translate([96, -4, 12]) cube([2,5,2]);"   "board-slot-height faceplate material unexpectedly voided (mobo_pcie_cutout regression)"
# pcie_bracket_mount_holes() is not cut into the faceplate: it bores a Z-axis
# hole through the bracket's FOOT, not a Y-extruding panel through-cut.
# Faceplate material just ABOVE the aperture's own top edge (69.38) must stay
# solid.
probe_solid "translate([96, -4, 71]) cube([2,5,2]);"   "faceplate above the PCIe aperture unexpectedly voided"

# --- Task 2: walls/floor/rear DC-in/fan/#40 tongue + PCIe floor mount hole.
# Numeric literals below match the default geometry: _tongue_y()=228,
# rear wall material Y=[225.6,228]; _rear_center_z()=44.055; _fan_cx()=-62,
# _dc_cx()=62 (fan_size=60 -> _rear_flank_cx()=_gusset_x()+_gusset_xw()/2+
# max(60,11)/2+2 = 25+5+30+2 = 62); _pcie_slot_cx()=97.13.

# Fan bore + DC-in must be REAL voids clean through the rear wall.
probe_empty "translate([-87, 226, 69.055]) cube([1,1,1]);" "fan opening does not open through the rear wall (see #72 regression block below for full pad/hole coverage)"
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

# PCIe bracket foot fastener: this chassis cuts NONE, and the floor under the
# bracket foot's would-be screw (97.13, 8.65) must stay SOLID. That screw
# position sits 2.14mm from structural standoff C's axis (98.65, 10.16) --
# inside the post's own 3.0mm radius -- so boring it would undercut the post's
# own footprint and leave it partly bridging open air. This probe is the
# regression guard: it is at the hole's own centre, inside the floor slab and
# BELOW the post (which starts at z=floor_th=2), so re-introducing the cut
# turns it empty. Verified to discriminate during implementation.
probe_solid "translate([96.5, 8, 0.4]) cube([1.3,1.3,1.2]);" "floor voided at the PCIe bracket foot screw -- undercuts standoff C (mount-hole regression)"
# Positive control: plain floor material well away from any of the above.
probe_solid "translate([50, 8, 0.5]) cube([1.3,1.3,1.5]);" "plain floor material unexpectedly empty"

# --- Aperture/bracket alignment (final-review C1). Both being "in bounds" is
# not enough: the SAME line of sight has to be open through the faceplate
# aperture AND through the card bracket's own I/O window, or a real card's
# ports face solid panel. Each probe is a Y-bar run through both solids
# independently -- the chassis, and pcie_bracket("low-profile") placed at the
# world transform the preview uses. Probed at the window centre and two inset
# corners, with negative controls just outside the window that must be solid
# in BOTH (proving the bars discriminate rather than always missing material).
align_probe() { # $1=x $2=z $3=want(empty|solid) $4=label
  for target in "mitx_2u_chassis()" "translate([97.13, 0, 8]) pcie_bracket(\"low-profile\")"; do
    rm -f "$tmp/al.stl"
    cat > "$tmp/al.scad" <<EOF
use <$mod>;
use <pcie-bracket/pcie-bracket.scad>;
intersection() {
    $target;
    translate([$1-0.4, -5, $2-0.4]) cube([0.8, 12, 0.8]);
}
EOF
    "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/al.scad.stl" "$tmp/al.scad" >/dev/null 2>&1
    n=$(python3 -c "import struct,os;p='$tmp/al.scad.stl';print(struct.unpack('<I',open(p,'rb').read()[80:84])[0] if os.path.exists(p) and os.path.getsize(p)>=84 else 0)")
    got=empty; [ "$n" -gt 0 ] && got=solid
    if [ "$got" != "$3" ]; then
      echo "FAIL: $4 -- expected $3 through '$target', got $got"; fail=1
    fi
    rm -f "$tmp/al.scad.stl"
  done
}
align_probe 97.13 47.6 empty "aperture/window not aligned at the window centre"
align_probe 92.2  27.0 empty "aperture/window not aligned at the low corner"
align_probe 102.0 68.2 empty "aperture/window not aligned at the high corner"
align_probe 97.13 71.0 solid "material above the window is not solid in both (probe miscalibrated)"
align_probe 105.5 47.6 solid "material beside the window is not solid in both (probe miscalibrated)"

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
# Right side wall (sx=+1): same full band as the left now (the LP-card
# "collision" band was dropped -- a vent is a cut THROUGH the wall). Same hex
# as the left probe, mirrored in X: world (109.8, 44.8, 42.5769).
probe_empty "translate([109.3, 44.3, 42.0769]) cube([1,1,1]);" "right side intake vent does not open through the wall"
probe_solid "translate([109.3, 7.5, 42.0769]) cube([1,1,1]);" "right side wall material before the vent's own Y-range unexpectedly empty"
# --- #72 regression: the fan opening is now a honeycomb band with solid
# bearing pads, not a teardrop bore. Each of the 4 fan_mount_holes(60)
# corners must be a REAL through-hole, and a point 3mm inboard of each
# (still within the 9mm pad, outside the ~4.3mm hole) must be solid.
probe_empty "translate([-87, 226, 69.055]) cube([1,1,1]);" "fan mount hole (corner local 5,5) does not open through"
probe_solid "translate([-84, 226, 69.055]) cube([1,1,1]);" "fan pad annulus (corner local 5,5) unexpectedly voided"
probe_empty "translate([-37, 226, 19.055]) cube([1,1,1]);" "fan mount hole (corner local 55,55) does not open through"
probe_solid "translate([-40, 226, 19.055]) cube([1,1,1]);" "fan pad annulus (corner local 55,55) unexpectedly voided"

[ "$fail" -eq 0 ] && echo ok || exit 1
