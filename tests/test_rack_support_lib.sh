#!/usr/bin/env bash
# Verifies the rack-support library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack-support/tests/rack_support_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack_support_test.scad asserts failed:"; echo "$out"; exit 1
fi

# No validation logic exists yet to drive a real negative control -- the
# accessors are plain constants with nothing to reject (Task 3/4 add
# rack_support_plate()/rack_support_tongue() and their own negative
# controls once there's real geometry/argument validation to break). For
# now, additionally require the accessor file renders with NO warnings at
# all (not just no errors), so a broken `use` path or an unknown-function
# typo in the test itself can't silently pass via WARNING-only output.
if echo "$out" | grep -qiE 'WARNING:'; then
  echo "rack_support_test.scad rendered with unexpected warnings:"; echo "$out"; exit 1
fi

echo ok
