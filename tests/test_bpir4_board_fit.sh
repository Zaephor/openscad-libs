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

# --- IO opening clearances (#85) ---
# usb_1 and both SFP cages need more headroom for their mating plugs; RJ45 is
# bench-confirmed correct and must NOT move.
cat > "$tmp/io.scad" <<EOS
enable_exhaust = true; fan_size = 40; fan_count = 2; fan_thickness = 20;
include <$proj/params.scad>;
use <$proj/parts/tray.scad>;
use <sbc/sbc.scad>;
echo(str("TOPC=", io_top_clearance, " PORTS=", io_top_clearance_ports()));
echo(str("WALL_DC_USBC=", _io_wall_w_dc_usbc()));
g = _io_gap_wall_geom("dc_power_1", "usbc_pwr_1", _io_wall_w_dc_usbc(), io_port_clearance, io_wall_dc_usbc_bias);
u = sbc_connector(BOARD, "usbc_pwr_1");
echo(str("USBC_FREE=", (board_x() + u[1][0]) - g[1]));
EOS
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/io.stl" "$tmp/io.scad" 2>&1)"
if ! echo "$out" | grep -q 'TOPC=0.5'; then
  echo "FAIL: io_top_clearance is not 0.5"; echo "$out"; fail=1
fi
# rj45_block must NOT be in the list -- it is bench-verified correct and
# loosening it would be a regression.
if echo "$out" | grep -q 'PORTS=.*rj45'; then
  echo "FAIL: rj45 must not receive top clearance"; echo "$out"; fail=1
fi
# NB: the trailing quote is load-bearing -- "WALL_DC_USBC=1" alone is a prefix
# of the old "WALL_DC_USBC=1.5" and would pass against the unfixed geometry.
if ! echo "$out" | grep -q 'WALL_DC_USBC=1"'; then
  echo "FAIL: dc/usbc wall not narrowed to 1.0"; echo "$out"; fail=1
fi
# Wall was 1.5 centred in a 4.6mm gap => 1.55mm free on the USB-C side.
# Target: 1.0 wall biased 0.25 toward dc_power_1 => 2.05mm free (+0.5).
if ! echo "$out" | grep -qE 'USBC_FREE=2\.05'; then
  echo "FAIL: USB-C side free space is not 2.05mm (+0.5 over the old 1.55)"
  echo "$out"; fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
