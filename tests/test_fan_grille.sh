#!/usr/bin/env bash
# Verifies projects/fan-grille/fan-grille.scad -- a flat, support-free
# honeycomb finger-guard for a case fan (2nd honeycomb.scad consumer after
# bpir4). Model: tests/test_bpir4_honeycomb_vents.sh's render-and-inspect
# idiom. Checks:
#   (a) the default (fan_size=40) grille renders clean (no ERROR / manifold
#       warning);
#   (b) the rendered STL has a high facet count -- proof the honeycomb field
#       is really an array of hex prisms cut through the plate, not a solid
#       square (a solid plate + 4 round holes would be tens of facets, not
#       hundreds+);
#   (c) honeycomb.scad's own self-recomputed HONEYCOMB_WORST_SPAN echo is
#       present and <=5mm, the design-for-print self-support ceiling (see
#       that file's header comment for why this is the real regression
#       guard, not just the facet count);
#   (d) a SECOND fan_size from fan_known_sizes() also renders clean --
#       proves fan_grille() is actually parametric on fan_size, not
#       hard-coded to the 40mm default.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/fan-grille"
fail=0

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# (a) default render.
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/fan-grille-40.stl" \
       "$proj/fan-grille.scad" 2>&1)"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: fan-grille (fan_size=40) render errored:"; echo "$out"; fail=1
fi
if [ ! -s "$tmp/fan-grille-40.stl" ]; then
  echo "FAIL: empty fan-grille STL"; fail=1
fi

# (b) facet count -- proof the honeycomb array is really cut, not a solid plate.
facets=0
if [ -s "$tmp/fan-grille-40.stl" ]; then
  facets=$(grep -c "facet normal" "$tmp/fan-grille-40.stl")
  if [ "$facets" -lt 300 ]; then
    echo "FAIL: fan-grille STL has only $facets facets -- too few for a honeycomb vent array (expected 300+)"
    fail=1
  fi
fi

# (c) worst-case boundary-hex bridge span, self-recomputed inside honeycomb.scad, must be <=5mm.
span_line="$(echo "$out" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*' | tail -1)"
if [ -z "$span_line" ]; then
  echo "FAIL: HONEYCOMB_WORST_SPAN echo not found in render output -- can't verify bridge-span invariant"
  fail=1
else
  span="$(echo "$span_line" | cut -d= -f2)"
  if ! awk -v s="$span" 'BEGIN{exit !(s <= 5.000001)}'; then
    echo "FAIL: HONEYCOMB_WORST_SPAN=$span exceeds the 5mm self-support ceiling"
    fail=1
  fi
fi

# (d) parametricity: a second known fan_size also renders clean.
second_size=120
cat > "$tmp/render_second.scad" <<EOF
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;
use <$proj/fan-grille.scad>;
fan_grille(fan_size = $second_size);
EOF
out2="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/fan-grille-$second_size.stl" \
        "$tmp/render_second.scad" 2>&1)"
if echo "$out2" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: fan-grille (fan_size=$second_size) render errored:"; echo "$out2"; fail=1
fi
if [ ! -s "$tmp/fan-grille-$second_size.stl" ]; then
  echo "FAIL: empty fan-grille STL at fan_size=$second_size"; fail=1
fi
span2_line="$(echo "$out2" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*' | tail -1)"
if [ -z "$span2_line" ]; then
  echo "FAIL: HONEYCOMB_WORST_SPAN echo not found for fan_size=$second_size"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "ok ($facets facets, worst_span=${span:-?}mm at fan_size=40; also renders clean at fan_size=$second_size, worst_span=${span2_line#*=})"
exit "$fail"
