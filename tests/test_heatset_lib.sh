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

# Pocket: Z-extent must differ with/without melt_relief, and the mouth (top
# lead-in chamfer) must be wider than the pilot bore. All expected numbers are
# derived dynamically from the accessor functions, not hardcoded.
cat > "$tmp/pocket_dims.scad" <<'EOF'
use <heatset/heatset.scad>;
echo(heatset_insert_length("M3"));
echo(heatset_lead_in("M3"));
echo(heatset_pilot_dia("M3"));
EOF
dims_out="$(run "$tmp/pocket_dims.scad")"
m3_len="$(echo "$dims_out" | grep -m1 'ECHO:' | grep -oE '[0-9]+\.[0-9]+')"
m3_li="$(echo "$dims_out" | grep -m2 'ECHO:' | tail -1 | grep -oE '[0-9]+\.[0-9]+')"
m3_pd="$(echo "$dims_out" | grep -m3 'ECHO:' | tail -1 | grep -oE '[0-9]+\.[0-9]+')"

cat > "$tmp/pocket_norelief.scad" <<'EOF'
use <heatset/heatset.scad>;
heatset_pocket("M3", melt_relief = false);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/pocket_norelief.stl" "$tmp/pocket_norelief.scad" 2>/dev/null

cat > "$tmp/pocket_relief.scad" <<'EOF'
use <heatset/heatset.scad>;
heatset_pocket("M3", melt_relief = true);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/pocket_relief.stl" "$tmp/pocket_relief.scad" 2>/dev/null

python3 - "$tmp/pocket_norelief.stl" "$tmp/pocket_relief.stl" "$m3_len" "$m3_li" "$m3_pd" <<'PY' || { echo "pocket Z-extent/mouth-width incorrect"; exit 1; }
import struct,sys

def bbox(path):
    d=open(path,'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
    xs=[];zs=[]
    for i in range(n):
        for v in range(3):
            base=off+i*50+12+v*12
            x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); zs.append(z)
    return min(xs),max(xs),min(zs),max(zs)

nr_xmin,nr_xmax,nr_zmin,nr_zmax = bbox(sys.argv[1])
rl_xmin,rl_xmax,rl_zmin,rl_zmax = bbox(sys.argv[2])
length=float(sys.argv[3]); lead_in=float(sys.argv[4]); pilot_dia=float(sys.argv[5])
mouth_dia = pilot_dia + 2*lead_in
tol=0.1

ok = (
    abs(nr_zmin - (-length)) < tol and                      # no relief: bottom at -insert_length
    abs(rl_zmin - (-(length + lead_in))) < tol and           # with relief: extends further below
    rl_zmin < nr_zmin - 0.01 and                             # relief strictly deeper than no-relief
    nr_zmax < 0.1 and rl_zmax < 0.1 and                      # mouth at/near Z=0
    abs((nr_xmax - nr_xmin) - mouth_dia) < tol and           # mouth wider than pilot bore (lead-in chamfer)
    abs((rl_xmax - rl_xmin) - mouth_dia) < tol
)
sys.exit(0 if ok else 1)
PY

# Chamfer DIRECTION: the lead-in must widen going from the bore toward the
# mouth (Z=0), not just "a wide point exists somewhere in the solid" (a
# whole-solid bbox check can't tell widening-toward-+Z from widening-toward
# the bore, since the same max diameter appears in the union either way).
# Slice the no-relief pocket mesh at two known-vertex Z-bands: the bottom cap
# (deep in the uniform-diameter pilot bore, always narrow) and the mouth
# (Z=0, should be measurably wider than the bore in the correct direction).
python3 - "$tmp/pocket_norelief.stl" "$m3_len" "$m3_li" "$m3_pd" <<'PY' || { echo "pocket chamfer direction incorrect (mouth not wider than bore)"; exit 1; }
import struct,sys

path,length,lead_in,pilot_dia = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])

d=open(path,'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
verts=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12])
        verts.append((x,z))

def band_xspan(target_z, band=0.15):
    xs=[x for x,z in verts if abs(z-target_z)<band]
    return (max(xs)-min(xs)) if xs else None

bore_dia  = band_xspan(-length)  # bottom cap: pure pilot bore, unaffected by chamfer direction
mouth_dia = band_xspan(0.0)      # mouth (Z=0): wide only if chamfer widens toward +Z

margin = lead_in  # require a real margin (one full lead_in), not just faceting/epsilon noise

ok = (
    bore_dia is not None and mouth_dia is not None and
    abs(bore_dia - pilot_dia) < 0.1 and
    mouth_dia > bore_dia + margin
)
sys.exit(0 if ok else 1)
PY

echo ok
