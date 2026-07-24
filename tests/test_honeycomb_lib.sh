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
# Cell=20, height=10 creates a scenario where uncontrolled clipping would
# expose spans larger than the 5mm self-support ceiling. This test verifies
# the module rejects misconfigured callers.
cat > "$tmp/bad_params.scad" <<'EOF'
use <honeycomb/honeycomb.scad>;
honeycomb_vent(width=50, height=10, depth=2, cell=20, wall=0.5);
EOF
out="$(run "$tmp/bad_params.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|Current top level object is empty'; then
  echo "negative control should have detected unsafe parameters:"; echo "$out"; exit 1
fi

echo ok
