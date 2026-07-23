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
// channel (opens -Y) accepts the consumer tongue. Per the DESIGN NOMINALS datum,
// device-bottom / the channel FLOOR / the tongue underside all share Z=0: the
// bearing-floor MATERIAL sits below that (Z in [-floor_t,0]) so its top face
// (Z=0) is the load-bearing contact surface the tongue rests on -- bearing/shear
// under sustained load, not a snap/latch (creep-friendly, see README). A 45deg
// gusset ties the floor's underside back to the mounting wall, entirely below
// the Z>=0 slot cavity (clear of it). Support-free: the floor/gusset are a
// constant Y-cross-section (no new unsupported area appears) in the print
// orientation that lays the panel's broad face flat (thickness axis vertical,
// -Y/mouth-side up per the lib header) -- the shrinking-taper lead-in chamfer
// and the 45deg gusset stay within that same self-supporting logic; the mouth
// is chamfered so the tongue gets a lead-in ramp instead of a sharp lip.
module rack_support_plate(standard, u, thickness = 3, hole_type = "round") {
    w  = rack10_panel_width(standard);
    h  = rack10_device_height(u);
    rs = rack_support_rail_size();          // [tongue_w, tongue_h]
    cl = rack_support_slot_clearance();
    ed = rack_support_engagement_depth();
    slot_w  = rs[0] + 2 * cl;               // side clearance both sides
    slot_h  = rs[1] + cl;                   // top clearance only; floor stays tight (bearing)
    floor_t = 2;                            // bearing-floor material thickness, below Z=0
    lead_in = floor_t;                      // mouth chamfer run (Y); == floor_t -> 45deg
    difference() {
        union() {
            // Panel blank (mounting face Y=0, grows +Y).
            translate([-w/2, 0, 0]) cube([w, thickness, h]);
            // Bearing floor: spans the mouth (Y=-ed) through into the panel
            // (Y=thickness) -- contiguous with the panel, no gap. Material is
            // below Z=0 so the floor's TOP face (Z=0) is the bearing surface.
            translate([-slot_w/2, -ed, -floor_t])
                cube([slot_w, ed + thickness, floor_t]);
            // 45deg gusset: right angle at the wall/floor-underside corner,
            // equal legs (both = ed) along the wall (down) and along the
            // floor underside (out to the mouth) -> hypotenuse at exactly
            // 45deg from vertical. Entirely at Z <= -floor_t, strictly below
            // the Z>=0 slot cavity carved out below -- clear of it.
            _rack_support_yz_prism(
                [[0, -floor_t], [-ed, -floor_t], [0, -floor_t - ed]], slot_w);
        }
        // The channel cavity the tongue slides into (opens -Y, floor at
        // Z=0): from the bearing floor's top up by slot_h, tongue-width +
        // clearance wide, spanning the same Y-range as the floor (mouth
        // through into the panel) so the panel's own thickness caps/roofs
        // the seated end. Z starts at -eps (not exactly 0) so the cutter
        // genuinely overlaps the floor's top face instead of merely
        // touching it -- an exactly-coincident cutter/solid face at Z=0
        // over the Y<0 region (outside the panel, where nothing else fills
        // that gap) leaves CGAL a zero-thickness sliver and renders
        // non-manifold (verified: dropping this eps reproduces "Object may
        // not be a valid 2-manifold"). eps is well under any dimension
        // here, so it doesn't move the Z=0 bearing-surface datum in any
        // way that matters.
        eps = 0.01;
        translate([-slot_w/2, -ed, -eps])
            cube([slot_w, ed + thickness, slot_h + eps]);
        // Chamfered mouth: bevel the floor's sharp top-front corner (45deg,
        // run = lead_in) so the tongue gets a lead-in ramp, not a lip.
        _rack_support_yz_prism(
            [[-ed, 0], [-ed + lead_in, 0], [-ed, -lead_in]], slot_w);
        // Rear mounting holes — front pattern reused on this plane (single
        // source of truth; NOT re-literaled). round default; consumer picks type.
        rack10_holes(standard, u, hole_type = hole_type,
                     dia = hole_type == "round" ? rack10_screw_clearance("m6") : 0);
    }
}
