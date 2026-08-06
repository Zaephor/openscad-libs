#!/usr/bin/env bash
# #84: the bpi-r4 board must not intersect the tray. A 3.248 mm^3 collision
# between the board's front corners and the front lid-post fillets shipped
# undetected because nothing ever intersected assembly.scad's own board
# placeholder with tray() -- every render, every test and a colored
# per-surface review passed while the board physically could not be installed.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Mesh volume via the divergence theorem over the exported triangles.
meshvol() {
  python3 - "$1" <<'PY'
import sys, numpy as np
vs=[]
for line in open(sys.argv[1], errors='ignore'):
    if line.lstrip().startswith('vertex'):
        vs.append([float(x) for x in line.split()[1:4]])
if not vs:
    print("0.0"); raise SystemExit
t=np.array(vs).reshape(-1,3,3)
print(f"{abs(np.einsum('ij,ij->i', t[:,0], np.cross(t[:,1],t[:,2])).sum()/6.0):.4f}")
PY
}

cat > "$tmp/static.scad" <<EOS
enable_exhaust = true; fan_size = 40; fan_count = 2; fan_thickness = 20;
include <$proj/params.scad>;
use <$proj/parts/tray.scad>;
\$fn = 64;
module board_slab() {
  cr = sbc_corner_radius(BOARD); th = sbc_thickness(BOARD);
  translate([board_x(), board_y(), board_z()])
    linear_extrude(th)
      hull() for (dx = [cr, board_w()-cr], dy = [cr, board_d()-cr])
        translate([dx, dy]) circle(r = cr);
}
intersection() { tray(); board_slab(); }
EOS

out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/static.stl" "$tmp/static.scad" 2>&1)"
if echo "$out" | grep -qiE "Ignoring unknown|Can't open library"; then
  echo "FAIL: unresolved library import"; echo "$out"; fail=1
fi
v="$(meshvol "$tmp/static.stl")"
# Threshold, not zero: faces that legitimately touch produce exact-0.000
# coincident-face artifacts (the REAR post corners do this). Anything with
# real volume is a genuine collision.
if awk "BEGIN{exit !($v > 0.001)}"; then
  echo "FAIL: board intersects tray by ${v} mm^3 (expected ~0)"; fail=1
else
  echo "ok: board-vs-tray static interference ${v} mm^3"
fi

# --- M2 board standoffs (#84) ---
cat > "$tmp/fast.scad" <<EOS
enable_exhaust = true; fan_size = 40; fan_count = 2; fan_thickness = 20;
include <$proj/params.scad>;
use <$proj/parts/tray.scad>;
echo(str("INSERT=", board_insert_size, " BORE=", board_insert_bore(), " OD=", _board_standoff_od()));
EOS
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/fast.stl" "$tmp/fast.scad" 2>&1)"
if ! echo "$out" | grep -q "INSERT=M2 BORE=3.23 OD=6.43"; then
  echo "FAIL: board standoffs are not M2 (expected BORE=3.23 OD=6.43)"; echo "$out"; fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
