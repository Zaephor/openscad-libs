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

  # Single STL parse feeds all four checks below (bbox/plug/noclip, mesh
  # connectivity, and the direct per-tab edge-coordinate check) -- avoids
  # re-reading/re-parsing the same binary STL three times (test-only nit).
  python3 - "$tmp/insert_$STYLE.stl" "$sow" "$soh" "$fw" "$fh" "$FIT" "$PLATE" "$ledge_z" "$tab_th" "$STYLE" <<'PY' || { echo "insert ($STYLE) geometry check failed"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
verts=[]   # raw (x,y,z) per vertex, in STL order
tris=[]    # per-triangle list of rounded (x,y,z) vertices, for connectivity
for i in range(n):
    tri=[]
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12])
        verts.append((x,y,z))
        tri.append((round(x,2), round(y,2), round(z,2)))
    tris.append(tri)
ow,oh,fw,fh,fit,plate,ledge_z,tab_th=map(float,sys.argv[2:10]); style=sys.argv[10]
tol=0.1
xs=[x for x,y,z in verts]; ys=[y for x,y,z in verts]; zs=[z for x,y,z in verts]
errs=[]

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
plug_h_xy = fh - 2*fit
if not plug_ok:
    errs.append(f"plug cross-section {plug_w:.2f}x{plug_h:.2f} != face-derived {fw-2*fit:.2f}x{fh-2*fit:.2f}")

# body reaches behind the plate rear (latch/clip region)
behind_ok = minz < -plate - 0.2

# no-collision invariant: any vertex strictly WITHIN the plate's solid Z-band
# (excludes the front flange at Z>=0 and any feature at/behind the plate rear,
# which are allowed -- by design -- to grip material outside the window) must
# stay within the window's raw X/Y bound, i.e. never punch into solid frame.
inband = [(x,y) for x,y,z in verts if -(plate-0.02) < z < -0.02]
noclip_ok = all(abs(x) <= ow/2+0.05 and abs(y) <= oh/2+0.05 for x,y in inband)
if not noclip_ok:
    errs.append("insert tab protrudes into solid frame within the plate band (regression)")

# Tab/plug connectivity (#28 review finding): plug_ok above only checks the
# plug TIP cross-section (deepest Z -- unrelated to hook/latch position) and
# noclip_ok only checks an UPPER bound against the window edge, which the
# original mid-flight bug also satisfied (it capped at the same o[1]/2, just
# with a gap on the PLUG side). Neither would catch a regression that
# reintroduces the exact bug the implementer hand-caught by dumping raw STL
# vertices: a hook/latch (or fulcrum/clip) tab anchored to a stale
# opening-derived Y offset instead of the plug's own face-derived edge
# (plug_h_xy/2 = (fh-2*fit)/2), leaving it floating with a gap instead of
# meeting the plug flush. Detect this directly and style-agnostically: the
# keystone_insert() solid (flange+plug+both retention features) is meant to
# be ONE physical part, so if any tab doesn't actually touch the plug it
# will render as a disconnected island in the STL mesh -- count connected
# components via union-find over (rounded) shared vertices and require
# exactly one.
parent={}
def find(x):
    while parent[x]!=x:
        parent[x]=parent[parent[x]]; x=parent[x]
    return x
def union(a,b):
    ra,rb=find(a),find(b)
    if ra!=rb: parent[ra]=rb
for tri in tris:
    for v in tri: parent.setdefault(v,v)
    a,b,c=tri; union(a,b); union(b,c)
roots=set(find(v) for v in parent)
conn_ok = (len(roots)==1)
if not conn_ok:
    errs.append(f"insert ({style}) is NOT one connected solid: {len(roots)} disjoint piece(s)")

# Direct per-tab inner-edge coordinate check (#28 RE-REVIEW finding): the
# connectivity check above has a proven blind spot for "lip"'s fulcrum tab --
# it stays welded to the body via the front flange (both touch the Z=0 plane,
# fulcrum footprint subset of flange footprint) regardless of whether ITS OWN
# inner Y-edge actually reaches the plug, so a fulcrum floating away from the
# plug still counts as "1 connected component". Sidestep that confound
# entirely: read each tab's OWN free face -- a Z-plane that belongs to no
# other feature (not the flange, not the plug, not the other tab) -- and
# assert its inner Y-edge sits at +/-plug_h_xy/2 directly from raw
# coordinates. This does not depend on mesh connectivity at all, so a floating
# fulcrum (or hook/latch/clip) is caught even when it's still touching
# something else in the solid.
#   face: hook tip Z=-(ledge_z+tab_th), latch tip Z=-(plate+tab_th)
#   lip:  fulcrum tip Z=-ledge_z,       clip tip Z=-(plate+tab_th)
# (both tips are chosen as the Z-plane FARTHEST from any shared boundary --
# the flange only occupies Z in [0,1.2], the plug only has corners at Z=0/-6.)
ZTOL = 0.03
YTOL = 0.05
def inner_edge_at(z_target, want_max):
    pts_y = [y for x,y,z in verts if abs(z - z_target) < ZTOL]
    if not pts_y:
        return None
    return max(pts_y) if want_max else min(pts_y)

if style == "face":
    tab_checks = [
        ("hook",   -(ledge_z + tab_th), False,  plug_h_xy/2),  # +Y edge: inner = min(Y)
        ("latch",  -(plate + tab_th),   True,  -plug_h_xy/2),  # -Y edge: inner = max(Y)
    ]
else:  # "lip"
    tab_checks = [
        ("fulcrum", -ledge_z,          True,  -plug_h_xy/2),   # -Y edge: inner = max(Y)
        ("clip",    -(plate + tab_th), False,  plug_h_xy/2),   # +Y edge: inner = min(Y)
    ]

for name, z_target, want_max, expected in tab_checks:
    inner = inner_edge_at(z_target, want_max)
    if inner is None:
        errs.append(f"insert ({style}) {name}: no vertices found at its own free face Z={z_target:.2f} (tab missing/misshapen)")
    elif abs(inner - expected) > YTOL:
        errs.append(f"insert ({style}) {name}: inner Y-edge {inner:.3f} != plug edge {expected:.3f} (floating gap, #28 regression)")

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(0 if (flange_ok and behind_ok and not errs) else 1)
PY
done

echo ok
