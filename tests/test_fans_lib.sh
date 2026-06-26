#!/usr/bin/env bash
# Verifies the fans library asserts via OpenSCAD stderr (exit code is unreliable
# on assert files, so we grep stderr for ERROR/Assertion).
# NOTE: --export-format echo silently swallows assert failures on OpenSCAD 2021.01;
# --export-format stl surfaces them on stderr as expected by this harness.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/fans/tests/fans_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

# Positive: the real test file must NOT emit an assertion error.
out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fans_test.scad asserts failed:"; echo "$out"; exit 1
fi

# Negative: a deliberately-wrong assert MUST be caught (proves the harness has teeth).
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/bad_test.scad" <<'EOF'
use <fans/fans.scad>;
assert(fan_hole_spacing(120) == 999, "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

echo ok
