#!/usr/bin/env bash
# Verifies the vesa library asserts via OpenSCAD stderr (exit code
# unreliable; --export-format echo swallows assert failures on OpenSCAD
# 2021.01 — use --export-format stl instead). Mirrors tests/test_embedded_lib.sh.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/vesa/tests/vesa_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "vesa_test.scad asserts failed:"; echo "$out"; exit 1
fi
if ! echo "$out" | grep -q "vesa_test OK"; then
  echo "vesa_test.scad did not report OK:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Intentionally-wrong assert -> must be CAUGHT (harness sanity check).
cat > "$tmp/bad_test.scad" <<'EOF'
use <vesa/vesa.scad>;
assert(vesa_spacing("mis-d-75") == [1, 1], "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

# Negative control: unknown/bogus pattern name -> must assert.
cat > "$tmp/bad_pattern.scad" <<'EOF'
use <vesa/vesa.scad>;
x = vesa_holes("bogus");
EOF
out="$(run "$tmp/bad_pattern.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown pattern:"; echo "$out"; exit 1
fi

# Unknown role -> must assert.
cat > "$tmp/bad_role.scad" <<'EOF'
use <vesa/vesa.scad>;
x = vesa_holes_xy("mis-d-100", "bogus");
EOF
out="$(run "$tmp/bad_role.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "unknown role must assert"; echo "$out"; exit 1; }

echo ok
