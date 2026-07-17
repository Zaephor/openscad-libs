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

# Negative control: assert the fit-check rejects a deliberately-too-tight pitch.
cat > "$tmp/tight.scad" <<'EOF'
use <keystone/keystone.scad>;
assert(keystone_pitch_ok(keystone_min_pitch() - 0.5) == false, "too-tight pitch must fail");
assert(keystone_pitch_ok(keystone_min_pitch()) == true, "exact min_pitch must pass");
EOF
out="$(run "$tmp/tight.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fit-check boundary wrong:"; echo "$out"; exit 1
fi

# keystone_pitch_assert must ABORT render on a too-tight pitch (stderr assert).
cat > "$tmp/assert_tight.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_pitch_assert(keystone_min_pitch() - 0.5);
EOF
out="$(run "$tmp/assert_tight.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_pitch_assert failed to abort a too-tight pitch:"; echo "$out"; exit 1
fi
# ...and must NOT abort at exact min_pitch.
cat > "$tmp/assert_ok.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_pitch_assert(keystone_min_pitch());
EOF
out="$(run "$tmp/assert_ok.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_pitch_assert wrongly aborted at min_pitch:"; echo "$out"; exit 1
fi

# Negative control: keystone_opening("bogus") must abort with assert.
cat > "$tmp/unknown_style.scad" <<'EOF'
use <keystone/keystone.scad>;
o = keystone_opening("bogus");
EOF
out="$(run "$tmp/unknown_style.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_opening(\"bogus\") failed to abort with unknown style:"; echo "$out"; exit 1
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

# Cutout: window (ow+2c) x (oh+2c), spanning the plate thickness in Z with overcut.
cat > "$tmp/opening.scad" <<'EOF'
use <keystone/keystone.scad>;
o = keystone_opening();
echo(o[0]); echo(o[1]);
EOF
op_out="$(run "$tmp/opening.scad")"
ow="$(echo "$op_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
oh="$(echo "$op_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

PLATE=3.0; CLR=0.25
cat > "$tmp/cutout.scad" <<EOF
use <keystone/keystone.scad>;
keystone_cutout(plate_thickness = $PLATE, clearance = $CLR);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/cutout.stl" "$tmp/cutout.scad" 2>/dev/null

python3 - "$tmp/cutout.stl" "$ow" "$oh" "$CLR" "$PLATE" <<'PY' || { echo "cutout window/extent incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y); zs.append(z)
ow,oh,clr,plate=map(float,sys.argv[2:6]); tol=0.1
wx=ow+2*clr; wy=oh+2*clr
ok=(abs((max(xs)-min(xs))-wx)<tol and abs((max(ys)-min(ys))-wy)<tol and
    max(zs)>0.5 and                      # front overcut above Z=0
    min(zs) < -(plate) + 0.001)          # rear overcut below the plate rear face
sys.exit(0 if ok else 1)
PY

# Tab: [hook_ledge_z, tab_thickness, hook_edge, latch_edge] -- need ledge_z/
# tab_th to sample the hook ledge's actual Z band (not a guessed midpoint).
cat > "$tmp/tab.scad" <<'EOF'
use <keystone/keystone.scad>;
t = keystone_tab();
echo(t[0]); echo(t[1]);
EOF
tab_out="$(run "$tmp/tab.scad")"
ledge_z="$(echo "$tab_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
tab_th="$(echo "$tab_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

# Insert: flange wider than opening; plug fits window; body reaches behind plate.
PLATE=3.0
cat > "$tmp/insert.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(plate_thickness = $PLATE);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/insert.stl" "$tmp/insert.scad" 2>/dev/null

python3 - "$tmp/insert.stl" "$ow" "$oh" "$PLATE" "$ledge_z" "$tab_th" <<'PY' || { echo "insert mate geometry incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
verts=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); verts.append((x,y,z))
ow,oh,plate,ledge_z,tab_th=map(float,sys.argv[2:7]); tol=0.1
xs=[x for x,y,z in verts]; ys=[y for x,y,z in verts]; zs=[z for x,y,z in verts]
# flange: overall X span exceeds the opening width (front stop present)
flange_ok = (max(xs)-min(xs)) > ow + 0.5
# plug fits: sample verts at the hook ledge's actual top edge (Z=-ledge_z, per
# keystone_tab()[0] -- NOT a guessed midpoint); their X span must stay under
# the raw opening, confirming the plug+hook cross-section threads the window.
topz = -ledge_z
band=[ (x,y) for x,y,z in verts if abs(z-topz) < 0.05 ]
plug_ok = bool(band) and (max(x for x,y in band)-min(x for x,y in band)) <= ow - 0.05
# body reaches behind the plate rear (latch region)
behind_ok = min(zs) < -plate - 0.2
# hook Y-extent regression: plug/hook region (Z<0) must not exceed raw opening
# edge (regression check for Y-protrusion bug). Flange (Z>=0) intentionally
# exceeds opening as a front stop, so excluded from this check.
plug_verts = [(x,y,z) for x,y,z in verts if z < 0]
hook_ok = all(y <= oh/2 + 0.01 for x,y,z in plug_verts)
if not hook_ok:
    sys.stderr.write("insert hook Y-extent exceeds opening bound (regression)\n")
sys.exit(0 if (flange_ok and plug_ok and behind_ok and hook_ok) else 1)
PY

echo ok
