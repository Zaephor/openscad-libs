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

# Negative control: keystone_slot("bogus") / keystone_notch("bogus") must abort (#38).
cat > "$tmp/unknown_slot_style.scad" <<'EOF'
use <keystone/keystone.scad>;
sl = keystone_slot("bogus");
EOF
out="$(run "$tmp/unknown_slot_style.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_slot(\"bogus\") failed to abort with unknown style:"; echo "$out"; exit 1
fi
cat > "$tmp/unknown_notch_style.scad" <<'EOF'
use <keystone/keystone.scad>;
nt = keystone_notch("bogus");
EOF
out="$(run "$tmp/unknown_notch_style.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_notch(\"bogus\") failed to abort with unknown style:"; echo "$out"; exit 1
fi

# Negative control: keystone_boss_footprint("face") must abort -- no boss for "face".
cat > "$tmp/boss_footprint_no_face.scad" <<'EOF'
use <keystone/keystone.scad>;
bf = keystone_boss_footprint("face");
EOF
out="$(run "$tmp/boss_footprint_no_face.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_boss_footprint(\"face\") failed to abort (no boss for face):"; echo "$out"; exit 1
fi

# Negative control: keystone_boss("bogus") must abort -- an ACTUALLY unknown
# style, distinct from "face" (a legitimate no-op, not an error).
cat > "$tmp/boss_unknown_style.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_boss(style = "bogus");
EOF
out="$(run "$tmp/boss_unknown_style.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_boss(\"bogus\") failed to abort with unknown style:"; echo "$out"; exit 1
fi

# Negative control: keystone_insert(...,flex_side="bogus") must abort (#38 Task 3).
cat > "$tmp/bad_flex_side.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_insert(plate_thickness = 3.0, style = "standard", flex_side = "bogus");
EOF
out="$(run "$tmp/bad_flex_side.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_insert(flex_side=\"bogus\") failed to abort with unknown flex_side:"; echo "$out"; exit 1
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

# Cutout window: X-extent matches ow+2c exactly (width never diverges from
# keystone_opening() -- the slit doesn't narrow in X). Y-extent is checked
# against keystone_slot()'s own raw fields (mouth_h + 2*wall_thickness +
# 2*clearance), NOT keystone_opening()'s height -- as of a code-review fix,
# keystone_opening("standard")'s height is RESEARCH.md's directly measured
# max window (22.25mm, asymmetric top/bottom), while the physical cutout
# (built from keystone_slot()'s wall_thickness field, symmetric top/bottom,
# see keystone_cutout()'s module comment) is intentionally a bit smaller
# (21.42mm) -- opening() reports a real, sourced number that's a
# conservative UPPER bound on the actual cut, safe for flange-sizing
# consumers (never undersized), not a tighter lower bound. Both are locked
# in as explicit, tested facts below rather than left as a silent gap.
cat > "$tmp/opening.scad" <<'EOF'
use <keystone/keystone.scad>;
o = keystone_opening();
echo(o[0]); echo(o[1]);
EOF
op_out="$(run "$tmp/opening.scad")"
ow="$(echo "$op_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
oh="$(echo "$op_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

cat > "$tmp/slot.scad" <<'EOF'
use <keystone/keystone.scad>;
sl = keystone_slot();
echo(sl[1]); echo(sl[3]);
EOF
slot_out="$(run "$tmp/slot.scad")"
slot_wt="$(echo "$slot_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
slot_mh="$(echo "$slot_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

PLATE=3.0; CLR=0.25
cat > "$tmp/cutout.scad" <<EOF
use <keystone/keystone.scad>;
keystone_cutout(plate_thickness = $PLATE, clearance = $CLR);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/cutout.stl" "$tmp/cutout.scad" 2>/dev/null

python3 - "$tmp/cutout.stl" "$ow" "$oh" "$slot_wt" "$slot_mh" "$CLR" "$PLATE" <<'PY' || { echo "cutout window/extent incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y); zs.append(z)
ow,oh,wt,mh,clr,plate=map(float,sys.argv[2:8]); tol=0.1
wx=ow+2*clr                    # X: matches keystone_opening() exactly
wy_physical=(mh+2*wt)+2*clr    # Y: matches keystone_slot()'s own raw fields, NOT keystone_opening()
errs=[]
if not (abs((max(xs)-min(xs))-wx)<tol):
    errs.append(f"cutout X-extent {(max(xs)-min(xs)):.2f} != opening-derived {wx:.2f}")
if not (abs((max(ys)-min(ys))-wy_physical)<tol):
    errs.append(f"cutout Y-extent {(max(ys)-min(ys)):.2f} != slot-derived {wy_physical:.2f}")
if not (max(zs)>0.5):
    errs.append("cutout does not overcut above the panel front (Z=0)")
if not (min(zs) < -(plate) + 0.001):
    errs.append("cutout does not extend well past the plate rear (plate-thickness-independent)")
if not (oh > wy_physical + 0.3):
    errs.append(f"keystone_opening() height {oh:.2f} no longer exceeds the physical cutout Y-extent {wy_physical:.2f} (the documented conservative-upper-bound gap is expected here)")
if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
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
# "standard"'s keystone_insert() branch is an explicit Task-3 placeholder as of
# #38 (see keystone_insert()'s own comment) -- it is intentionally NOT put
# through the detailed hook/latch mate-check machinery below (that would
# assert on geometry nobody claims is final yet). Only "face" (untouched by
# #38) runs the full mate-check loop; the "standard" channel's own HARD
# assertion (real section/void check, not just render-without-error) lives in
# the dedicated block further down.
FIT=0.2
for STYLE in face; do
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

  # Overlay-mate render: insert dropped into the cutout window. Any
  # non-manifold/CGAL error on the combined solid means the insert collides
  # with (or fails to clear) the frame material this style's cutout leaves behind.
  PLATE=3.0
  cat > "$tmp/mate_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
union() {
    difference() {
        union() {
            translate([-15, -15, -$PLATE]) cube([30, 30, $PLATE]);
            keystone_boss(plate_thickness = $PLATE, style = "$STYLE");
        }
        keystone_cutout(plate_thickness = $PLATE, style = "$STYLE");
    }
    keystone_insert(plate_thickness = $PLATE, style = "$STYLE");
}
EOF
  mate_out="$(run "$tmp/mate_$STYLE.scad")"
  if echo "$mate_out" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "keystone_insert/cutout overlay-mate ($STYLE) failed:"; echo "$mate_out"; exit 1
  fi

  # HARD assertion: a real geometric boolean intersection between the FRAME
  # (remaining solid material after keystone_boss()+keystone_cutout()) and the
  # INSERT, restricted to Z < -0.01 (strictly behind the panel front, excluding
  # the front flange -- which is BY DESIGN coplanar/flush with the panel front
  # at Z=0 and would otherwise register as a false-positive degenerate
  # zero-volume "overlap"). If the insert's tabs clip solid frame material
  # ANYWHERE behind the panel, this intersection is non-empty and OpenSCAD
  # exports a real STL; if they truly clear the frame (just
  # render-without-error, which a union of overlapping solids would also
  # satisfy), OpenSCAD reports an empty top-level object and refuses to
  # export anything (checked via absence of a non-empty STL file).
  cat > "$tmp/overlap_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
intersection() {
    intersection() {
        difference() {
            union() {
                translate([-15, -15, -$PLATE]) cube([30, 30, $PLATE]);
                keystone_boss(plate_thickness = $PLATE, style = "$STYLE");
            }
            keystone_cutout(plate_thickness = $PLATE, style = "$STYLE");
        }
        keystone_insert(plate_thickness = $PLATE, style = "$STYLE");
    }
    translate([-20, -20, -20]) cube([40, 40, 19.99]);
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/overlap_$STYLE.stl" "$tmp/overlap_$STYLE.scad" >/dev/null 2>&1
  if [ -s "$tmp/overlap_$STYLE.stl" ]; then
    # Non-empty doesn't necessarily mean a real clip: two solids that touch
    # with zero gap also produce a non-empty CGAL intersection, but it's a
    # zero-VOLUME degenerate sliver (one axis extent == 0.0), unlike a real
    # clip which has genuine extent on all three axes.
    python3 - "$tmp/overlap_$STYLE.stl" "$STYLE" <<'PY' || exit 1
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12])
        xs.append(x); ys.append(y); zs.append(z)
ex,ey,ez=(max(xs)-min(xs)), (max(ys)-min(ys)), (max(zs)-min(zs))
eps=0.02
if ex > eps and ey > eps and ez > eps:
    sys.stderr.write(f"insert/frame no-clip check ({sys.argv[2]}) FAILED: real volumetric overlap {ex:.3f}x{ey:.3f}x{ez:.3f}mm (insert tab clips solid frame material)\n")
    sys.exit(1)
sys.exit(0)
PY
  fi

  # Insert alone, numeric bbox checks.
  cat > "$tmp/insert_$STYLE.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(plate_thickness = $PLATE, style = "$STYLE");
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/insert_$STYLE.stl" "$tmp/insert_$STYLE.scad" 2>/dev/null

  python3 - "$tmp/insert_$STYLE.stl" "$sow" "$soh" "$fw" "$fh" "$FIT" "$PLATE" "$ledge_z" "$tab_th" "$STYLE" \
      <<'PY' || { echo "insert ($STYLE) geometry check failed"; exit 1; }
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
if not flange_ok:
    errs.append(f"insert ({style}) flange X-span {(max(xs)-min(xs)):.2f} does not exceed window width {ow:.2f}+0.5 (missing front stop)")

# plug tip = the deepest point (through-plug always extends further back than
# any tab feature); its cross-section must be the jack FACE minus fit per
# side -- NOT the (style-varying) opening.
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
if not behind_ok:
    errs.append(f"insert ({style}) min Z {minz:.2f} does not reach behind the plate rear ({-plate-0.2:.2f}) (latch/clip region missing)")

# no-collision invariant: any vertex strictly WITHIN the plate's solid Z-band
# (excludes the front flange at Z>=0 and any feature at/behind the plate rear,
# which are allowed -- by design -- to grip material outside the window) must
# stay within the window's raw X/Y bound, i.e. never punch into solid frame.
# "face": plain-rectangle cutout, raw X/Y bound (ow/2, oh/2) constant through
# the whole plate depth (unchanged).
inband = [(x,y) for x,y,z in verts if -(plate-0.02) < z < -0.02]
noclip_ok = all(abs(x) <= ow/2+0.05 and abs(y) <= oh/2+0.05 for x,y in inband)
if not noclip_ok:
    errs.append("insert tab protrudes into solid frame within the plate band (regression)")

# Tab/plug connectivity: the keystone_insert() solid (flange+plug+both
# retention features) is meant to be ONE physical part, so if any tab doesn't
# actually touch the plug it will render as a disconnected island in the STL
# mesh -- count connected components via union-find over (rounded) shared
# vertices and require exactly one.
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

# Direct per-tab inner-edge coordinate check (#28 review finding): read each
# tab's OWN free face -- a Z-plane that belongs to no other feature -- and
# assert its inner Y-edge sits at +/-plug_h_xy/2 directly from raw
# coordinates. Does not depend on mesh connectivity, so a floating tab is
# caught even when it's still touching something else in the solid.
ZTOL = 0.03
YTOL = 0.05
def inner_edge_at(z_target, want_max):
    pts_y = [y for x,y,z in verts if abs(z - z_target) < ZTOL]
    if not pts_y:
        return None
    return max(pts_y) if want_max else min(pts_y)

tab_checks = [
    ("hook",   -(ledge_z + tab_th), False,  plug_h_xy/2),  # +Y edge: inner = min(Y)
    ("latch",  -(plate + tab_th),   True,  -plug_h_xy/2),  # -Y edge: inner = max(Y)
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

# --- "standard" cutout section check (#38): real channel+slit material, not
# just render-without-error. render-without-CGAL-error is NOT proof of correct
# geometry (a union()/difference() of overlapping solids is still perfectly
# manifold) -- this forces OpenSCAD to compute a REAL cross-section
# (intersection() with a thin slab) at two Z-depths and reads the resulting
# STL's Y-extent / emptiness:
#   - Z=-1.0 (before either slit starts, sl[6]=sl[9]=2.05mm): the cutout's own
#     void must be confined to the plain mouth height -- proves the top/bottom
#     WALL material stands there (nothing already cut).
#   - Z=-5.0 (inside both slits' Z-range): the cutout's void must reach out to
#     the slit's outer (wall) edge -- proves the slit genuinely opens the
#     wall there, not just a wider mouth throughout.
#   - A third check intersects the ASSEMBLED solid (plate+boss-cutout, not
#     just the bare cutout) with a thin slab in the wall band at Z=-1.0 and
#     requires a NON-EMPTY export -- directly proves real wall material is
#     present (the previous two checks only prove the *void* shape; this
#     proves the *solid* the void leaves behind actually exists).
section_ok() {
  local z="$1" name="$2"
  cat > "$tmp/std_section_$name.scad" <<EOF
use <keystone/keystone.scad>;
intersection() {
    keystone_cutout(plate_thickness = 3.0, clearance = 0.25, style = "standard");
    translate([-20, -20, $z - 0.05]) cube([40, 40, 0.1]);
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/std_section_$name.stl" "$tmp/std_section_$name.scad" 2>/dev/null
}

section_ok "-1.0" prewall
section_ok "-5.0" slit

python3 - "$tmp/std_section_prewall.stl" "$tmp/std_section_slit.stl" <<'PY' || { echo "standard cutout section check failed (#38 real channel+slit material)"; exit 1; }
import struct,sys

def read_verts(path):
    d=open(path,'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
    verts=[]
    for i in range(n):
        for v in range(3):
            base=off+i*50+12+v*12
            x,y,z=struct.unpack('<3f',d[base:base+12])
            verts.append((x,y,z))
    return verts

errs=[]
# keystone_slot("standard") fields mirrored here for the expected bounds (see
# keystone.scad keystone_slot() -- single source of truth for the geometry
# itself; these are just the reference numbers to check against).
mouth_h, wall_thickness = 18.4, 1.51
clearance = 0.25
mouth_half = mouth_h/2 + clearance
slit_outer = mouth_h/2 + wall_thickness + clearance

pre_verts = read_verts(sys.argv[1])
if not pre_verts:
    errs.append("pre-slit section (Z=-1.0) is empty -- mouth void missing")
else:
    top_here = max(y for x,y,z in pre_verts)
    if not (top_here < mouth_half + 0.2):
        errs.append(f"pre-slit slice top edge {top_here:.2f} exceeds the plain mouth height {mouth_half:.2f} -- wall already cut before the slit starts (regression)")

slit_verts = read_verts(sys.argv[2])
if not slit_verts:
    errs.append("slit section (Z=-5.0) is empty -- slit void missing")
else:
    top_here = max(y for x,y,z in slit_verts)
    if not (top_here > mouth_half + 0.5):
        errs.append(f"slit slice top edge {top_here:.2f} does not exceed the plain mouth height {mouth_half:.2f} -- slit not modeled (plain-mouth regression)")
    if not (top_here <= slit_outer + 0.2):
        errs.append(f"slit slice top edge {top_here:.2f} exceeds the slit's own outer wall edge {slit_outer:.2f}")

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
PY

# Wall-band section (positive proof): real solid material stands in the top
# wall band (Y just above the mouth) at Z=-1.0, before the slit starts.
cat > "$tmp/std_wall_present.scad" <<EOF
use <keystone/keystone.scad>;
intersection() {
    difference() {
        union() {
            translate([-15, -15, -3]) cube([30, 30, 3]);
            keystone_boss(plate_thickness = 3.0, style = "standard");
        }
        keystone_cutout(plate_thickness = 3.0, style = "standard");
    }
    translate([-20, 9.3, -1.05]) cube([40, 2.0, 0.1]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/std_wall_present.stl" "$tmp/std_wall_present.scad" 2>/dev/null
if [ ! -s "$tmp/std_wall_present.stl" ]; then
  echo "standard channel wall-band section (Z=-1.0) is empty -- top wall material missing (#38)"; exit 1
fi

# --- keystone_boss() geometry check (#38): footprint + reaches the full
# channel depth (well past back_wall_depth, including the print-safety roof
# taper) regardless of plate_thickness.
cat > "$tmp/boss.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_boss(plate_thickness = 3.0, clearance = 0.25, style = "standard");
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/boss.stl" "$tmp/boss.scad" 2>/dev/null

python3 - "$tmp/boss.stl" <<'PY' || { echo "keystone_boss geometry check failed"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12])
        xs.append(x); ys.append(y); zs.append(z)
errs=[]
# Boss front face must sit flush at Z=0 (never poking past the panel front
# into +Z) and must reach well past back_wall_depth (10.05mm, #38) -- the
# print-safety roof taper adds further depth beyond that.
if max(zs) > 0.01:
    errs.append(f"boss front face at {max(zs):.2f}, expected flush with panel front (Z<=0)")
if min(zs) > -10.0:
    errs.append(f"boss min Z {min(zs):.2f} does not reach past back_wall_depth (~-10.05, #38)")
# Footprint must be wider than the raw mouth width (wall margin present).
if (max(xs)-min(xs)) <= 15.3:
    errs.append(f"boss X footprint {(max(xs)-min(xs)):.2f} does not exceed the raw mouth width 15.3 (missing wall margin)")
if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
PY

# --- #38 Task 3: standard insert seated-mate + insertion-motion no-collision ---
# The mate-reference insert (fulcrum + flexing arm, keystone_notch()-derived)
# dropped into the real channel frame must INTERLOCK (both triangular notches
# seated inside their respective slit VOID, plate wall material adjacent) with
# NO solid-body interference, and the insertion sweep must never clip -- this
# is the check the superseded #31 rotate-and-snap motion FAILED (its swinging
# body solid-overlapped the frame mid-sweep). render-without-CGAL-error is NOT
# sufficient (a union of overlapping solids is still manifold); every check
# below forces a REAL boolean intersection and reads the resulting STL bbox.

# real_overlap FILE LABEL: fail iff the intersection STL has genuine extent on
# all three axes (a real volumetric clip). Two solids that merely touch produce
# a zero-VOLUME degenerate sliver (>=1 axis extent ~0), which is allowed.
real_overlap() {
  local f="$1" label="$2"
  [ -s "$f" ] || return 0   # empty export => no intersection => no clip
  python3 - "$f" "$label" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y); zs.append(z)
ex,ey,ez=(max(xs)-min(xs)),(max(ys)-min(ys)),(max(zs)-min(zs))
eps=0.05
if ex>eps and ey>eps and ez>eps:
    sys.stderr.write(f"{sys.argv[2]}: real volumetric insert/frame overlap {ex:.2f}x{ey:.2f}x{ez:.2f}mm\n")
    sys.exit(1)
sys.exit(0)
PY
}

# Seated mate for BOTH flex_side orientations: intersection of the frame
# (plate+boss-cutout) with the seated insert, restricted to Z < -0.01 (behind
# the panel -- the front flange is BY DESIGN flush at Z=0 and excluded), must
# be a zero-volume sliver. The notches live in the slit voids; the plug in the
# mouth void; nothing punches solid frame.
for FS in top bottom; do
  cat > "$tmp/std_seat_$FS.scad" <<EOF
use <keystone/keystone.scad>;
intersection() {
    intersection() {
        difference() {
            union() {
                translate([-15, -15, -3]) cube([30, 30, 3]);
                keystone_boss(plate_thickness = 3.0, style = "standard");
            }
            keystone_cutout(plate_thickness = 3.0, style = "standard");
        }
        keystone_insert(plate_thickness = 3.0, style = "standard", flex_side = "$FS");
    }
    translate([-20, -20, -20]) cube([40, 40, 19.99]);
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/std_seat_$FS.stl" "$tmp/std_seat_$FS.scad" 2>/dev/null
  real_overlap "$tmp/std_seat_$FS.stl" "standard seated mate (flex_side=$FS)" \
    || { echo "standard insert seated-mate clips solid frame (#38 Task 3)"; exit 1; }
done

# Positive interlock: section the SEATED insert with a thin Z-slab at the top
# notch's CATCH face (~6.3mm behind the front face = topnotch_z 7.4 - base/2
# 1.3, where the triangular notch is at ~full protrusion). BOTH notches must
# reach OUT past the mouth's own Y half-height (into their slit bands) --
# proving the notches genuinely engage the slit voids, not float inside the
# mouth. (mouth_h/2 = 9.2; both notch tips should clear it.)
cat > "$tmp/std_notch_engage.scad" <<'EOF'
use <keystone/keystone.scad>;
intersection() {
    keystone_insert(plate_thickness = 3.0, style = "standard", flex_side = "top");
    translate([-20, -20, -6.3 - 0.05]) cube([40, 40, 0.1]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/std_notch_engage.stl" "$tmp/std_notch_engage.scad" 2>/dev/null
python3 - "$tmp/std_notch_engage.stl" <<'PY' || { echo "standard insert notches do not engage the slits (#38 Task 3)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
ys=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); ys.append(y)
if not ys:
    sys.stderr.write("no insert material at the notch depth (-6.3mm) -- notches missing\n"); sys.exit(1)
mouth_half=18.4/2  # keystone_slot() mouth_h/2
if max(ys) <= mouth_half + 0.3:
    sys.stderr.write(f"top (flex-arm) notch tip {max(ys):.2f} does not clear the mouth half-height {mouth_half:.2f} -- not seated in the slit\n"); sys.exit(1)
if min(ys) >= -(mouth_half + 0.3):
    sys.stderr.write(f"bottom (fulcrum) notch tip {min(ys):.2f} does not clear the mouth half-height {-mouth_half:.2f} -- not seated in the slit\n"); sys.exit(1)
sys.exit(0)
PY

# Insertion-motion no-collision (standard): sample the sweep at >=4 stages via
# the assembly's own stage helper. The corrected push-to-click model deflects
# the notches inward while travelling (they clear the wall bridges) and springs
# them into the slits only at seat, so the insert never solid-overlaps the
# frame at ANY stage. This is the direct regression guard against #31's clip.
for ST in 0 0.33 0.66 1.0; do
  name="std_${ST//./_}"
  cat > "$tmp/mot_$name.scad" <<EOF
use <keystone/keystone.scad>;
use <keystone/assembly.scad>;
intersection() {
    difference() {
        union() {
            translate([-15, -15, -3]) cube([30, 30, 3]);
            keystone_boss(plate_thickness = 3.0, style = "standard");
        }
        keystone_cutout(plate_thickness = 3.0, style = "standard");
    }
    _keystone_insert_at_stage(3.0, 0.2, "standard", $ST);
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/mot_$name.stl" "$tmp/mot_$name.scad" 2>/dev/null
  real_overlap "$tmp/mot_$name.stl" "standard insertion motion (stage $ST)" \
    || { echo "standard insertion-motion CLIPS the frame at stage $ST (#38 Task 3 -- the #31 bug)"; exit 1; }
done

# Face motion must still render at every stage (keep-working guard). Face
# retention is plate-thickness front/rear grip and its viz is a straight
# push-fit (pre-#28, out of #38 scope); its wide snap latch is modeled passing
# through the window plane during travel (an accepted simplification, NOT a
# swinging-body collision), so face is NOT held to the strict no-clip bar
# above -- only that the sweep compiles/renders without a CGAL error.
for ST in 0 0.33 0.66 1.0; do
  cat > "$tmp/face_mot.scad" <<EOF
use <keystone/keystone.scad>;
use <keystone/assembly.scad>;
keystone_assembly_motion(plate_thickness = 3.0, style = "face", stage = $ST);
EOF
  fmo="$(run "$tmp/face_mot.scad")"
  if echo "$fmo" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "face insertion-motion failed to render at stage $ST:"; echo "$fmo"; exit 1
  fi
done

echo ok
