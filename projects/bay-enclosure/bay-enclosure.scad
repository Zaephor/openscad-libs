// bay-enclosure — parametric 1U/2U rack10 enclosure for a front-accessible bay
// device (5.25" optical / 3.5" bay accessory). Side-rail mount, open front cutout
// exposing the device face, rear #40 support tongue. Consumes drives/rack10/
// rack-support. Prints flat (Z = build height, walls vertical), support-free.
// Task 2: scaffold + front rack panel + device-face cutout + fit-assert.
// Task 3 (#41): floor + side walls w/ device side-mount holes + a 45deg rear
// buttress ramp + rear rack-support (#40) tongue mate. (No front root gusset:
// see bay_enclosure()'s "Front floor/faceplate joint" comment below for why
// one doesn't fit there.)
// Task 4 (#41): three device presets locked -- bay525_hh->device_u=1
// [default], bay525_fh->device_u=2, bay35->device_u=1 -- checked in
// tests/test_bay_enclosure.sh (default + -D override renders) plus the
// tests/asserts.scad negative control; see README.md for the full design
// writeup + preset table.
// Part B review fix (#41): the front cutout now opens to the FULL interior
// height budget (_int_h()), not just the device's own height (_dh()) -- see
// _be_faceplate()'s comment below for why (eliminates an unsupported
// bridge above the device on the two presets with real height headroom).
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
front_clearance = 1.0;     // side (width-only) gap around the device face; height cutout spans the full interior budget (flush at the floor, open to the panel top), see _be_faceplate()

assert(len([for (t = drive_known_types()) if (t == device_type && drive_family(t) == "block") t]) > 0,
    str("bay-enclosure: device_type '", device_type, "' must be a block drive"));

function _dsz()   = drive_size(device_type);   // [len, width, height] — X=length(depth), Y=width, Z=height
function _dlen()  = _dsz()[0];
function _dw()    = _dsz()[1];
function _dh()    = _dsz()[2];
function _clear() = rack10_clear_width(standard);
function _int_h() = rack10_device_height(device_u) - floor_th;

// Fit-asserts (width + height; depth in T3 with rear-post-Y).
// The device itself (not the cutout -- see _be_faceplate(), which opens to
// the full _int_h() regardless) must fit within the interior budget, flush
// on the floor with no headroom allowance above it (no front_clearance on
// this axis), so the gate is exactly _dh() <= _int_h().
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
        // Height spans the FULL interior budget (_int_h() = this preset's
        // rack10_device_height(device_u) minus floor_th) -- from the floor
        // line (Z=floor_th) up to the panel's own top (Z=rack10_device_height
        // (device_u)) -- NOT just the device's own height (_dh()).
        // Sizing the cutout to _dh() alone (a prior revision of this
        // comment/code) is correct ONLY at presets where the device fills
        // essentially the whole interior budget (bay525_hh@1U: 42.3mm device
        // vs. 42.46mm interior, ~0.16mm margin). At the other two LOCKED
        // presets there's real headroom above the device (bay525_fh@2U:
        // 82.55mm device vs. 86.91mm interior; bay35@1U: 25.4mm device vs.
        // 42.46mm interior), and a cutout stopping at _dh() would leave a
        // solid strip of faceplate material spanning the cutout's full
        // WIDTH between the top of the device and the top of the panel, with
        // nothing under it -- an unsupported horizontal bridge (a real
        // review finding: ~148mm wide x 4.36mm thick at bay525_fh@2U, ~104mm
        // wide x 17.06mm thick at bay35@1U -- PETG, this project's material,
        // bridges poorly well short of spans that wide). Opening the cutout
        // all the way to the panel's own top removes that strip entirely:
        // there is no faceplate material left spanning across the opening
        // above the device, so there is nothing left to bridge.
        // The device itself still sits flush on the floor (bottom edge
        // unchanged, Z=floor_th) -- only the cutout's TOP edge moves. Where
        // the device is shorter than the interior budget, more interior is
        // simply visible through the opening above it; that's fine/
        // intentional, not a defect. front_clearance still means side-edge
        // (width) clearance only, not top/bottom -- the cutout's vertical
        // extent is driven by the interior budget, not a padded device
        // height, so there is no equivalent "height clearance" concept here.
        translate([-(_dw()/2 + front_clearance), -faceplate_th - 1, floor_th])
            cube([_dw() + 2*front_clearance, faceplate_th + 2, _int_h()]);
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
    ramp_margin_min = 3;                        // sanity minimum: flat floor-run (Y=0..ramp_y0) before the rear ramp must be at least this deep
    assert(ramp_y0 > ramp_margin_min,
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

            // Front floor/faceplate joint: NO gusset here, on purpose --
            // (this used to be a wall-X-band-only wedge; removed after
            // review found it a geometric no-op, ~0.023mm^3 out of
            // ~112290mm^3 exported volume, i.e. nothing. Root cause: at the
            // wall's own X-band, the wall cube below already spans the FULL
            // Y=[0,rpy] x Z=[0,device height] volume for that X-band, and
            // floor_th < device height, so the floor's [0,floor_th] slab is
            // already a strict subset of the wall's own solid there -- one
            // contiguous block, not two members meeting at a joint. A
            // wall-band gusset literally has nothing to brace.)
            //
            // The joint that WOULD need bracing is the CENTER strip (under
            // the device, X in [-_dw()/2,_dw()/2]): there the floor's top
            // face (Z=floor_th) is exposed to air and meets the faceplate's
            // back face (Y=0) at a sharp, unfilled interior corner, same
            // shape as the rear buttress's problem. But it can't be fixed
            // the same way: _be_device_frame() parks the device's underside
            // at EXACTLY Z=floor_th (zero clearance, by design -- see that
            // module's header comment), so there is zero headroom above the
            // floor in this X-band for ANY raised material -- not "thin",
            // literally none. Any wedge/fillet/chamfer that rises even
            // slightly above floor_th here fouls the device fit. So this
            // corner is left unbraced: it's an inherent consequence of the
            // zero-clearance device fit this project targets, not an
            // oversight, and there's no self-supporting geometry that both
            // adds real material and respects that clearance.

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
