// rack10 — 10-inch mini-rack mechanical reference, vendor-keyed (v1 = LabRax only).
// Datum: millimeters. X centered on rack width (X=0 at rack centerline).
// Z=0 at the bottom of the U-stack (+Z = upward, stacking U-by-U).
// Y=0 at the front post face (+Y = rearward, into the rack).
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — rack10_placeholder(): envelope solid for fit checks
//   3. Hole-stamp  — rack10_holes(): mounting holes for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn.
// Vendor-keyed data: unlike rack19 (a real, if paywalled, governing standard
// — EIA-310-D), there is NO governing standard for 10-inch mini-racks at
// all — LabRax's own designer says so explicitly ("There is no strict
// standard for 10-inch racks, but Lab Rax follows the most commonly
// accepted dimensions" — see RESEARCH.md). So [A] is not reachable for
// anything in this library; the ceiling is [B]. Every geometry fn below
// therefore takes a `standard` key (see rack10_known_standards()); v1 ships
// only "labrax" — nothing in this library is [A].
// Provenance legend (see RESEARCH.md for the full evidence log this pass):
//   [A] upstream vendor datasheet or governing standard — not reachable this
//       pass (no standard exists for 10in mini-racks at all).
//   [B] corroborated across multiple independent peers (the vendor's own
//       article + an independent to-scale diagram, etc.) — most values here
//       are [B].
//   [C] single-sourced / reverse-engineered from a public STL/SCAD artifact,
//       or a third-party (non-designer) corroboration only (cite the URL) /
//       OR a named standard cited but not fetched this pass.
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
// Data functions below are real LabRax core dimensions (Task 2), sourced
// from RESEARCH.md. The generator-stub Placeholder/Hole-stamp modules below
// referenced placeholder stub data fns (rack10_width() etc.) that Task 2
// replaced with the real vendor-keyed fns, so they no longer compile — they
// are commented out below pending Tasks 4-6, which add the real modules.

$fn = 48;

/* [Data] — 10in mini-rack, vendor-keyed. Tiers per docs/LIBRARY-AUTHORING.md; see RESEARCH.md. */
function rack10_u() = 44.45; // [B] LabRax designer article (explicit, "44.45mm rack unit spacing"); EIA-compatible pitch — see RESEARCH.md "1U pitch"

function rack10_known_standards() = ["labrax"];

// Per-vendor geometry row: [panel_width, hole_h_span, clear_width, depth_ftf] (mm).
// labrax — see RESEARCH.md for full evidence per field, summarized here:
//   panel_width  254     [B] //VERIFY not stated by LabRax itself; sourced only
//                         from the independent, to-scale Wikimedia diagram
//                         (closure-checked against its own numbers).
//   hole_h_span  236.525 [B] LabRax article + Wikimedia diagram, exact match,
//                         two independent sources — strongest-confirmed value.
//   clear_width  222     [B] //VERIFY LabRax's own stated figure; the diagram
//                         gives 222.25, a 0.25mm gap unresolved without a mesh
//                         measurement of the actual part.
//   depth_ftf    240     [C] //VERIFY weaker than the rest: sourced only from
//                         an unaffiliated third-party remix description (not
//                         the designer, not a mesh/caliper measurement) —
//                         could be circular; see RESEARCH.md "Mounting depth".
function _rack10_geom(standard) =
    standard == "labrax" ? [254, 236.525, 222, 240] :
    assert(false, str("rack10: unknown standard '", standard, "'"));

function rack10_panel_width(standard)  = _rack10_geom(standard)[0];
function rack10_hole_h_span(standard)  = _rack10_geom(standard)[1];
function rack10_clear_width(standard)  = _rack10_geom(standard)[2];
function rack10_depth_preset(standard) = _rack10_geom(standard)[3];
// Rail hole X centers (datum X-centered), derived from the vendor span above.
function rack10_hole_h_centers(standard) =
    [-rack10_hole_h_span(standard)/2, rack10_hole_h_span(standard)/2];

// Tasks 4-6 add the real modules (Hole-stamp / Placeholder / panel helper).
// Stub geometry below is disabled (referenced now-removed placeholder data
// fns) and kept only for reference until those tasks land.
// /* [Placeholder] */
// // Envelope solid for dropping into an assembly to check fit.
// module rack10_placeholder() {
//     translate([0, 0, rack10_height() / 2])
//         cube([rack10_width(), rack10_depth(), rack10_height()], center = true);
// }
//
// /* [Hole-stamp] */
// // Mounting holes; use inside a consumer difference().
// module rack10_holes(depth = -1) {
//     h = depth < 0 ? rack10_height() + 2 : depth;
//     for (p = rack10_holes_xy())
//         translate([p[0], p[1], -1])
//             cylinder(h = h, d = rack10_hole_dia());
// }
//
// // Visual self-check when opened directly.
// difference() {
//     rack10_placeholder();
//     rack10_holes();
// }
