// keystone/assembly.scad — keystone_insert()/keystone_cutout() mate demo +
// insertion-motion visualization (#31 Task 3). Geometric correctness gate
// for the mating insert: renders the assembled (seated) state, an
// insertion-motion sequence, and the bare front window/removal-slot, for
// both retention styles.
// Render: openscad -D 'view="mated"' -D 'style="lip"' assembly.scad
//         (or via .claude/skills/verify-scad-geometry)
//
// STAGE PARAM (motion view only): `stage` is a 0..1 scalar (or one of the
// keywords "hook"/"rotate"/"seated", mapped to 0/0.5/1) driving a SIMPLIFIED,
// non-kinematic 2-keyframe lerp of the insert's pose -- NOT a physical
// rotate-and-snap arc (that would need a real hinge simulation, out of scope
// for a virtual mate-reference). This is a deliberate, documented engineering
// simplification (#31 Task 3): good enough to *see* the motion and confirm
// no solid-body interference along the way, not a kinematic model.
//   "lip" (rotate-and-snap, per keystone_latch()/RESEARCH.md -- hook engages
//   near-flush first, then the body rotates in and the latch catches):
//     stage 0.0 "hook"   — insert tilted at an angle, backed off +Z, as if
//                          the hook has just found the pocket entrance and
//                          the (deeper) latch end is still swung clear.
//     stage 1.0 "seated" — tilt=0, normal keystone_insert() pose (identical
//                          to the "mated" view).
//     0 < stage < 1       — straight-line (linear) lerp of tilt angle + a
//                          along-axis withdraw offset between the two
//                          keyframes above, rotated about a pivot near the
//                          hook-pocket's own Z/Y position (see
//                          _keystone_insert_at_stage()). Illustrative only;
//                          the real mechanism's rotation arc is not this
//                          simple, per RESEARCH.md's "unmeasured" undercut
//                          note.
//   "face" (straight push-fit, no rotation): stage is a pure -Z insertion
//   depth lerp (0 = tip just clear of the front flange plane, 1 = fully
//   seated flush).
use <keystone/keystone.scad>;

function _stage_t(stage) =
    stage == "hook"   ? 0 :
    stage == "rotate" ? 0.5 :
    stage == "seated" ? 1 :
    stage; // assume numeric 0..1
function _lerp(a, b, t) = a + (b - a) * t;

// _keystone_frame(plate_thickness, clearance, style): the real consumer
// pattern documented in keystone_cutout()'s module comment -- union the boss
// into a representative faceplate swatch, then difference the cutout through
// both (boss is a no-op for "face"). Single source of truth for the "what
// does a real panel look like" question in every view below.
module _keystone_frame(plate_thickness = 3.0, clearance = 0.25, style = "lip") {
    plate_w = 40; plate_h = 40; // representative faceplate swatch, centered
    difference() {
        union() {
            translate([-plate_w/2, -plate_h/2, -plate_thickness])
                cube([plate_w, plate_h, plate_thickness]);
            keystone_boss(plate_thickness, clearance, style);
        }
        keystone_cutout(plate_thickness, clearance, style);
    }
}

// _keystone_insert_at_stage(): insert positioned per `stage` (see header).
module _keystone_insert_at_stage(plate_thickness, fit, style, stage) {
    t = _stage_t(stage);
    if (style == "lip") {
        l = keystone_latch(style); // [width,front_h,hook_z,hook_h,pocket_z,latch_z,latch_h]
        // Pivot near the hook-pocket's own Z/Y -- approximates "hook finds
        // its pocket first" by keeping that end roughly anchored while the
        // rest of the body swings in as tilt_deg -> 0.
        pivot_z = (l[2] + l[4]) / 2;
        pivot_y = l[3] - l[1]/2;
        tilt_deg = _lerp(-28, 0, t);  // 0=hook-engaged-at-angle .. 1=seated flush
        withdraw = _lerp(6, 0, t);    // extra +Z pull-out while tilted (angled entry)
        translate([0, 0, withdraw])
            translate([0, pivot_y, pivot_z])
                rotate([tilt_deg, 0, 0])
                    translate([0, -pivot_y, -pivot_z])
                        keystone_insert(plate_thickness, fit, style);
    } else { // "face": straight push-fit, no rotation
        depth = _lerp(8, 0, t); // 0=tip just clear of the flange plane, 1=seated flush
        translate([0, 0, depth])
            keystone_insert(plate_thickness, fit, style);
    }
}

// [Mated] — insert fully seated in a plate with the real cutout. The
// correctness gate: verify-scad-geometry must show the tabs engaging the
// lips with no solid-body interference.
module keystone_assembly_mated(plate_thickness = 3.0, clearance = 0.25, fit = 0.2, style = "lip") {
    _keystone_frame(plate_thickness, clearance, style);
    keystone_insert(plate_thickness, fit, style);
}

// [Motion] — insert at an arbitrary insertion `stage` (see header), same
// frame. Sweep `stage` 0->1 (or pass "hook"/"rotate"/"seated") to visualize
// the insertion sequence one static render at a time.
module keystone_assembly_motion(plate_thickness = 3.0, clearance = 0.25, fit = 0.2, style = "lip", stage = 1) {
    _keystone_frame(plate_thickness, clearance, style);
    _keystone_insert_at_stage(plate_thickness, fit, style, stage);
}

// [Removal slot] — the bare front window/cavity (frame only, no insert),
// for inspecting the cutout shape a jack is inserted through / removed from.
module keystone_assembly_removal_slot(plate_thickness = 3.0, clearance = 0.25, style = "lip") {
    _keystone_frame(plate_thickness, clearance, style);
}

/* [View] */
view = "mated"; // ["mated", "motion", "removal_slot"]
style = "lip";  // ["lip", "face"]

/* [Mate Params] */
plate_thickness = 3.0;
clearance = 0.25;
fit = 0.2;

/* [Insertion Motion — motion view only] */
stage = 1; // 0..1, or "hook"/"rotate"/"seated" via -D 'stage="hook"'

if (view == "mated") keystone_assembly_mated(plate_thickness, clearance, fit, style);
else if (view == "motion") keystone_assembly_motion(plate_thickness, clearance, fit, style, stage);
else if (view == "removal_slot") keystone_assembly_removal_slot(plate_thickness, clearance, style);
else assert(false, str("keystone assembly: unknown view '", view, "'"));
