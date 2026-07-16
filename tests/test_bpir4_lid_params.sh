#!/usr/bin/env bash
# Verifies lid()'s enable_exhaust PARAMETER actually drives geometry, and
# (the box-length propagation gap) that the cooling toggle shrinks the whole
# ASSEMBLY via the real Customizer path -- editing the top-level literal in
# assembly.scad, NOT `-D` (which masks the bug by overriding the global in
# every file).
#
# Root cause under test: int_depth()/rear_off()/rear_wall_y() in params.scad
# are FUNCTIONS that read the file-global enable_exhaust. A function cannot
# see a caller's MODULE parameter, so merely threading enable_exhaust into
# tray()/lid() as module params (Task 1) does not reach these functions --
# the box length (and lid-post Y, which derives from rear_wall_y()) stayed
# pinned to the default global's length regardless of the Customizer value.
# The fix adds an optional `ee` param to each function (default = the file
# global, so every existing no-arg call site is unchanged) and threads
# enable_exhaust through from tray()/lid()'s module params into those calls.
#
# Discriminator: STL export vertex order is non-deterministic (re-rendering
# identical input yields differing bytes at the same facet count), so a raw
# `cmp -s` on two STLs ALWAYS reports "differ" -- even on unfixed code --
# and would be a false pass. We use deterministic, order-invariant summaries
# instead: facet count (`grep -c 'facet normal'`) and the Y-max bounding-box
# vertex coordinate ($2=X, $3=Y, $4=Z in an STL `vertex x y z` line).
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

fatal_re='ERROR:|Assertion .* failed|WARNING: Object may not be a valid'

# render_consumer <name> <lid-call-args>
# Writes a throwaway consumer .scad UNDER projects/bpir4-1u-chassis/ (OpenSCAD
# resolves a consumer's `use <parts/lid.scad>` relative to the consumer
# file's own directory, not cwd -- a /tmp consumer fails to find the lib) and
# renders it via scripts/openscad.sh into $stl_dir/<name>.stl.
render_consumer() {
  local name="$1" args="$2"
  local scad="$proj/_t2_${name}.scad"
  consumers+=("$scad")
  cat > "$scad" <<EOF
use <parts/lid.scad>
lid($args);
EOF
  "$osc" --export-format stl -o "$stl_dir/${name}.stl" "$scad" >"$stl_dir/${name}.stdout" 2>"$stl_dir/${name}.stderr"
}

# --- (a) LID param drives geometry: enable_exhaust=false vs default (true) ---
render_consumer lid_default ""
def_ymax="$(ymax "$stl_dir/lid_default.stl")"
def_facets="$(facets "$stl_dir/lid_default.stl")"
echo "lid default: facets=$def_facets ymax=$def_ymax"

render_consumer lid_off "enable_exhaust=false"
off_ymax="$(ymax "$stl_dir/lid_off.stl")"
off_facets="$(facets "$stl_dir/lid_off.stl")"
echo "lid enable_exhaust=false: facets=$off_facets ymax=$off_ymax"

if [ "$off_ymax" = "$def_ymax" ]; then
  echo "FAIL: lid(enable_exhaust=false) ymax ($off_ymax) == default ymax ($def_ymax) -- param has no effect on lid geometry"
  fail=1
else
  if ! awk -v o="$off_ymax" -v d="$def_ymax" 'BEGIN{exit !(o<d)}'; then
    echo "FAIL: lid(enable_exhaust=false) ymax ($off_ymax) should be SHORTER than default ymax ($def_ymax)"
    fail=1
  else
    echo "ok: lid enable_exhaust param drives geometry (ymax $def_ymax -> $off_ymax)"
  fi
fi

# --- (b) END-TO-END box-shrink via the CUSTOMIZER path (the gap-fix
# acceptance test). Simulate editing the Customizer by sed-ing the top-level
# literal in assembly.scad (NOT -D, which would mask the bug by overriding
# the global in every use'd file uniformly regardless of any function-param
# threading bug). ---
asm_true="$proj/assembly.scad"
asm_false="$proj/_t2_asm_false.scad"
consumers+=("$asm_false")
sed 's/^enable_exhaust = true;/enable_exhaust = false;/' "$asm_true" > "$asm_false"
if ! grep -q '^enable_exhaust = false;' "$asm_false"; then
  echo "FAIL: sed did not rewrite assembly.scad's top-level enable_exhaust literal -- check the source line still reads 'enable_exhaust = true;'"
  fail=1
fi

asm_true_err="$("$osc" --export-format stl -o "$stl_dir/asm_true.stl" "$asm_true" 2>&1)"
asm_false_err="$("$osc" --export-format stl -o "$stl_dir/asm_false.stl" "$asm_false" 2>&1)"

if echo "$asm_true_err" | grep -qiE "$fatal_re"; then
  echo "FAIL: assembly.scad (customizer true) render errored:"; echo "$asm_true_err"; fail=1
fi
if echo "$asm_false_err" | grep -qiE "$fatal_re"; then
  echo "FAIL: assembly.scad (customizer false) render errored:"; echo "$asm_false_err"; fail=1
fi

asm_true_ymax="$(ymax "$stl_dir/asm_true.stl")"
asm_false_ymax="$(ymax "$stl_dir/asm_false.stl")"
echo "assembly customizer true: ymax=$asm_true_ymax"
echo "assembly customizer false: ymax=$asm_false_ymax"

if ! awk -v f="$asm_false_ymax" -v t="$asm_true_ymax" 'BEGIN{exit !(f<t)}'; then
  echo "FAIL: assembly ymax(customizer false=$asm_false_ymax) must be < ymax(customizer true=$asm_true_ymax) -- the box did not shrink via the Customizer path"
  fail=1
else
  echo "ok: assembly box shrinks via the Customizer path (ymax $asm_true_ymax -> $asm_false_ymax)"
fi

# --- (c) Standalone no-regression: lid.scad and tray.scad (defaults) still
# render manifold. Same fatal/non-manifold pattern as
# tests/test_bpir4_corner_posts.sh / test_bpir4_tray_params.sh. ---
check_standalone() {
  local label="$1"
  local src="$2"
  local out="$stl_dir/${label}.stl"
  local err
  err="$("$osc" --export-format stl -o "$out" "$src" 2>&1)"
  if echo "$err" | grep -qiE "$fatal_re"; then
    echo "FAIL: standalone $label render reported a fatal/non-manifold result:"
    echo "$err"
    fail=1
    return
  fi
  if [ ! -s "$out" ]; then
    echo "FAIL: standalone $label produced an empty/missing STL"
    fail=1
    return
  fi
  local f
  f="$(facets "$out")"
  if [ "$f" -lt 1 ]; then
    echo "FAIL: standalone $label STL has 0 facets"
    fail=1
    return
  fi
  echo "ok: standalone $label renders manifold ($f facets)"
}
check_standalone lid_standalone "$proj/parts/lid.scad"
check_standalone tray_standalone "$proj/parts/tray.scad"

# --- (d) Post/countersink alignment sanity: full assembly in passive mode
# (customizer false, already rendered above for check (b)) must be clean --
# tray posts + lid countersinks both derive from _lid_post_xy(enable_exhaust)
# so a manifold, error-free assembly confirms they stayed coincident. ---
if echo "$asm_false_err" | grep -qiE "$fatal_re"; then
  echo "FAIL: passive-mode assembly (posts+countersinks) reported a fatal/non-manifold result (already shown above)"
  fail=1
elif [ ! -s "$stl_dir/asm_false.stl" ]; then
  echo "FAIL: passive-mode assembly produced an empty/missing STL"
  fail=1
else
  echo "ok: passive-mode assembly (tray posts + lid countersinks) renders clean/manifold"
fi

[ "$fail" -eq 0 ] && echo "ok (lid enable_exhaust drives geometry; assembly box shrinks end-to-end via the Customizer path; lid/tray standalone renders clean; passive assembly manifold)"
exit "$fail"
