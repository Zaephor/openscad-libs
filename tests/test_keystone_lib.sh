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

# Negative control: keystone_latch("face") must abort -- "face" has no lip mechanism (#31).
cat > "$tmp/latch_no_face.scad" <<'EOF'
use <keystone/keystone.scad>;
l = keystone_latch("face");
EOF
out="$(run "$tmp/latch_no_face.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_latch(\"face\") failed to abort (no lip mechanism for face):"; echo "$out"; exit 1
fi

# Negative control: keystone_boss_footprint("face") must abort -- no boss for "face" (#31).
cat > "$tmp/boss_footprint_no_face.scad" <<'EOF'
use <keystone/keystone.scad>;
bf = keystone_boss_footprint("face");
EOF
out="$(run "$tmp/boss_footprint_no_face.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_boss_footprint(\"face\") failed to abort (no boss for face):"; echo "$out"; exit 1
fi

# Negative control: keystone_boss("bogus") must abort -- an ACTUALLY unknown
# style, distinct from "face" (a legitimate no-op, not an error). Review
# finding (#31): keystone_boss() previously had no `else` arm, so a typo'd
# style silently produced zero geometry instead of erroring, unlike every
# other style-keyed accessor in this file.
cat > "$tmp/boss_unknown_style.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_boss(style = "bogus");
EOF
out="$(run "$tmp/boss_unknown_style.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_boss(\"bogus\") failed to abort with unknown style:"; echo "$out"; exit 1
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

# echo_val: Nth (1-based) ECHO: value from OpenSCAD output, sign preserved --
# the plain digit-grepping pattern used above can't handle keystone_latch()'s
# negative Z breakpoints (hook_z/pocket_z/latch_z), needed below (#31 Task 3).
echo_val() { echo "$1" | grep 'ECHO:' | sed -n "${2}p" | sed -E 's/^ECHO:[[:space:]]*//'; }

# keystone_latch("lip") breakpoints (#31 Task 3): fetched once, style-agnostic
# (only "lip" has a latch mechanism at all) -- feeds the "lip" mating-tab
# checks in the per-style loop below, single source of truth mirrored from
# keystone_insert()'s own "lip" branch derivation.
cat > "$tmp/latch_lip.scad" <<'EOF'
use <keystone/keystone.scad>;
l = keystone_latch("lip");
echo(l[0]); echo(l[1]); echo(l[2]); echo(l[3]); echo(l[4]); echo(l[5]); echo(l[6]);
echo(_keystone_plateau_depth());
EOF
latch_out="$(run "$tmp/latch_lip.scad")"
# Names mirror keystone_latch()'s own field doc (l[0]..l[6]) 1:1 -- NOT
# offset/reindexed, to avoid an off-by-one between this fetch and the scad
# source of truth. L_PLATEAU_DEPTH is fetched from the scad source too (not
# hand-copied) so a future _keystone_plateau_depth() change can't silently
# drift from this test's own rear_overcut/plateau-zone math.
L_WIDTH="$(echo_val "$latch_out" 1)";   L_FRONT_H="$(echo_val "$latch_out" 2)"
L_HOOK_Z="$(echo_val "$latch_out" 3)";  L_HOOK_H="$(echo_val "$latch_out" 4)"
L_POCKET_Z="$(echo_val "$latch_out" 5)"; L_LATCH_Z="$(echo_val "$latch_out" 6)"
L_LATCH_H="$(echo_val "$latch_out" 7)"; L_PLATEAU_DEPTH="$(echo_val "$latch_out" 8)"

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
  # Frame includes keystone_boss() (no-op for "face", #31's real consumer
  # pattern for "lip" -- see keystone_cutout()'s module comment) so the "lip"
  # smoke check actually exercises the boss-hosted mechanism, not just a bare
  # thin plate that the plate-thickness-independent "lip" cutout mostly
  # overshoots into open air.
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

  # HARD assertion (#31 Task 3): a real geometric boolean intersection
  # between the FRAME (remaining solid material after keystone_boss()+
  # keystone_cutout()) and the INSERT, restricted to Z < -0.01 (strictly
  # behind the panel front, excluding the front flange -- which is BY DESIGN
  # coplanar/flush with the panel front at Z=0 and would otherwise register
  # as a false-positive degenerate zero-volume "overlap"). If the insert's
  # tabs clip solid frame material ANYWHERE behind the panel, this
  # intersection is non-empty and OpenSCAD exports a real STL; if they truly
  # clear the frame (just render-without-error, which a union of overlapping
  # solids would also satisfy -- that's the whole reason this check exists
  # instead of trusting $mate_out above), OpenSCAD reports "Current top
  # level object is empty" and refuses to export anything (checked via
  # absence of a non-empty STL file, not stderr text, since that message
  # isn't guaranteed stable across OpenSCAD versions).
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
    # with zero gap (both styles do this by design -- "face"'s hook/latch
    # tabs meet the raw window edge exactly, no fit inset on that side) also
    # produce a non-empty CGAL intersection, but it's a zero-VOLUME
    # degenerate sliver (confirmed empirically: one axis extent == 0.0),
    # unlike a real clip which has genuine extent on all three axes. Parse
    # the STL bbox and only fail on an actual 3D volume.
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

  # Single STL parse feeds all four checks below (bbox/plug/noclip, mesh
  # connectivity, and the direct per-tab edge-coordinate check) -- avoids
  # re-reading/re-parsing the same binary STL three times (test-only nit).
  python3 - "$tmp/insert_$STYLE.stl" "$sow" "$soh" "$fw" "$fh" "$FIT" "$PLATE" "$ledge_z" "$tab_th" "$STYLE" \
      "$L_WIDTH" "$L_FRONT_H" "$L_HOOK_Z" "$L_HOOK_H" "$L_POCKET_Z" "$L_LATCH_Z" "$L_LATCH_H" "$L_PLATEAU_DEPTH" \
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
# keystone_latch("lip") breakpoints (#31 Task 3) -- field names match
# keystone_latch()'s own doc 1:1 (width,front_h,hook_z,hook_h,pocket_z,
# latch_z,latch_h). Always present (style-agnostic fetch), only used when
# style == "lip".
lw,lfh,lhz,lhh,lpz,llz,llh,lplateau = map(float, sys.argv[11:19])
tol=0.1
xs=[x for x,y,z in verts]; ys=[y for x,y,z in verts]; zs=[z for x,y,z in verts]
errs=[]

# flange: overall X span exceeds the window width (front stop present)
flange_ok = (max(xs)-min(xs)) > ow + 0.5
if not flange_ok:
    errs.append(f"insert ({style}) flange X-span {(max(xs)-min(xs)):.2f} does not exceed window width {ow:.2f}+0.5 (missing front stop)")

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
if not behind_ok:
    errs.append(f"insert ({style}) min Z {minz:.2f} does not reach behind the plate rear ({-plate-0.2:.2f}) (latch/clip region missing)")

# no-collision invariant: any vertex strictly WITHIN the plate's solid Z-band
# (excludes the front flange at Z>=0 and any feature at/behind the plate rear,
# which are allowed -- by design -- to grip material outside the window) must
# stay within the window's raw X/Y bound, i.e. never punch into solid frame.
# "face": plain-rectangle cutout, raw X/Y bound (ow/2, oh/2) constant through
# the whole plate depth (unchanged).
if style == "face":
    inband = [(x,y) for x,y,z in verts if -(plate-0.02) < z < -0.02]
    noclip_ok = all(abs(x) <= ow/2+0.05 and abs(y) <= oh/2+0.05 for x,y in inband)
    if not noclip_ok:
        errs.append("insert tab protrudes into solid frame within the plate band (regression)")

# "lip" (#31 Task 3): the real cutout is Z-varying (front flat -> hook ramp
# -> hook pocket -> latch ramp -> latch plateau, see keystone_cutout()), so
# the flat ow/2,oh/2 bound above would false-fail a CORRECT lip insert whose
# hook/latch legitimately reach inward past it. Mirror keystone_cutout()'s
# own per-zone Y bound (raw, pre-clearance -- this module doesn't know the
# cutout's own `clearance` param, which only ever grows the cavity further,
# so checking the raw bound is already conservative) and confirm every
# vertex fits inside it at its own Z. This is a real per-vertex section
# check, not a sampled slice -- the primary "geometric section/no-clip"
# proof for the "lip" style (the full-3D empty-intersection check above is
# the other, style-shared half of that proof).
if style == "lip":
    raw_top_hook  = lhh - lfh/2
    raw_bot_front = -lfh/2
    raw_bot_latch = raw_top_hook - llh
    rear_overcut  = llz - lplateau - 1  # mirrors keystone_cutout()'s own rear_overcut (_keystone_plateau_depth() fetched from source + 1mm overcut)
    def lip_bound_at_z(z):
        if z > -0.02:
            return None  # front flange territory (Z>=0, outside the panel -- a bezel resting on the front face, not constrained by the cavity bound at all) -- not checked here
        if z >= lhz:      # hook ramp: Z 0 -> hook_z, top edge interpolates front->hook
            t = z / lhz if lhz != 0 else 0.0
            return (raw_bot_front, (lfh/2) + t*(raw_top_hook - lfh/2))
        if z >= lpz:      # hook pocket flat
            return (raw_bot_front, raw_top_hook)
        if z >= llz:      # latch ramp: bottom edge interpolates hook->latch
            t = (z - lpz) / (llz - lpz)
            return (raw_bot_front + t*(raw_bot_latch - raw_bot_front), raw_top_hook)
        if z >= rear_overcut:  # latch plateau + rear overcut, flat
            return (raw_bot_latch, raw_top_hook)
        return None  # past the modeled cutout depth entirely -- not checked here
    margin = 0.03  # float slop only; the real safety margin is `fit`, baked into the geometry itself
    clip_pts = []
    for x,y,z in verts:
        b = lip_bound_at_z(z)
        if b is None:
            continue
        bot,top = b
        if not (bot - margin <= y <= top + margin):
            clip_pts.append((round(x,2), round(y,2), round(z,2)))
    if clip_pts:
        errs.append(f"insert (lip) has {len(clip_pts)} vertex/vertices outside the real lip cavity bound (frame clip), e.g. {clip_pts[0]}")

    # Interlock proof: the hook tab's outer Y edge must exceed the FRONT
    # window's half-height (lfh/2) -- i.e. the tab is wider than the narrow
    # front opening, so it cannot be withdrawn straight out through the
    # front without clipping the lip standing between Z=0 and hook_z. This
    # is what makes it a genuine hook (vs. just floating in a wide pocket).
    hook_outer_y = raw_top_hook - fit
    if not (hook_outer_y > lfh/2 + margin):
        errs.append(f"insert (lip) hook tab outer Y {hook_outer_y:.2f} does not exceed the front window half-height {lfh/2:.2f} -- not a real hook (would pass straight through the front)")

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
else:  # "lip" (#31 Task 3): keystone_latch()-derived hook/latch tabs. Each
    # tab's own free face is one of its flat zone's own Z boundaries -- both
    # hook_z/-4.32 (hook tab: spans pocket_z..hook_z) and latch_z/-6.97
    # (latch tab: spans latch_z-plateau_depth..latch_z) belong to no other
    # feature (flange only occupies Z in [0,1.2]; plug corners are only at
    # Z=0 and Z=-plug_h), confirmed empirically against the actual STL.
    tab_checks = [
        ("hook",  lhz, False,  plug_h_xy/2),  # +Y edge: inner = min(Y)
        ("latch", llz, True,  -plug_h_xy/2),  # -Y edge: inner = max(Y)
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

# --- "lip" cutout section check (#31): real lip material, not a plain
# rectangle. The HARD assertion for this task -- render-without-CGAL-error is
# NOT proof of correct geometry (a union()/difference() of overlapping solids
# is still perfectly manifold), so this forces OpenSCAD to compute a REAL
# cross-section (intersection() with a thin slab, at Z-slices inside the hook
# ramp and the latch ramp) and reads the resulting STL's Y-extent -- the
# cavity's edge must be PARTWAY through its transition there (real material
# fills the gap to the max window; the old plain-rectangle cutout would show
# the FULL max window at every Z, i.e. no material, only open air, at these
# same slices). Raw vertex-scanning at an arbitrary interior Z would find
# nothing (hull()'s ramp faces are flat quads between the two end slices, no
# vertices in between) -- intersection() makes OpenSCAD compute the section
# for real.
section_ok() {
  # $1 = Z center, $2 = python check name (unused, just for the temp filename)
  local z="$1" name="$2"
  cat > "$tmp/lip_section_$name.scad" <<EOF
use <keystone/keystone.scad>;
intersection() {
    keystone_cutout(plate_thickness = 3.0, clearance = 0.25, style = "lip");
    translate([-20, -20, $z - 0.05]) cube([40, 40, 0.1]);
}
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/lip_section_$name.stl" "$tmp/lip_section_$name.scad" 2>/dev/null
}

section_ok "-2.0" hook
section_ok "-6.17" latch

python3 - "$tmp/lip_section_hook.stl" "$tmp/lip_section_latch.stl" <<'PY' || { echo "lip cutout section check failed (#31 real lip material)"; exit 1; }
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

# keystone_latch("lip") breakpoints, mirrored here for the expected bounds
# (see keystone.scad keystone_latch() -- single source of truth for the
# geometry itself; these are just the reference numbers to check against).
front_h, hook_h, latch_h = 17.43, 21.30, 22.90
clearance = 0.25
front_top = front_h/2 + clearance
max_top   = (hook_h - front_h/2) + clearance          # top edge's final value (unchanged after the hook ramp)
front_bot = -(front_h/2 + clearance)
max_bot   = ((hook_h - front_h/2) - latch_h) - clearance  # bottom edge's final value (after the latch ramp)

# Hook ramp midpoint (Z=-2.0, between Z=0 and hook_z=-4.32): the TOP edge
# must be PARTWAY between front_top and max_top -- neither still at the
# front value nor already at the max (a plain rectangle sized at the max
# window would show max_top here; a rectangle sized at the front window
# would show front_top; only a real ramp shows something strictly between).
hook_verts = read_verts(sys.argv[1])
if not hook_verts:
    errs.append("hook-ramp section (Z=-2.0) is empty -- geometry missing")
else:
    top_here = max(y for x,y,z in hook_verts)
    if not (front_top + 0.3 < top_here < max_top - 0.3):
        errs.append(f"hook-ramp slice top edge {top_here:.2f} not strictly between front ({front_top:.2f}) and max ({max_top:.2f}) -- ramp not modeled (plain-rectangle regression)")

# Latch ramp midpoint (Z=-6.17, between pocket_z=-5.37 and latch_z=-6.97):
# the BOTTOM edge must be PARTWAY between front_bot and max_bot, same logic.
latch_verts = read_verts(sys.argv[2])
if not latch_verts:
    errs.append("latch-ramp section (Z=-6.17) is empty -- geometry missing")
else:
    bot_here = min(y for x,y,z in latch_verts)
    if not (max_bot + 0.3 < bot_here < front_bot - 0.3):
        errs.append(f"latch-ramp slice bottom edge {bot_here:.2f} not strictly between max ({max_bot:.2f}) and front ({front_bot:.2f}) -- ramp not modeled (plain-rectangle regression)")

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
PY

# --- keystone_boss() geometry check (#31): footprint + reaches the full
# mechanism depth regardless of plate_thickness.
cat > "$tmp/boss.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_boss(plate_thickness = 3.0, clearance = 0.25, style = "lip");
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
# Boss must reach the full ~8.27mm mechanism depth (independent of the
# plate_thickness=3.0 passed above) and its front face must sit flush at Z=0
# (never poking past the panel front into +Z).
if max(zs) > 0.01:
    errs.append(f"boss front face at {max(zs):.2f}, expected flush with panel front (Z<=0)")
if min(zs) > -8.0:
    errs.append(f"boss min Z {min(zs):.2f} does not reach the mechanism's full depth (~-8.27, plate_thickness-independent)")
# Footprint must be wider than the raw cutout envelope (wall margin present).
if (max(xs)-min(xs)) <= 14.90:
    errs.append(f"boss X footprint {(max(xs)-min(xs)):.2f} does not exceed the raw cutout width 14.90 (missing wall margin)")
if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
PY

echo ok
