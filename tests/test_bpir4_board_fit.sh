#!/usr/bin/env bash
# #84: the bpi-r4 board must not intersect the tray. A 3.248 mm^3 collision
# between the board's front corners and the front lid-post fillets shipped
# undetected because nothing ever intersected assembly.scad's own board
# placeholder with tray() -- every render, every test and a colored
# per-surface review passed while the board physically could not be installed.
#
# SWEEP TECHNIQUE: the exact swept volume of a linear translation is
# minkowski(solid, segment), but minkowski on this mesh is impractically slow.
# This uses a discrete union at STEP=0.25mm over board_install_travel().
# LIMITATION, STATED DELIBERATELY: it can tunnel straight through any tray
# feature thinner than 0.25mm in Y. hull() of the two endpoints would NOT be a
# valid substitute -- the board+connectors solid is non-convex, so a hull
# overstates the swept volume and reports collisions that cannot occur.
# The sweep is verified to have teeth: restoring the front lid-post fillet
# makes it report 3.2214 mm^3 instead of 0.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Mesh volume via the divergence theorem over the exported triangles.
# A genuinely empty intersection is the PASS case for several probes below, and
# OpenSCAD writes NO output file at all for one ("Current top level object is
# empty") -- so a missing file means zero volume, not an error. Without this
# the empty case yields an empty string, awk gets a syntax error, and a correct
# result is reported as a failure.
meshvol() {
  [ -s "$1" ] || { echo "0.0"; return; }
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

# --- inner-edge lead-in chamfers (#85) ---
# The chamfer is a lead-in funnel on the faceplate's INTERIOR face. The failure
# mode worth testing is the sign error: a funnel built on the +Y side of that
# face sits in open cavity air, removes nothing, and still renders perfectly
# clean. So this probes the geometry directly rather than trusting the render.
#
# NOT DONE BY RE-RENDERING WITH io_chamfer=0, which cannot work here: params.
# scad ASSIGNS io_chamfer, so an entry-file pre-declaration loses to it
# (last-assignment-wins), and tray() is `use`d, so it reads its OWN file scope
# regardless. -D would set it everywhere at once and give a false pass. The
# probe below needs no such override.
#
# Two probe boxes, both just left of usb_1's opening (board-local x0=8.0,
# k=io_port_clearance=0.4, so the nominal opening's left edge is x=7.6 and
# everything left of it is panel material without a chamfer):
#   near  -- y in [-0.3,-0.1], i.e. 0.1-0.3mm into the panel from the interior
#            face. At depth d the 45-degree funnel has grown (ch - d), so at
#            d=0.2 it reaches x=6.8; the probe sits at x in [6.9,7.4], inside
#            the cut. MUST BE VOID.
#   deep  -- y in [-2.9,-2.7], near the panel's FRONT face, same x/z. The
#            funnel is only io_chamfer=1.0 deep, so it never reaches here.
#            MUST BE SOLID -- this is what proves the near probe's emptiness is
#            the chamfer and not a hole through the whole panel, and that the
#            port's through-opening at the front face is untouched.
cat > "$tmp/ch.scad" <<EOS
enable_exhaust = true; fan_size = 40; fan_count = 2; fan_thickness = 20;
include <$proj/params.scad>;
use <$proj/parts/tray.scad>;
use <sbc/sbc.scad>;
echo(str("CHAMFER=", io_chamfer));
PROBE = "\$PROBE";
u = sbc_connector(BOARD, "usb_1");
x0 = board_x() + u[1][0] - io_port_clearance - 0.7;   // 0.3mm inside the funnel's reach
z0 = board_z() + u[1][2] + 2.6;
y0 = PROBE == "near" ? -0.3 : -2.9;
intersection() {
  tray();
  translate([x0, y0, z0]) cube([0.5, 0.2, 6]);
}
EOS
sed 's/\$PROBE/near/' "$tmp/ch.scad" > "$tmp/ch_near.scad"
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/ch_near.stl" "$tmp/ch_near.scad" 2>&1)"
if ! echo "$out" | grep -q "CHAMFER=1"; then
  echo "FAIL: io_chamfer is not 1.0"; echo "$out"; fail=1
fi
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: chamfer render errored"; echo "$out"; fail=1
fi
if echo "$out" | grep -qiE "Ignoring unknown|Can't open library"; then
  echo "FAIL: chamfer render has an unresolved import or unknown variable"
  echo "$out"; fail=1
fi
sed 's/\$PROBE/deep/' "$tmp/ch.scad" > "$tmp/ch_deep.scad"
"$root/scripts/openscad.sh" --export-format stl -o "$tmp/ch_deep.stl" "$tmp/ch_deep.scad" 2>/dev/null
vnear="$(meshvol "$tmp/ch_near.stl")"; vdeep="$(meshvol "$tmp/ch_deep.stl")"
# Probe box is 0.5 x 0.2 x 6 = 0.6 mm^3.
if awk "BEGIN{exit !($vnear < 0.01)}"; then
  echo "ok: lead-in chamfer has opened the interior face (near probe ${vnear} mm^3 of 0.6)"
else
  echo "FAIL: interior face is still solid beside usb_1 (near probe ${vnear} mm^3 of 0.6)"
  echo "      -- a funnel built at +Y cuts open cavity air and removes nothing"
  fail=1
fi
if awk "BEGIN{exit !($vdeep > 0.55)}"; then
  echo "ok: chamfer is a lead-in only -- panel still solid at the front face (deep probe ${vdeep} mm^3 of 0.6)"
else
  echo "FAIL: chamfer cut through to the front face (deep probe ${vdeep} mm^3 of 0.6, expected ~0.6 solid)"
  fail=1
fi

# --- swept install-motion clearance (#84) ---
# The board must be able to REACH its seated pose, not merely occupy it. Sweep
# the board slab along +Y over the full install travel and intersect with the
# tray.
cat > "$tmp/sweep.scad" <<EOS
enable_exhaust = true; fan_size = 40; fan_count = 2; fan_thickness = 20;
include <$proj/params.scad>;
use <$proj/parts/tray.scad>;
\$fn = 32;
STEP = 0.25;
module board_slab() {
  cr = sbc_corner_radius(BOARD); th = sbc_thickness(BOARD);
  translate([board_x(), board_y(), board_z()])
    linear_extrude(th)
      hull() for (dx = [cr, board_w()-cr], dy = [cr, board_d()-cr])
        translate([dx, dy]) circle(r = cr);
}
echo(str("TRAVEL=", board_install_travel()));
intersection() {
  tray();
  union() for (i = [0 : ceil(board_install_travel()/STEP)])
    translate([0, min(i*STEP, board_install_travel()), 0]) board_slab();
}
EOS
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/sweep.stl" "$tmp/sweep.scad" 2>&1)"
if echo "$out" | grep -qiE "Ignoring unknown|Can't open library"; then
  echo "FAIL: sweep has an unresolved import or unknown variable"; echo "$out"; fail=1
fi
echo "$out" | grep -o 'TRAVEL=[0-9.]*' | head -1
sv="$(meshvol "$tmp/sweep.stl")"
if awk "BEGIN{exit !($sv > 0.001)}"; then
  echo "FAIL: board collides during installation sweep by ${sv} mm^3"; fail=1
else
  echo "ok: swept install clearance ${sv} mm^3"
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
