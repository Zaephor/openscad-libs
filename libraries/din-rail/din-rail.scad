// din-rail library.
// EN 60715 TS35 top-hat DIN rail: profile data (Task 2) + support-free
// mounting clip (Task 3). See RESEARCH.md for tiered dimensional sourcing.
//
// Component roles (see docs/LIBRARY-AUTHORING.md):
//   1. Data    — functions returning constants / [x,y] coord lists
//                (expose as functions: OpenSCAD `use` does not import variables)
//   2. Profile — din_rail_profile(): reference hat-section solid, fit/context geometry
//   3. Clip    — din_clip(): support-free printable snap clip that mates with the rail
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
//
// NOTE: identifiers use underscores, not hyphens — OpenSCAD parses a hyphen
// as the minus operator, so the hyphenated library/file name "din-rail"
// cannot appear literally in a function/module name.
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

/* [Clip] — support-free TS35 snap clip. */
// din_clip_catch_span(type, clearance): outer-tip-to-outer-tip Y span of the two
// catch barbs the clip presents to the rail. The modeled rail's retention
// feature is an INWARD return lip (din_rail_lip), so the clip catches from
// INSIDE the hat channel: the span must exceed the gap between the two lips'
// inner edges (din_rail_size[0] - 2*t - 2*lip_return) so each barb overlaps its
// lip, yet stay under the gap between the leg inner faces (…- 2*t) so the barb
// clears the leg on entry. Single source of truth for the clip's catch width
// and the mate assert in tests/din-rail_test.scad.
function din_clip_catch_span(type, clearance = 0.4) =
    din_rail_size(type)[0] - 2 * din_rail_size(type)[2] - 2 * clearance;

// din_clip(): printable snap clip that mates with din_rail_profile(type).
//
// PRINT ORIENTATION (support-free, Bambu P1S / PETG, no supports): the flat
// BACK PLATE lies on the bed and the two catch prongs point straight UP (+Z).
// Every face is then support-free by construction: the back plate is the first
// layer; the prongs are vertical walls (0° overhang); each catch barb is a
// SYMMETRIC 45° triangular wedge, so both its lead-in (upper) face and its
// retention (under) face sit at 45° — the steepest self-supporting angle for
// PETG (design-for-print: overhangs-supports.md / house-rules.md). No bridges,
// no undercut steeper than 45°.
//
// MOUNTING FACE: the OUTER face of the back plate (the -Z face, farthest from
// the rail) is the face that BONDS to the consumer's part — glue it, or union
// din_clip() into a host body so this face is co-planar with the host's
// mounting surface. The +Z (inner) face of the back plate seats flush against
// the rail's open front face.
//
// ENGAGEMENT: an inner-grip catch (see din_clip_catch_span). Two prongs enter
// the hat channel; each carries an outward barb that hooks the rail's inward
// return lip (din_rail_lip). One prong is a rigid, gusset-braced FIXED hook;
// the other is an unbraced FLEXING cantilever that deflects inward to snap over
// its lip and springs back — the standard fixed-hook-one-edge /
// flexing-latch-other-edge DIN pattern. Physical snap tension is bench-tuned by
// the caller via `clearance` and `wall` (`wall` sets the cantilever's
// stiffness — thinner wall = softer snap). `flex_len` does NOT affect snap
// tension: the catch barb's load point is pinned at apex_z = lip_h, near the
// prong's fixed root, regardless of flex_len — raising flex_len only adds
// guide-wall height ABOVE the barb (see `lead_in`), not flex between the root
// and the load point. (NOT validated here — the CI gate is geometric
// engagement only; see README "Coverage").
//
// Params:
//   type      rail key (din_known_rails()).
//   width     clip extent along the rail length (X), mm.
//   clearance per-side running gap between barb tip and leg inner face, mm
//             (free/running band; larger = looser snap).
//   wall      prong / back-plate thickness, mm.
//   flex_len  Z height of the flexing cantilever's prong WALL, from the back
//             plate up to the wall top; undef => auto (just tall enough to
//             carry the barb + lead_in). Does NOT soften the snap: the catch
//             barb's load point is pinned at apex_z = lip_h regardless of
//             flex_len, so this only sets the guide-wall height above the
//             barb (rail lead-in / insertion alignment). Must be >= the
//             barb's top (asserted below) so the barb stays wall-backed. To
//             soften the snap, reduce `wall` instead (thinner wall = more
//             flexible cantilever).
//   lead_in   extra prong-wall height above the barb, a straight guide lip
//             that funnels the rail into the mouth, mm. (The barb's own lower
//             45° face is the actual snap lead-in.)
module din_clip(type = "ts35-7.5", width = 15, clearance = 0.4,
                wall = 2.4, flex_len = undef, lead_in = 1.0) {
    sz  = din_rail_size(type);        // [w, d, t, pitch]
    w = sz[0]; d = sz[1]; t = sz[2];
    lp = din_rail_lip(type);          // [lip_h, lip_return]
    lip_h = lp[0]; lip_r = lp[1];

    // Barb geometry (symmetric 45° wedge => support-free both faces).
    apex_y = w / 2 - t - clearance;   // outer barb tip: just inside the leg face
    reach  = lip_r + clearance;       // barb protrusion from the prong outer face
    prong_out = apex_y - reach;       // prong outer face Y
    apex_z  = lip_h;                  // catch tip at the lip TOP plane (hooks over the lip)
    barb_lo = apex_z - reach;         // barb inner-base bottom (45°; may dip <0 into back plate)
    barb_hi = apex_z + reach;         // barb inner-base top (45° lead-in face down to apex)
    prong_h = barb_hi + lead_in;      // prong rises to carry barb + guide-lip mouth

    // Keep the prong under the rail's top bridge (Z in [d-t, d]) — no clip-thru.
    max_h = d - t - clearance;
    assert(prong_h <= max_h,
        str("din_clip: prong (", prong_h, "mm) exceeds channel depth for '",
            type, "' (", max_h, "mm) — reduce lead_in/clearance"));

    flen = is_undef(flex_len) ? prong_h : min(flex_len, max_h);
    assert(flen >= barb_hi,
        str("din_clip: flex_len (", flen, "mm) is below the catch barb's top (",
            barb_hi, "mm) — the barb would go unbacked by the prong wall; ",
            "raise flex_len or omit it"));

    back_y = w / 2 + 2;               // back plate half-width (past the rail edge)

    // One prong: vertical wall + outward 45° catch barb, built at +Y and
    // mirrored for -Y. The barb's LOWER 45° face is the insertion lead-in (the
    // rail lip cams on it); its UPPER 45° face is the retention catch. The
    // `lead_in` param raises the prong wall above the barb as a guide lip that
    // funnels the rail into the mouth. `braced` adds an inner 45° gusset
    // (=> rigid fixed hook); unbraced => flexing cantilever latch. `h` is the
    // prong height (barb top + lead_in).
    module _prong(braced, h) {
        // vertical prong wall, rooted on the back plate top (Z=0)
        translate([-width/2, prong_out - wall, 0]) cube([width, wall, h]);
        // outward catch barb: symmetric 45° wedge, apex at the lip top plane
        // (apex_y, apex_z). Underside (apex->barb_lo) is the retention catch that
        // hooks over the lip; upper face (apex->barb_hi) is the insertion lead-in.
        // Fully supported from below by its own triangle (no floating edge).
        rotate([0, 90, 0]) translate([0, 0, -width/2]) linear_extrude(width)
            polygon([[-barb_lo, prong_out], [-apex_z, apex_y], [-barb_hi, prong_out]]);
        // fixed hook: inner 45° gusset bracing the prong against inward flex
        if (braced)
            rotate([0, 90, 0]) translate([0, 0, -width/2]) linear_extrude(width)
                polygon([[0, prong_out - wall], [0, prong_out - wall - h],
                         [-h, prong_out - wall]]);
    }

    union() {
        // back plate: flat on the bed (mounting face at Z=-wall), spanning the
        // rail front. Seats against the rail front plane at Z=0.
        translate([-width/2, -back_y, -wall]) cube([width, 2 * back_y, wall]);
        // +Y prong = rigid FIXED hook (gusset-braced)
        _prong(true, prong_h);
        // -Y prong = FLEXING cantilever latch (unbraced), height = flen
        mirror([0, 1, 0]) _prong(false, flen);
    }
}
