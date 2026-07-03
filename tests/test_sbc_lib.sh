#!/usr/bin/env bash
# Verifies the sbc library asserts via OpenSCAD stderr (exit code unreliable;
# --export-format echo swallows assert failures on OpenSCAD 2021.01).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/sbc/tests/sbc_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "sbc_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/bad_test.scad" <<'EOF'
use <sbc/sbc.scad>;
assert(sbc_size("pi4b") == [1, 1], "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

echo ok
