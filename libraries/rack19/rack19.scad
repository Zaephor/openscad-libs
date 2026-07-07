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
// Data functions below are real EIA-310-D core dimensions (Task 2), sourced
// from RESEARCH.md. The generator-stub Placeholder/Hole-stamp modules below
// referenced placeholder stub data fns (rack19_width() etc.) that Task 2
// replaced with the real EIA-310-D fns, so they no longer compile — they are
// commented out below pending Tasks 4-6, which add the real modules.

$fn = 48;

/* [Data] — EIA-310-D. Tiers per docs/LIBRARY-AUTHORING.md; see RESEARCH.md. */
function rack19_u()             = 44.45;    // [B] Wikipedia + IBM; 1U = 1.75in
function rack19_panel_width()   = 482.6;    // [B] Wikipedia (closure-checked)
function rack19_opening_width() = 450.85;   // [B] Wikipedia + IBM
function rack19_hole_h_span()   = 465.1;    // [B] //VERIFY 465.1 nominal vs IBM 464.2-465.8mm band — no discrete point-value source
// Rail hole X centers (datum X-centered), derived from the span above.
function rack19_hole_h_centers() =
    [-rack19_hole_h_span()/2, rack19_hole_h_span()/2];  // rail X, datum X-centered

// Tasks 4-6 add the real modules (Placeholder / Hole-stamp / panel helper).
// Stub geometry below is disabled (referenced now-removed placeholder data
// fns) and kept only for reference until those tasks land.
// /* [Placeholder] */
// // Envelope solid for dropping into an assembly to check fit.
// module rack19_placeholder() {
//     translate([0, 0, rack19_height() / 2])
//         cube([rack19_width(), rack19_depth(), rack19_height()], center = true);
// }
//
// /* [Hole-stamp] */
// // Mounting holes; use inside a consumer difference().
// module rack19_holes(depth = -1) {
//     h = depth < 0 ? rack19_height() + 2 : depth;
//     for (p = rack19_holes_xy())
//         translate([p[0], p[1], -1])
//             cylinder(h = h, d = rack19_hole_dia());
// }
//
// // Visual self-check when opened directly.
// difference() {
//     rack19_placeholder();
//     rack19_holes();
// }
