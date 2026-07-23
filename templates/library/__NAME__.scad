// __NAME__ library.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — __IDENT___placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — __IDENT___holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
// Pure-data libraries (data functions only, no geometry) keep ONLY the Data functions below and
// delete the placeholder/holes modules.

$fn = 48;

/* [Data] */
function __IDENT___width()  = 40;   // mm, X envelope   // [tier] <source>
function __IDENT___depth()  = 40;   // mm, Y envelope   // [tier] <source>
function __IDENT___height() = 10;   // mm, Z envelope   // [tier] <source>
// Mounting-hole coordinates [x, y], relative to the centered origin.
function __IDENT___holes_xy() = [[-15, -15], [15, -15], [15, 15], [-15, 15]];
function __IDENT___hole_dia() = 3.4; // mm, clearance hole   // [tier] <source>

/* [Placeholder] */
// Envelope solid for dropping into an assembly to check fit.
module __IDENT___placeholder() {
    translate([0, 0, __IDENT___height() / 2])
        cube([__IDENT___width(), __IDENT___depth(), __IDENT___height()], center = true);
}

/* [Hole-stamp] */
// Mounting holes; use inside a consumer difference().
module __IDENT___holes(depth = -1) {
    h = depth < 0 ? __IDENT___height() + 2 : depth;
    for (p = __IDENT___holes_xy())
        translate([p[0], p[1], -1])
            cylinder(h = h, d = __IDENT___hole_dia());
}

// Visual self-check when opened directly.
difference() {
    __IDENT___placeholder();
    __IDENT___holes();
}
