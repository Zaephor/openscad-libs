// bay-enclosure — parametric 1U/2U rack10 enclosure for a front-accessible bay
// device (5.25" optical / 3.5" bay accessory). Side-rail mount, open front cutout
// exposing the device face, rear #40 support tongue. Consumes drives/rack10/
// rack-support. Prints flat, support-free.
// Task 2 scope: scaffold + front rack panel + device-face cutout + fit-assert
// only. Floor/walls/side-rail mount/rear tongue are added in Task 3 (#41).
use <drives/drives.scad>;
use <rack10/rack10.scad>;

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
front_clearance = 1.0;     // gap around the device face in the front cutout

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

module bay_enclosure() {
    _be_faceplate();
    // floor + walls + side-rail mount + rear tongue added in Task 3
    // drive_placeholder(type) draws cube(drive_size(type)) in the DRIVE's own
    // datum frame: local X = length (front->rear insertion axis), local Y =
    // width, local Z = height (drives.scad header). The rack10/enclosure
    // frame used here is X = rack width (left/right), Y = rack depth
    // (front->rear), Z = up — i.e. the drive's length axis must land on rack
    // Y, and its width axis on rack X, NOT a direct 1:1 axis copy. rotate(
    // [0,0,90]) maps local (x,y) -> global (-y,x), so the rotated cube spans
    // global X in [-width,0] and Y in [0,length]; translating by +width/2 in
    // X re-centers it under the faceplate cutout (which is centered on
    // X=0, width _dw()). Confirmed by rendering: without this rotate the
    // drive's 200mm length axis splays across X (rack width) instead of Y
    // (rack depth), badly overshooting the cutout.
    % translate([_dw()/2, 0, floor_th]) rotate([0, 0, 90]) drive_placeholder(device_type);
}
bay_enclosure();
