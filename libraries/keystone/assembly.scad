// keystone/assembly.scad — keystone_insert() + keystone_cutout()/boss()
// consumer-pattern demo (#38, updated #54). check.sh compiles this file with
// its own Customizer defaults below.
// Render: openscad -D 'view="mated"' -D 'style="standard"' assembly.scad
//         (or via .claude/skills/verify-scad-geometry)
//
// #54 STATUS: the flagship keystone_insert() (caliper-faithful, style-
// independent) is a DIFFERENT scale/mechanism than the old guessed
// keystone_slot()/keystone_notch() channel this frame still cuts -- the slot
// side is intentionally PARKED pending a separate, deferred reconciliation
// effort (see keystone_insert()'s own comment in keystone.scad). So the
// "mated" view below renders the frame and the new insert TOGETHER for
// compile/smoke purposes only -- it is NOT a real geometric mate-check (the
// old #38 Task-3 notch-engagement / no-collision motion sweep this file used
// to drive no longer applies to the new insert's geometry and has been
// dropped, not adapted). A true insert/slot mate-check is future work once
// the slot is rebuilt against this insert's envelope.
use <keystone/keystone.scad>;

// _keystone_frame(plate_thickness, clearance, style): the real consumer
// pattern documented in keystone_cutout()'s module comment -- union the boss
// into a representative faceplate swatch, then difference the cutout through
// both (boss is a no-op for "face"). Single source of truth for the "what does
// a real panel look like" question in every view below. Slot-side only --
// unrelated to keystone_insert(), untouched by #54.
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

// [Mated] — frame + a static seated flagship insert, side by side for a
// compile/visual smoke check (see #54 STATUS above -- not a real mate-check;
// the insert's own front face is placed at the frame's front, Z=0, same as
// the frame's datum, but the two are not claimed to interlock).
module keystone_assembly_mated(plate_thickness = 3.0, clearance = 0.25, fit = 0.2,
                                latch_wall = 1.0, style = "standard") {
    _keystone_frame(plate_thickness, clearance, style);
    keystone_insert(fit = fit, latch_wall = latch_wall);
}

// [Motion] — PARKED (#54): the old #38 Task-3 insertion-motion viz
// (flex_side/deflect) was built for the superseded guessed "standard"
// keystone_insert() branch and does not apply to the new caliper-faithful
// insert (no motion data was measured/modeled this task -- the real
// pivot-and-latch motion belongs to the deferred slot-reconciliation pass).
// This view is kept only so the Customizer's view= combo still resolves;
// it renders the same static seated insert as [Mated].
module keystone_assembly_motion(plate_thickness = 3.0, clearance = 0.25, fit = 0.2,
                                 latch_wall = 1.0, style = "standard") {
    keystone_assembly_mated(plate_thickness, clearance, fit, latch_wall, style);
}

// [Removal slot] — the bare front window/cavity (frame only, no insert), for
// inspecting the cutout shape a jack is inserted through / removed from.
// Slot-side only -- unrelated to keystone_insert(), untouched by #54.
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
latch_wall = 1.0;

if (view == "mated") keystone_assembly_mated(plate_thickness, clearance, fit, latch_wall, style);
else if (view == "motion") keystone_assembly_motion(plate_thickness, clearance, fit, latch_wall, style);
else if (view == "removal_slot") keystone_assembly_removal_slot(plate_thickness, clearance, style);
else assert(false, str("keystone assembly: unknown view '", view, "'"));
