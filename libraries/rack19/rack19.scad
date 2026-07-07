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
//   [C] single-sourced / reverse-engineered from a public STL/SCAD artifact
//       (cite the URL) / OR a named standard cited but not fetched this pass.
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
// Data functions below are real EIA-310-D core dimensions, sourced from
// RESEARCH.md. The Data / Hole-stamp / Placeholder / Panel-helper sections
// below are all fully implemented and live (nothing commented out).

$fn = 48;

/* [Data] — EIA-310-D. Tiers per docs/LIBRARY-AUTHORING.md; see RESEARCH.md. */
function rack19_u()             = 44.45;    // [B] Wikipedia + IBM; 1U = 1.75in
function rack19_panel_width()   = 482.6;    // [B] Wikipedia (closure-checked)
function rack19_opening_width() = 450.85;   // [B] Wikipedia + IBM
function rack19_hole_h_span()   = 465.1;    // [B] //VERIFY 465.1 nominal vs IBM 464.2-465.8mm band — no discrete point-value source
// Rail hole X centers (datum X-centered), derived from the span above.
function rack19_hole_h_centers() =
    [-rack19_hole_h_span()/2, rack19_hole_h_span()/2];  // rail X, datum X-centered

// Three hole centers within one U, Z measured up from that U's lower edge.
// Gaps 15.875/15.875/12.7 (0.625/0.625/0.5in) sum to one U.
function rack19_u_hole_offsets() = [6.35, 22.225, 38.1]; // //VERIFY first-hole offset from U lower edge — Wikipedia prose only, not read off a to-scale drawing; gaps [B] Wikipedia+IBM
// Every hole-center Z for a stack of `u` units, ascending.
// round(...*1e6)/1e6 below is NOT a data decision — it only strips ~1e-14mm
// binary floating-point summation noise (verified: 1*rack19_u()+6.35 !=
// 50.8 by ~7e-15 in OpenSCAD's double arithmetic) so the exact decimal
// values (all defined to <=3 decimal mm places) compare equal with `==`.
function rack19_hole_z(u) =
    [for (i = [0:u-1]) for (o = rack19_u_hole_offsets())
        round((i*rack19_u() + o)*1e6)/1e6];

// Cage-nut square hole side. [B] Wikipedia (Cage nut), single-source this
// pass — //VERIFY second vendor cage-nut datasheet, see RESEARCH.md.
function rack19_square_size()   = 9.5;  // 0.375in
function rack19_known_threads() = ["10-32", "12-24", "M6"];
// Panel screw-clearance dia per rail thread (equipment-side hole into a
// cage nut / tapped rail hole), mm. Tiers/derivations in RESEARCH.md:
//   10-32, 12-24: [C] //VERIFY — ANSI B18.2 close-fit clearance-drill
//     (#10≈0.199in=5.05mm→5.0mm; #12≈0.221in=5.61mm→5.6mm); named
//     standard, not fetched this pass (paywalled/bot-gated, see
//     RESEARCH.md fetch-attempt table).
//   M6: [B] ISO 273 close-fit, per this repo's hardware lib precedent
//     (libraries/hardware/hardware.scad: M3->3.4, M4->4.5, M5->5.5).
function rack19_screw_clearance(thread) =
    thread == "10-32" ? 5.0 :
    thread == "12-24" ? 5.6 :
    thread == "M6"    ? 6.6 :
    assert(false, str("rack19: unknown thread '", thread, "'"));

// Rail post/flange width. [B] Wikipedia only this pass —
// //VERIFY second source for 15.875mm post width. Used for the panel-width
// closure check (see RESEARCH.md) and the placeholder envelope below.
function rack19_flange_width() = 15.875; // 0.625in
// Rail flange (sheet-metal) thickness — informational only, NOT an
// EIA-310-D value (rail gauge is a fabricator's choice, not spec-fixed).
// [C] //VERIFY typical 2-3mm cold-rolled steel, vendor-dependent
function rack19_flange_thickness() = 2.0;

// Common front-to-rear post face-to-face MOUNTING depths (mm) — illustrative
// vendor presets, NOT EIA-310-D-fixed values (EIA-310-D governs the front
// panel/hole pattern only, not cabinet depth). [C] //VERIFY illustrative
// common 19in mounting depths, vendor-dependent — not EIA-fixed, not
// independently corroborated (see RESEARCH.md "Depth presets").
function rack19_known_depths() = ["short-400", "std-600", "std-800"];
function rack19_depth_preset(name) =
    name == "short-400" ? 400 :
    name == "std-600"   ? 600 :
    name == "std-800"   ? 800 :
    assert(false, str("rack19: unknown depth preset '", name, "'"));

/* [Hole-stamp] */
// EIA hole strip as subtractable solids, both rails, `u` units. Axis along +Y.
// hole_type: "square" (cage-nut square, rack19_square_size()), "tapped" (pass
// thread string in `dia`, resolved via rack19_screw_clearance), "round" (pass
// numeric clearance dia directly in `dia`). The cutter is CENTERED on the
// front-post plane (Y=0), spanning y in [-d/2, +d/2], so a single stamp cuts
// in both +/-Y directions: panels (which grow into -Y from Y=0) and rail
// flanges (which grow into +Y from Y=0). depth (`d`) sizes that span; default
// 40 gives -20..+20, deep enough to fully penetrate any realistic panel or
// flange thickness. `depth` MUST exceed the target's thickness/flange-depth
// or the cut falls short of a through-hole; the default 40 covers realistic
// panels (<=~20mm) and rails, but a smaller caller-supplied value can
// under-cut a thicker target.
module rack19_holes(u, hole_type = "square", dia = 0, depth = 0) {
    assert(hole_type == "square" || hole_type == "tapped" || hole_type == "round",
        str("rack19_holes: unknown hole_type '", hole_type, "'"));
    d = depth > 0 ? depth : 40;
    for (x = rack19_hole_h_centers())
        for (z = rack19_hole_z(u))
            translate([x, -d/2, z]) rotate([-90, 0, 0]) {
                if (hole_type == "square")
                    linear_extrude(d)
                        square(rack19_square_size(), center = true);
                else {
                    dd = hole_type == "tapped" ? rack19_screw_clearance(dia) : dia;
                    cylinder(h = d, d = dd);
                }
            }
}

/* [Placeholder] */
// Reference envelope: four vertical rail flanges (front + rear, L + R) as
// solids over `u` units, carrying the hole strip on the FRONT flanges only.
// Front flange faces sit at Y=0; rear flange faces sit at
// depth_ftf - flange_thickness. The usable-equipment keep-out (opening_width
// wide, depth_ftf deep, u*pitch tall) is shown with the `%` background
// modifier for a visual fit-check, not part of the solid envelope.
module rack19_placeholder(u, depth_ftf, hole_type = "square") {
    h  = u * rack19_u();
    fw = rack19_flange_width();
    ft = rack19_flange_thickness();
    // four vertical rail flanges (front + rear, L + R)
    // NOTE: flanges are centered on the hole column (x +/- fw/2), not the true
    // EIA post centerline (holes sit ~0.8mm inboard of post center on real
    // racks) — a reference-envelope simplification, not post-accurate; fine
    // for this placeholder's stated non-print-ready fit-check role.
    for (x = rack19_hole_h_centers())
        for (y = [0, depth_ftf - ft])
            difference() {
                translate([x - fw/2, y, 0]) cube([fw, ft, h]);
                if (y == 0)  // stamp holes only through the front flanges
                    rack19_holes(u, hole_type,
                        // 5mm: illustrative default round-hole clearance dia for this
                        // preview only, NOT a sourced value — a consumer wanting a real
                        // round-hole size should call rack19_holes() directly with dia set.
                        hole_type == "round" ? 5 : hole_type == "tapped" ? "M6" : 0);
            }
    // usable equipment volume marker (between rails, front to rear)
    %translate([-rack19_opening_width()/2, 0, 0])
        cube([rack19_opening_width(), depth_ftf, h]);
}

/* [Panel helper] */
// Faceplate blank: full 19in panel width x (u*pitch) tall x `thickness`, front
// face on Y=0 (grows -Y). Consumer subtracts rack19_holes() for mounting holes.
module rack19_panel(u, thickness = 3) {
    translate([-rack19_panel_width()/2, -thickness, 0])
        cube([rack19_panel_width(), thickness, u * rack19_u()]);
}
