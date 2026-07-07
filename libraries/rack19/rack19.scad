// rack19 — 19-inch EIA-310-D rack mechanical reference.
// Datum: millimeters. X centered on rack width (X=0 at rack centerline).
// Z=0 at the bottom of the U-stack (+Z = upward, stacking U-by-U).
// Y=0 at the front post face (+Y = rearward, into the rack).
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — rack19_placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — rack19_holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn.
// Provenance legend (see RESEARCH.md for the full evidence log this pass):
//   [A] upstream vendor datasheet or governing standard (EIA-310-D itself —
//       paywalled; not directly fetched this pass, see RESEARCH.md).
//   [B] corroborated across multiple independent peers (Wikipedia + vendor
//       install specs, etc.) — most values in this library are [B].
//   [C] reverse-engineered from a public STL/SCAD artifact (cite the URL).
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
// Data functions/modules below are still the generator's placeholder stub —
// real EIA-310-D data lands in Tasks 2+, sourced from RESEARCH.md.

$fn = 48;

/* [Data] */
function rack19_width()  = 40;   // mm, X envelope   // [tier] <source>
function rack19_depth()  = 40;   // mm, Y envelope   // [tier] <source>
function rack19_height() = 10;   // mm, Z envelope   // [tier] <source>
// Mounting-hole coordinates [x, y], relative to the centered origin.
function rack19_holes_xy() = [[-15, -15], [15, -15], [15, 15], [-15, 15]];
function rack19_hole_dia() = 3.4; // mm, clearance hole   // [tier] <source>

/* [Placeholder] */
// Envelope solid for dropping into an assembly to check fit.
module rack19_placeholder() {
    translate([0, 0, rack19_height() / 2])
        cube([rack19_width(), rack19_depth(), rack19_height()], center = true);
}

/* [Hole-stamp] */
// Mounting holes; use inside a consumer difference().
module rack19_holes(depth = -1) {
    h = depth < 0 ? rack19_height() + 2 : depth;
    for (p = rack19_holes_xy())
        translate([p[0], p[1], -1])
            cylinder(h = h, d = rack19_hole_dia());
}

// Visual self-check when opened directly.
difference() {
    rack19_placeholder();
    rack19_holes();
}
