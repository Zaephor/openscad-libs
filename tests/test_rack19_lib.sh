#!/usr/bin/env bash
# Verifies the rack19 library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack19/tests/rack19_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack19_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control 1: a wrong assert must be caught.
cat > "$tmp/bad_test.scad" <<'EOF'
use <rack19/rack19.scad>;
assert(rack19_u() == 1, "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

# Negative control 2: an unknown thread must assert.
cat > "$tmp/bad_thread.scad" <<'EOF'
use <rack19/rack19.scad>;
x = rack19_screw_clearance("bogus");
EOF
out="$(run "$tmp/bad_thread.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown thread:"; echo "$out"; exit 1
fi

echo ok
