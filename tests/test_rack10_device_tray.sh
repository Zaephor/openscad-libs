#!/usr/bin/env bash
# Verifies rack10-device-tray's Task-1 scaffold: default (GS308) preset
# renders clean, the RLA-PS1 preset (wider AND deeper envelope) also
# renders clean, and the two negative controls (device too tall for 1U;
# a secure_holes entry outside the device footprint) genuinely abort their
# respective fit-asserts (OpenSCAD exit code alone is not always reliable
# for asserts under some export paths -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/rack10-device-tray"

run() { # <stl-out> <scad>
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default (GS308) must render clean.
out="$(run "$tmp/default.stl" "$proj/rack10-device-tray.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: default rack10-device-tray.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/default.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# Positive control: RLA-PS1 preset (wider AND deeper than the default) must
# also render clean -- tests/rla_ps1.scad overrides device_size.
out="$(run "$tmp/rla_ps1.stl" "$proj/tests/rla_ps1.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: tests/rla_ps1.scad (RLA-PS1 preset) errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/rla_ps1.stl" ] || { echo "FAIL: RLA-PS1 preset render produced no/empty STL"; fail=1; }

# Negative control: tests/asserts_height.scad overrides device_size to
# [158,102,45] -- MUST abort the 1U-height fit-assert. A silent pass here
# means the fit-assert regressed.
out="$(run "$tmp/neg_height.stl" "$proj/tests/asserts_height.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_height.scad (device_size height=45) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_height.stl" ]; then
  echo "FAIL: tests/asserts_height.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control: tests/asserts_holes.scad overrides secure_holes with an
# entry whose x lands outside the device footprint -- MUST abort the
# per-hole fit-assert.
out="$(run "$tmp/neg_holes.stl" "$proj/tests/asserts_holes.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_holes.scad (secure hole outside footprint) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_holes.stl" ]; then
  echo "FAIL: tests/asserts_holes.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
