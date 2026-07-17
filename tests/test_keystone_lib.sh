#!/usr/bin/env bash
# Verifies the keystone library via OpenSCAD stderr asserts (exit code unreliable)
# plus STL-bbox geometry checks. Geometry checks are added by later tasks.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/keystone/tests/keystone_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: a bad-arity tab consumer must still compile; instead assert
# the fit-check rejects a deliberately-too-tight pitch.
cat > "$tmp/tight.scad" <<'EOF'
use <keystone/keystone.scad>;
assert(keystone_pitch_ok(keystone_min_pitch() - 0.5) == false, "too-tight pitch must fail");
assert(keystone_pitch_ok(keystone_min_pitch()) == true, "exact min_pitch must pass");
EOF
out="$(run "$tmp/tight.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fit-check boundary wrong:"; echo "$out"; exit 1
fi

# Placeholder bbox: bw x bh x bd, front face at Z=0, body grows -Z.
cat > "$tmp/dims.scad" <<'EOF'
use <keystone/keystone.scad>;
b = keystone_body();
echo(b[0]); echo(b[1]); echo(b[2]);
EOF
dims_out="$(run "$tmp/dims.scad")"
bw="$(echo "$dims_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
bh="$(echo "$dims_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
bd="$(echo "$dims_out" | grep -m3 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

cat > "$tmp/placeholder.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_placeholder();
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/placeholder.stl" "$tmp/placeholder.scad" 2>/dev/null

python3 - "$tmp/placeholder.stl" "$bw" "$bh" "$bd" <<'PY' || { echo "placeholder bbox incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y); zs.append(z)
bw,bh,bd=float(sys.argv[2]),float(sys.argv[3]),float(sys.argv[4]); tol=0.1
ok=(abs((max(xs)-min(xs))-bw)<tol and abs((max(ys)-min(ys))-bh)<tol and
    abs((max(zs)-min(zs))-bd)<tol and abs(max(zs))<tol and abs(min(zs)-(-bd))<tol)
sys.exit(0 if ok else 1)
PY

echo ok
