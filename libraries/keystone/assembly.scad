// keystone/assembly.scad — keystone_insert()/keystone_cutout() mate demo +
// insertion-motion visualization (#38 Task 3). Geometric correctness gate for
// the mating insert: renders the assembled (seated) state, an insertion-motion
// sequence, and the bare front window/removal-slot, for both retention styles.
// Render: openscad -D 'view="mated"' -D 'style="standard"' assembly.scad
//         (or via .claude/skills/verify-scad-geometry)
//
// STAGE PARAM (motion view only): `stage` is a 0..1 scalar (or one of the
// keywords "hook"/"mid"/"seated", mapped to 0/0.5/1 waypoints). This is a
// SIMPLIFIED, non-kinematic pose lerp -- enough to SEE the motion and confirm
// no solid-body interference along the way, not a physical spring simulation.
//   "standard" (#38, push-to-click -- RESEARCH.md "Standard keystone latch
//   geometry": the jack is presented near-flush and pushed STRAIGHT in; the
//   flexing arm's notch deflects inward to clear the channel wall and springs
//   into its slit at depth -- no tilt/rotate, both notches at the same depth):
//     stage 0.0 "hook"    — insert backed off in +Z, clear of the panel, both
//                           notches deflected inward (ready to enter the mouth).
//     0 < stage < ~0.85   — straight -Z push: the body slides into the mouth
//                           with notches held deflected (they clear the wall
//                           bridges), no rotation.
//     ~0.85 < stage < 1.0 — at full insertion depth the notches spring back OUT
//                           into their top/bottom wall-slits (the click).
//     stage 1.0 "seated"  — relaxed, notches engaged (identical to "mated").
//   This replaces the superseded #31 "lip" rotate-and-snap arc, whose swinging
//   body solid-overlapped the frame mid-sweep (the clip bug this task fixes).
//   The rigid fulcrum notch's modeled inward deflection is a non-kinematic
//   stand-in for its triangular ramp camming past the wall (see
//   keystone_insert()'s "standard" comment).
//   "face" (straight push-fit, no rotation): the SAME collision-free model --
//   straight -Z push (0 = backed off clear of the panel, 1 = seated flush) with
//   the +Y hook / -Y latch bump deflected inward during travel (clearing the
//   plate) and springing to their plate-thickness grip at seat. The retention
//   SHAPE is the pre-#28 model, unchanged; only the motion now retracts the
//   tabs so the sweep is collision-free (matching "standard"'s strict no-clip
//   bar, per the #38 Task-3 review).
use <keystone/keystone.scad>;

function _stage_t(stage) =
    stage == "hook"   ? 0 :
    stage == "mid"    ? 0.5 :
    stage == "seated" ? 1 :
    stage; // assume numeric 0..1
function _lerp(a, b, t) = a + (b - a) * t;

// _keystone_frame(plate_thickness, clearance, style): the real consumer
// pattern documented in keystone_cutout()'s module comment -- union the boss
// into a representative faceplate swatch, then difference the cutout through
// both (boss is a no-op for "face"). Single source of truth for the "what does
// a real panel look like" question in every view below.
module _keystone_frame(plate_thickness = 3.0, clearance = 0.25, style = "standard") {
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
// BOTH styles share one collision-free model: a straight -Z push-in with the
// retention features (standard's fulcrum/arm notches; face's hook + latch bump)
// deflected inward during travel so they clear the panel, springing to their
// seated grip only at the end. Differs from the superseded #31 rotate-and-snap
// arc, whose swinging body clipped the frame mid-sweep.
module _keystone_insert_at_stage(plate_thickness, fit, style, stage, flex_side = "top") {
    t = _stage_t(stage);
    s = _keystone_resolve_style(style);
    z_start = (s == "standard") ? 11 : 8;      // backed-off distance at stage 0
    p_ins   = min(t / 0.85, 1);                // straight-in progress (done by ~0.85)
    z_off   = _lerp(z_start, 0, p_ins);
    defl    = t <= 0.85 ? 1 : _lerp(1, 0, (t - 0.85) / 0.15); // spring/click at the end
    translate([0, 0, z_off])
        keystone_insert(plate_thickness, fit, s, flex_side, defl);
}

// [Mated] — insert fully seated in a plate with the real cutout. The
// correctness gate: verify-scad-geometry must show the notches engaging the
// slits with no solid-body interference.
module keystone_assembly_mated(plate_thickness = 3.0, clearance = 0.25, fit = 0.2, style = "standard", flex_side = "top") {
    _keystone_frame(plate_thickness, clearance, style);
    keystone_insert(plate_thickness, fit, style, flex_side, 0);
}

// [Motion] — insert at an arbitrary insertion `stage` (see header), same frame.
// Sweep `stage` 0->1 (or pass "hook"/"mid"/"seated") to visualize the
// insertion sequence one static render at a time.
module keystone_assembly_motion(plate_thickness = 3.0, clearance = 0.25, fit = 0.2, style = "standard", stage = 1, flex_side = "top") {
    _keystone_frame(plate_thickness, clearance, style);
    _keystone_insert_at_stage(plate_thickness, fit, style, stage, flex_side);
}

// [Removal slot] — the bare front window/cavity (frame only, no insert), for
// inspecting the cutout shape a jack is inserted through / removed from.
module keystone_assembly_removal_slot(plate_thickness = 3.0, clearance = 0.25, style = "standard") {
    _keystone_frame(plate_thickness, clearance, style);
}

/* [View] */
view = "mated"; // ["mated", "motion", "removal_slot"]
style = "standard";  // ["standard", "face"]

/* [Mate Params] */
plate_thickness = 3.0;
clearance = 0.25;
fit = 0.2;
flex_side = "top"; // ["top", "bottom"]

/* [Insertion Motion — motion view only] */
stage = 1; // 0..1, or "hook"/"mid"/"seated" via -D 'stage="hook"'

if (view == "mated") keystone_assembly_mated(plate_thickness, clearance, fit, style, flex_side);
else if (view == "motion") keystone_assembly_motion(plate_thickness, clearance, fit, style, stage, flex_side);
else if (view == "removal_slot") keystone_assembly_removal_slot(plate_thickness, clearance, style);
else assert(false, str("keystone assembly: unknown view '", view, "'"));
