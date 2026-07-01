// motherboards library.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — motherboards_placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — motherboards_holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
// Pure-data libraries (e.g. hardware) keep ONLY the Data functions below and
// delete the placeholder/holes modules.

$fn = 48;

/* [Data] */
function motherboards_width()  = 40;   // mm, X envelope   // [tier] <source>
function motherboards_depth()  = 40;   // mm, Y envelope   // [tier] <source>
function motherboards_height() = 10;   // mm, Z envelope   // [tier] <source>
// Mounting-hole coordinates [x, y], relative to the centered origin.
function motherboards_holes_xy() = [[-15, -15], [15, -15], [15, 15], [-15, 15]];
function motherboards_hole_dia() = 3.4; // mm, clearance hole   // [tier] <source>

/* [Placeholder] */
// Envelope solid for dropping into an assembly to check fit.
module motherboards_placeholder() {
    translate([0, 0, motherboards_height() / 2])
        cube([motherboards_width(), motherboards_depth(), motherboards_height()], center = true);
}

/* [Hole-stamp] */
// Mounting holes; use inside a consumer difference().
module motherboards_holes(depth = -1) {
    h = depth < 0 ? motherboards_height() + 2 : depth;
    for (p = motherboards_holes_xy())
        translate([p[0], p[1], -1])
            cylinder(h = h, d = motherboards_hole_dia());
}

// Visual self-check when opened directly.
difference() {
    motherboards_placeholder();
    motherboards_holes();
}
