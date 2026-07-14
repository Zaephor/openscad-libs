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
// Data functions below are real LabRax core dimensions, sourced from
// RESEARCH.md. The Data / Hole-stamp / Placeholder / Panel-helper sections
// below are all fully implemented and live (nothing commented out).

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

// Three hole centers within one U, Z from that U's lower edge. Gaps
// 15.875/15.875/12.7 sum to one U. LabRax targets EIA hole compatibility.
function rack10_u_hole_offsets() = [6.35, 22.225, 38.1]; // //VERIFY 10in uses the 3-hole EIA sub-pattern — confirm in RESEARCH.md; gaps [B]
// Every hole-center Z for a `u`-unit stack, ascending. round(...*1e6)/1e6
// strips ~1e-14mm float summation noise so exact decimals compare with ==.
function rack10_hole_z(u) =
    [for (i = [0:u-1]) for (o = rack10_u_hole_offsets())
        round((i*rack10_u() + o)*1e6)/1e6];

// Cage-nut square side (carried for future square-hole vendors e.g. DeskPi/
// TecMojo; LabRax itself uses round/M6/#10-32). [B] //VERIFY (rack19 precedent).
function rack10_square_size() = 9.5;
function rack10_known_hole_types() = ["round", "m6", "10-32", "square", "slot"];
// Screw-clearance dia per fastener, mm (values + provenance carried from rack19,
// re-implemented locally — no cross-lib coupling). See RESEARCH.md.
//   m6:    [B] ISO 273 close-fit (repo hardware lib series 3.4/4.5/5.5).
//   10-32: [C] //VERIFY ANSI B18.2 close-fit (#10 ~0.199in=5.05->5.0mm), named
//          standard cited from memory, not fetched.
function rack10_screw_clearance(fastener) =
    fastener == "m6"    ? 6.6 :
    fastener == "10-32" ? 5.0 :
    assert(false, str("rack10: unknown fastener '", fastener, "'"));

/* [Hole-stamp] */
// 10in hole strip as subtractable solids, both rails, `u` units. Axis along +Y.
// hole_type: "round" (numeric clearance dia in `dia`), "m6"/"10-32" (dia from
// rack10_screw_clearance), "square" (rack10_square_size), "slot" (obround,
// dia + slot_travel along X). Cutter CENTERED on the
// front-post plane Y=0 (spans y in [-d/2,+d/2]) so one stamp cuts panels (grow
// -Y) and rail flanges (grow +Y). depth (`d`) sizes that span; default 40 =
// -20..+20, enough for realistic panels/rails; a smaller value can under-cut.
module rack10_holes(standard, u, hole_type = "round", dia = 0, depth = 0, slot_travel = 4) {
    assert(hole_type == "round" || hole_type == "m6" || hole_type == "10-32"
        || hole_type == "square" || hole_type == "slot",
        str("rack10_holes: unknown hole_type '", hole_type, "'"));
    d = depth > 0 ? depth : 40;
    for (x = rack10_hole_h_centers(standard))   // also asserts on unknown standard
        for (z = rack10_hole_z(u))
            translate([x, -d/2, z]) rotate([-90, 0, 0]) {
                if (hole_type == "square")
                    linear_extrude(d) square(rack10_square_size(), center = true);
                else if (hole_type == "slot") {
                    // Horizontal obround (racetrack); width from dia (a screw
                    // clearance), elongated slot_travel along X.
                    // slot_travel default = 4mm is illustrative, no sourced
                    // post-tolerance figure. //VERIFY: confirm against real
                    // rackpost drilling tolerance if available.
                    assert(dia > 0,
                        "rack10_holes: slot requires dia>0 (e.g. rack10_screw_clearance(\"m6\"))");
                    linear_extrude(d)
                        hull() for (sx = [-1, 1])
                            translate([sx * slot_travel / 2, 0]) circle(d = dia);
                }
                else {
                    dd = hole_type == "round" ? dia : rack10_screw_clearance(hole_type);
                    cylinder(h = d, d = dd);
                }
            }
}

/* [Panel helper] */
// Faceplate blank: vendor panel width × (u*pitch) tall × `thickness`, front
// face on Y=0 (grows -Y). Consumer subtracts rack10_holes() for mounting holes.
module rack10_panel(standard, u, thickness = 3) {
    translate([-rack10_panel_width(standard)/2, -thickness, 0])
        cube([rack10_panel_width(standard), thickness, u * rack10_u()]);
}

// Rail/post envelope — informational placeholder ONLY, NOT measured (LabRax
// STL unreachable, see RESEARCH.md "Rail flange width/thickness"). LabRax
// posts are printed plastic, not sheet metal, so there is no rolled-flange
// spec to source in the first place. These are illustrative defaults for the
// reference envelope, not a sourced dimension — no tier tag applies; there is
// literally zero numeric evidence behind either number this pass.
function rack10_flange_width()     = 10; // illustrative default, not measured
function rack10_flange_thickness() = 3;  // illustrative default, not measured

/* [Placeholder] */
// Reference envelope: four vertical rail flanges (front+rear, L+R) over `u`
// units at the vendor's hole-cc, carrying the hole strip on the FRONT flanges.
// Front faces at Y=0; rear faces at depth_ftf - flange_thickness. Usable-
// equipment keep-out (clear_width wide × depth_ftf deep × u*pitch tall) shown
// with `%`. Flanges centered on the hole column (reference-envelope
// simplification, not post-accurate) — non-print-ready fit-check role.
module rack10_placeholder(standard, u, depth_ftf, hole_type = "round") {
    h  = u * rack10_u();
    fw = rack10_flange_width();
    ft = rack10_flange_thickness();
    for (x = rack10_hole_h_centers(standard))
        for (y = [0, depth_ftf - ft])
            difference() {
                translate([x - fw/2, y, 0]) cube([fw, ft, h]);
                if (y == 0)  // holes on front flanges only
                    rack10_holes(standard, u, hole_type,
                        // 5mm: illustrative preview clearance for "round"/"slot" only,
                        // NOT sourced; slot_travel uses its default.
                        hole_type == "round" || hole_type == "slot" ? 5 : 0);
            }
    %translate([-rack10_clear_width(standard)/2, 0, 0])
        cube([rack10_clear_width(standard), depth_ftf, h]);
}
