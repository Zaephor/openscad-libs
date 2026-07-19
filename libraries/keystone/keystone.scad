// keystone — keystone-jack snap-footprint reference (de-facto interchangeable
// standard: one snap profile fits any compliant jack/plate). Datum: millimeters.
// DEFAULT ORIENTATION (panel-mount): panel FRONT face at Z=0, centered in X/Y,
// jack body grows -Z (behind the panel), show-face/opening toward +Z. Consumers
// rotate the whole port to orient their panel (e.g. -90deg about X for a
// vertical 1U faceplate). Opening [ow,oh] = X width x Y height of the plate
// window; body [bw,bh,bd] = X,Y extents x Z depth behind the panel.
//
// Retention mechanism (#38): the canonical style is "standard" -- a
// `[`-shaped channel (back wall + top/bottom walls) with a wide slit cut
// clean through EACH of the top and bottom walls, mated by a jack whose rear
// section carries a solid fulcrum (bottom) and a flexing arm (top), each
// with its own small notch, both clicking into their respective slit at the
// SAME insertion depth (push-to-click, not rotate-in -- see RESEARCH.md
// "Standard keystone latch geometry (#38)"). "lip" is a DEPRECATED ALIAS
// resolving to "standard" (it named a different, real-but-less-common
// rotate-and-snap mechanism mesh-measured by #31 before #38 corrected course
// -- see RESEARCH.md "Real latch geometry (#31, STL-mesh)" for that
// superseded reading). Proprietary lookalike modules (Mini-Com, HD) are out
// of scope.
//
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//                    incl. keystone_slot(style): measured `[`-channel/slit
//                    geometry (#38) and keystone_notch(style): measured
//                    jack-side fulcrum/flex-arm geometry (#38); also
//                    keystone_boss_footprint(style, clearance): the boss
//                    sizing keystone_boss()/keystone_min_pitch() below derive from
//   2. Placeholder — keystone_placeholder(): jack envelope solid for fit checks
//   3. Hole-stamp  — keystone_cutout(plate_thickness, clearance, style): plate
//                    window for a consumer difference(); keystone_boss(
//                    plate_thickness, clearance, style): LOCAL positive
//                    material behind a thin panel so "standard"'s real
//                    channel always lands in solid material regardless of
//                    panel thickness (no-op for "face");
//                    keystone_insert(plate_thickness, fit, style): geometric
//                    mate-reference body, plug = keystone_face() (NOT
//                    print-tuned in v1; "standard"'s tabs are a Task-3
//                    placeholder as of #38, see its own comment)
//   + Fit-check    — keystone_pitch()/min_pitch(style)/pitch_ok(pitch,style)/
//                    layout_ok(xs,style) + keystone_pitch_assert(pitch,style):
//                    single-source port-spacing guard, boss-footprint-driven
//                    for "standard", opening+wall for "face" (unchanged)
// Provenance legend (see RESEARCH.md for the evidence log):
//   [A] vendor datasheet / governing drawing.  [B] >=2 independent peers agree.
//   [C] reverse-engineered from a public STL/SCAD mesh (cite the artifact
//       URL) — NOT single-sourced/uncorroborated (that's //VERIFY).
//   //VERIFY marks a weak/unsourced value — never a tier it didn't earn.
//
// Keystone is a de-facto standard; expect [A]/[B]/VERIFY. opening/pitch/tmin
// (both styles) and the "standard" channel/notch geometry (keystone_slot(),
// keystone_notch(), #38) are sourced+tiered below; body depth+W/H, min_wall,
// tmax, and keystone_tab() numerics remain //VERIFY pending stronger
// corroboration — see RESEARCH.md.
// All three roles implemented: (1) data table + accessor functions
// (keystone_opening(), keystone_body(), keystone_plate_thickness(), keystone_pitch(),
// keystone_min_wall(), keystone_tab(), keystone_slot(), keystone_notch(),
// keystone_boss_footprint()), (2) keystone_placeholder() envelope for
// fit-check, and (3) keystone_cutout()/keystone_boss()/keystone_insert()
// hole-stamp/mate-reference modules.

$fn = 48;

/* [Data] — single canonical keystone profile. Tiers per docs/LIBRARY-AUTHORING.md;
   see RESEARCH.md for the full evidence log. */
function keystone_known_styles() = ["standard", "face"];

// _keystone_resolve_style(style): canonical-name resolution. undef and the
// deprecated "lip" alias both resolve to "standard"; "standard"/"face" pass
// through unchanged; anything else aborts. Every style-keyed accessor below
// routes through this first so the alias/default only needs to live in one
// place (#38).
function _keystone_resolve_style(style) =
    (style == undef || style == "lip") ? "standard" :
    (style == "standard" || style == "face") ? style :
    assert(false, str("keystone: unknown style '", style, "'"));

// Invariant jack face / plug cross-section [fw,fh], mm. [B] Wikipedia keystone
// module (14.5 x 16.0), corroborated across retailer/installer sources.
function keystone_face() = [14.5, 16.0];

// keystone_slot(style): measured `[`-channel/slit geometry (#38, RESEARCH.md
// "Standard keystone latch geometry (#38, STL-mesh)" > "Slot (channel)
// geometry"), "standard" only ("face" has no channel -- plain rectangular
// hole, see keystone_cutout()). Two independent slot models were
// mesh-sectioned; Model 1 ("Ethernet RJ45 keystone socket wall plate",
// Printables 1014552) has the fuller per-slit breakdown and is the source
// for every field below unless noted. Returns
// [back_wall_depth, wall_thickness, mouth_w, mouth_h, top_slit_w,
//  top_slit_len, top_slit_depth, bot_slit_w, bot_slit_len, bot_slit_depth],
// all mm, all //VERIFY (single-model reading) except where marked [C]:
//   back_wall_depth (10.05) — [C] cross-model corroborated: Model 1 reads
//     10.05mm, Model 2 ("Voron 0.2r1 Rear Skirt w/keystone", Printables
//     533549) independently reads ~10.0-10.05mm — two unrelated designs
//     agreeing on this specific value clears the [C] bar.
//   wall_thickness (1.51) — residual material bridging each slit, same on
//     top and bottom in Model 1.
//   mouth_w, mouth_h (15.3, 18.4) — baseline channel cross-section just past
//     the front lead-in (this library does not model that lead-in chamfer
//     separately -- see keystone_cutout()'s module comment).
//   top_slit_w, bot_slit_w (15.3, == mouth_w) — "slit width in X does not
//     narrow -- each slit runs the full width of the channel."
//   top_slit_len, bot_slit_len (8.0, 6.5) — top slit runs essentially to the
//     back wall; bottom slit is shorter (ends ~1.5mm before the back wall).
//     This top>bottom asymmetry is single-model (Model 2's own close is
//     symmetric-taper, not corroborating this specific asymmetry).
//   top_slit_depth, bot_slit_depth (both 2.05) — [C] for the QUALITATIVE
//     finding that both slits begin at the SAME depth (corroborated
//     jointly by Model 2, which shows both edges moving together at ~1.5mm
//     depth in its own reading) -- this is the finding that distinguishes
//     "standard" from #31's staged "lip" mechanism. The exact 2.05mm value
//     itself is single-model //VERIFY (Model 2's own specific depth,
//     1.5mm, differs).
function keystone_slot(style = undef) =
    let(s = _keystone_resolve_style(style))
    s == "standard" ? [
        10.05, // back_wall_depth [C] (1014552 + 533549)
        1.51,  // wall_thickness //VERIFY (1014552)
        15.3,  // mouth_w //VERIFY (1014552)
        18.4,  // mouth_h //VERIFY (1014552)
        15.3,  // top_slit_w //VERIFY (1014552; == mouth_w, full-width slit)
        8.0,   // top_slit_len //VERIFY (1014552)
        2.05,  // top_slit_depth //VERIFY mm ([C] same-start-depth finding, jointly w/ 533549)
        15.3,  // bot_slit_w //VERIFY (1014552; == mouth_w)
        6.5,   // bot_slit_len //VERIFY (1014552)
        2.05   // bot_slit_depth //VERIFY mm ([C] same-start-depth finding, jointly w/ 533549)
    ] :
    assert(false, str("keystone: keystone_slot has no channel data for style '", s, "'"));

// keystone_notch(style): measured jack-side fulcrum/flex-arm geometry (#38,
// RESEARCH.md "Standard keystone latch geometry (#38, STL-mesh)" > "Insert
// (module) geometry"), "standard" only. Model 1 ("SMA-Keystone Modul",
// Printables 366437) is a single self-contained STL modeling both features
// and is the source for every field below (it's also the only model with a
// measurable arm_root_z -- Model 2's ("SFP+ Cable Keystone Jack", Printables
// 314383) Hook.stl ships unregistered to its body's coordinate frame, so
// root_z could not be read from it). Returns
// [fulcrum_base, fulcrum_protrusion, fulcrum_z, arm_thickness, arm_length,
//  arm_root_z, topnotch_base, topnotch_protrusion, topnotch_z], all mm, all
// //VERIFY (single-model mm) except where marked [C]:
//   fulcrum_base/protrusion (2.0, 1.5) — the bottom fulcrum's triangular notch.
//   fulcrum_z (7.1) — midpoint of the measured 6.1-8.1mm behind-front-face
//     range (a range, not a point, in the source reading).
//   arm_thickness, arm_length (1.7, 14.0) — the top flex arm's cantilever
//     thickness and free length (root fold to where its own notch begins).
//   arm_root_z (20.0) — depth behind the front face where the arm's root
//     (hairpin fold) sits.
//   topnotch_base/protrusion (2.6, 1.0) — the top arm's own triangular notch,
//     at the arm's FREE TIP (not partway along it -- corrected via an
//     ordered-vertex re-trace, see RESEARCH.md).
//   topnotch_z (7.4) — midpoint of the measured 6.1-8.7mm range.
//   [C]: both models independently corroborate the SHAPE and
//   position-ORDER-OF-MAGNITUDE of (a) a triangular notch on a solid bottom
//   fulcrum in the ~6-8.7mm range and (b) a flexing top arm with its own
//   triangular notch at the arm's free tip -- this is what confirms the
//   push-to-click, same-depth mechanism (both notches seat where
//   keystone_slot()'s two slits open). The exact mm figures differ per
//   model and are NOT numerically corroborated, so every individual number
//   above stays //VERIFY.
function keystone_notch(style = undef) =
    let(s = _keystone_resolve_style(style))
    s == "standard" ? [
        2.0,  // fulcrum_base //VERIFY (366437)
        1.5,  // fulcrum_protrusion //VERIFY (366437)
        7.1,  // fulcrum_z //VERIFY (366437; midpoint of measured 6.1-8.1mm)
        1.7,  // arm_thickness //VERIFY (366437)
        14.0, // arm_length //VERIFY (366437)
        20.0, // arm_root_z //VERIFY (366437; unmeasurable in 314383)
        2.6,  // topnotch_base //VERIFY (366437)
        1.0,  // topnotch_protrusion //VERIFY (366437)
        7.4   // topnotch_z //VERIFY (366437; midpoint of measured 6.1-8.7mm)
    ] :
    assert(false, str("keystone: keystone_notch has no notch data for style '", s, "'"));

// Panel WINDOW to cut, per retention style [ow,oh], mm:
//   "standard" = the channel's max window: mouth width x (mouth height + 2x
//                the wall thickness the slits open through) -- derived from
//                keystone_slot() (single source of truth), not hand-copied.
//   "face"     = face-grip (retention by plate-thickness front/rear grip):
//                [14.70, 16.40] [A] Samm Teknoloji "Suggested Panel Cutout" (pre-#28 value).
function keystone_opening(style = undef) =
    let(s = _keystone_resolve_style(style))
    s == "standard" ? let(sl = keystone_slot(s)) [sl[2], sl[3] + 2 * sl[1]] :
    [14.70, 16.40];

// [bw,bh,bd] jack envelope keep-out (X,Y,Z-depth behind panel), mm. bd=28.60
// //VERIFY: Samm Teknoloji drawing's single labelled overall-depth dimension
// (assembled jack + rear wire cap) — a single, non-decomposed reading from
// one vendor drawing, not STL/mesh-derived and not corroborated by a second
// source, so it does not earn [C] or [B]. Confirm against a second jack's
// drawing (or an STL/caliper measurement) before treating as load-bearing.
// bw/bh //VERIFY: the drawing's orthographic view callouts (~17-20mm range)
// could not be confidently axis-mapped this pass; seeded as a conservative
// keep-out margin above keystone_opening().
function keystone_body()            = [17.5, 19.5, 28.60];
// [min,max] accepted faceplate thickness, mm. tmin=1.5 [A] Samm Teknoloji
// drawing's suggested cutout-panel thickness (1.50~1.60, both Metal and
// Plastic variants). tmax //VERIFY: no source found this pass for the upper
// bound the snap latch tolerates; seeded from common off-the-shelf
// decora/wall-plate stock thickness, not measured/fetched.
function keystone_plate_thickness() = [1.5, 3.0];
// Nominal center-to-center in a patch-panel/faceplate strip, mm. [B] 3/4in
// (19.05mm) cited as the de-facto keystone patch-panel port pitch across
// multiple independent retailer/community sources; some brand variance noted
// (a few run wider to clear bulky punch-down backs). See RESEARCH.md.
function keystone_pitch()           = 19.05;
// Min printable material wall between adjacent openings, mm. //VERIFY: this
// is the repo's generic print-process convention (2x 0.4mm nozzle line
// width, 2-perimeter default), not a keystone-specific spec and not backed
// by any source at all (no datasheet, no mesh, no corroboration) — confirm
// with an actual print test (or point at a shared print-convention library
// value, if/when one exists) before treating as load-bearing.
function keystone_min_wall()        = 1.6;
// tab: [hook_ledge_z, tab_thickness, hook_edge, latch_edge] — mate-reference
// placeholder numerics for keystone_insert()'s "face" branch (unchanged
// since #28) and, for now, its "standard" branch too (#38 renamed the style
// key this applies under; the NUMBERS were never "lip"-mechanism-derived in
// the first place -- keystone_insert()'s real retention shape for "standard"
// comes from keystone_notch(), see keystone_insert()'s own comment; this
// function stays a compiling placeholder until Task 3 replaces its
// "standard" usage). hook_edge/latch_edge //VERIFY: Wikipedia's "Keystone
// module" article describes a fixed angled flange opposite a flexing
// cantilever latch -- a single secondary source, not independently
// corroborated, so it does not earn [B].
function keystone_tab(style = undef) =
    let(s = _keystone_resolve_style(style)) [1.0, 1.2, "+Y", "-Y"];

// keystone_boss_footprint(style, clearance): [w, h, y_center] rectangular
// footprint (X,Y) for keystone_boss(style) below -- "standard"'s channel
// envelope (keystone_slot() mouth + both wall thicknesses, clearance-grown)
// plus keystone_min_wall() wall margin per side (adjacent-port spacing;
// "standard"'s channel itself is X-invariant/open-sided per RESEARCH.md, so
// this margin is a print-convention/spacing addition, not a measured wall).
// "standard" ONLY (keystone_boss() is a no-op for "face" -- nothing to
// size). clearance defaults to keystone_cutout()'s own default (0.25) --
// pass the SAME clearance to both if overriding it, else the boss and its
// cutout disagree. y_center is 0 (the standard channel's top/bottom slits
// open the SAME amount, unlike #31's "lip" asymmetric hook/latch offset).
// keystone_min_pitch() below is this footprint's sole other consumer
// (single source of truth for the boss-collision guard).
function keystone_boss_footprint(style = undef, clearance = 0.25) =
    let(s = _keystone_resolve_style(style))
    s == "standard" ? let(
        sl = keystone_slot(s),
        margin = keystone_min_wall(),
        w = sl[2] + 2 * clearance + 2 * margin,
        h = sl[3] + 2 * sl[1] + 2 * clearance
    ) [w, h, 0] :
    assert(false, str("keystone: keystone_boss_footprint has no boss for style '", s, "'"));

/* [Fit-check] — single-source port-spacing guard. min_pitch derived once here so
   no consumer re-derives it. "standard" (#38) is boss-footprint-driven (the
   boss, not the raw opening, is what two adjacent ports must clear); "face"
   is unchanged (plain-rectangle opening + wall, no boss). */
function keystone_min_pitch(style = undef) =
    let(s = _keystone_resolve_style(style))
    s == "standard" ? keystone_boss_footprint(s)[0] :
    keystone_opening(s)[0] + keystone_min_wall();
function keystone_pitch_ok(pitch, style = undef) = pitch >= keystone_min_pitch(style);
// keystone_layout_ok(xs, style): xs = ascending list of port X-centers; true
// if every adjacent gap clears min_pitch(style). (<2 ports always fits.)
function keystone_layout_ok(xs, style = undef) =
    len(xs) < 2 ? true
    : min([for (i = [1:len(xs)-1]) xs[i] - xs[i-1]]) >= keystone_min_pitch(style);

// keystone_pitch_assert(pitch, style): hard-fail at render if a consumer's
// uniform port pitch is below min_pitch(style) (catch it here, not on the
// print bed).
module keystone_pitch_assert(pitch, style = undef) {
    assert(keystone_pitch_ok(pitch, style),
        str("keystone: pitch ", pitch, " < min_pitch ", keystone_min_pitch(style)));
}

/* [Placeholder] — jack envelope: flange face at Z=0, body grows -Z. For
   fit/interference viz only (envelope is a max keep-out, not a detailed jack). */
module keystone_placeholder() {
    b = keystone_body(); // [bw, bh, bd]
    translate([-b[0]/2, -b[1]/2, -b[2]])
        cube([b[0], b[1], b[2]]);
}

// _keystone_plateau_depth(): carried forward from #31 -- still used by
// keystone_insert()'s placeholder branch below (Task 3 will remove this
// dependency when it rebuilds that branch from keystone_notch()).
function _keystone_plateau_depth() = 1.30;

// _keystone_chamfer_margin(): print-safety factor (NOT a measured value --
// a repo print-process choice, same spirit as keystone_min_wall()) applied
// to the bare 45deg self-support minimum for keystone_cutout("standard")'s
// back-wall taper below, so the modeled ramp sits safely under 45deg rather
// than exactly at the limit (design-for-print guidance: "don't treat 44deg
// as automatically safe, leave margin"). 1.15 = the ramp is 15% longer than
// the bare-minimum 45deg run for its rise, i.e. ~41deg from vertical.
function _keystone_chamfer_margin() = 1.15;

/* [Cutout] — plate window for a consumer difference(). "face" = plain
   rectangular through-hole (unchanged; NO undercut => support-free from any
   orientation; jack retention is by plate front-lip + rear-edge, so the
   plate thickness must sit within keystone_plate_thickness()).
   "standard" (#38) = the REAL channel negative: a `[`-shaped void (mouth +
   a wide slit cut clean through each of the top and bottom walls, per
   keystone_slot()) -- replaces #31's wrong ramped-window "lip" guess. This
   full channel needs ~10mm+ of Z depth (RESEARCH.md), far more than
   keystone_plate_thickness()'s 1.5-3.0mm range, so the "standard" branch's
   Z-extent is PLATE-THICKNESS-INDEPENDENT (always cuts the full measured
   depth) -- a thin panel alone can't host the whole channel; pair with
   keystone_boss(plate_thickness, clearance, style) below, which adds the
   missing material behind a thin panel so the cut always lands in real
   solid:
       union() { plate; translate(p) keystone_boss(t, c, style); }
       difference() { <that>; translate(p) keystone_cutout(t, c, style); }
   (Faceplate wiring of this pattern is backlog #38 Task 4, not this module.)
   Front-lead-in chamfer: RESEARCH.md's slot models show a small front
   insertion bevel on the mouth; this library does not model it separately
   (folded into the mouth's own front overcut) -- it's a lead-in detail, not
   load-bearing for the click mechanism, and omitting it keeps this module's
   geometry to exactly what keystone_slot()'s fields describe.
   Rendered slit depth vs keystone_slot()'s measured lengths: BOTH slits are
   rendered running the full remaining depth to the back wall (matching the
   longer, measured top_slit_len), rather than the bottom slit's own shorter
   measured length (bot_slit_len, kept verbatim in keystone_slot() for
   research fidelity). This is a deliberate print-driven simplification: it
   only ADDS extra clearance behind the fulcrum notch's required click depth
   (keystone_notch()'s fulcrum_z sits well inside either length), never
   removes material the mechanism needs, and it avoids a second "wall
   resumes mid-depth" overhang transition that the measured asymmetry would
   otherwise introduce (see PRINT ORIENTATION below).
   PRINT ORIENTATION (pin, "standard" only): panel FRONT face (Z=0) DOWN on
   the print bed, -Z (into the panel/boss) pointing UP during the print --
   same convention as the rest of this library. In this orientation the
   channel's own depth axis (file Z) becomes the print's vertical build
   axis, so the mouth is a tall hollow shaft (open at the bed end, closed by
   the back wall near the top of the print) and the back wall is effectively
   a "roof" over that shaft -- a flat roof over a hollow shaft needs support
   unless self-supporting (design-for-print: "chamfer/cone a blind pocket's
   closed end rather than leaving it flat" -- the vertical-shaft analogue of
   the horizontal teardrop-hole pattern). This module therefore closes the
   channel's full envelope (mouth + both slit bands) via a PYRAMIDAL TAPER
   (hull() from the full cross-section down to a point) rather than an
   abrupt flat cap, so every closing face -- in BOTH X and Y -- slopes at
   `_keystone_chamfer_margin()`-scaled-under-45deg from vertical, self-
   supporting at every layer (no bridging, no flat overhang). This taper is
   a print-safety ADDITION behind keystone_slot()'s own back_wall_depth, not
   part of the measured geometry -- it only extends the boss further into
   -Z, it never narrows the functional mouth/slit clearance in front of it.
   Front face at Z=0; mouth overcuts +1 above (folded into the front flat
   zone). `clearance` grows the mouth/slit envelope per side (X +/-
   clearance; the slits' outer Y edge +/- clearance). */
module keystone_cutout(plate_thickness = 3.0, clearance = 0.25, style = undef) {
    s = _keystone_resolve_style(style);
    if (s == "face") {
        o = keystone_opening(s); // [ow, oh]
        wx = o[0] + 2 * clearance;
        wy = o[1] + 2 * clearance;
        translate([-wx/2, -wy/2, -(plate_thickness + 1)])
            cube([wx, wy, plate_thickness + 2]);
    } else { // "standard" (#38)
        sl = keystone_slot(s); // [back_wall_depth,wall_thickness,mouth_w,mouth_h,top_slit_w,top_slit_len,top_slit_depth,bot_slit_w,bot_slit_len,bot_slit_depth]
        bwd = sl[0]; wt = sl[1]; mw = sl[2]; mh = sl[3];
        tsd = sl[6]; bsd = sl[9]; // top_slit_depth, bot_slit_depth -- both slit voids below run from here to z_back (see module comment)
        mh2 = mh / 2;
        outer = mh2 + wt;
        wx = mw + 2 * clearance;
        z_back = -bwd;
        front_overcut = 1;
        eps = 0.02;
        rise = max(outer + clearance, wx / 2); // larger of the Y and X half-envelopes being closed
        ramp = rise * _keystone_chamfer_margin();
        union() {
            // mouth (+ front overcut), spans the whole channel depth
            translate([-wx / 2, -(mh2 + clearance), z_back])
                cube([wx, 2 * (mh2 + clearance), front_overcut - z_back]);
            // top slit -- wall material removed from mh2+clearance out to
            // the slit's outer edge, from its measured start depth to the
            // back wall (see module comment on rendered-vs-measured length)
            translate([-wx / 2, mh2 + clearance, z_back])
                cube([wx, (outer + clearance) - (mh2 + clearance), -tsd - z_back]);
            // bottom slit, mirrored
            translate([-wx / 2, -(outer + clearance), z_back])
                cube([wx, (outer + clearance) - (mh2 + clearance), -bsd - z_back]);
            // back-wall roof: pyramidal taper closing the full combined
            // mouth+slit envelope to a point over `ramp` -- print-safety
            // addition, see PRINT ORIENTATION above.
            hull() {
                translate([-wx / 2, -(outer + clearance), z_back - eps])
                    cube([wx, 2 * (outer + clearance), eps]);
                translate([-eps / 2, -eps / 2, z_back - ramp - eps / 2])
                    cube([eps, eps, eps]);
            }
        }
    }
}

/* [Boss] — LOCAL positive material behind a thin panel, pairs with
   keystone_cutout(...,"standard") (see that module's comment for the full
   union()+difference() consumer pattern). "face" is a no-op (its
   plain-rectangle mechanism already fits keystone_plate_thickness()
   unchanged -- nothing to add). "standard" (#38): a rectangular pedestal,
   front face flush with the panel front (Z=0), growing -Z past the full
   channel depth INCLUDING the back-wall taper's ramp (keystone_cutout()'s
   own PRINT ORIENTATION comment) plus a small safety margin, so the
   "standard" cut above always lands in real solid regardless of
   `plate_thickness`. keystone_boss_footprint() sizes the X/Y footprint.
   PRINT ORIENTATION: same as keystone_cutout() -- front face down. The
   boss's own OUTER footprint is a CONSTANT rectangle through its whole
   Z-depth (no taper) -- a perfectly vertical prism, 0deg from vertical, so
   it needs no chamfer of its own to stay support-free (every cross-section
   is identical, and it sits on the panel's own flat, fully-solid rear
   face); all the shaping (and the one taper this module needs) happens in
   keystone_cutout()'s void, differenced through this block afterward. */
module keystone_boss(plate_thickness = 3.0, clearance = 0.25, style = undef) {
    s = _keystone_resolve_style(style);
    if (s == "standard") {
        fw = keystone_boss_footprint(s, clearance); // [w, h, y_center]
        sl = keystone_slot(s);
        bwd = sl[0]; wt = sl[1]; mh = sl[3]; mw = sl[2];
        outer = mh / 2 + wt;
        rise = max(outer + clearance, (mw + 2 * clearance) / 2);
        ramp = rise * _keystone_chamfer_margin();
        z_bottom = -(bwd + ramp + 0.05); // small safety margin past the taper's apex
        translate([-fw[0]/2, fw[2] - fw[1]/2, z_bottom])
            cube([fw[0], fw[1], -z_bottom]);
    } else if (s == "face") {
        // no-op -- see module comment.
    } else {
        assert(false, str("keystone: unknown style '", s, "'"));
    }
}

/* [Insert] — geometric keystone mate-reference (NOT print-tuned; a print-ready
   flexing-latch insert is out of scope for v1, see backlog #22). Datum matches
   keystone_cutout(...,style) so keystone_insert(...,style) dropped into the
   same-style cutout overlays for a virtual mate-check. Front flange stops at
   Z=0 (grows +Z, common bezel both styles); plug passes through the window.
   Plug cross-section is ALWAYS the real jack face (keystone_face()), style-
   independent — the window it must thread is the style-varying part, not the
   jack itself. `fit` = clearance the plug sits under the face, per side.
   Retention geometry differs per style:
     "face": keystone_tab(style)-derived. hook (+Y) rides just behind the
             front face; latch (-Y) bumps out past the window's raw edge but
             entirely behind the plate rear (open air there, not solid
             material) -- grips the plate's flat front/rear faces (pre-#28
             model, unchanged).
     "standard" (#38): TODO Task 3 -- this branch is a COMPILING PLACEHOLDER
             only, derived from keystone_slot()'s slit Z-ranges (a rough
             hook-shaped box in each slit's span), NOT the real
             fulcrum/flex-arm mechanism keystone_notch() describes. It keeps
             keystone_insert() rendering (needed so consumers/tests that
             smoke-render it don't break) without claiming to be a correct
             mate-check for the standard mechanism -- Task 3 replaces this
             entirely with keystone_notch()-derived geometry. */
module keystone_insert(plate_thickness = 3.0, fit = 0.2, style = "standard") {
    o = keystone_opening(style);  // [ow, oh] — the window THIS style's cutout leaves
    f = keystone_face();          // [fw, fh] — the real jack, style-independent
    t = keystone_tab(style);      // [hook_ledge_z, tab_thickness, hook_edge, latch_edge] -- "face" only
    ledge_z = t[0];
    tab_th  = t[1];
    flange  = 1.5;   // flange lip beyond the window, per side
    plug_w  = f[0] - 2*fit;  // plug cross-section: jack face, less `fit` per side
    plug_h_xy = f[1] - 2*fit;
    // through-plug depth: "face" reaches 3mm behind the plate rear (pre-#28,
    // unchanged). "standard" (#38, Task-3 placeholder) is plate-thickness-
    // independent like its cutout/boss -- reaches past keystone_slot()'s
    // back_wall_depth.
    std_slot = keystone_slot("standard");
    std_rear_z = -std_slot[0] - _keystone_plateau_depth();
    plug_h  = (style == "face") ? (plate_thickness + 3) : (-std_rear_z + 0.5);
    union() {
        // front flange: front stop, Z=0..+1.2
        translate([-(o[0]/2 + flange), -(o[1]/2 + flange), 0])
            cube([o[0] + 2*flange, o[1] + 2*flange, 1.2]);
        // through-plug: jack FACE cross-section less `fit` per side, front to behind rear
        translate([-plug_w/2, -plug_h_xy/2, -plug_h])
            cube([plug_w, plug_h_xy, plug_h]);

        if (style == "face") {
            // top hook ledge on +Y edge, engaging just behind the front face. Z
            // driven by ledge_z (keystone_tab("face")[0]): top edge sits at
            // -ledge_z, extending tab_th further back. Y-span runs from the
            // plug's own +Y face (plug_h_xy/2 -- so it stays CONNECTED to the
            // face-derived plug) out to the raw window edge o[1]/2, never past
            // it.
            translate([-(o[0]/2 - fit), plug_h_xy/2, -(ledge_z + tab_th)])
                cube([o[0] - 2*fit, o[1]/2 - plug_h_xy/2, tab_th]);
            // bottom latch bump on -Y edge, behind the plate rear.
            translate([-(o[0]/2 - fit), -(o[1]/2 + tab_th - fit), -(plate_thickness + tab_th)])
                cube([o[0] - 2*fit, (o[1]/2 + tab_th - fit) - plug_h_xy/2, tab_th]);
        } else { // "standard" (#38 Task-3 placeholder, see module comment)
            sl = keystone_slot("standard"); // [back_wall_depth,wall_thickness,mouth_w,mouth_h,top_slit_w,top_slit_len,top_slit_depth,bot_slit_w,bot_slit_len,bot_slit_depth]
            mh2 = sl[3] / 2; wt = sl[1];
            top_outer = mh2 + wt;
            top_z0 = -sl[6];           // top_slit_depth
            top_z1 = -(sl[6] + sl[5]); // top_slit_depth + top_slit_len
            bot_z0 = -sl[9];           // bot_slit_depth
            bot_z1 = -(sl[9] + sl[8]); // bot_slit_depth + bot_slit_len
            // rough "hook" occupying the top slit's Z-range, connected to the
            // plug's own +Y face out to (short of) the slit's outer edge.
            translate([-plug_w/2, plug_h_xy/2, top_z1])
                cube([plug_w, (top_outer - fit) - plug_h_xy/2, top_z0 - top_z1]);
            // mirrored on the bottom slit's Z-range.
            translate([-plug_w/2, -(top_outer - fit), bot_z1])
                cube([plug_w, (top_outer - fit) - plug_h_xy/2, bot_z0 - bot_z1]);
        }
    }
}
