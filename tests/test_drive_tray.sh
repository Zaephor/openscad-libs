#!/usr/bin/env bash
# Verifies the drive-tray project renders clean at defaults, that the
# tests/asserts.scad negative control genuinely aborts the width fit-assert,
# and that the default grid stamps the expected total bottom-hole count
# (OpenSCAD exit code unreliable for asserts -- grep stderr, per repo idiom).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/drive-tray"

run() { # <stl-out> <scad> [extra -D args...]
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format binstl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

# Default (#44: 2x hdd35) must render clean.
out="$(run "$tmp/dt.stl" "$proj/drive-tray.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: default drive-tray.scad errored:"; echo "$out"; fail=1
fi
[ -s "$tmp/dt.stl" ] || { echo "FAIL: default render produced no/empty STL"; fail=1; }

# Negative control: tests/asserts.scad overrides cols=9 -- MUST abort the
# grid-width fit-assert. A silent pass here means the fit-assert regressed.
out="$(run "$tmp/neg.stl" "$proj/tests/asserts.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: tests/asserts.scad (cols=9) did NOT abort -- negative control broken:"
  echo "$out"; fail=1
fi
if [ -s "$tmp/neg.stl" ]; then
  echo "FAIL: tests/asserts.scad negative control produced a non-empty STL (should have aborted)"
  fail=1
fi

# Hole-count check: the default grid (cols=2, rows=1, drive_type=hdd35) must
# stamp exactly cols*rows*len(drive_bottom_holes(drive_type)) bottom holes.
# Proxy (same idiom as test_bay_enclosure.sh's check_side_holes): render just
# the cutter geometry through the project's OWN _dt_device_frame() transform
# (single source of truth for cell placement, not a duplicated offset
# formula) as a bare union with no difference(). CGAL's own render-summary
# "Volumes:" line counts N disjoint solids as N+1 -- so (Volumes - 1) must
# equal the drives-lib-computed EXPECT, which the probe echoes itself rather
# than hardcoding, so a future drives-lib data change updates both sides of
# the comparison together.
probe="$tmp/holes.scad"
cat > "$probe" <<EOF
use <drives/drives.scad>;
use <$proj/drive-tray.scad>;
device_type = "hdd35"; // mirrors drive-tray.scad's own default drive_type (use-scope: not importable)
cols = 2; rows = 1;    // mirrors drive-tray.scad's own default cols/rows (use-scope: not importable)
echo(str("EXPECT=", cols*rows*len(drive_bottom_holes(device_type))));
for (c = [0:cols-1]) for (r = [0:rows-1])
    _dt_device_frame(c, r) drive_holes(device_type, faces = "bottom", depth = 5);
EOF
out="$(run "$tmp/holes.stl" "$probe")"
expect="$(echo "$out" | grep -o 'EXPECT=[0-9]*' | tail -1 | cut -d= -f2)"
volumes="$(echo "$out" | grep -o 'Volumes:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
if [ -z "$expect" ] || [ -z "$volumes" ]; then
  echo "FAIL: hole-count probe produced no EXPECT/Volumes -- can't verify hole count:"; echo "$out"; fail=1
elif [ "$((volumes - 1))" -ne "$expect" ]; then
  echo "FAIL: default grid hole count $((volumes - 1)) != expected $expect"
  fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
