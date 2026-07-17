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

echo ok
