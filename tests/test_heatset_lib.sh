#!/usr/bin/env bash
# Verifies the heatset library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/heatset/tests/heatset_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "heatset_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: unknown size must assert.
cat > "$tmp/bad_size.scad" <<'EOF'
use <heatset/heatset.scad>;
x = heatset_insert_od("M99");
EOF
out="$(run "$tmp/bad_size.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown size:"; echo "$out"; exit 1
fi

echo ok
