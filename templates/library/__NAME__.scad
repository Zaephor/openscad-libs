// __NAME__ library.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — __NAME___placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — __NAME___holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
// Pure-data libraries (data functions only, no geometry) keep ONLY the Data functions below and
// delete the placeholder/holes modules.

$fn = 48;

/* [Data] */
function __NAME___width()  = 40;   // mm, X envelope   // [tier] <source>
function __NAME___depth()  = 40;   // mm, Y envelope   // [tier] <source>
function __NAME___height() = 10;   // mm, Z envelope   // [tier] <source>
// Mounting-hole coordinates [x, y], relative to the centered origin.
function __NAME___holes_xy() = [[-15, -15], [15, -15], [15, 15], [-15, 15]];
function __NAME___hole_dia() = 3.4; // mm, clearance hole   // [tier] <source>

/* [Placeholder] */
// Envelope solid for dropping into an assembly to check fit.
module __NAME___placeholder() {
    translate([0, 0, __NAME___height() / 2])
        cube([__NAME___width(), __NAME___depth(), __NAME___height()], center = true);
}

/* [Hole-stamp] */
// Mounting holes; use inside a consumer difference().
module __NAME___holes(depth = -1) {
    h = depth < 0 ? __NAME___height() + 2 : depth;
    for (p = __NAME___holes_xy())
        translate([p[0], p[1], -1])
            cylinder(h = h, d = __NAME___hole_dia());
}

// Visual self-check when opened directly.
difference() {
    __NAME___placeholder();
    __NAME___holes();
}
