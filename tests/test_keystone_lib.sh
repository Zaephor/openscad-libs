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

# Negative control: keystone_tab("bogus") must abort with assert (#28 style-keying).
cat > "$tmp/unknown_tab_style.scad" <<'EOF'
use <keystone/keystone.scad>;
t = keystone_tab("bogus");
EOF
out="$(run "$tmp/unknown_tab_style.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_tab(\"bogus\") failed to abort with unknown style:"; echo "$out"; exit 1
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

# Jack face (plug cross-section) -- style-independent (#28: plug = face, not opening).
cat > "$tmp/face.scad" <<'EOF'
use <keystone/keystone.scad>;
f = keystone_face();
echo(f[0]); echo(f[1]);
EOF
face_out="$(run "$tmp/face.scad")"
fw="$(echo "$face_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
fh="$(echo "$face_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

# Per-style tab + insert mate-check (#28): keystone_tab(style)/keystone_insert(...,style).
# Mirrors the pre-#28 single-style insert check, generalized across BOTH "lip"
# (fulcrum/flex-clip vs the opening's lips) and "face" (grip the plate faces).
FIT=0.2
for STYLE in lip face; do
  cat > "$tmp/opening_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
o = keystone_opening("$STYLE");
echo(o[0]); echo(o[1]);
EOF
  op_out="$(run "$tmp/opening_$STYLE.scad")"
  sow="$(echo "$op_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
  soh="$(echo "$op_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

  cat > "$tmp/tab_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
t = keystone_tab("$STYLE");
echo(t[0]); echo(t[1]);
EOF
  tab_out="$(run "$tmp/tab_$STYLE.scad")"
  ledge_z="$(echo "$tab_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
  tab_th="$(echo "$tab_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

  # Overlay-mate render: insert dropped into the cutout window, both styles. Any
  # non-manifold/CGAL error on the combined solid means the insert collides
  # with (or fails to clear) the frame material this style's cutout leaves behind.
  PLATE=3.0
  cat > "$tmp/mate_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
union() {
    difference() {
        translate([-15, -15, -$PLATE]) cube([30, 30, $PLATE]);
        keystone_cutout(plate_thickness = $PLATE, style = "$STYLE");
    }
    keystone_insert(plate_thickness = $PLATE, style = "$STYLE");
}
EOF
  mate_out="$(run "$tmp/mate_$STYLE.scad")"
  if echo "$mate_out" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "keystone_insert/cutout overlay-mate ($STYLE) failed:"; echo "$mate_out"; exit 1
  fi

  # Insert alone, numeric bbox checks.
  cat > "$tmp/insert_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(plate_thickness = $PLATE, style = "$STYLE");
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/insert_$STYLE.stl" "$tmp/insert_$STYLE.scad" 2>/dev/null

  python3 - "$tmp/insert_$STYLE.stl" "$sow" "$soh" "$fw" "$fh" "$FIT" "$PLATE" <<'PY' || { echo "insert mate geometry incorrect ($STYLE)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
verts=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); verts.append((x,y,z))
ow,oh,fw,fh,fit,plate=map(float,sys.argv[2:8]); tol=0.1
xs=[x for x,y,z in verts]; ys=[y for x,y,z in verts]; zs=[z for x,y,z in verts]
# flange: overall X span exceeds the window width (front stop present)
flange_ok = (max(xs)-min(xs)) > ow + 0.5
# plug tip = the deepest point (through-plug always extends further back than
# any tab feature); its cross-section must be the jack FACE minus fit per
# side -- NOT the (style-varying, taller-for-lip) opening. This is the core
# #28 regression: plug used to be opening-derived.
minz = min(zs)
band = [(x,y) for x,y,z in verts if abs(z-minz) < 0.05]
plug_w = max(x for x,y in band) - min(x for x,y in band)
plug_h = max(y for x,y in band) - min(y for x,y in band)
plug_ok = bool(band) and abs(plug_w-(fw-2*fit)) < tol and abs(plug_h-(fh-2*fit)) < tol
# body reaches behind the plate rear (latch/clip region)
behind_ok = minz < -plate - 0.2
# no-collision invariant: any vertex strictly WITHIN the plate's solid Z-band
# (excludes the front flange at Z>=0 and any feature at/behind the plate rear,
# which are allowed -- by design -- to grip material outside the window) must
# stay within the window's raw X/Y bound, i.e. never punch into solid frame.
inband = [(x,y) for x,y,z in verts if -(plate-0.02) < z < -0.02]
noclip_ok = all(abs(x) <= ow/2+0.05 and abs(y) <= oh/2+0.05 for x,y in inband)
if not plug_ok:
    sys.stderr.write(f"plug cross-section {plug_w:.2f}x{plug_h:.2f} != face-derived {fw-2*fit:.2f}x{fh-2*fit:.2f}\n")
if not noclip_ok:
    sys.stderr.write("insert tab protrudes into solid frame within the plate band (regression)\n")
sys.exit(0 if (flange_ok and plug_ok and behind_ok and noclip_ok) else 1)
PY
done

echo ok
