#!/usr/bin/env bash
# Verifies the css610-underdesk-mount project renders + data asserts pass
# (OpenSCAD exit code unreliable; grep stderr).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/css610-underdesk-mount"
run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

# Data asserts must pass.
out="$(run "$proj/tests/asserts.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "asserts.scad failed"; echo "$out"; exit 1; } || true

echo ok
