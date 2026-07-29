#!/usr/bin/env bash
# Verifies the rack-support library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack-support/tests/rack_support_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack_support_test.scad asserts failed:"; echo "$out"; exit 1
fi

# No validation logic exists yet to drive a real negative control -- the
# accessors are plain constants with nothing to reject (Task 3/4 add
# rack_support_plate()/rack_support_tongue() and their own negative
# controls once there's real geometry/argument validation to break). For
# now, additionally require the accessor file renders with NO warnings at
# all (not just no errors), so a broken `use` path or an unknown-function
# typo in the test itself can't silently pass via WARNING-only output.
if echo "$out" | grep -qiE 'WARNING:'; then
  echo "rack_support_test.scad rendered with unexpected warnings:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# --- rack_support_plate() presence checks (#40 Task 3, Z-datum fix) ---
# Per rack10's own global datum (rack10.scad:3, "Z=0 at the bottom of the
# U-stack") and rack10_stack_gap()'s ~0.79mm inter-device relief, ALL solid
# material of this plate must stay at Z>=0 -- a plate with material below
# Z=0 would collide with whatever device occupies the U-slot below in a
# real rack10 stack. So the plate's real Z-span is bounded by
# [~0, rack10_device_height(1)=43.66] (the panel top), NOT extended below
# zero the way an earlier revision of this module did (fixed: #40 review).
# Confirmed via verify-scad-geometry: floor bottom @ Z=0 / floor top
# (bearing surface) @ Z=floor_t=2 / gusset exactly 45deg, clear of the slot
# cavity / rear holes penetrate / support-free in the flat print
# orientation. zmin is allowed a hair of negative slack (sub-micron,
# `_rack_support_yz_prism`'s hull() spheres have radius 0.001) but must be
# nowhere near the old bug's -14.
cat > "$tmp/plate.scad" <<'EOF'
use <rack-support/rack-support.scad>;
rack_support_plate("labrax", 1);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/plate.stl" "$tmp/plate.scad" 2>/dev/null
python3 - "$tmp/plate.stl" <<'PY' || { echo "rack_support_plate Z-extent wrong (want max~43.66, min~0, all material Z>=0)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12
        zs.append(struct.unpack('<3f',d[b:b+12])[2])
zmax=max(zs); zmin=min(zs)
ok = abs(zmax-43.66)<0.05 and zmin > -0.05
sys.exit(0 if ok else 1)
PY

# Slot cavity is a real removed-material void, not just a modeled-but-solid
# feature: probe a small box centered in X (X in [-1,1]), within the
# engagement zone forward of the mounting face (Y in [-8,-4], inside
# [-ed,0]=[-12,0]) and within the channel's Z-band (Z in [5,9], inside
# [floor_t,floor_t+slot_h]=[2,12.4]) -- this must render EMPTY (OpenSCAD
# prints "Current top level object is empty." and writes no STL) if the
# cavity was actually cut. A plain panel (or a plate with the slot merely
# drawn but not subtracted) would NOT be empty here.
cat > "$tmp/probe_center.scad" <<'EOF'
use <rack-support/rack-support.scad>;
intersection() {
    rack_support_plate("labrax", 1);
    translate([-1, -8, 5]) cube([2, 4, 4]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_center.stl" "$tmp/probe_center.scad" 2>&1)"
if [ -f "$tmp/probe_center.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "slot cavity band is NOT empty at center -- cavity not actually removed:"; echo "$out"; exit 1
fi

# Positive control: the SAME Z-band, off to the side (X~30, well outside the
# slot_w=~40.8mm-wide channel but still inside the panel's own Y=[0,thickness]
# range where the panel is unconditionally solid) must be non-empty --
# proves the plate isn't just globally hollow at that Z, only narrower at
# the slot band (the actual claim under test).
cat > "$tmp/probe_side.scad" <<'EOF'
use <rack-support/rack-support.scad>;
intersection() {
    rack_support_plate("labrax", 1);
    translate([30, 1, 5]) cube([2, 2, 4]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_side.stl" "$tmp/probe_side.scad" 2>/dev/null
if [ ! -s "$tmp/probe_side.stl" ]; then
  echo "positive control (off-slot panel material) unexpectedly empty"; exit 1
fi

# Gusset presence (Z-datum fix, #40 review): the 45deg gusset is now built
# full panel-width and only survives as ribs flanking the slot (its central
# slot-width band gets removed by the same cut that carves the channel
# cavity -- see module doc). Probe the flank region -- X derived from the
# same accessors the module reads (slot_w/2 + gusset_rib()/2, the rib
# band's own midpoint; NOT re-literaled -- a rib-width change must not
# silently make this probe land outside the rib by luck the way the old
# hardcoded X=25 did) -- in the mouth zone (Y=-6, inside [-ed,0]=[-12,0])
# at a low Z band (Z in [1,3], inside the gusset's cross-section height
# there -- at Y=-6 the triangle's height is Y+ed=6, well above this band,
# and entirely below the slot cavity's Z-floor of floor_t=2..12.4, so this
# probe is unambiguously the gusset rib, not the floor or the cavity roof)
# -- must be non-empty. Confirms the flanking-rib redesign actually leaves
# real bracing material, not just an empty central cut.
cat > "$tmp/probe_gusset.scad" <<'EOF'
use <rack-support/rack-support.scad>;
rs = rack_support_rail_size();
cl = rack_support_slot_clearance();
slot_w = rs[0] + 2 * cl;
rib = rack_support_gusset_rib();
probe_x = slot_w / 2 + rib / 2;
intersection() {
    rack_support_plate("labrax", 1);
    translate([probe_x - 1, -6, 1]) cube([2, 2, 2]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_gusset.stl" "$tmp/probe_gusset.scad" 2>/dev/null
if [ ! -s "$tmp/probe_gusset.stl" ]; then
  echo "gusset flank rib (Z-datum fix) unexpectedly empty -- bracing material missing"; exit 1
fi

# Negative control (#63 Task 1/2): the narrowed gusset's actual claim is
# that it does NOT reach beyond the rib -- nothing currently tested that
# absence. Same Y/Z band as the positive probe above, X well past the
# rib's outer edge (slot_w/2 + gusset_rib(), +5mm clearance) -- must be
# EMPTY. Derived from accessors, same "is empty" idiom as the slot-cavity
# probes.
cat > "$tmp/probe_gusset_negative.scad" <<'EOF'
use <rack-support/rack-support.scad>;
rs = rack_support_rail_size();
cl = rack_support_slot_clearance();
slot_w = rs[0] + 2 * cl;
rib = rack_support_gusset_rib();
neg_x = slot_w / 2 + rib + 5;
intersection() {
    rack_support_plate("labrax", 1);
    translate([neg_x, -6, 1]) cube([2, 2, 2]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_gusset_negative.stl" "$tmp/probe_gusset_negative.scad" 2>&1)"
if [ -f "$tmp/probe_gusset_negative.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "gusset extends beyond its narrowed rib width -- negative control unexpectedly non-empty:"; echo "$out"; exit 1
fi

# Rear mounting holes penetrate: probe a small box straddling one hole
# center (X = hole_h_span/2 = 118.2625, first hole Z = 6.35) must be EMPTY
# (the round clearance hole actually punches through), matching the same
# "is empty" idiom above.
cat > "$tmp/probe_hole.scad" <<'EOF'
use <rack-support/rack-support.scad>;
intersection() {
    rack_support_plate("labrax", 1);
    translate([118.2625 - 1, -1, 6.35 - 1]) cube([2, 2, 2]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_hole.stl" "$tmp/probe_hole.scad" 2>&1)"
if [ -f "$tmp/probe_hole.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "rear mounting hole does NOT penetrate (expected empty at a hole center):"; echo "$out"; exit 1
fi

# --- rack_support_tongue() span checks (#40 Task 4) ---
# X-span == rack_support_rail_size()[0] (40), Y-span ==
# rack_support_engagement_depth() (12), Z-span == rack_support_rail_size()[1]
# (10). A span (max-min) is unaffected by the tongue's Z-datum fix
# (underside seated at rack_support_floor_thickness()=2, not Z=0 -- see the
# module doc) since it's a difference, not an absolute position; the
# absolute Z position is what verify-scad-geometry confirmed mates with the
# plate's real channel band, separately from this shape check.
cat > "$tmp/tongue.scad" <<'EOF'
use <rack-support/rack-support.scad>;
rack_support_tongue();
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tongue.stl" "$tmp/tongue.scad" 2>/dev/null
python3 - "$tmp/tongue.stl" <<'PY' || { echo "rack_support_tongue span wrong (want X=40, Y=12, Z=10)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[];zs=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[b:b+12]); xs.append(x); ys.append(y); zs.append(z)
xspan=max(xs)-min(xs); yspan=max(ys)-min(ys); zspan=max(zs)-min(zs)
ok = abs(xspan-40)<0.05 and abs(yspan-12)<0.05 and abs(zspan-10)<0.05
sys.exit(0 if ok else 1)
PY

# Tongue underside sits at rack_support_floor_thickness() (2), not Z=0 --
# the Z-datum fix this task adapted to. zmin must be ~2, not ~0.
python3 - "$tmp/tongue.stl" <<'PY' || { echo "rack_support_tongue zmin wrong (want ~2, the plate's bearing-floor top, not 0)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12
        zs.append(struct.unpack('<3f',d[b:b+12])[2])
sys.exit(0 if abs(min(zs)-2)<0.05 else 1)
PY

# --- plate/tongue intersection regression (final review, Minor #2) ---
# The README consumer-contract placement formula (mirrored from
# assembly.scad, which already uses it to seat the reference stub tray):
#   reach = rack10_rear_post_y(standard) - rack_support_engagement_depth()
#   translate([0, reach, 0]) rack_support_tongue();
#   translate([0, rack10_rear_post_y(standard), 0]) rack_support_plate(standard, u);
# At that placement the tongue must seat inside the plate's channel cavity
# without clipping into any of the plate's solid material -- intersection()
# of the two solids must render EMPTY, the same "is empty" idiom the slot-
# cavity/hole probes above use (OpenSCAD prints "Current top level object
# is empty." and writes no STL).
cat > "$tmp/probe_mate.scad" <<'EOF'
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
u = 1;
reach = rack10_rear_post_y(standard) - rack_support_engagement_depth();
intersection() {
    translate([0, rack10_rear_post_y(standard), 0]) rack_support_plate(standard, u);
    translate([0, reach, 0]) rack_support_tongue();
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_mate.stl" "$tmp/probe_mate.scad" 2>&1)"
if [ -f "$tmp/probe_mate.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "rack_support_plate/rack_support_tongue clip through each other at the documented placement (expected empty intersection):"; echo "$out"; exit 1
fi

# --- rack_support_plate_keepout() real-consumer interference tests (#63 Task 2) ---
# A minimal consumer body reproducing assembly.scad's reference stub tray
# (front ear panel + floor reaching the mounting plane + tongue seated in
# the channel -- same accessor-derived dims/placement as that file; kept
# here rather than reused from assembly.scad because that file is a script,
# not a module, so `use` cannot import its top-level geometry, and this
# suite must defend the library without depending on a projects/ file).
# All probe coordinates are accessor calls inside the .scad, never -D
# injection (use does not import top-level variables).
tray_body() {
cat <<'EOF'
module consumer_body() {
    union() {
        translate([-rack10_panel_width(standard)/2, -3, 0])
            cube([rack10_panel_width(standard), 3, rack10_device_height(u)]);
        translate([-rw/2, 0, 0]) cube([rw, rpy, ft]);
        translate([0, reach, 0]) rack_support_tongue();
    }
}
EOF
}

# (a) Interference: a consumer that differences the published keepout out of
# its own body, at the SAME placement it uses for the plate (the documented
# consumer contract in the module doc), must reach ZERO interference with
# the plate -- intersection() must be EMPTY. Task 1's narrowed gusset alone
# only reduced the collision (3554.86mm^3 -> 1333.51mm^3); this closes it.
cat > "$tmp/interference.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
u = 1;
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rw  = rack_support_rail_size()[0];
reach = rpy - rack_support_engagement_depth();
$(tray_body)
intersection() {
    translate([0, rpy, 0]) rack_support_plate(standard, u);
    difference() {
        consumer_body();
        translate([0, rpy, 0]) rack_support_plate_keepout();
    }
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/interference.stl" "$tmp/interference.scad" 2>&1)"
if [ -f "$tmp/interference.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "consumer body (keepout subtracted) still interferes with the plate -- keepout envelope incomplete:"; echo "$out"; exit 1
fi

# (b) PAIRED -- tongue survives, checked by volume (not mere presence): an
# over-broad keepout that also eats the channel cavity would still pass (a)
# by deleting the consumer's own tongue, AND would still leave the probe
# band file non-empty (a cavity-less draft measurably erodes the tongue but
# does not erase it -- verified during development: it left ~58% of the
# tongue's volume, 2799mm^3 of 4800mm^3, so a plain non-empty/exists check
# does NOT catch it). So this asserts the FULL undamaged volume survives:
# intersect the differenced consumer with the tongue's own bounding band
# (X +-rail_size()[0]/2 with slight slack, Y [rpy-ed,rpy], Z
# [ft,ft+rail_size()[1]]) and require its volume equal
# rail_size()[0]*ed*rail_size()[1] exactly (nothing else occupies that band
# in consumer_body -- the floor tops out at Z=ft, the probe starts there --
# so any deficit against the tongue's own volume is erosion by the keepout).
cat > "$tmp/interference_tongue_survives.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
u = 1;
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rw  = rack_support_rail_size()[0];
rs  = rack_support_rail_size();
ed  = rack_support_engagement_depth();
reach = rpy - ed;
slack = 0.1;
$(tray_body)
intersection() {
    difference() {
        consumer_body();
        translate([0, rpy, 0]) rack_support_plate_keepout();
    }
    translate([-rs[0]/2 - slack, rpy - ed, ft])
        cube([rs[0] + 2 * slack, ed, rs[1]]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/interference_tongue_survives.stl" "$tmp/interference_tongue_survives.scad" 2>/dev/null
python3 - "$tmp/interference_tongue_survives.stl" <<'PY' || { echo "keepout eroded the consumer's own tongue (paired assertion failed) -- rack_support_plate_keepout() is over-broad, must exactly exclude the channel cavity"; exit 1; }
import struct,sys
try:
    d=open(sys.argv[1],'rb').read()
except FileNotFoundError:
    sys.exit(1)
n=struct.unpack('<I',d[80:84])[0]; off=84
vol=0.0
for i in range(n):
    pts=[]
    for v in range(3):
        b=off+i*50+12+v*12
        pts.append(struct.unpack('<3f',d[b:b+12]))
    x1,y1,z1=pts[0]; x2,y2,z2=pts[1]; x3,y3,z3=pts[2]
    vol += (x1*(y2*z3-y3*z2) - y1*(x2*z3-x3*z2) + z1*(x2*y3-x3*y2))/6.0
vol = abs(vol)
want = 40 * 12 * 10  # rail_size()[0] * engagement_depth() * rail_size()[1]
sys.exit(0 if abs(vol - want) < 1.0 else 1)
PY

echo ok
