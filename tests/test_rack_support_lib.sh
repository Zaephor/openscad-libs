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
    rh = rack_support_rail_size()[1];   // tongue height == root-gusset rise == run (45deg)
    union() {
        translate([-rack10_panel_width(standard)/2, -3, 0])
            cube([rack10_panel_width(standard), 3, rack10_device_height(u)]);
        translate([-rw/2, 0, 0]) cube([rw, rpy, ft]);
        // 45deg tongue-root gusset, mirroring assembly.scad's own (and the
        // README consumer contract's "45deg root gussets at ...
        // tongue-to-body junctions"). Load-bearing for check (c) below: the
        // keep-out necessarily deletes the floor under the tongue's whole
        // engagement span (the plate's bearing floor lives there), so this
        // gusset -- forward of the root, where the plate never reaches -- is
        // what keeps the tongue attached to the body at all.
        _rack_support_yz_prism([[reach - rh, ft], [reach, ft], [reach, ft + rh]], rw);
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
# [ft,ft+rail_size()[1]]) and require its volume equal the SAME band
# intersected with a lone reference rack_support_tongue() at the same
# placement (rendered separately below) -- not a hand-computed literal
# (single source of truth: the expected volume comes from the accessor-
# driven module itself, same as the actual volume under test).
cat > "$tmp/interference_tongue_survives.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
u = 1;
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rs  = rack_support_rail_size();
rw  = rs[0];
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

# Reference volume for the comparison above: the SAME probe band intersected
# with a lone, undamaged rack_support_tongue() at the same placement (no
# keepout involved) -- this is the "what a fully-surviving tongue in this
# band looks like" ground truth, derived from the accessor-driven module,
# not a re-literaled number.
cat > "$tmp/tongue_reference.scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rs  = rack_support_rail_size();
ed  = rack_support_engagement_depth();
reach = rpy - ed;
slack = 0.1;
intersection() {
    translate([0, reach, 0]) rack_support_tongue();
    translate([-rs[0]/2 - slack, rpy - ed, ft])
        cube([rs[0] + 2 * slack, ed, rs[1]]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/tongue_reference.stl" "$tmp/tongue_reference.scad" 2>/dev/null

python3 - "$tmp/interference_tongue_survives.stl" "$tmp/tongue_reference.stl" <<'PY' || { echo "keepout eroded the consumer's own tongue (paired assertion failed) -- rack_support_plate_keepout() is over-broad, must exactly exclude the channel cavity"; exit 1; }
import struct,sys

def stl_volume(path):
    try:
        d = open(path, 'rb').read()
    except FileNotFoundError:
        return 0.0
    n = struct.unpack('<I', d[80:84])[0]; off = 84
    vol = 0.0
    for i in range(n):
        pts = []
        for v in range(3):
            b = off + i*50 + 12 + v*12
            pts.append(struct.unpack('<3f', d[b:b+12]))
        x1,y1,z1 = pts[0]; x2,y2,z2 = pts[1]; x3,y3,z3 = pts[2]
        vol += (x1*(y2*z3-y3*z2) - y1*(x2*z3-x3*z2) + z1*(x2*y3-x3*y2)) / 6.0
    return abs(vol)

actual = stl_volume(sys.argv[1])
want   = stl_volume(sys.argv[2])
sys.exit(0 if want > 0 and abs(actual - want) < 1.0 else 1)
PY

# (c) CONNECTIVITY -- the missing half of (b). (b) measures the tongue's
# VOLUME inside its own band, which the cavity exclusion preserves exactly;
# it says nothing about whether the tongue is still ATTACHED to the body. It
# is blind to detachment by construction, and detachment really happened: an
# earlier rack_support_plate_keepout() grew its floor slab by margin in -Y
# and +-X while (correctly) never growing the cavity exclusion, which carved
# a margin-wide moat around the cavity's footprint -- exactly the material
# joining the tongue to the rest of the tray. Measured on this same reference
# shape: one solid at margin=0, TWO at margin=0.1 and 0.2, the second being
# the tongue plus its 4804.80mm^3 band (tongue + eps film), severed.
#
# CGAL's own render-summary "Volumes:" line is the cheapest reliable probe
# here (same line tests/test_bay_enclosure.sh's side-hole counter already
# reads). It counts the unbounded outer volume too, so ONE solid reports
# "Volumes: 2" and a tongue split off reports 3 -- calibrated against this
# exact geometry, not assumed: on the GUSSET-LESS tray this printed 2 / 3 / 3
# for margins 0 / 0.1 / 0.2 pre-fix and prints 2 / 2 / 2 now.
#
# SCOPE, measured rather than assumed: with the root gusset now present (it
# lives above Z=ft, where a moat confined to Z in [0,ft] cannot reach), the
# PRE-FIX keep-out also reports 2 at margins 0.1/0.2 -- verified directly
# against the pre-fix module. So this check is a general "tongue is still
# attached" guard against a keep-out that grows into the moat band, NOT a
# sharp guard against the moat itself -- check (d) below is the one that
# fails on the pre-fix geometry, and is why (c) alone is not enough.
#
# This check does NOT catch a lost root gusset either, and that is not a
# hypothetical: once the margin clamp closes the moat (post-fix library),
# the shelf reconnects to the tongue across the real 2D face at Y=reach on
# its own, gusset or no gusset. Verified by negative control -- deleting the
# gusset call from a consumer and re-rendering against THIS post-fix library
# still reports Volumes: 2 here, even though the tongue's first printed
# layer collapses back to an isolated, unanchored island (see the actual
# C1 claim, checked below by (e)). Nonzero margins are exercised anyway: at
# margin=0 there is no moat to carve at all, so a margin-0-only check
# proves nothing about margin.
check_tray_connectivity() { # <margin>
  local m="$1"
  local scad="$tmp/connectivity_$m.scad"
  cat > "$scad" <<EOF
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;
standard = "labrax";
u = 1;
rpy = rack10_rear_post_y(standard);
ft  = rack_support_floor_thickness();
rw  = rack_support_rail_size()[0];
reach = rpy - rack_support_engagement_depth();
$(tray_body)
difference() {
    consumer_body();
    translate([0, rpy, 0]) rack_support_plate_keepout($m);
}
EOF
  local out volumes
  out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/connectivity_$m.stl" "$scad" 2>&1)"
  volumes="$(echo "$out" | grep -o 'Volumes:[[:space:]]*[0-9]*' | tail -1 | grep -o '[0-9]*$')"
  if [ -z "$volumes" ]; then
    echo "connectivity check at margin=$m produced no CGAL Volumes: line -- cannot verify the tongue is still attached:"
    echo "$out"; exit 1
  fi
  if [ "$volumes" -ne 2 ]; then
    echo "rack_support_plate_keepout($m) DETACHED the consumer's tongue -- CGAL reports Volumes: $volumes (want 2, i.e. a single solid). margin must not carve a moat around the channel cavity's footprint; see that module's doc."
    exit 1
  fi
}
check_tray_connectivity 0
check_tray_connectivity 0.1
check_tray_connectivity 0.2

# (d) MARGIN CONTAINMENT -- the sharp guard on the invariant that makes (c)
# hold for any consumer, gusset or not: margin may only inflate the keep-out
# AWAY from the channel cavity's own XY footprint, never into the ring of
# consumer material surrounding it (see rack_support_plate_keepout()'s doc).
# Both probes below discriminate against the pre-fix module by a wide, verified
# margin, so a reintroduced moat fails here even though (c) would not.
#
# (d1) No -Y growth: the keep-out's rearmost forward reach is the plate's own
# mouth plane, Y=-engagement_depth(), for EVERY margin. Pre-fix this measured
# -12.201 at margin=0.2 (= -ed - margin - hull-sphere slack); it now measures
# -12.001. The 0.05 tolerance covers _rack_support_yz_prism()'s 0.001 sphere
# radius while leaving the pre-fix value failing by 4x the tolerance.
for m in 0 0.1 0.2; do
  cat > "$tmp/keepout_ymin_$m.scad" <<EOF
use <rack-support/rack-support.scad>;
echo(rack_support_engagement_depth());
rack_support_plate_keepout($m);
EOF
  out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/keepout_ymin_$m.stl" "$tmp/keepout_ymin_$m.scad" 2>&1)"
  ed="$(echo "$out" | grep -oE 'ECHO: [0-9.]+' | grep -oE '[0-9.]+')"
  python3 - "$tmp/keepout_ymin_$m.stl" "$ed" <<'PY' || { echo "rack_support_plate_keepout() reaches past the plate's mouth plane (Y=-engagement_depth()) -- margin is carving a -Y moat at the tongue root; see (d1) above"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
ed=float(sys.argv[2])
ys=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12
        ys.append(struct.unpack('<3f',d[b:b+12])[1])
sys.exit(0 if min(ys) > -ed - 0.05 else 1)
PY
done

# (d2) No +-X growth of the bearing-floor slab: near the mouth the 45deg wedge
# has almost no height, so the slab alone sets the keep-out's X extent there.
# Probe a box just OUTSIDE the cavity's own half-width (slot_w/2 + 0.02, i.e.
# inside what margin=0.2 used to add) in that mouth band, below the cavity's
# own Z-floor so the cavity exclusion cannot be what empties it -- must be
# EMPTY, same "is empty" idiom as the cavity/hole probes above. Pre-fix this
# probe measured 0.0288mm^3 of keep-out material.
cat > "$tmp/keepout_xmoat.scad" <<'EOF'
use <rack-support/rack-support.scad>;
rs = rack_support_rail_size();
cl = rack_support_slot_clearance();
ed = rack_support_engagement_depth();
ft = rack_support_floor_thickness();
slot_w = rs[0] + 2 * cl;
intersection() {
    rack_support_plate_keepout(0.2);
    translate([slot_w/2 + 0.02, -ed + 0.1, ft - 0.5]) cube([0.16, 0.4, 0.45]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/keepout_xmoat.stl" "$tmp/keepout_xmoat.scad" 2>&1)"
if [ -f "$tmp/keepout_xmoat.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "rack_support_plate_keepout(0.2) extends past the channel cavity's own half-width near the mouth -- margin is carving a +-X moat along the tongue's flanks; see (d2) above:"
  echo "$out"; exit 1
fi

# (e) GUSSET REGRESSION GUARD -- neither (c) nor (d) verifies the actual C1
# claim (final-fix re-review, Important #1): material anchoring the
# tongue's first printed layer at its root. Verified by negative control
# in this checkout: once the margin clamp closes the moat, deleting
# consumer_body()'s own root gusset (the _rack_support_yz_prism() call in
# tray_body() above) still passes (c) at every margin -- the shelf
# reconnects to the tongue across the real 2D face at Y=reach on its own,
# so Volumes: 2 holds with or without the gusset. (c)/(d) are therefore no
# regression guard at all for a silently-lost gusset; this probe is.
#
# Probe the anchor band directly behind the tongue root, in the tongue's
# first printed layer above the bearing floor: X +-rail_size()[0]/2, Y
# [reach-2,reach] (forward of the tongue itself, which starts at Y=reach --
# only the gusset can put material here), Z [ft,ft+0.2]. A fully-solid
# band would be rw*2*0.2 = 16.0mm^3; require most of that (>8.0mm^3, well
# above the 0mm^3 a missing gusset leaves and well below the true value, so
# neither hull()-sphere slack nor mesh noise can cause a false pass). This
# checks consumer_body() alone, not the margin-differenced body: the
# gusset is a per-consumer obligation this library cannot build itself
# (see the README consumer contract), only detect the absence of in a
# reference consumer -- margin plays no part in whether it exists.
cat > "$tmp/gusset_anchor.scad" <<EOF
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
    consumer_body();
    translate([-rw/2, reach - 2, ft]) cube([rw, 2, 0.2]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/gusset_anchor.stl" "$tmp/gusset_anchor.scad" 2>/dev/null
python3 - "$tmp/gusset_anchor.stl" <<'PY' || { echo "tongue-root anchor band (X +-rail_size()[0]/2, Y[reach-2,reach], Z[ft,ft+0.2]) has too little material -- the 45deg root gusset that anchors the tongue's first printed layer appears to be missing or shrunk; see (e) above"; exit 1; }
import struct,sys
def stl_volume(path):
    try:
        d = open(path, 'rb').read()
    except FileNotFoundError:
        return 0.0
    n = struct.unpack('<I', d[80:84])[0]; off = 84
    vol = 0.0
    for i in range(n):
        pts = []
        for v in range(3):
            b = off + i*50 + 12 + v*12
            pts.append(struct.unpack('<3f', d[b:b+12]))
        x1,y1,z1 = pts[0]; x2,y2,z2 = pts[1]; x3,y3,z3 = pts[2]
        vol += (x1*(y2*z3-y3*z2) - y1*(x2*z3-x3*z2) + z1*(x2*y3-x3*y2)) / 6.0
    return abs(vol)
sys.exit(0 if stl_volume(sys.argv[1]) > 8.0 else 1)
PY

echo ok
