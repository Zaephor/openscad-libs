#!/usr/bin/env bash
# Verifies the keystone-faceplate project renders + asserts (OpenSCAD exit code
# unreliable; grep stderr). Geometry checks via STL bbox.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/keystone-faceplate"
run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Blank + ears render clean at defaults.
out="$(run "$proj/keystone-faceplate.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "default faceplate errored"; echo "$out"; exit 1; } || true

# Panel is device_height(1)=43.66 tall (consumes the gap-aware rack10_panel).
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/fp.stl" \
  "$proj/keystone-faceplate.scad" 2>/dev/null
python3 - "$tmp/fp.stl" <<'PY' || { echo "faceplate height != device_height(1)=43.66"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        zs.append(struct.unpack('<3f',d[base:base+12])[2])
sys.exit(0 if abs((max(zs)-min(zs))-43.66)<0.01 else 1)
PY

# Drift checks + blank-plate render.
out="$(run "$proj/tests/asserts.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "asserts.scad failed"; echo "$out"; exit 1; } || true

# N ports pierce the plate: a 6-port plate has strictly more facets removed than
# a 0-port plate (each window adds facets). Proxy: 6-port STL triangle count >
# 0-port STL count.
# NOTE: OPENSCADPATH is only libraries/ (scripts/openscad.sh) — projects/ is NOT
# on it, so the temp scad files use an ABSOLUTE path to the entry file via an
# unquoted heredoc ($proj expands; the snippets contain no OpenSCAD `$` tokens).
tri() { python3 - "$1" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read(); print(struct.unpack('<I',d[80:84])[0])
PY
}
cat > "$tmp/p0.scad" <<EOF
use <keystone/keystone.scad>;
use <$proj/keystone-faceplate.scad>;
keystone_faceplate("labrax", 0, keystone_pitch(), 3.0);
EOF
cat > "$tmp/p6.scad" <<EOF
use <keystone/keystone.scad>;
use <$proj/keystone-faceplate.scad>;
keystone_faceplate("labrax", 6, keystone_pitch(), 3.0);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p0.stl" "$tmp/p0.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/p6.stl" "$tmp/p6.scad" 2>/dev/null
[ "$(tri "$tmp/p6.stl")" -gt "$(tri "$tmp/p0.stl")" ] \
  || { echo "6-port plate has no more facets than blank -> ports not cut"; exit 1; }

# Each bad-param render MUST assert.
expect_assert() { # $1 = scad file, $2 = label
  local o; o="$(run "$1")"
  echo "$o" | grep -qiE 'ERROR:|Assertion .* failed' \
    || { echo "expected assert: $2"; echo "$o"; exit 1; }
}
# Absolute path to the entry file (OPENSCADPATH excludes projects/); unquoted
# heredocs so $proj expands.
# Sub-min pitch.
cat > "$tmp/badpitch.scad" <<EOF
use <keystone/keystone.scad>;
use <$proj/keystone-faceplate.scad>;
keystone_faceplate("labrax", 4, 5, 3.0);   // 5mm << min_pitch
EOF
expect_assert "$tmp/badpitch.scad" "sub-min pitch"
# Thickness above snap range.
cat > "$tmp/badthick.scad" <<EOF
use <keystone/keystone.scad>;
use <$proj/keystone-faceplate.scad>;
keystone_faceplate("labrax", 4, keystone_pitch(), 5.0);  // > 3.0 max
EOF
expect_assert "$tmp/badthick.scad" "thickness above range"
# Too many ports -> row overflows into ear columns.
cat > "$tmp/badN.scad" <<EOF
use <keystone/keystone.scad>;
use <$proj/keystone-faceplate.scad>;
keystone_faceplate("labrax", 40, keystone_pitch(), 3.0);
EOF
expect_assert "$tmp/badN.scad" "port row overflow"

# Boss-driven ear-collision guard (Task 4): 12 ports at default pitch fits
# under the raw opening half-width (7.7mm) but NOT under the "lip" boss
# footprint half-width (9.3mm) -- the boss is physically wider than its own
# cutout window, so a guard keyed off keystone_opening() alone under-protects
# for "lip". Confirms outer_edge uses keystone_boss_footprint() for "lip".
cat > "$tmp/badN_boss.scad" <<EOF
use <keystone/keystone.scad>;
use <$proj/keystone-faceplate.scad>;
keystone_faceplate("labrax", 12, keystone_pitch(), 3.0);
EOF
expect_assert "$tmp/badN_boss.scad" "lip boss overflow (opening-only guard would pass)"

echo ok
