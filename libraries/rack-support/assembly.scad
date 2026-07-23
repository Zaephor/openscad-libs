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
// this stub tray's own floor is built at the SAME height (Z in [0,ft]) as a
// flush, support-free hand-off into the tongue -- no floating shelf/overhang
// under the tongue the way a Z=0-to-3 floor (the brief's original literal)
// would leave.
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
reach = rack10_rear_post_y(standard) - rack_support_engagement_depth();
difference() {
    union() {
        // front ear panel (own blank, rack10 width, device-height tall)
        translate([-rack10_panel_width(standard)/2, -3, 0])
            cube([rack10_panel_width(standard), 3, rack10_device_height(u)]);
        // floor to the rear, built at the SAME Z the tongue seats at (ft),
        // running all the way to the mounting plane (rack10_rear_post_y) so
        // it fully overlaps the tongue's underside face (see FLOOR-LENGTH
        // note above) -- flush, manifold, support-free hand-off.
        translate([-rw/2, 0, 0]) cube([rw, rack10_rear_post_y(standard), ft]);
        // tongue at the rear, on the floor, into the plate slot
        translate([0, reach, 0]) rack_support_tongue();
    }
    rack10_holes(standard, u, hole_type="slot", dia=rack10_screw_clearance("10-32"));
}
% rack10_rackpost_context(standard, 1, 1, rack10_depth_preset(standard));
