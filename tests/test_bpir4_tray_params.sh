#!/usr/bin/env bash
# Verifies tray()'s enable_exhaust/fan_size/fan_count/ear_hole_type PARAMETERS
# actually drive geometry (not tray.scad's own file-scope globals).
#
# Root cause under test: OpenSCAD `use` does not share variable scope, so a
# consumer (e.g. assembly.scad) setting enable_exhaust etc. at its own file
# scope never reaches tray.scad's globals. The fix threads these as explicit
# tray() parameters (and further into the _rear_openings()/_faceplate()
# helpers that read them), defaulting to tray.scad's own globals so a bare
# `tray();` standalone render is unchanged.
#
# Discriminator: STL export vertex order is non-deterministic (re-rendering
# identical input yields differing bytes at the same facet count), so a raw
# `cmp` on two STLs ALWAYS reports "differ" -- even on unfixed code -- and
# would be a false pass. Instead we compare deterministic, order-invariant
# geometry summaries: facet count (`grep -c 'facet normal'`) and the Y-max
# bounding-box vertex coordinate. A parameter only counts as "driving
# geometry" if at least one of those differs from the DEFAULT render.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"

stl_dir="$(mktemp -d)"
consumers=()
cleanup() {
  rm -rf "$stl_dir"
  for c in "${consumers[@]:-}"; do [ -n "$c" ] && rm -f "$c"; done
}
trap cleanup EXIT

fail=0

facets() { grep -c 'facet normal' "$1"; }
ymax() { awk '/vertex/ { if ($3+0 > m) m = $3+0 } END { printf "%.3f", m }' "$1"; }

# render_consumer <name> <tray-call-args>
# Writes a throwaway consumer .scad UNDER projects/bpir4-1u-chassis/ (OpenSCAD
# resolves a consumer's `use <parts/tray.scad>` relative to the consumer
# file's own directory, not cwd -- a /tmp consumer fails to find the lib) and
# renders it via scripts/openscad.sh into $stl_dir/<name>.stl.
render_consumer() {
  local name="$1" args="$2"
  local scad="$proj/_t1_${name}.scad"
  consumers+=("$scad")
  cat > "$scad" <<EOF
use <parts/tray.scad>
tray($args);
EOF
  "$osc" --export-format stl -o "$stl_dir/${name}.stl" "$scad" >"$stl_dir/${name}.stdout" 2>"$stl_dir/${name}.stderr"
}

# --- Default render (matches tray.scad's own top-level globals). ---
render_consumer default ""
def_facets="$(facets "$stl_dir/default.stl")"
def_ymax="$(ymax "$stl_dir/default.stl")"
echo "default: facets=$def_facets ymax=$def_ymax"

# check_differs <name> <args> <label>
# Renders with the given args and FAILs unless facet count and/or ymax
# differs from the default render.
check_differs() {
  local name="$1" args="$2" label="$3"
  render_consumer "$name" "$args"
  local f y
  f="$(facets "$stl_dir/${name}.stl")"
  y="$(ymax "$stl_dir/${name}.stl")"
  if [ "$f" = "$def_facets" ] && [ "$y" = "$def_ymax" ]; then
    echo "FAIL: $label param has no effect (facets=$f ymax=$y, same as default facets=$def_facets ymax=$def_ymax)"
    fail=1
  else
    echo "ok: $label differs from default (facets $def_facets -> $f, ymax $def_ymax -> $y)"
  fi
}

# Step 1/2 case: enable_exhaust=false vs default (rest held at default values).
check_differs off 'enable_exhaust=false, fan_count=2, fan_size=40, ear_hole_type="slot"' enable_exhaust

# Step 5 extension: fan_count, fan_size, ear_hole_type each alone vs default.
check_differs fc1 'enable_exhaust=true, fan_count=1, fan_size=40, ear_hole_type="slot"' fan_count
# NOTE: 30mm is not a valid fan_known_sizes() entry (fans.scad's fan_table()
# is 40/50/60/70/80/92/120/140/200/220) -- it asserts out with "unknown size
# 30mm" rather than rendering, so it cannot serve as a differs-from-default
# probe. Use fan_size=50 instead (a real, valid table entry).
check_differs fs50 'enable_exhaust=true, fan_count=2, fan_size=50, ear_hole_type="slot"' fan_size
check_differs earround 'enable_exhaust=true, fan_count=2, fan_size=40, ear_hole_type="round"' ear_hole_type

# --- No-regression: standalone tray.scad (defaults, no args) still renders
# manifold: non-empty STL, no ERROR on stderr. ---
standalone_stl="$stl_dir/standalone.stl"
standalone_err="$("$osc" --export-format stl -o "$standalone_stl" "$proj/parts/tray.scad" 2>&1)"
# Match the repo's established fatal/non-manifold pattern (same regex as
# test_bpir4_corner_posts.sh / test_bpir4_honeycomb_vents.sh). A non-manifold
# result surfaces as "WARNING: Object may not be a valid 2-manifold", NOT an
# ERROR -- and still writes a non-empty STL with facets -- so grepping ERROR
# alone would let a real manifold regression pass silently.
if echo "$standalone_err" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: standalone tray.scad render reported a fatal/non-manifold result:"
  echo "$standalone_err"
  fail=1
fi
if [ ! -s "$standalone_stl" ]; then
  echo "FAIL: standalone tray.scad produced an empty/missing STL"
  fail=1
else
  sf="$(facets "$standalone_stl")"
  if [ "$sf" -lt 1 ]; then
    echo "FAIL: standalone tray.scad STL has 0 facets"
    fail=1
  fi
fi

[ "$fail" -eq 0 ] && echo "ok (enable_exhaust/fan_count/fan_size/ear_hole_type each drive geometry; standalone tray.scad still manifold)"
exit "$fail"
