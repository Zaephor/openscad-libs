#!/usr/bin/env bash
# Verifies the connectors library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/connectors/tests/connectors_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "connectors_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Positive control: Task 1 types must be resolvable and present in the known-type list.
cat > "$tmp/task1_types.scad" <<'EOF'
use <connectors/connectors.scad>;
types = ["microsd", "sim_2ff", "m2_key_b", "m2_key_m", "mpcie"];
for (t = types) assert(len(connector_size(t)) == 3, str(t, " size"));
for (t = types) assert(search([t], connector_known_types())[0] != undef, str(t, " in known types"));
EOF
out="$(run "$tmp/task1_types.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "Task 1 connector types failed:"; echo "$out"; exit 1
fi

# Negative control: unknown type must assert.
cat > "$tmp/bad_type.scad" <<'EOF'
use <connectors/connectors.scad>;
x = connector_size("bogus");
EOF
out="$(run "$tmp/bad_type.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type:"; echo "$out"; exit 1
fi

echo ok
