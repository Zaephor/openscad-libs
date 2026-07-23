#!/usr/bin/env bash
# Verifies the bay-enclosure project renders clean at defaults, and that the
# tests/asserts.scad negative control genuinely aborts the height fit-assert
# (OpenSCAD exit code unreliable for asserts -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bay-enclosure"

run() { # <stl-out> <scad> [extra -D args...]
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default (bay525_hh, device_u=1) must render clean.
out="$(run "$tmp/be.stl" "$proj/bay-enclosure.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: default bay-enclosure.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/be.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# Faceplate bbox: X-span == rack10_panel_width("labrax")=254, Z-span ==
# rack10_device_height(1)=43.66 (the front panel itself -- the % ghost
# preview of drive_placeholder() is excluded from STL export).
python3 - "$tmp/be.stl" <<'PY' || { echo "FAIL: faceplate bbox != panel_width(254) x device_height(1)=43.66"; fail=1; }
import struct, sys
d = open(sys.argv[1], "rb").read()
n = struct.unpack("<I", d[80:84])[0]; off = 84
xs = []; zs = []
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        x, y, z = struct.unpack("<3f", d[b:b+12])
        xs.append(x); zs.append(z)
xspan = max(xs) - min(xs); zspan = max(zs) - min(zs)
ok = abs(xspan - 254) < 0.05 and abs(zspan - 43.66) < 0.05
sys.exit(0 if ok else 1)
PY

# Negative control: tests/asserts.scad overrides device_type=bay525_fh
# (full-height, 82.55mm) at device_u=1 -- MUST abort the height fit-assert.
# A silent-pass here means the fit-assert regressed.
out="$(run "$tmp/neg.stl" "$proj/tests/asserts.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts.scad (bay525_fh @ 1U) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg.stl" ]; then
  echo "FAIL: tests/asserts.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Device-type guard: an unknown / non-block device_type must also abort (the
# drive_known_types()+drive_family()=="block" guard at the top of the file).
out="$(run "$tmp/badtype.stl" "$proj/bay-enclosure.scad" -D 'device_type="m2_2280"')"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: card-family device_type (m2_2280) did NOT abort the block-drive guard:"
  echo "$out"; fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
