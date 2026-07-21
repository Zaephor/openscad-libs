// vesa library.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — vesa_placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — vesa_holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
// Pure-data libraries (data functions only, no geometry) keep ONLY the Data functions below and
// delete the placeholder/holes modules.

$fn = 48;

/* [Data] */
function vesa_width()  = 40;   // mm, X envelope   // [tier] <source>
function vesa_depth()  = 40;   // mm, Y envelope   // [tier] <source>
function vesa_height() = 10;   // mm, Z envelope   // [tier] <source>
// Mounting-hole coordinates [x, y], relative to the centered origin.
function vesa_holes_xy() = [[-15, -15], [15, -15], [15, 15], [-15, 15]];
function vesa_hole_dia() = 3.4; // mm, clearance hole   // [tier] <source>

/* [Placeholder] */
// Envelope solid for dropping into an assembly to check fit.
module vesa_placeholder() {
    translate([0, 0, vesa_height() / 2])
        cube([vesa_width(), vesa_depth(), vesa_height()], center = true);
}

/* [Hole-stamp] */
// Mounting holes; use inside a consumer difference().
module vesa_holes(depth = -1) {
    h = depth < 0 ? vesa_height() + 2 : depth;
    for (p = vesa_holes_xy())
        translate([p[0], p[1], -1])
            cylinder(h = h, d = vesa_hole_dia());
}

// Visual self-check when opened directly.
difference() {
    vesa_placeholder();
    vesa_holes();
}
