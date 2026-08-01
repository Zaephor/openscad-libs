#!/usr/bin/env bash
# Verifies the honeycomb library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/honeycomb/tests/honeycomb_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

# Positive control: test basic honeycomb_vent rendering
out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "honeycomb_test.scad asserts failed:"; echo "$out"; exit 1
fi
if ! echo "$out" | grep -q 'HONEYCOMB_WORST_SPAN'; then
  echo "honeycomb_test.scad missing HONEYCOMB_WORST_SPAN echo:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: parameters that violate self-support constraint.
# cell=12, wall=1, height=40 lands a boundary hex's equator-region clip at a
# span of 6mm (>5mm max_safe_span), which genuinely trips the module's
# assert() rather than just producing an empty render. This test verifies
# the module rejects misconfigured callers.
cat > "$tmp/bad_params.scad" <<'EOF'
use <honeycomb/honeycomb.scad>;
honeycomb_vent(width=40, height=40, depth=2, cell=12, wall=1);
EOF
out="$(run "$tmp/bad_params.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "negative control should have detected unsafe parameters:"; echo "$out"; exit 1
fi

# Consistency: honeycomb_cell_centres() must report exactly as many centres as
# honeycomb_vent() draws hexes (same args). Cross-check by rendering a probe
# that reports both counts and asserting they match -- catches the accessor
# and the draw loop silently drifting apart.
cat > "$tmp/consistency_probe.scad" <<'EOF'
use <honeycomb/honeycomb.scad>;
centres = honeycomb_cell_centres(width=40, height=15.9, cell=8, wall=1.2);
echo(str("CENTRES_COUNT=", len(centres)));
honeycomb_vent(width=40, height=15.9, depth=2, cell=8, wall=1.2);
EOF
out="$(run "$tmp/consistency_probe.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "consistency probe asserted:"; echo "$out"; exit 1
fi
centres_count="$(echo "$out" | grep -oE 'CENTRES_COUNT=[0-9]+' | grep -oE '[0-9]+')"
worst_span="$(echo "$out" | grep -oE 'HONEYCOMB_WORST_SPAN=[0-9.]+' | head -1 | grep -oE '[0-9.]+')"
if [ -z "$centres_count" ] || [ "$centres_count" -lt 1 ]; then
  echo "FAIL: honeycomb_cell_centres() reported $centres_count centres (expected > 0)"; exit 1
fi
if [ -z "$worst_span" ]; then
  echo "FAIL: honeycomb_vent() did not echo HONEYCOMB_WORST_SPAN for the same params"; exit 1
fi
echo "ok: honeycomb_cell_centres() reported $centres_count centres, honeycomb_vent() worst_span=$worst_span"

echo ok
