#!/usr/bin/env bash
# Verifies the lid's center vent band uses the shared self-supporting
# honeycomb hex-hole cutter (libraries/honeycomb/honeycomb.scad) instead of
# the old slot-cube loop (parts/lid.scad's old `lid_vents` block), for
# visual consistency with the faceplate's honeycomb intake vents (see
# tests/test_bpir4_honeycomb_vents.sh for that half). Checks:
#   (a) the old per-slot cube loop is gone from lid.scad;
#   (b) lid.scad now calls honeycomb_vent(...);
#   (c) the lid still renders clean (no ERROR / manifold warning);
#   (d) the rendered lid is actually a many-hole honeycomb array, not the old
#       handful of slot cubes -- far more STL facets (real-teeth proxy for
#       (a)+(b) actually being wired together, not just textually true);
#   (e) the worst-case boundary-hex bridge span honeycomb.scad computes for
#       itself (echo()'d as HONEYCOMB_WORST_SPAN=, see
#       libraries/honeycomb/honeycomb.scad and
#       tests/test_bpir4_honeycomb_vents.sh for why this is the real
#       regression guard) is numerically <=5mm, the design-for-print
#       self-support ceiling.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
fail=0

# (a) old per-slot vent cube loop must be gone.
if grep -q 'cube(\[lid_vent_band_w, vent_slot_w' "$proj/parts/lid.scad"; then
  echo "FAIL: lid slot vents still present"
  fail=1
fi

# (b) lid.scad must now call the shared honeycomb helper.
if ! grep -q 'honeycomb_vent(' "$proj/parts/lid.scad"; then
  echo "FAIL: lid.scad does not call honeycomb_vent()"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "FAIL: skipping render checks (prerequisite checks above failed)"
  exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/lid.stl" \
       "$proj/parts/lid.scad" 2>&1)"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: lid render errored:"; echo "$out"; fail=1
fi
if [ ! -s "$tmp/lid.stl" ]; then
  echo "FAIL: empty lid STL"; fail=1
fi

facets=0
if [ -s "$tmp/lid.stl" ]; then
  facets=$(grep -c "facet normal" "$tmp/lid.stl")
  # Old slot-loop design (10 rectangular through-slots) rendered ~1764 facets
  # total for the whole lid; a honeycomb array over the same band adds dozens
  # of hex prisms and should push this well past that.
  if [ "$facets" -lt 2500 ]; then
    echo "FAIL: lid STL has only $facets facets -- too few for a honeycomb vent array (expected 2500+)"
    fail=1
  fi
fi

# (e) worst-case boundary-hex bridge span must be <=5mm.
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

[ "$fail" -eq 0 ] && echo "ok ($facets facets, worst_span=${span:-?}mm)"
exit "$fail"
