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

[ "$fail" -eq 0 ] && echo ok || exit 1
