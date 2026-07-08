#!/usr/bin/env bash
# Verifies the rack10 library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack10/tests/rack10_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack10_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control 1: unknown standard must assert.
cat > "$tmp/bad_std.scad" <<'EOF'
use <rack10/rack10.scad>;
x = rack10_hole_h_span("bogus");
EOF
out="$(run "$tmp/bad_std.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown standard:"; echo "$out"; exit 1
fi

# Negative control 2: unknown hole_type must assert.
cat > "$tmp/bad_hole.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, "taped");
EOF
out="$(run "$tmp/bad_hole.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown hole_type:"; echo "$out"; exit 1
fi

echo ok
