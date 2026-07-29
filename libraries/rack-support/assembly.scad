// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// rack-support reference demo (#40) — a MINIMAL stub tray (front ears + short
// floor + rack_support_tongue()) slid into rack_support_plate(). Demonstrator
// only; real device trays are #41-45. Render: make render P=... (or dind), or
// via .claude/skills/verify-scad-geometry for the mate correctness gate.
//
// Z-DATUM NOTE (adapted from the original Task-4 brief pseudocode, written
// before Task 3's Z-fix): rack_support_plate()'s channel cavity sits ABOVE
// its bearing floor (Z in [floor_t, floor_t+slot_h]), not at Z=0 -- see that
// module's header comment. rack_support_tongue() already bakes in this
// offset (its underside is at rack_support_floor_thickness(), not 0), so
// this stub tray's own floor is built at the SAME height (Z in [0,ft]), i.e.
// it hands off to the tongue's underside flush rather than leaving the
// stacked-but-non-overlapping join a Z=0-to-3 floor (the brief's original
// literal) would give.
//
// TONGUE-SUPPORT NOTE: that flush floor does NOT survive under the tongue's
// engagement span, and cannot. The keep-out subtraction below deletes the
// tray's material over Y in [reach,rpy] x Z in [0,ft] because that is where
// rack_support_plate()'s OWN bearing floor sits -- the two are separate
// printed parts and only one of them may occupy it. All that is left under
// the tongue is the eps-thick film the cavity exclusion preserves (measured:
// 4.8001mm^3 = 40 x 12 x 0.01), which is ~1/20 of a layer height and which
// no slicer emits. So the tongue's 40 x 12mm underside is a genuine
// unsupported overhang in EVERY consumer of this interface, not a defect of
// this demo. What makes it printable is the 45deg root gusset unioned below:
// it rises above Z=ft strictly FORWARD of the tongue root (Y < reach, which
// the plate never reaches -- measured ymin 227.999 ~= reach), so it costs
// nothing in clearance while giving the tongue's first printed layer a solid
// in-layer anchor to start from. That is the same role drive-tray's
// full-height rear wall plays for its own tongue, and it leaves the same
// knowingly-accepted residual risk that file documents: a stocky 40x10mm
// cantilever reaching engagement_depth() (12mm) off an anchored root.
//
// FLOOR-LENGTH NOTE (found under render, not in the brief): the floor must
// run all the way to the rear mounting plane (Y=rack10_rear_post_y), i.e.
// it must overlap the tongue's own Y-span by a real 2D face, not merely
// touch it edge-to-edge at Y=reach. A floor that stopped exactly at
// Y=reach (the brief's literal boundary) meets the tongue's underside
// (Z=ft) only along a 1D line where the floor's top (Z in [0,ft]) and the
// tongue's bottom (Z in [ft,ft+rs[1]]) are stacked but non-overlapping in
// Z -- CGAL reports that as a non-manifold union (verified: reproduces
// "Object may not be a valid 2-manifold"). Extending the floor to the same
// far Y-edge as the tongue's tip gives a full-area coincident face (same
// pattern as the front-ear/floor join below, which IS manifold), and is
// also the more physically sensible shape: the tongue rides as a raised
// rail on top of a floor that already reaches the plate's mounting face.
// Running the full-length floor into the plate's own bearing-floor/gusset
// band DOES create real solid-solid overlap, though (#63) -- measured
// 875.89mm^3 before the fix below. The keep-out subtraction resolves that
// without shortening the floor (which would reintroduce the non-manifold
// join above): rack_support_plate_keepout(), the plate's own published
// forward envelope (single source of truth -- see that module's doc), is
// differenced out of this body at the SAME rear-post placement the plate
// itself uses, carving away just the overlap and leaving the tongue (which
// legitimately occupies the channel cavity) untouched.
use <rack-support/rack-support.scad>;
use <rack10/rack10.scad>;

standard = "labrax";
u = 1;

// Rear plate at the rear mounting plane.
translate([0, rack10_rear_post_y(standard), 0]) rack_support_plate(standard, u);

// Stub tray: front ear panel at Y=0 + a floor spanning to the plate + the
// tongue seated in the channel. Sized so the tongue reaches the slot.
ft    = rack_support_floor_thickness();          // plate bearing-floor top == tongue underside
rw    = rack_support_rail_size()[0];              // tongue/floor width (single source, not re-literaled)
rh    = rack_support_rail_size()[1];              // tongue height -- also the root gusset's rise/run (see below)
reach = rack10_rear_post_y(standard) - rack_support_engagement_depth();
difference() {
    union() {
        // front ear panel (own blank, rack10 width, device-height tall)
        translate([-rack10_panel_width(standard)/2, -3, 0])
            cube([rack10_panel_width(standard), 3, rack10_device_height(u)]);
        // floor to the rear, built at the SAME Z the tongue seats at (ft),
        // running all the way to the mounting plane (rack10_rear_post_y) so
        // it fully overlaps the tongue's underside face (a flush, manifold
        // hand-off -- see FLOOR-LENGTH note above). Only the part FORWARD of
        // the tongue root survives the keep-out below; over the engagement
        // span the plate's own bearing floor takes this volume (see
        // TONGUE-SUPPORT note above).
        translate([-rw/2, 0, 0]) cube([rw, rack10_rear_post_y(standard), ft]);
        // 45deg tongue-root gusset (rack-support README consumer contract:
        // "45deg root gussets at ... tongue-to-body junctions"). Right
        // triangle in YZ, vertical leg on the tongue's own front face
        // (Y=reach, Z from ft up to ft+rh) and horizontal leg on the floor's
        // top face (Z=ft, Y from reach-rh back to reach) -- equal legs, so
        // the hypotenuse is exactly 45deg and the footprint shrinks
        // monotonically upward from a base that sits on solid floor:
        // support-free with no floating start. Extruded across the tongue's
        // own width (rw). Both legs are rack_support_rail_size()[1], i.e. the
        // gusset braces the tongue's FULL root cross-section, apex flush with
        // the tongue's top face -- no new dimension is invented, and the
        // whole wedge lives at Y <= reach, outside the plate's envelope.
        // Built with rack-support's own prism idiom (same helper, hence the
        // same any-winding correctness argument, as the plate's gusset).
        _rack_support_yz_prism(
            [[reach - rh, ft], [reach, ft], [reach, ft + rh]], rw);
        // tongue at the rear, on the floor, into the plate slot
        translate([0, reach, 0]) rack_support_tongue();
    }
    rack10_holes(standard, u, hole_type="slot", dia=rack10_screw_clearance("10-32"));
    // Clear the plate's forward envelope (see FLOOR-LENGTH note above) --
    // same placement as the plate itself, so the two can never drift apart.
    translate([0, rack10_rear_post_y(standard), 0]) rack_support_plate_keepout();
}
% rack10_rackpost_context(standard, 1, 1, rack10_depth_preset(standard));
