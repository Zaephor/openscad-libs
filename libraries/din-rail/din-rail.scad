// din-rail library.
// EN 60715 TS35 top-hat DIN rail: profile data (Task 2) + support-free
// mounting clip (Task 3). See RESEARCH.md for tiered dimensional sourcing.
//
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — envelope solid for fit checks
//   3. Hole-stamp  — mounting/cutout stamps for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
//
// NOTE: OpenSCAD identifiers cannot contain hyphens (parsed as the minus
// operator) — the template's naive __NAME__ substitution produces invalid
// identifiers (e.g. "din-rail_width") for this hyphenated library name.
// Task 2/3 must name functions/modules with underscores instead
// (e.g. din_rail_width(), din_rail_placeholder()), not the literal
// "din-rail" library/file name.
//
// Task 2: profile data + accessors + din_rail_profile() reference module.
// Task 3 adds the support-free din_clip().

$fn = 48;

/* [Data] — TS35 top-hat rail table. Tiers per docs/LIBRARY-AUTHORING.md; see RESEARCH.md.
   Row: [type, width, depth, material_t, slot_pitch, lip_height, lip_return] mm.
   width/depth/material_t/slot_pitch = TS35 profile per EN 60715 (via corroborating
   vendor peers — EN 60715 itself is paywalled, capping these at [B]).
   lip_height/lip_return = inward return-edge lip a snap clip catches on; no source
   found gives a dimensioned drawing (IEC 60715 Annex A, paywalled) — modeled as a
   conservative nominal, [C]//VERIFY, per RESEARCH.md "Return-edge lip geometry". */
function _din_table() = [
    // type          w    d     t    pitch  lip_h  lip_return
    ["ts35-7.5",     35,  7.5,  1.0, 25,    1.0,   1.0], // [B] dims: WAGO 210-112, Phoenix Contact NS 35/7.5 PERF (25mm pitch, not the brief's ~27mm guess). [C]//VERIFY lip: height ~= material_t, return = conservative 1mm minimum
    ["ts35-15",      35,  15,   1.5, 25,    1.5,   1.0], // [B]//VERIFY dims: WAGO 210-197 (material_t is vendor-variant, 1.2-2.3mm reported elsewhere; 1.5mm used as nominal). [C]//VERIFY lip: height ~= material_t, return = conservative 1mm minimum
];
function din_known_rails() = [for (e = _din_table()) e[0]];
function _din_row(type) =
    let (m = [for (e = _din_table()) if (e[0] == type) e])
    len(m) > 0 ? m[0]
    : assert(false, str("din-rail: unknown rail '", type, "'"));
function din_rail_size(type) = [ _din_row(type)[1], _din_row(type)[2], _din_row(type)[3], _din_row(type)[4] ];
function din_rail_lip(type)  = [ _din_row(type)[5], _din_row(type)[6] ];

/* [Profile] */
// Reference/fit geometry for the TS35 top-hat cross-section, extruded along X
// (rail length). Orientation: rail axis = X (centered), cross-section in Y/Z
// (width centered in Y, bottom of legs on Z=0), hat opening toward -Z (hollow
// between the legs, under the top bridge, open at the bottom). Built as the
// outer envelope (width x depth) minus an inner cavity inset by material_t on
// the sides and top (open at the bottom, per orientation) — leaving two side
// legs and a top bridge each of thickness material_t — plus the inward return
// lips (din_rail_lip) at the inner-bottom edge of each leg, where a clip hooks
// on. Reference geometry for fit context (typically rendered `%` by
// consumers); not itself print-oriented.
module din_rail_profile(type, length = 100) {
    sz  = din_rail_size(type); // [w, d, t, pitch]
    w = sz[0]; d = sz[1]; t = sz[2];
    lip = din_rail_lip(type);  // [lip_h, lip_return]
    lip_h = lip[0]; lip_r = lip[1];

    translate([-length / 2, -w / 2, 0])
    union() {
        difference() {
            cube([length, w, d]);                                    // outer hat envelope
            translate([0, t, 0]) cube([length, w - 2 * t, d - t]);    // inner cavity, open at bottom (-Z)
        }
        // inward return lips, inner-bottom edge of each leg
        translate([0, t, 0])              cube([length, lip_r, lip_h]);
        translate([0, w - t - lip_r, 0])  cube([length, lip_r, lip_h]);
    }
}
