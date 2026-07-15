#!/usr/bin/env bash
# Verifies the motherboards library asserts via OpenSCAD stderr (exit code is
# unreliable on assert files, so we grep stderr for ERROR/Assertion).
# NOTE: --export-format echo silently swallows assert failures on OpenSCAD 2021.01;
# --export-format stl surfaces them on stderr as expected by this harness.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/motherboards/tests/motherboards_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

# Positive: the real test file must NOT emit an assertion error.
out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "motherboards_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Backward-compat control (Task 2 of the hole-role-tagging plan): a no-role
# consumer must still render cleanly with NO role-categories WARNING (every
# form factor in this lib is single-role today -- structural-mount only --
# so unfiltered access never warns, unlike sbc's multi-role bpir4).
cat > "$tmp/norole_holes.scad" <<'EOF'
use <motherboards/motherboards.scad>;
difference() {
    cube([304.80, 243.84, 1.57]);
    mobo_standoff_holes("atx"); // role omitted -> undef, all holes, single role -> no WARNING
}
EOF
out="$(run "$tmp/norole_holes.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "no-role mobo_standoff_holes(\"atx\") failed to render:"; echo "$out"; exit 1
fi
if echo "$out" | grep -qiE 'WARNING:'; then
  echo "no-role mobo_standoff_holes(\"atx\") unexpectedly emitted a WARNING (lib is single-role today):"; echo "$out"; exit 1
fi

# Negative: a deliberately-wrong assert MUST be caught (proves the harness has teeth).
cat > "$tmp/bad_test.scad" <<'EOF'
use <motherboards/motherboards.scad>;
assert(mobo_size("atx") == [1, 1], "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

# Negative: an unknown hole-role string MUST assert (sbc parity -- a typo'd
# role must not silently return an empty list). mirrors sbc's unknown-role
# negative control.
cat > "$tmp/badrole.scad" <<'EOF'
use <motherboards/motherboards.scad>;
x = mobo_standoff_xy("atx", "bogus-role");
EOF
out="$(run "$tmp/badrole.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "unknown hole role must assert:"; echo "$out"; exit 1
fi

echo ok
