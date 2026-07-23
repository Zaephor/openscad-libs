// bay-enclosure — parametric 1U/2U rack10 enclosure for a front-accessible bay
// device (5.25" optical / 3.5" bay accessory). Side-rail mount, open front cutout
// exposing the device face, rear #40 support tongue. Consumes drives/rack10/
// rack-support. Prints flat (Z = build height, walls vertical), support-free.
// Task 2: scaffold + front rack panel + device-face cutout + fit-assert.
// Task 3 (#41): floor + side walls w/ device side-mount holes + 45deg root
// gussets + rear rack-support (#40) tongue mate.
use <drives/drives.scad>;
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;

/* [Rack] */
standard = "labrax";
device_u = 1;
ear_type = "slot";
/* [Device] */
device_type = "bay525_hh"; // bay525_hh | bay525_fh | bay35
/* [Print] */
wall = 2.4;
// Floor thickness eaten out of the device_u height budget (this project has
// no top lid — the device's own top is the enclosure's topmost feature, so
// only the floor, not a floor+lid pair like bpir4, subtracts from the U
// pitch). Kept deliberately thin (vs. bpir4's/rack-support's 2.0mm
// convention): bay525_hh (H=42.3, drives lib) vs. rack10_device_height(1)
// (43.66) leaves only ~1.36mm of total headroom for ANY floor under the
// tightest preset (bay525_hh -> device_u=1, locked in the design spec) —
// 2.0mm simply does not fit. 1.2mm is a commonly-cited minimum solid-floor
// thickness for FDM (~3 layers at 0.4mm) and clears bay525_hh with a thin
// but real margin. Per the rack-support (#40) consumer contract, the
// REAR-most engagement_depth() of floor is allowed to be thicker (ramped up
// via a 45deg buttress to rack_support_floor_thickness()=2 where the tongue
// mates) — that ramp is Task 3's job, not this uniform Task 2 default.
floor_th = 1.2;
faceplate_th = 3.0;
front_clearance = 1.0;     // side (width-only) gap around the device face; height cutout is flush top+bottom, see _be_faceplate()

assert(len([for (t = drive_known_types()) if (t == device_type && drive_family(t) == "block") t]) > 0,
    str("bay-enclosure: device_type '", device_type, "' must be a block drive"));

function _dsz()   = drive_size(device_type);   // [len, width, height] — X=length(depth), Y=width, Z=height
function _dlen()  = _dsz()[0];
function _dw()    = _dsz()[1];
function _dh()    = _dsz()[2];
function _clear() = rack10_clear_width(standard);
function _int_h() = rack10_device_height(device_u) - floor_th;

// Fit-asserts (width + height; depth in T3 with rear-post-Y).
// Height cutout is flush top AND bottom (no front_clearance on this axis —
// see _be_faceplate()), so the gate is exactly _dh() <= _int_h().
assert(_dh() <= _int_h() + 1e-6,
    str("bay-enclosure: device height ", _dh(), " > ", device_u, "U interior ", _int_h(),
        " (increase device_u)"));
assert(_dw() <= _clear() - 2*wall + 1e-6,
    str("bay-enclosure: device width ", _dw(), " > usable ", _clear() - 2*wall));

// Depth fit-assert (device length vs. rack10's rear-post depth budget, minus
// the tongue's own engagement land AND this project's faceplate thickness --
// a deliberately conservative margin, not the tight structural minimum: the
// floor/walls/tongue themselves are placed by the rack-support (#40)
// consumer-contract formula directly against rack10_rear_post_y(), below,
// not against this reduced figure -- this assert exists only to keep the
// device itself from being sized so long it leaves no depth margin at all).
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();
assert(_dlen() <= _usable_depth() + 1e-6,
    str("bay-enclosure: device depth ", _dlen(), " > usable ", _usable_depth(),
        " for ", standard));

// Front rack panel with a large open cutout to the device face.
module _be_faceplate() {
    difference() {
        translate([-rack10_panel_width(standard)/2, -faceplate_th, 0])
            cube([rack10_panel_width(standard), faceplate_th, rack10_device_height(device_u)]);
        // ear holes
        if (ear_type == "slot")
            rack10_holes(standard, device_u, hole_type="slot", dia=rack10_screw_clearance("10-32"));
        else rack10_holes(standard, device_u, hole_type=ear_type);
        // device-face cutout (centered on width, resting on the floor line).
        // Height is flush top AND bottom (cutout height is exactly _dh(),
        // no front_clearance): the default preset has near-zero height
        // margin (~0.16mm), and front_clearance has only ever meant
        // side-edge (width) clearance for the two edges a hand reaches
        // around — not top/bottom. Width keeps its existing symmetric
        // 2*front_clearance.
        translate([-(_dw()/2 + front_clearance), -faceplate_th - 1, floor_th])
            cube([_dw() + 2*front_clearance, faceplate_th + 2, _dh()]);
    }
}

// Device datum -> enclosure-frame transform. drive_placeholder(type) draws
// cube(drive_size(type)) in the DRIVE's own datum frame: local X = length
// (front->rear insertion axis), local Y = width, local Z = height
// (drives.scad header). The rack10/enclosure frame used here is X = rack
// width (left/right), Y = rack depth (front->rear), Z = up — i.e. the
// drive's length axis must land on rack Y, and its width axis on rack X, NOT
// a direct 1:1 axis copy. rotate([0,0,90]) maps local (x,y) -> global
// (-y,x), so the rotated cube spans global X in [-width,0] and Y in
// [0,length]; translating by +width/2 in X re-centers it under the
// faceplate cutout (which is centered on X=0, width _dw()), and +floor_th in
// Z lands it on the floor's top face. Confirmed by rendering: without this
// rotate the drive's 200mm length axis splays across X (rack width) instead
// of Y (rack depth), badly overshooting the cutout.
// Single source of truth for this transform: drive_holes(...,"side") (the
// side-mount-hole cutter, in bay_enclosure() below) is applied through the
// SAME module, so the cut holes can never drift out of alignment with the
// placeholder/real device sitting on this same datum.
module _be_device_frame() {
    translate([_dw()/2, 0, floor_th]) rotate([0, 0, 90]) children();
}

// 45deg self-supporting wedge gusset: a right-triangle prism extruded along
// X between x0 and x1, built from `pts` (a list of 2+ [Y,Z] points -- a
// plain 2-point right-angle pair is enough; a 3rd point is only needed for
// a non-right-angle triangle) as hull() of tiny-sphere end triangles.
// Mirrors rack-support's own _rack_support_yz_prism idiom: a triangular
// prism IS the convex hull of its 6 vertices, so this is correct for any
// winding of `pts`, and self-supporting as long as the shape's footprint
// shrinks monotonically going up in Z (true for every call site below —
// each is a right triangle with its long, wide edge at the bottom).
module _be_yz_wedge(pts, x0, x1) {
    hull()
        for (p = pts)
            for (x = [x0, x1])
                translate([x, p[0], p[1]]) sphere(r = 0.001, $fn = 6);
}

module bay_enclosure() {
    _be_faceplate();

    // --- floor + side walls + root gussets + rear #40 support tongue ---
    ft      = rack_support_floor_thickness();   // tongue's bearing-floor datum (2mm) -- see rack-support README consumer contract
    ed      = rack_support_engagement_depth();  // tongue insertion depth (12mm)
    rpy     = rack10_rear_post_y(standard);     // rear post plane == rack_support_plate()'s own mounting Y
    reach   = rpy - ed;                         // tongue ROOT, per rack-support's consumer-contract placement formula (root = rear_post_y - engagement_depth; tip lands exactly at rear_post_y)
    ramp    = ft - floor_th;                    // rise the floor must gain before the tongue root; ramp run == rise -> 45deg
    ramp_y0 = reach - ramp;                     // where the floor begins ramping from floor_th up to ft
    fw      = _dw() + 2 * wall;                 // overall floor/wall-pair width
    fx0     = -(_dw() / 2 + wall);              // floor's/left-wall's outer-X origin
    gusset_leg = 3;                             // front root-gusset leg (Y and Z) -- modest brace, sized to clear the device envelope (see call site)
    assert(ramp_y0 > gusset_leg,
        "bay-enclosure: usable depth too short for the tongue's buttress ramp");

    difference() {
        union() {
            // Floor: spans the full depth, front (Y=0, just behind the
            // faceplate) through to the rear post plane (rpy) — NOT just
            // under the device. Running it all the way to rpy means its
            // rear end fully OVERLAPS the tongue's own footprint (a real 2D
            // face, not merely an edge) — see rack-support's own
            // assembly.scad "FLOOR-LENGTH note": a floor that stops exactly
            // at the tongue's near face meets it only along a 1D edge,
            // which CGAL reports as non-manifold; extending the floor under
            // the tongue's whole Y-span (as done here) is the proven fix.
            translate([fx0, 0, 0]) cube([fw, rpy, floor_th]);

            // Rear buttress: rack-support's (#40) consumer contract requires
            // the tongue's underside (Z=ft) be met by solid floor with no
            // unsupported gap — this project's own floor is thinner
            // (floor_th) than that bearing datum (ft), so it must ramp up
            // first. 45deg wedge (ramp run == ramp rise == ft-floor_th) from
            // ramp_y0 up to the tongue root (reach), then a flat ft-thick
            // shelf under the tongue's whole engagement span (reach..rpy).
            // Built full floor-width (not tongue-width) — this whole region
            // sits behind the device's own length for every current preset
            // (see _usable_depth()'s assert above), so there's no device
            // clearance to protect here; the extra bearing width is free
            // structure, not a fit risk.
            translate([fx0, 0, 0]) {
                _be_yz_wedge([[ramp_y0, floor_th], [reach, floor_th], [reach, ft]], 0, fw);
                translate([0, reach, floor_th]) cube([fw, rpy - reach, ft - floor_th]);
            }

            // Front root gusset: brace the floor/faceplate corner (a plain
            // butt joint otherwise — design-for-print's "gusset a
            // cantilevered arm's root joint" guidance). Confined to the
            // wall's own X-band (not the full floor width): a gusset
            // spanning under the device's own footprint would stand proud
            // of the floor's top face (Z>floor_th) exactly where the device
            // sits flush against it (X in [-_dw()/2,_dw()/2], zero
            // clearance by design — see _be_device_frame()) and foul the
            // fit; restricting it to the wall bands braces the same corner
            // (and incidentally the wall's own root) without that conflict.
            // 45deg (leg==leg); self-supporting, same wedge family as the
            // rear buttress above.
            for (sx = [-1, 1]) {
                wx0 = sx > 0 ? _dw() / 2 : -(_dw() / 2 + wall);
                translate([wx0, 0, 0])
                    _be_yz_wedge([[0, floor_th], [0, floor_th + gusset_leg], [gusset_leg, floor_th]], 0, wall);
            }

            // Side walls, device_u tall, running the full floor depth (ties
            // them into the rear buttress/tongue area for a stiffer closed
            // channel, rather than stopping at the device's own length).
            // Each wall spans Z in [0, device height], i.e. it already
            // shares the floor's own Z in [0,floor_th] band across its
            // whole length — the two are one contiguous solid there, not a
            // thin free-standing fin butted onto a floor, so no separate
            // wall-root gusset is needed (unlike the front corner above,
            // where the faceplate is a genuinely separate solid).
            for (sx = [-1, 1])
                translate([sx > 0 ? _dw() / 2 : -(_dw() / 2 + wall), 0, 0])
                    cube([wall, rpy, rack10_device_height(device_u)]);
        }
        // Device SIDE mount holes, cut through both walls in one call via
        // the same datum transform the placeholder uses (single source of
        // truth — see _be_device_frame()). The cutter's Z lands well above
        // the floor/gusset/buttress material (device side-hole Z + floor_th
        // clears all of it), so this single difference() only ever removes
        // material from the walls, never the floor.
        _be_device_frame() drive_holes(device_type, faces = "side", depth = 2 * wall + 2);
    }

    // Rear #40 support tongue — placement formula per rack-support's own
    // README consumer contract: tip lands at rpy (rack_support_plate()'s own
    // mounting plane), root sits engagement_depth() forward of that.
    translate([0, reach, 0]) rack_support_tongue();

    _be_device_frame() % drive_placeholder(device_type);
}
bay_enclosure();
