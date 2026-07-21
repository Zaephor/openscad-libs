#!/usr/bin/env bash
# Verifies the pcie-bracket library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/pcie-bracket/tests/pcie-bracket_test.scad"

run() { OPENSCADPATH="$root/libraries" "$root/scripts/openscad.sh" \
          --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "pcie-bracket_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: unknown type must assert.
cat > "$tmp/bad_type.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_size("bogus");
EOF
out="$(run "$tmp/bad_type.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type:"; echo "$out"; exit 1
fi

# Negative control: unknown type must assert on the holes accessor too.
cat > "$tmp/bad_type_holes.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_holes("bogus");
EOF
out="$(run "$tmp/bad_type_holes.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type (pcie_bracket_holes):"; echo "$out"; exit 1
fi

# Negative control: unknown/typo'd hole role must assert (not silently return []).
cat > "$tmp/bad_role.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_holes("full-height", "structural-moutn"); // typo, must assert
EOF
out="$(run "$tmp/bad_role.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown hole role:"; echo "$out"; exit 1
fi

# Positive control: a known-but-absent role ("keep-out") is a legal no-op
# filter (0 holes, no error), not an assert -- exercises the vocab/data split.
cat > "$tmp/keep_out.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_holes("low-profile", "keep-out");
assert(x == [], "keep-out should be a legal empty filter");
EOF
out="$(run "$tmp/keep_out.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keep-out no-op filter unexpectedly failed:"; echo "$out"; exit 1
fi

# Positive control: role="all" is a silent wildcard synonym for undef -- must
# render cleanly (no assert) and return the same single hole.
cat > "$tmp/role_all.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
assert(pcie_bracket_holes("full-height", "all") == pcie_bracket_holes("full-height"), "all == undef");
EOF
out="$(run "$tmp/role_all.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "role=\"all\" consumer failed:"; echo "$out"; exit 1
fi

echo ok
