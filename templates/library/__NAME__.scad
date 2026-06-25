// __NAME__ library.
// Multi-role component convention:
//   1. Data        — named dim constants + [x,y] hole-coordinate lists
//   2. Placeholder — __NAME___placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — __NAME___holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances only from
// named constants; millimeters; central $fn.
// Pure-data libraries (e.g. hardware) keep ONLY the Data block below and
// delete the placeholder/holes modules.

$fn = 48;

/* [Data] */
__NAME___width  = 40;   // mm, X envelope
__NAME___depth  = 40;   // mm, Y envelope
__NAME___height = 10;   // mm, Z envelope
// Mounting-hole coordinates [x, y], relative to the centered origin.
__NAME___holes_xy = [[-15, -15], [15, -15], [15, 15], [-15, 15]];
__NAME___hole_dia = 3.4; // mm, clearance hole

/* [Placeholder] */
// Envelope solid for dropping into an assembly to check fit.
module __NAME___placeholder() {
    translate([0, 0, __NAME___height / 2])
        cube([__NAME___width, __NAME___depth, __NAME___height], center = true);
}

/* [Hole-stamp] */
// Mounting holes; use inside a consumer difference().
module __NAME___holes(depth = __NAME___height + 2) {
    for (p = __NAME___holes_xy)
        translate([p[0], p[1], -1])
            cylinder(h = depth, d = __NAME___hole_dia);
}

// Visual self-check when opened directly.
difference() {
    __NAME___placeholder();
    __NAME___holes();
}
