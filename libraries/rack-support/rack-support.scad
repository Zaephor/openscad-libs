// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// rack-support — generic rear-support faceplate + slide-in tongue/slot mating
// interface for rack10 device trays (#40). The rear plate bolts to the rear
// rack posts and presents a forward-facing channel; a consumer tray adds
// rack_support_tongue() at its rear and slides in. Converts a front cantilever
// into a two-end-supported beam (creep mitigation — see README consumer
// contract). Consumes rack10 for widths/holes/depth. See RESEARCH.md for
// provenance: the mating dims are DESIGN values (fit clearances), not measured.
use <rack10/rack10.scad>;

// --- mating interface (single source of truth; DESIGN values, //VERIFY,
// bench-tunable P1S/PETG — see design-for-print) ---
function rack_support_rail_size()      = [40, 10]; // tongue [width_X, height_Z] mm //VERIFY design
function rack_support_slot_clearance() = 0.4;      // per-side slide fit gap    //VERIFY design
function rack_support_engagement_depth() = 12;     // tongue insertion depth Y  //VERIFY design
// Bearing-floor material thickness inside rack_support_plate() (Z in
// [0,floor_t]); the floor's TOP face (Z=floor_t) is the actual bearing
// contact datum -- see that module's Z-DATUM comment. Promoted to a
// function (not a plate-local literal) because rack_support_tongue() must
// seat on the SAME datum: single source of truth for both consumers of
// this number. //VERIFY design
function rack_support_floor_thickness() = 2;
// Width of the 45deg gusset rib flanking EACH side of the channel. The gusset
// was originally built full panel-width, which made the plate's solid envelope
// span the entire 254mm panel over Z in [0,ed] -- that collided with any
// consumer body reaching the rear post plane (#63). Narrowed to two ribs that
// still bond the bearing floor to the mounting wall while leaving the rest of
// the panel free for consumer geometry. DESIGN value (no external spec exists
// for a mechanism this library invents), bench-tunable P1S/PETG. //VERIFY design
function rack_support_gusset_rib() = 10;

/* [Rear plate] */
// Convex prism from 3 [Y,Z] points, extruded along X (width xw, X-centered).
// Built as hull() of 6 tiny spheres at the two end-triangles rather than a
// hand-rolled polyhedron face list -- a triangular prism IS the convex hull
// of its 6 vertices, so this is correct for ANY winding of `pts` (no risk of
// an inverted-normal face list silently producing a bad manifold).
module _rack_support_yz_prism(pts, xw) {
    x0 = -xw / 2; x1 = xw / 2;
    hull()
        for (p = pts)
            for (x = [x0, x1])
                translate([x, p[0], p[1]]) sphere(r = 0.001, $fn = 6);
}

// Rear-support plate: a rack10-width panel at the rear posts. Mounting face at
// Y=0 (rack10_holes stamps here), body grows +Y into the rack. A forward-facing
// channel (opens -Y) accepts the consumer tongue.
//
// Z-DATUM (rack10.scad:3 -- "Z=0 at the bottom of the U-stack"; rack10_stack_gap()
// = 0.79mm relief to the device below): ALL solid material of this plate stays
// at Z>=0 -- it must never intrude into the U-slot below, which houses a
// different device in a real rack10 stack. The bearing floor's BOTTOM face
// sits at Z=0 (resting on this device's own U-floor, not below it); its TOP
// face (Z=floor_t) is the load-bearing contact surface the tongue rests on --
// bearing/shear under sustained load, not a snap/latch (creep-friendly, see
// README). The channel cavity sits above the floor (Z in [floor_t,
// floor_t+slot_h]). The 45deg gusset that braces the floor's cantilever also
// stays at Z in [0,ed] -- since that overlaps the cavity's Z-range in the
// slot's own X-band, the gusset is narrowed to slot-width plus two flanking
// ribs (rack_support_gusset_rib() wide each) bonded to both the floor slab and
// the mounting wall. This frees the rest of the panel for consumer geometry
// that may reach the rear-post plane (#63).
// Support-free: printed mouth-up (-Y up), each layer's material footprint
// shrinks monotonically going up -- the gusset narrows to zero at the mouth
// while the floor/wall stay continuous -- so every layer is supported by a
// wider one below it; the mouth is chamfered so the tongue gets a lead-in
// ramp instead of a sharp lip.
module rack_support_plate(standard, u, thickness = 3, hole_type = "round") {
    w  = rack10_panel_width(standard);
    h  = rack10_device_height(u);
    rs = rack_support_rail_size();          // [tongue_w, tongue_h]
    cl = rack_support_slot_clearance();
    ed = rack_support_engagement_depth();
    slot_w  = rs[0] + 2 * cl;               // side clearance both sides
    slot_h  = rs[1] + cl;                   // top clearance only; floor stays tight (bearing)
    floor_t = rack_support_floor_thickness(); // bearing-floor material thickness, Z in [0,floor_t]
    lead_in = floor_t;                      // mouth chamfer run (Y); == floor_t -> 45deg
    assert(ed <= h, "rack_support_plate: engagement depth exceeds device height");
    difference() {
        union() {
            // Panel blank (mounting face Y=0, grows +Y).
            translate([-w/2, 0, 0]) cube([w, thickness, h]);
            // Bearing floor: spans the mouth (Y=-ed) through into the panel
            // (Y=thickness) -- contiguous with the panel, no gap. Material
            // occupies Z in [0,floor_t] (bottom face on the Z=0 device-floor
            // datum) so the floor's TOP face (Z=floor_t) is the bearing
            // surface.
            translate([-slot_w/2, -ed, 0])
                cube([slot_w, ed + thickness, floor_t]);
            // 45deg gusset: right angle at the wall/floor corner (Y=0,Z=0),
            // equal legs (both = ed) along the wall (up) and along the floor
            // (out to the mouth) -> hypotenuse at exactly 45deg from
            // vertical. Narrowed to slot_w + 2 * gusset_rib(): the central
            // slot-width band is removed below by the same difference() that
            // cuts the channel cavity (that band sits directly under the cavity,
            // Z in [floor_t,ed] there), leaving ribs flanking the slot that are
            // solidly bonded to both the floor slab (Z in [0,floor_t], all X)
            // and the mounting wall. The narrowed envelope frees the rest of the
            // panel for consumer geometry.
            _rack_support_yz_prism([[0, 0], [-ed, 0], [0, ed]], slot_w + 2 * rack_support_gusset_rib());
        }
        // The channel cavity the tongue slides into (opens -Y, floor top at
        // Z=floor_t): from the bearing floor's top up by slot_h, tongue-
        // width + clearance wide, spanning the same Y-range as the floor
        // (mouth through into the panel) so the panel's own thickness
        // caps/roofs the seated end. Z starts at floor_t-eps (not exactly
        // floor_t) so the cutter genuinely overlaps the floor's top face
        // instead of merely touching it -- an exactly-coincident cutter/
        // solid face over the Y<0 region (outside the panel, where nothing
        // else fills that gap) leaves CGAL a zero-thickness sliver and
        // renders non-manifold (verified: dropping this eps reproduces
        // "Object may not be a valid 2-manifold"). eps is well under any
        // dimension here, so it doesn't move the floor_t bearing-surface
        // datum in any way that matters. This same cut also removes the
        // gusset's central (slot-width) band above floor_t, leaving the
        // flanking ribs described above.
        eps = 0.01;
        translate([-slot_w/2, -ed, floor_t - eps])
            cube([slot_w, ed + thickness, slot_h + eps]);
        // Chamfered mouth: bevel the floor's sharp top-front corner (45deg,
        // run = lead_in) so the tongue gets a lead-in ramp, not a lip.
        _rack_support_yz_prism(
            [[-ed, floor_t], [-ed + lead_in, floor_t], [-ed, floor_t - lead_in]], slot_w);
        // Rear mounting holes — front pattern reused on this plane (single
        // source of truth; NOT re-literaled). round default; consumer picks type.
        rack10_holes(standard, u, hole_type = hole_type,
                     dia = hole_type == "round" ? rack10_screw_clearance("m6") : 0);
    }
}

// The plate's forward-projecting solid envelope, for consumers to
// difference() out of their own body at the SAME placement they use for the
// plate. Two rigid printed parts cannot share volume; before this existed the
// interface was an unwritten assumption and both shipped consumers violated
// it (#63).
//
// CRITICAL: the channel cavity is SUBTRACTED from this envelope -- the
// consumer's tongue legitimately occupies it. An envelope that includes the
// cavity deletes the caller's own tongue, which makes the interference test
// pass for entirely the wrong reason. tests/test_rack_support_lib.sh carries a
// paired assertion against exactly that failure.
//
// Composed only from the SAME accessors rack_support_plate() reads (single
// source of truth -- no re-literaled numbers) and covers only the part of
// the envelope that projects past the mounting face (local Y<0): the
// panel-internal portion (Y in [0,thickness]) is never reached by a
// consumer body that stops at the mounting face the way the reference stub
// tray does (see assembly.scad), so it's left out to avoid over-claiming.
//
// margin inflates the envelope for assembly clearance (default 0 = exact):
// grows the wedge's two free vertices (mouth point further out, top point
// higher) and the floor slab's reach/width -- NOT the channel cavity cut,
// which must stay exactly the tongue's own clearance envelope regardless of
// margin, or growing margin would eat into the tongue's reserved volume.
module rack_support_plate_keepout(margin = 0) {
    rs      = rack_support_rail_size();
    cl      = rack_support_slot_clearance();
    ed      = rack_support_engagement_depth();
    ft      = rack_support_floor_thickness();
    rib     = rack_support_gusset_rib();
    slot_w  = rs[0] + 2 * cl;
    slot_h  = rs[1] + cl;
    m       = margin;
    // Same eps-overlap technique as rack_support_plate()'s own cavity cut
    // (see that module's comment): the cavity cutter's bottom face would
    // otherwise sit exactly coincident with the floor slab's top face over
    // the mouth region (Y<0, outside any panel-internal material), leaving
    // CGAL a zero-thickness sliver and a non-manifold result.
    eps = 0.01;
    difference() {
        union() {
            // 45deg gusset wedge -- mirrors rack_support_plate()'s own
            // wedge shape/width exactly (single source of truth: same
            // slot_w + 2*gusset_rib() term), margin grows the two outer
            // vertices away from the wall/floor corner (which stays fixed).
            _rack_support_yz_prism([[0, 0], [-ed - m, 0], [0, ed + m]],
                                    slot_w + 2 * rib + 2 * m);
            // Bearing-floor slab's mouth-projecting portion only (Y in
            // [-ed,0]; the plate's own floor additionally spans into the
            // panel at Y in [0,thickness], omitted here per the module doc).
            translate([-slot_w/2 - m, -ed - m, 0])
                cube([slot_w + 2 * m, ed + m, ft]);
        }
        // Channel cavity -- mirrors rack_support_plate()'s own cavity cut
        // (same slot_w/ft/slot_h terms, over the mouth-projecting Y-range)
        // so the two can never drift apart.
        translate([-slot_w/2, -ed, ft - eps])
            cube([slot_w, ed, slot_h + eps]);
    }
}

// The mating tongue a consumer tray unions at its rear, centered on the
// tray width, projecting +Y to slide into rack_support_plate()'s forward-
// opening (-Y) channel. Sized from rack_support_rail_size(); reaches
// rack_support_engagement_depth() into the slot.
//
// Z-POSITIONING (matches rack_support_plate()'s Z-DATUM fix, not the
// original Z=0-flush assumption): the plate's channel cavity sits ABOVE
// its bearing floor (Z in [floor_t, floor_t+slot_h]), not at Z=0 -- the
// floor's bottom rests on the shared rack10 U-floor datum, and its TOP
// face (Z=floor_t, rack_support_floor_thickness()) is the real bearing
// contact surface. So the tongue is built at Z in [floor_t, floor_t+rs[1]]
// (underside on the bearing floor, tight fit; top has the plate's
// slot_clearance headroom), NOT at Z in [0,rs[1]]. rack_support_
// floor_thickness() is the single source for this offset -- both this
// module and rack_support_plate() read it, so the two can never drift
// apart independently.
//
// Consumers place their body so the tongue root sits at
// rack10_rear_post_y(standard) minus rack_support_engagement_depth() (see
// README consumer contract / placement formula). Leading edge left square:
// it mates with the plate's own chamfered mouth lead-in, so no additional
// tongue-side bevel is needed for slide-in clearance. Support-free: a flat
// vertical end face has no overhang; consumers must bring their own floor
// up to meet the tongue's underside (Z=floor_t) with no unsupported gap --
// see the README consumer contract for the required buttressing detail.
module rack_support_tongue() {
    rs = rack_support_rail_size();          // [w, h]
    ed = rack_support_engagement_depth();
    ft = rack_support_floor_thickness();    // plate bearing-floor top = tongue underside
    translate([-rs[0] / 2, 0, ft])
        cube([rs[0], ed, rs[1]]);
}
