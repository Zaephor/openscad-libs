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

echo ok
