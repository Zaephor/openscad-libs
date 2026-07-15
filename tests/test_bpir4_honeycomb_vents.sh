#!/usr/bin/env bash
# Verifies the faceplate's above-IO intake vent band uses a self-supporting
# honeycomb hex-hole cutter (parts/_honeycomb.scad) instead of the old
# full-width bridge slot (a flat unsupported roof spanning the whole
# connector-cluster width -- the thing this task replaces). Checks:
#   (a) the old full-width vent-slot cube is gone from tray.scad;
#   (b) parts/_honeycomb.scad exposes the exact honeycomb_vent(width, height,
#       depth, cell, wall) signature Task 3 (lid vents) depends on verbatim;
#   (c) the faceplate still renders clean (no ERROR / manifold warning);
#   (d) the rendered band is actually a many-hole array, not one big slot --
#       a honeycomb of dozens of hex prisms produces far more STL facets than
#       the old single cube-per-row slot did (real-teeth proxy for (a)+(b)
#       actually being wired together, not just textually true).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
fail=0

# (a) old full-width vent-slot cube must be gone.
if grep -q 'cube(\[bx1 - bx0' "$proj/parts/tray.scad"; then
  echo "FAIL: full-width vent slot cube still present in tray.scad"
  fail=1
fi

# (b) exact module signature (Task 3 depends on this without further changes).
if ! grep -Eq 'module[[:space:]]+honeycomb_vent\([[:space:]]*width,[[:space:]]*height,[[:space:]]*depth,[[:space:]]*cell,[[:space:]]*wall[[:space:]]*\)' \
      "$proj/parts/_honeycomb.scad" 2>/dev/null; then
  echo "FAIL: parts/_honeycomb.scad missing exact honeycomb_vent(width, height, depth, cell, wall) signature"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "FAIL: skipping render checks (prerequisite checks above failed)"
  exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/faceplate.stl" \
       "$proj/tests/render_faceplate.scad" 2>&1)"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: faceplate render errored:"; echo "$out"; fail=1
fi
if [ ! -s "$tmp/faceplate.stl" ]; then
  echo "FAIL: empty faceplate STL"; fail=1
fi

facets=0
if [ -s "$tmp/faceplate.stl" ]; then
  # OpenSCAD's default `-o *.stl` export is ASCII (one "facet normal" line per
  # triangle) -- count those lines rather than assume a binary layout.
  facets=$(grep -c "facet normal" "$tmp/faceplate.stl")
  if [ "$facets" -lt 800 ]; then
    echo "FAIL: faceplate STL has only $facets facets -- too few for a honeycomb vent array (expected 800+)"
    fail=1
  fi
fi

[ "$fail" -eq 0 ] && echo "ok ($facets facets)"
exit "$fail"
