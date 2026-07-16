#!/usr/bin/env bash
# Verifies the rear wall's PASSIVE branch (enable_exhaust=false) is now a
# self-supporting honeycomb vent over the fan footprint, replacing the old
# full-width vertical-slot array (a bug: the "passive" path used to cut
# slots across the ENTIRE body_w(), not just over where fans would sit).
#
# Discriminators (all deterministic -- STL export vertex order is NOT
# deterministic across renders, so `cmp -s` on STL bytes is a false-pass and
# is never used here; see test_bpir4_tray_params.sh's header for the same
# reasoning):
#   1. Source check: tray.scad now has >=2 honeycomb_vent( call sites (the
#      pre-existing faceplate call + the new rear-wall call). A bare
#      `grep -q honeycomb_vent` is insufficient on its own -- the faceplate
#      already calls it -- so this counts call sites instead.
#   2. Runtime check: honeycomb_vent() echoes "HONEYCOMB_WORST_SPAN=" to
#      stderr once per call (see parts/_honeycomb.scad). Render tray() and
#      tray(enable_exhaust=false) via throwaway consumers UNDER
#      projects/bpir4-1u-chassis/ (a `use <parts/tray.scad>` only resolves
#      relative to the consumer file's own directory -- see
#      test_bpir4_tray_params.sh's render_consumer() comment) and count
#      those echo lines: active should see exactly 1 (faceplate only),
#      passive should see MORE than active (faceplate + the new rear vent).
#      This deterministically proves the passive branch adds a honeycomb
#      call, independent of any facet-count heuristic.
#   3. Geometry-differs: passive facet count != active facet count.
#   4. Self-support + manifold: passive stderr must not contain a fatal
#      ERROR, a failed assert (this is exactly how honeycomb_vent's own
#      worst_span<=5 self-support ceiling assert would surface if the
#      fan_size=40 band violated it), or a non-manifold warning.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"

fail=0

# --- 1. Source check: >=2 honeycomb_vent( call sites in tray.scad. Exclude
# comment-only lines (leading `//`) so a prose mention of the function name
# (e.g. "...with honeycomb_vent() (parts/_honeycomb.scad): ...") doesn't
# inflate the count -- only lines that actually invoke it. ---
call_sites="$(grep -v '^[[:space:]]*//' "$proj/parts/tray.scad" | grep -c 'honeycomb_vent(')"
if [ "$call_sites" -lt 2 ]; then
  echo "FAIL: expected >=2 honeycomb_vent( call sites in tray.scad (faceplate + rear), found $call_sites"
  fail=1
else
  echo "ok: tray.scad has $call_sites honeycomb_vent( call sites"
fi

stl_dir="$(mktemp -d)"
consumers=()
cleanup() {
  rm -rf "$stl_dir"
  for c in "${consumers[@]:-}"; do [ -n "$c" ] && rm -f "$c"; done
}
trap cleanup EXIT

# render_consumer <name> <tray-call-args> -> writes stdout/stderr/stl under $stl_dir
render_consumer() {
  local name="$1" args="$2"
  local scad="$proj/_t3_${name}.scad"
  consumers+=("$scad")
  cat > "$scad" <<EOF
use <parts/tray.scad>
tray($args);
EOF
  "$osc" --export-format stl -o "$stl_dir/${name}.stl" "$scad" >"$stl_dir/${name}.stdout" 2>"$stl_dir/${name}.stderr"
}

render_consumer active "enable_exhaust=true, fan_count=2, fan_size=40"
render_consumer passive "enable_exhaust=false, fan_count=2, fan_size=40"

facets() { grep -c 'facet normal' "$1"; }
worst_span_count() { grep -c 'HONEYCOMB_WORST_SPAN=' "$1"; }

# --- 2. Runtime honeycomb-present check. ---
active_spans="$(worst_span_count "$stl_dir/active.stderr")"
passive_spans="$(worst_span_count "$stl_dir/passive.stderr")"
echo "honeycomb call count: active=$active_spans passive=$passive_spans"
if [ "$passive_spans" -le "$active_spans" ]; then
  echo "FAIL: passive render must echo MORE HONEYCOMB_WORST_SPAN= lines than active (faceplate + rear vs faceplate only); active=$active_spans passive=$passive_spans"
  fail=1
fi

# --- 3. Geometry-differs: passive facet count != active facet count. ---
active_facets="$(facets "$stl_dir/active.stl")"
passive_facets="$(facets "$stl_dir/passive.stl")"
echo "facets: active=$active_facets passive=$passive_facets"
if [ "$active_facets" = "$passive_facets" ]; then
  echo "FAIL: passive facet count ($passive_facets) must differ from active ($active_facets)"
  fail=1
fi

# --- 4. Self-support + manifold: no ERROR / failed assert / non-manifold warning. ---
if grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid' "$stl_dir/passive.stderr"; then
  echo "FAIL: passive render reported a fatal/non-manifold result:"
  cat "$stl_dir/passive.stderr"
  fail=1
fi
if [ ! -s "$stl_dir/passive.stl" ]; then
  echo "FAIL: passive render produced an empty/missing STL"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "ok (call_sites=$call_sites, honeycomb calls active=$active_spans/passive=$passive_spans, facets active=$active_facets/passive=$passive_facets, passive manifold+self-supporting)"
exit "$fail"
