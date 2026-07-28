#!/usr/bin/env bash
# Verifies the mitx-1u-chassis project renders + its fit-asserts pass at
# defaults, and that the two negative controls genuinely abort (OpenSCAD
# exit code unreliable for asserts -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/mitx-1u-chassis"
mod="$proj/mitx-1u-chassis.scad"
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
  echo "FAIL: default mitx-1u-chassis.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/default.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# Honeycomb vents (Task 3): three fields (2 side intake + 1 rear fan-flanking)
# each self-recompute + echo HONEYCOMB_WORST_SPAN inside honeycomb.scad --
# same idiom as tests/test_bpir4_honeycomb_vents.sh / test_fan_grille.sh.
# Facet count is a real-teeth proxy that the fields are actual hex-prism
# arrays cut through the walls, not dead/solid space; the worst-span values
# are the actual self-support regression guard.
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
  if [ "$facets" -lt 3000 ]; then
    echo "FAIL: default chassis STL has only $facets facets -- too few for 3 honeycomb vent fields (expected 3000+)"
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

# --- Negative control 1: heatsink_ceiling=40 must abort the 1U clearance
# fit-assert (standoff_h + mobo_thickness() + heatsink_ceiling > _int_h()).
out="$(run "$tmp/neg_heatsink.stl" "$mod" -D "heatsink_ceiling=40")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: heatsink_ceiling=40 did NOT abort -- 1U clearance fit-assert broken:"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_heatsink.stl" ] && { echo "FAIL: heatsink_ceiling=40 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Negative control 2: a board_offset that shoves the board (and the
# button, which tracks the IO cutout's low edge) hard toward -X must abort
# the off-center guard (button hole walks off the panel's low edge).
out="$(run "$tmp/neg_offcenter.stl" "$mod" -D "board_offset=-80")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: board_offset=-80 did NOT abort -- off-center guard broken:"
  echo "$out"; fail=1
fi
[ -s "$tmp/neg_offcenter.stl" ] && { echo "FAIL: board_offset=-80 negative control produced a non-empty STL (should have aborted)"; fail=1; }

# --- Hole-void regression: the IO cutout and button hole must be REAL voids
# through the faceplate (not just numerically-placed dead space) -- same
# probe idiom as tests/test_css610_underdesk_mount.sh. Positive controls
# (off-cutout material) prove the probes are actually discriminating.
probe_empty() { # $1 = probe .scad body (intersection block), $2 = description
  rm -f "$tmp/p.stl"
  cat > "$tmp/p.scad" <<EOF
use <$mod>;
intersection() {
    mitx_1u_chassis();
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
    mitx_1u_chassis();
    $1
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p.stl" "$tmp/p.scad" >/dev/null 2>&1
  [ -s "$tmp/p.stl" ] || { echo "FAIL: $2 -- expected solid material, got empty (probe miscalibrated)"; fail=1; }
}

# IO cutout: low edge, mid, high edge (numeric literals below match the
# default board_offset=20 geometry: _io_x0()=-67.62, _io_x1()=91.13).
probe_empty "translate([-65, -4, 20]) cube([2,5,2]);" "IO cutout near low edge does not open through"
probe_empty "translate([0, -4, 20]) cube([2,5,2]);"   "IO cutout mid-span does not open through"
probe_empty "translate([87, -4, 20]) cube([2,5,2]);"  "IO cutout near high edge does not open through"
# Button hole (default _button_x()=-97.31, panel Z mid = rack10_device_height(1)/2=21.83).
probe_empty "translate([-98.31, -4, 20.83]) cube([2,5,2]);" "button hole does not open through"
# Positive controls: faceplate material clear of any cutout/hole.
probe_solid "translate([60, -4, 4]) cube([2,5,2]);"    "below-IO faceplate material unexpectedly empty"
probe_solid "translate([-115, -4, 40]) cube([2,5,2]);" "left-ear faceplate material unexpectedly empty"
# IO window reaches flush to the 1U interior ceiling (_io_window_h() =
# _int_h()-standoff_h, top edge = floor_th+standoff_h+_io_window_h() =
# rack10_device_height(1) = 43.66) -- probe just under the panel top,
# inside the IO window's X-span, confirms the window is cut to its full
# computed height rather than some smaller nominal/placeholder band.
probe_empty "translate([60, -4, 43]) cube([2,5,0.5]);" "IO window does not reach flush to the 1U interior ceiling"

# Rear wall / #40 tongue (Task 2). Numeric literals below match the default
# geometry (standard=labrax: rack10_rear_post_y=240, rack_support_engagement_depth=12
# -> _tongue_y()=228; wall=2.4 -> rear wall inner face=225.6; fan_size=40 ->
# _fan_cx()=-55.5, dc_dia=11 -> _dc_cx()=55.5; rear_center_z=21.83).
# Fan bore + DC-in must be REAL voids clean through the rear wall.
probe_empty "translate([-56.5, 226, 20.83]) cube([2,2,2]);" "fan bore does not open through the rear wall"
probe_empty "translate([54.5, 226, 20.83]) cube([2,2,2]);"  "DC-in hole does not open through the rear wall"
# Positive control: plain rear wall material clear of the fan/DC-in/tongue.
probe_solid "translate([-91, 226, 20.83]) cube([2,2,2]);" "rear wall material beside the fan unexpectedly empty"
# The #40 tongue must be REAL material (not just numerically placed dead
# space) at its own footprint, well past the rear wall.
probe_solid "translate([-1, 233, 5]) cube([2,2,2]);" "#40 tongue is not real material"
# Buttress regression: the tongue's underside must be solidly supported by
# the tray's own floor for its full engagement reach (no unsupported
# overhang) -- rack-support's own README "Buttressing" consumer contract.
# A floor that stops short of the tongue's own Y-span (a real prior bug
# caught only by this probe, not by a clean render) would leave this empty.
probe_solid "translate([-0.4, 233.6, 0.1]) cube([0.8,0.8,0.8]);" "no floor/buttress under the #40 tongue -- unsupported overhang"

[ "$fail" -eq 0 ] && echo ok || exit 1
