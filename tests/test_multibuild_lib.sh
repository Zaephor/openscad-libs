#!/usr/bin/env bash
# Verifies the multibuild library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/multibuild/tests/multibuild_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "multibuild_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: unknown type must assert.
cat > "$tmp/bad_type.scad" <<'EOF'
use <multibuild/multibuild.scad>;
x = multibuild_hole_dia("bogus");
EOF
out="$(run "$tmp/bad_type.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type:"; echo "$out"; exit 1
fi

# Placeholder: snap type bbox must match tip-flare diameter × engagement length
# with top face at Z=0, cylinder extending in -Z direction.
cat > "$tmp/placeholder_snap.scad" <<'EOF'
use <multibuild/multibuild.scad>;
multibuild_mount_placeholder("snap");
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/placeholder_snap.stl" "$tmp/placeholder_snap.scad" 2>/dev/null

# Derive snap dimensions dynamically from accessors
cat > "$tmp/get_snap_dims.scad" <<'EOF'
use <multibuild/multibuild.scad>;
echo(multibuild_mount_tip_flare("snap"));
echo(multibuild_mount_engagement("snap"));
EOF
dims_out="$(run "$tmp/get_snap_dims.scad")"
snap_flare="$(echo "$dims_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.[0-9]+')"
snap_engage="$(echo "$dims_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.[0-9]+')"

python3 - "$tmp/placeholder_snap.stl" "$snap_flare" "$snap_engage" <<'PY' || { echo "snap placeholder bbox incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y); zs.append(z)
xspan=max(xs)-min(xs); yspan=max(ys)-min(ys); zspan=max(zs)-min(zs)
zmin=min(zs); zmax=max(zs)
# Expected dimensions: diameter = 2*tip_flare, height = engagement
expected_d=2*float(sys.argv[2]); expected_h=float(sys.argv[3])
# Tolerance for $fn=48 faceting: ~2%
tol=0.1
sys.exit(0 if abs(xspan-expected_d)<tol and abs(yspan-expected_d)<tol and abs(zspan-expected_h)<tol and abs(zmin-(-expected_h))<tol and abs(zmax)<tol else 1)
PY

# Mount (positive connector feature): snap type must be a valid manifold
# whose bbox diameter/height match the placeholder envelope (shaft + arms
# span the same tip-flare x engagement envelope), and must NOT be a
# degenerate/near-zero-volume shape (a botched hull() can "succeed" while
# producing a sliver).
cat > "$tmp/mount_snap.scad" <<'EOF'
use <multibuild/multibuild.scad>;
multibuild_mount("snap");
EOF
mount_out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/mount_snap.stl" "$tmp/mount_snap.scad" 2>&1)"
if echo "$mount_out" | grep -qiE 'not a valid 2-manifold|ERROR:'; then
  echo "multibuild_mount(\"snap\") did not render a clean manifold:"; echo "$mount_out"; exit 1
fi

python3 - "$tmp/mount_snap.stl" "$snap_flare" "$snap_engage" <<'PY' || { echo "snap mount bbox/manifold incorrect"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
vol=0.0
for i in range(n):
    tri=[]
    for v in range(3):
        base=off+i*50+12+v*12
        p=struct.unpack('<3f',d[base:base+12]); tri.append(p)
        xs.append(p[0]); ys.append(p[1]); zs.append(p[2])
    (x1,y1,z1),(x2,y2,z2),(x3,y3,z3)=tri
    vol += (x1*(y2*z3-y3*z2) - y1*(x2*z3-x3*z2) + z1*(x2*y3-x3*y2))/6.0
xspan=max(xs)-min(xs); yspan=max(ys)-min(ys); zspan=max(zs)-min(zs)
zmin=min(zs); zmax=max(zs)
expected_d=2*float(sys.argv[2]); expected_h=float(sys.argv[3])
tol=0.1
# a degenerate/collapsed hull would have near-zero volume and/or triangle count
sane = n > 100 and vol > 50
ok = (abs(xspan-expected_d)<tol and abs(yspan-expected_d)<tol and abs(zspan-expected_h)<tol
      and abs(zmin-(-expected_h))<tol and abs(zmax)<tol and sane)
sys.exit(0 if ok else 1)
PY

# Fit-check: for every known mount type, the positive mount's radial
# envelope (STL bbox X/Y extent) must not exceed the negative hole's radial
# envelope (STL bbox X/Y extent) -- i.e. the snap can physically pass
# through the hole. This is a RADIAL check only: multibuild_mount is a
# through-hole snap whose engagement length is deliberately taller than
# multibuild_hole_depth (the tip pokes past the far face to flare and
# retain -- see multibuild.scad comments), so Z/height containment is NOT
# asserted here; asserting it would incorrectly fail on working geometry.
cat > "$tmp/get_types.scad" <<'EOF'
use <multibuild/multibuild.scad>;
for (t = multibuild_known_mounts()) echo(t);
EOF
types_out="$(run "$tmp/get_types.scad")"
mapfile -t fit_types < <(echo "$types_out" | grep -oE 'ECHO: "[^"]*"' | sed -E 's/ECHO: "(.*)"/\1/')
if [ "${#fit_types[@]}" -eq 0 ]; then
  echo "fit-check: failed to enumerate multibuild_known_mounts()"; exit 1
fi

for t in "${fit_types[@]}"; do
  cat > "$tmp/fit_mount_$t.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_mount("$t");
EOF
  cat > "$tmp/fit_hole_$t.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_hole("$t");
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/fit_mount_$t.stl" "$tmp/fit_mount_$t.scad" 2>/dev/null
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/fit_hole_$t.stl" "$tmp/fit_hole_$t.scad" 2>/dev/null

  python3 - "$tmp/fit_mount_$t.stl" "$tmp/fit_hole_$t.stl" "$t" <<'PY' || { echo "radial clearance failed for mount type '$t'"; exit 1; }
import struct, sys

def bbox_xy(path):
    d = open(path, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]
    off = 84
    xs = []; ys = []
    for i in range(n):
        for v in range(3):
            base = off + i * 50 + 12 + v * 12
            x, y, z = struct.unpack('<3f', d[base:base + 12])
            xs.append(x); ys.append(y)
    return max(xs) - min(xs), max(ys) - min(ys)

mount_path, hole_path, t = sys.argv[1], sys.argv[2], sys.argv[3]
mx, my = bbox_xy(mount_path)
hx, hy = bbox_xy(hole_path)
# Radial fit only (X/Y extent): the mount must be able to pass through the
# hole's diameter. Deliberately NOT checking Z/height -- the through-hole
# snap's engagement length exceeds the hole depth by design.
tol = 1e-6
ok = mx <= hx + tol and my <= hy + tol
if not ok:
    sys.stderr.write(
        "type=%s mount x/y=%.4f/%.4f hole x/y=%.4f/%.4f\n" % (t, mx, my, hx, hy))
sys.exit(0 if ok else 1)
PY
done

# --- Fix-Point (Multipoint) accessory-side negative: slide-on fit (#32) ---
# SLIDE AXIS = +X (in-plane, lateral). The Fix-Point engages by sliding along
# +X into the dovetail pocket, NOT by the snap's -Z pass-through -- so the
# radial X/Y-bbox check used for "snap" above does NOT transfer here. Instead:
# difference a project-like plate with the accessory-side negative
# multibuild_hole(fp), then confirm the positive Fix-Point placeholder NESTS in
# the resulting pocket (its intersection with the remaining plate material is
# ~zero volume) and that the pocket is at least as long along +X as the
# placeholder (room to slide in).
# HONESTY (mirrors the snap fit-check's radial-only disclaimer above): this
# proves clearance ALONG THE +X SLIDE only. It does NOT prove dovetail
# retention/engagement (that the seated part resists -Z/+Z pull-out) -- a
# bbox/volume test cannot establish that.
for fp in multipoint multipoint_rail; do
  cat > "$tmp/fp_fit_$fp.scad" <<EOF
use <multibuild/multibuild.scad>;
intersection() {
  difference() {
    translate([0, 0, -4]) cube([80, 50, 8], center = true); // plate top face at Z=0
    multibuild_hole("$fp");
  }
  multibuild_fixpoint_placeholder("$fp");
}
EOF
  cat > "$tmp/fp_place_$fp.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_fixpoint_placeholder("$fp");
EOF
  cat > "$tmp/fp_hole_$fp.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_hole("$fp");
EOF
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/fp_fit_$fp.stl"   "$tmp/fp_fit_$fp.scad"   2>/dev/null || true
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/fp_place_$fp.stl" "$tmp/fp_place_$fp.scad" 2>/dev/null
  "$root/scripts/openscad.sh" --export-format binstl -o "$tmp/fp_hole_$fp.stl"  "$tmp/fp_hole_$fp.scad"  2>/dev/null

  python3 - "$tmp/fp_fit_$fp.stl" "$tmp/fp_place_$fp.stl" "$tmp/fp_hole_$fp.stl" "$fp" <<'PY' || { echo "Fix-Point slide-fit failed for '$fp'"; exit 1; }
import struct, sys, os

def read(path):
    if not os.path.exists(path) or os.path.getsize(path) < 84:
        return 0, 0.0, (0, 0, 0, 0, 0, 0)
    d = open(path, 'rb').read(); n = struct.unpack('<I', d[80:84])[0]; off = 84
    xs = []; ys = []; zs = []; vol = 0.0
    for i in range(n):
        tri = []
        for v in range(3):
            base = off + i * 50 + 12 + v * 12
            p = struct.unpack('<3f', d[base:base + 12]); tri.append(p)
            xs.append(p[0]); ys.append(p[1]); zs.append(p[2])
        (x1, y1, z1), (x2, y2, z2), (x3, y3, z3) = tri
        vol += (x1 * (y2 * z3 - y3 * z2) - y1 * (x2 * z3 - x3 * z2) + z1 * (x2 * y3 - x3 * y2)) / 6.0
    if not xs:
        return n, 0.0, (0, 0, 0, 0, 0, 0)
    return n, abs(vol), (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))

fit, place, hole, fp = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
nf, vf, _ = read(fit)
npl, vpl, bpl = read(place)
nh, vh, bh = read(hole)
errs = []
# guard against a trivially-empty pass: the placeholder must be a real solid
if not (npl >= 12 and vpl > 50):
    errs.append("placeholder degenerate: facets=%d vol=%.3f" % (npl, vpl))
# containment: the placeholder nests inside the pocket, so its intersection with
# the remaining plate material is ~zero (a real interference would be many mm^3)
if vf > 1.0:
    errs.append("placeholder interferes with plate: intersection vol=%.3f" % vf)
# slide clearance along +X: the pocket must be at least as long as the placeholder
place_x = bpl[1] - bpl[0]; hole_x = bh[1] - bh[0]
if hole_x + 1e-6 < place_x:
    errs.append("no slide room: pocket X=%.3f < placeholder X=%.3f" % (hole_x, place_x))
if errs:
    sys.stderr.write("type=%s\n" % fp + "\n".join(errs) + "\n"); sys.exit(1)
sys.exit(0)
PY
done

# --- MultiBin container: envelope + cavity bbox / mutual alignment (#32) ---
# Render the external envelope (multibin_placeholder) and the internal cavity
# negative (multibin_cavity_cutout) for a seeded Simple Walls size, then verify
# the cavity sits measurably INSIDE the envelope, centered on both XY axes, with
# footprint - cavity == 2*wall. Catches two placeholders that each pass their own
# bbox but are mutually misaligned.
mb_size="[2,2,0.5]"

cat > "$tmp/mb_place.scad" <<EOF
use <multibuild/multibuild.scad>;
multibin_placeholder($mb_size);
EOF
cat > "$tmp/mb_cav.scad" <<EOF
use <multibuild/multibuild.scad>;
multibin_cavity_cutout($mb_size);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/mb_place.stl" "$tmp/mb_place.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/mb_cav.stl"   "$tmp/mb_cav.scad"   2>/dev/null

cat > "$tmp/mb_dims.scad" <<EOF
use <multibuild/multibuild.scad>;
sz = $mb_size;
echo(multibin_footprint(sz)[0]);
echo(multibin_footprint(sz)[1]);
echo(multibin_height(sz));
echo(multibin_cavity(sz)[0]);
echo(multibin_cavity(sz)[1]);
echo(multibin_cavity(sz)[2]);
echo(multibin_wall(sz));
EOF
mapfile -t mb_dims < <(run "$tmp/mb_dims.scad" | grep -oE 'ECHO: -?[0-9]+(\.[0-9]+)?' | grep -oE '\-?[0-9]+(\.[0-9]+)?')
if [ "${#mb_dims[@]}" -ne 7 ]; then
  echo "MultiBin: expected 7 dimension echoes, got ${#mb_dims[@]}"; exit 1
fi

python3 - "$tmp/mb_place.stl" "$tmp/mb_cav.stl" "${mb_dims[@]}" <<'PY' || { echo "MultiBin envelope/cavity bbox or alignment incorrect"; exit 1; }
import struct, sys

def bbox(path):
    d = open(path, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]; off = 84
    xs=[]; ys=[]; zs=[]
    for i in range(n):
        for v in range(3):
            base = off + i*50 + 12 + v*12
            x,y,z = struct.unpack('<3f', d[base:base+12])
            xs.append(x); ys.append(y); zs.append(z)
    return (min(xs),max(xs),min(ys),max(ys),min(zs),max(zs))

place, cav = sys.argv[1], sys.argv[2]
fw, fl, fh, cw, cl, ch, wall = (float(a) for a in sys.argv[3:10])
tol = 1e-3

pxmin,pxmax,pymin,pymax,pzmin,pzmax = bbox(place)
cxmin,cxmax,cymin,cymax,czmin,czmax = bbox(cav)

def close(a,b): return abs(a-b) < tol
errs = []
# envelope: footprint x height, floor at Z=0, centered XY
if not close(pxmax-pxmin, fw): errs.append("envelope X span %.4f != %.4f"%(pxmax-pxmin, fw))
if not close(pymax-pymin, fl): errs.append("envelope Y span %.4f != %.4f"%(pymax-pymin, fl))
if not close(pzmax-pzmin, fh): errs.append("envelope Z span %.4f != %.4f"%(pzmax-pzmin, fh))
if not close(pzmin, 0):        errs.append("envelope floor %.4f != 0"%pzmin)
if not close((pxmin+pxmax)/2, 0): errs.append("envelope not X-centered")
if not close((pymin+pymax)/2, 0): errs.append("envelope not Y-centered")
# cavity: cavity dims, centered XY
if not close(cxmax-cxmin, cw): errs.append("cavity X span %.4f != %.4f"%(cxmax-cxmin, cw))
if not close(cymax-cymin, cl): errs.append("cavity Y span %.4f != %.4f"%(cymax-cymin, cl))
if not close(czmax-czmin, ch): errs.append("cavity Z span %.4f != %.4f"%(czmax-czmin, ch))
if not close((cxmin+cxmax)/2, 0): errs.append("cavity not X-centered")
if not close((cymin+cymax)/2, 0): errs.append("cavity not Y-centered")
# wall consistency measured from the actual geometry
if not close((fw-cw)/2, wall): errs.append("X wall %.4f != %.4f"%((fw-cw)/2, wall))
if not close((fl-cl)/2, wall): errs.append("Y wall %.4f != %.4f"%((fl-cl)/2, wall))
# cavity strictly inside the envelope on every axis (mutual alignment)
if not (cxmin > pxmin - tol and cxmax < pxmax + tol): errs.append("cavity exceeds envelope in X")
if not (cymin > pymin - tol and cymax < pymax + tol): errs.append("cavity exceeds envelope in Y")
if not (czmin > pzmin - tol and czmax < pzmax + tol): errs.append("cavity exceeds envelope in Z")

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
    sys.exit(1)
sys.exit(0)
PY

# Negative control: unknown bin size must assert.
cat > "$tmp/bad_bin.scad" <<'EOF'
use <multibuild/multibuild.scad>;
x = multibin_footprint([9,9,9]);
EOF
out="$(run "$tmp/bad_bin.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown bin size:"; echo "$out"; exit 1
fi

# --- Tile (MultiBoard accessory panel): hole-stamp + placeholder (#33) ---
# Verify STL-rendered geometry that the scad-level asserts (multibuild_test.scad)
# can't reach: large/small hole COUNTS (via volume ratio against a single
# straight-cylinder reference -- the two hole families never overlap at this
# pitch/diameter, see multibuild.scad's Tile section) and the placeholder
# envelope's bbox/datum (top face at Z=0, slab grows -Z through the tile
# thickness, footprint cols*25 x rows*25, XY-centered like multibuild_grid_points).
tile_cols=3; tile_rows=3

cat > "$tmp/tile_dims.scad" <<EOF
use <multibuild/multibuild.scad>;
echo(multibuild_tile_thickness());
echo(multibuild_large_hole_dia());
echo(multibuild_small_hole_dia());
echo(multibuild_small_hole_depth());
EOF
mapfile -t tile_dims < <(run "$tmp/tile_dims.scad" | grep -oE 'ECHO: -?[0-9]+(\.[0-9]+)?' | grep -oE '\-?[0-9]+(\.[0-9]+)?')
tile_h="${tile_dims[0]}"; large_d="${tile_dims[1]}"; small_d="${tile_dims[2]}"; small_h="${tile_dims[3]}"

cat > "$tmp/tile_large.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_tile_holes($tile_cols, $tile_rows, "large");
EOF
cat > "$tmp/tile_small.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_tile_holes($tile_cols, $tile_rows, "small");
EOF
cat > "$tmp/tile_both.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_tile_holes($tile_cols, $tile_rows, "both");
EOF
cat > "$tmp/tile_placeholder.scad" <<EOF
use <multibuild/multibuild.scad>;
multibuild_tile_placeholder($tile_cols, $tile_rows);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tile_large.stl" "$tmp/tile_large.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tile_small.stl" "$tmp/tile_small.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tile_both.stl" "$tmp/tile_both.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tile_placeholder.stl" "$tmp/tile_placeholder.scad" 2>/dev/null

python3 - "$tmp/tile_large.stl" "$tmp/tile_small.stl" "$tmp/tile_both.stl" "$tmp/tile_placeholder.stl" \
  "$tile_cols" "$tile_rows" "$tile_h" "$large_d" "$small_d" "$small_h" <<'PY' || { echo "Tile hole-stamp/placeholder geometry incorrect"; exit 1; }
import struct, sys, math

def read(path):
    d = open(path, 'rb').read(); n = struct.unpack('<I', d[80:84])[0]; off = 84
    xs = []; ys = []; zs = []; vol = 0.0
    for i in range(n):
        tri = []
        for v in range(3):
            base = off + i * 50 + 12 + v * 12
            p = struct.unpack('<3f', d[base:base + 12]); tri.append(p)
            xs.append(p[0]); ys.append(p[1]); zs.append(p[2])
        (x1, y1, z1), (x2, y2, z2), (x3, y3, z3) = tri
        vol += (x1 * (y2 * z3 - y3 * z2) - y1 * (x2 * z3 - x3 * z2) + z1 * (x2 * y3 - x3 * y2)) / 6.0
    return n, abs(vol), (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))

large_path, small_path, both_path, place_path = sys.argv[1:5]
cols, rows = int(sys.argv[5]), int(sys.argv[6])
th, ld, sd, sh = (float(x) for x in sys.argv[7:11])

n_large_exp = cols * rows
n_small_exp = (cols - 1) * (rows - 1)

_, v_large, _ = read(large_path)
_, v_small, _ = read(small_path)
_, v_both, _  = read(both_path)
n_place, v_place, b_place = read(place_path)

vol_cyl = lambda d, h: math.pi * (d / 2) ** 2 * h
exp_large = n_large_exp * vol_cyl(ld, th)
exp_small = n_small_exp * vol_cyl(sd, sh)

errs = []
tol_rel = 0.03  # $fn=48 faceting underestimate, a couple % on small cylinders
def close_rel(a, b, tol=tol_rel):
    return abs(a - b) <= tol * max(abs(b), 1.0)

if not close_rel(v_large, exp_large):
    errs.append("large-hole volume %.3f != expected %.3f (n=%d)" % (v_large, exp_large, n_large_exp))
if not close_rel(v_small, exp_small):
    errs.append("small-hole volume %.3f != expected %.3f (n=%d)" % (v_small, exp_small, n_small_exp))
# "both" == large + small (the two families never overlap at this pitch/offset)
if not close_rel(v_both, v_large + v_small):
    errs.append("both-hole volume %.3f != large+small %.3f" % (v_both, v_large + v_small))

# Placeholder envelope: footprint cols*25 x rows*25, top face at Z=0, slab
# grows -Z through the tile thickness, XY-centered on the origin.
w_exp, d_exp = cols * 25, rows * 25
xmin, xmax, ymin, ymax, zmin, zmax = b_place
tol = 0.05
if abs((xmax - xmin) - w_exp) > tol: errs.append("placeholder X span %.4f != %.4f" % (xmax - xmin, w_exp))
if abs((ymax - ymin) - d_exp) > tol: errs.append("placeholder Y span %.4f != %.4f" % (ymax - ymin, d_exp))
if abs((zmax - zmin) - th) > tol: errs.append("placeholder Z span %.4f != %.4f" % (zmax - zmin, th))
if abs(zmax) > tol: errs.append("placeholder top face not at Z=0 (zmax=%.4f)" % zmax)
if abs((xmin + xmax) / 2) > tol: errs.append("placeholder not X-centered")
if abs((ymin + ymax) / 2) > tol: errs.append("placeholder not Y-centered")
slab_vol = w_exp * d_exp * th
exp_place = slab_vol - (v_large + v_small)
if not close_rel(v_place, exp_place, tol=0.05):
    errs.append("placeholder volume %.3f != slab-holes %.3f" % (v_place, exp_place))

if errs:
    sys.stderr.write("\n".join(errs) + "\n")
    sys.exit(1)
sys.exit(0)
PY

echo ok
