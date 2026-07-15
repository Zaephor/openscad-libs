#!/usr/bin/env bash
# Verifies the heatset library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/heatset/tests/heatset_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "heatset_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: unknown size must assert.
cat > "$tmp/bad_size.scad" <<'EOF'
use <heatset/heatset.scad>;
x = heatset_insert_od("M99");
EOF
out="$(run "$tmp/bad_size.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown size:"; echo "$out"; exit 1
fi

# Placeholder: M3 bbox must match insert_od x insert_length with top face at Z=0.
cat > "$tmp/placeholder_m3.scad" <<'EOF'
use <heatset/heatset.scad>;
heatset_placeholder("M3");
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/placeholder_m3.stl" "$tmp/placeholder_m3.scad" 2>/dev/null

# Derive M3 dimensions dynamically from accessors
cat > "$tmp/get_m3_dims.scad" <<'EOF'
use <heatset/heatset.scad>;
echo(heatset_insert_od("M3"));
echo(heatset_insert_length("M3"));
EOF
dims_out="$(run "$tmp/get_m3_dims.scad")"
m3_od="$(echo "$dims_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.[0-9]+')"
m3_len="$(echo "$dims_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.[0-9]+')"

python3 - "$tmp/placeholder_m3.stl" "$m3_od" "$m3_len" <<'PY' || { echo "M3 placeholder bbox incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y); zs.append(z)
xspan=max(xs)-min(xs); yspan=max(ys)-min(ys); zspan=max(zs)-min(zs)
zmin=min(zs); zmax=max(zs)
# Expected dimensions derived from accessor functions
expected_od=float(sys.argv[2]); expected_len=float(sys.argv[3])
# Tolerance for $fn=48 faceting: ~2%
tol=0.1
sys.exit(0 if abs(xspan-expected_od)<tol and abs(yspan-expected_od)<tol and abs(zspan-expected_len)<tol and abs(zmin-(-expected_len))<tol and abs(zmax)<tol else 1)
PY

echo ok
