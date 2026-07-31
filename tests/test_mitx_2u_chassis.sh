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

[ "$fail" -eq 0 ] && echo ok || exit 1
