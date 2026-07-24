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

# Negative control: keystone_insert(blank=false) must abort -- the RJ45
# pass-through receptacle is explicitly deferred/out-of-scope for the
# flagship insert (#54; see the keystone-insert design spec's Out-of-scope).
cat > "$tmp/insert_blank_false.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_insert(blank = false);
EOF
out="$(run "$tmp/insert_blank_false.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_insert(blank=false) failed to abort (RJ45 pass-through not yet implemented, #54):"; echo "$out"; exit 1
fi

# Negative control: keystone_insert(depth=...) too shallow for the latch root
# must abort -- depth is a Customizer-tunable arg, not a fixed constant, so a
# caller who shrinks it too far must be caught rather than silently building
# broken (root-less) geometry.
cat > "$tmp/insert_depth_too_shallow.scad" <<'EOF'
use <keystone/keystone.scad>;
keystone_insert(depth = 10);
EOF
out="$(run "$tmp/insert_depth_too_shallow.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keystone_insert(depth=10) failed to abort (too shallow for the latch root, #54):"; echo "$out"; exit 1
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

# --- #54: flagship keystone_insert() geometry (caliper-faithful, style-
# independent -- supersedes the old guessed per-style mate-check above). A
# real STL-bbox check, not just render-without-error: front face cross-
# section (the caliper face, less `fit` per side), overall depth, a latch
# feature reaching above the body's own top surface, and a retention lug
# reaching below the body's own bottom surface.
FIT=0.2
cat > "$tmp/insert.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(fit = $FIT);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/insert.stl" "$tmp/insert.scad" 2>/dev/null

cat > "$tmp/insert_dims.scad" <<'EOF'
use <keystone/keystone.scad>;
f = keystone_insert_face();
echo(f[0]); echo(f[1]); echo(keystone_insert_depth());
EOF
insert_dims_out="$(run "$tmp/insert_dims.scad")"
fw="$(echo "$insert_dims_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
fh="$(echo "$insert_dims_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"
depth="$(echo "$insert_dims_out" | grep -m3 'ECHO:' | tail -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)"

python3 - "$tmp/insert.stl" "$FIT" "$fw" "$fh" "$depth" <<'PY' || { echo "keystone_insert() geometry check failed"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
verts=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12])
        verts.append((x,y,z))
fit=float(sys.argv[2])
xs=[x for x,y,z in verts]; ys=[y for x,y,z in verts]; zs=[z for x,y,z in verts]
errs=[]

fw, fh, depth = float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5])   # live from keystone_insert_face()/keystone_insert_depth()
body_w, body_h = fw - 2*fit, fh - 2*fit
top = body_h / 2

if not (max(zs) <= 0.05):
    errs.append(f"insert front face at {max(zs):.2f}, expected flush at Z<=0")
if not (abs(min(zs) - (-depth)) < 0.5):
    errs.append(f"insert min Z {min(zs):.2f} != -depth {-depth:.2f}")

front_band = [(x,y) for x,y,z in verts if z > -0.05]
if not front_band:
    errs.append("no vertices found at the front face (Z~0) -- body missing")
else:
    fx = max(x for x,y in front_band) - min(x for x,y in front_band)
    fy = max(y for x,y in front_band) - min(y for x,y in front_band)
    if not (abs(fx - body_w) < 0.1 and abs(fy - body_h) < 0.1):
        errs.append(f"front face cross-section {fx:.2f}x{fy:.2f} != face-derived {body_w:.2f}x{body_h:.2f}")

if not (max(ys) > top + 0.5):
    errs.append(f"insert max Y {max(ys):.2f} does not exceed body top {top:.2f} -- latch/hook missing")
if not (min(ys) < -top - 0.5):
    errs.append(f"insert min Y {min(ys):.2f} does not exceed body bottom {-top:.2f} -- retention lug missing")

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
PY

# --- #60: guide ribs / lug are PLAIN RECTANGLES, not tapered ramps/wedges
# (Task 2 dropped the print-safety lead-in chamfers -- physical caliper
# showed no taper). A render-without-error smoke test can't distinguish a
# plain block from a wedge (both are manifold); this samples actual
# geometry:
#   - lug: the -Y protrusion sampled near BOTH ends of the lug's own Z-span
#     must be the SAME (== lug_prot) -- the old ramp had ~0 protrusion at
#     its flush (front) end, growing to lug_prot only at the rear.
#   - guide rib: no vertex may sit past the body's own side wall at a Z
#     deeper than the rib's own deep edge -- the old chamfer ramp used to
#     add exactly such material there.
cat > "$tmp/insert_feature_dims.scad" <<'EOF'
use <keystone/keystone.scad>;
rib = keystone_insert_guide_rib();
lug = keystone_insert_lug();
echo(rib[2]); echo(rib[3]);
echo(lug[1]); echo(lug[2]); echo(lug[3]);
EOF
feat_out="$(run "$tmp/insert_feature_dims.scad")"
nth_echo() { echo "$1" | grep -m"$2" 'ECHO:' | tail -1 | grep -oE '[-0-9]+\.?[0-9]*' | head -1; }
rib_thick="$(nth_echo "$feat_out" 1)"; rib_z0="$(nth_echo "$feat_out" 2)"
lug_prot="$(nth_echo "$feat_out" 3)"; lug_zlen="$(nth_echo "$feat_out" 4)"; lug_z0="$(nth_echo "$feat_out" 5)"

python3 - "$tmp/insert.stl" "$FIT" "$fw" "$fh" "$rib_thick" "$rib_z0" "$lug_prot" "$lug_zlen" "$lug_z0" <<'PY' || { echo "keystone_insert() plain-rectangle rib/lug geometry check failed (#60)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
verts=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12])
        verts.append((x,y,z))

fit=float(sys.argv[2]); fw=float(sys.argv[3]); fh=float(sys.argv[4])
rib_thick, rib_z0 = float(sys.argv[5]), float(sys.argv[6])
lug_prot, lug_zlen, lug_z0 = float(sys.argv[7]), float(sys.argv[8]), float(sys.argv[9])
body_w, body_h = fw - 2*fit, fh - 2*fit
bot = -body_h / 2
tol = 0.15
errs = []

def min_y_near_z(z0, zband=0.15):
    ys = [y for x, y, z in verts if abs(z - z0) < zband]
    return min(ys) if ys else None

z_lug_front = -lug_z0
z_lug_rear  = -(lug_z0 + lug_zlen)
y_front = min_y_near_z(z_lug_front)
y_rear  = min_y_near_z(z_lug_rear)
if y_front is None or y_rear is None:
    errs.append("lug: could not find vertices near its front/rear Z bands")
else:
    prot_front = bot - y_front
    prot_rear  = bot - y_rear
    if not (abs(prot_front - lug_prot) < tol):
        errs.append(f"lug front-band (z~{z_lug_front:.2f}) protrusion {prot_front:.2f} != lug_prot {lug_prot:.2f} -- still tapered/ramped, not a plain block")
    if not (abs(prot_rear - lug_prot) < tol):
        errs.append(f"lug rear-band (z~{z_lug_rear:.2f}) protrusion {prot_rear:.2f} != lug_prot {lug_prot:.2f}")

rib_zone_x = body_w / 2 + 0.05  # just past the body's own side wall -- ribs-only territory
z_rib_deep = -(rib_z0 + rib_thick)
beyond = [(x, y, z) for x, y, z in verts if abs(x) > rib_zone_x and z < z_rib_deep - tol]
if beyond:
    errs.append(f"rib: {len(beyond)} vertex/vertices with |x|>{rib_zone_x:.2f} at Z<{z_rib_deep:.2f} -- old chamfer ramp not removed")

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
sys.exit(1 if errs else 0)
PY

# guides=false must omit the guide ribs -- X-extent shrinks relative to the
# guides=true default.
cat > "$tmp/insert_guides_off.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(fit = $FIT, guides = false);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/insert_guides_off.stl" "$tmp/insert_guides_off.scad" 2>/dev/null

python3 - "$tmp/insert.stl" "$tmp/insert_guides_off.stl" <<'PY' || { echo "keystone_insert(guides=false) geometry check failed"; exit 1; }
import struct,sys
def read_xspan(path):
    d=open(path,'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
    xs=[]
    for i in range(n):
        for v in range(3):
            base=off+i*50+12+v*12
            x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x)
    return max(xs)-min(xs)
with_ribs = read_xspan(sys.argv[1])
without_ribs = read_xspan(sys.argv[2])
if not (with_ribs > without_ribs + 0.3):
    sys.stderr.write(f"guides=false X-span {without_ribs:.2f} not smaller than guides=true {with_ribs:.2f} -- ribs not toggled\n")
    sys.exit(1)
sys.exit(0)
PY

# Connectivity: the whole insert (body + ribs + lug + latch root/beam/hook)
# must be ONE physical solid.
python3 - "$tmp/insert.stl" <<'PY' || { echo "keystone_insert() connectivity check failed"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
parent={}
def find(x):
    while parent[x]!=x: parent[x]=parent[parent[x]]; x=parent[x]
    return x
def uni(a,b):
    ra,rb=find(a),find(b)
    if ra!=rb: parent[ra]=rb
for i in range(n):
    tri=[]
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); tri.append((round(x,2),round(y,2),round(z,2)))
    for vtx in tri: parent.setdefault(vtx,vtx)
    a,b,c=tri; uni(a,b); uni(b,c)
roots=set(find(v) for v in parent)
if len(roots)!=1:
    sys.stderr.write(f"keystone_insert() is NOT one connected solid: {len(roots)} disjoint piece(s)\n"); sys.exit(1)
sys.exit(0)
PY

echo ok
