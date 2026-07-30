#!/usr/bin/env bash
# Verifies rack10-device-tray's T1 scaffold + T2 faceplate/port/secure-hole
# additions: default (GS308) preset renders clean, the RLA-PS1 preset
# (wider AND deeper envelope) also renders clean, secure_holes=[] (GS308T,
# desktop-mount-only) renders clean and its facet count is measurably lower
# than the default's (proving the default's countersunk holes are actually
# cut, not silently skipped), and five negative controls (device too tall
# for 1U; a secure_holes entry outside the device footprint; a port cutout
# clipping the #70 chamfered panel corner; a countersink dia not exceeding
# its own hole dia; a countersink cone taller than floor_th) genuinely
# abort their respective fit-asserts (OpenSCAD exit code alone is not
# always reliable for asserts under some export paths -- grep stderr, per
# repo idiom).
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

facets() { echo "$1" | grep -o 'Facets:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$'; }

# Positive control (T2): secure_holes=[] (GS308T, desktop-mount-only) must
# render clean -- tests/no_secure_holes.scad overrides secure_holes. Proves
# the countersunk-hole cutter loop and its guarding asserts tolerate an
# empty list.
out_noholes="$(run "$tmp/no_secure_holes.stl" "$proj/tests/no_secure_holes.scad")"
if echo "$out_noholes" | grep -qiE 'ERROR:|Assertion .* failed|Ignoring unknown|Can.t open library'; then
  echo "FAIL: tests/no_secure_holes.scad (secure_holes=[]) errored:"; echo "$out_noholes"; fail=1
fi
[ -s "$tmp/no_secure_holes.stl" ] || { echo "FAIL: no_secure_holes.scad render produced no/empty STL"; fail=1; }

# T2 proof-of-cut: the default preset's 2 countersunk secure holes must
# actually remove material -- its facet count must exceed the otherwise-
# identical secure_holes=[] render's facet count. Facet-count alone isn't a
# generic geometry oracle, but a strict decrease-to-increase here can only
# come from the hole cutters being applied (same idiom as
# tests/test_drive_tray.sh's honeycomb-vent facet-count-jump check).
out_default="$(run "$tmp/default2.stl" "$proj/rack10-device-tray.scad")"
f_default="$(facets "$out_default")"
f_noholes="$(facets "$out_noholes")"
if [ -z "$f_default" ] || [ -z "$f_noholes" ]; then
  echo "FAIL: could not read CGAL Facets: count from default and/or no-holes render"; fail=1
elif [ "$f_default" -le "$f_noholes" ]; then
  echo "FAIL: default render facets ($f_default) <= secure_holes=[] render facets ($f_noholes) -- countersunk secure holes missing?"
  fail=1
fi

# Negative control (T2): tests/asserts_port.scad overrides port_cutout so
# its top edge lands in the #70 panel's top chamfer band and clips the
# corner -- MUST abort the port-in-panel fit-assert.
out="$(run "$tmp/neg_port.stl" "$proj/tests/asserts_port.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_port.scad (port clips chamfered corner) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_port.stl" ]; then
  echo "FAIL: tests/asserts_port.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control (T2): tests/asserts_csk_positive.scad overrides
# secure_holes with a hole dia >= csk_dia -- MUST abort the positive-
# countersink-cone-height fit-assert.
out="$(run "$tmp/neg_csk_pos.stl" "$proj/tests/asserts_csk_positive.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_csk_positive.scad (hole dia >= csk_dia) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_csk_pos.stl" ]; then
  echo "FAIL: tests/asserts_csk_positive.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Negative control (T2): tests/asserts_csk_breach.scad overrides csk_dia
# large enough that the countersink cone would rise taller than floor_th
# -- MUST abort the no-top-face-breach fit-assert.
out="$(run "$tmp/neg_csk_breach.stl" "$proj/tests/asserts_csk_breach.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts_csk_breach.scad (countersink cone taller than floor_th) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg_csk_breach.stl" ]; then
  echo "FAIL: tests/asserts_csk_breach.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
