// keystone — keystone-jack snap-footprint reference (de-facto interchangeable
// standard: one snap profile fits any compliant jack/plate). Datum: millimeters.
// DEFAULT ORIENTATION (panel-mount): panel FRONT face at Z=0, centered in X/Y,
// jack body grows -Z (behind the panel), show-face/opening toward +Z. Consumers
// rotate the whole port to orient their panel (e.g. -90deg about X for a
// vertical 1U faceplate). Opening [ow,oh] = X width x Y height of the plate
// window; body [bw,bh,bd] = X,Y extents x Z depth behind the panel.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//                    incl. keystone_latch(style): measured hook/flex-latch
//                    retention profile (#31) and keystone_boss_footprint(
//                    style, clearance): the boss sizing keystone_boss()/
//                    keystone_min_pitch() below derive from
//   2. Placeholder — keystone_placeholder(): jack envelope solid for fit checks
//   3. Hole-stamp  — keystone_cutout(plate_thickness, clearance, style): plate
//                    window for a consumer difference(); keystone_boss(
//                    plate_thickness, clearance, style): LOCAL positive
//                    material behind a thin panel so "lip"'s real mechanism
//                    (keystone_latch()) always lands in solid material
//                    regardless of panel thickness (#31; no-op for "face");
//                    keystone_insert(plate_thickness, fit, style): geometric
//                    mate-reference body, plug = keystone_face() (NOT
//                    print-tuned in v1)
//   + Fit-check    — keystone_pitch()/min_pitch(style)/pitch_ok(pitch,style)/
//                    layout_ok(xs,style) + keystone_pitch_assert(pitch,style):
//                    single-source port-spacing guard, boss-footprint-driven
//                    for "lip" (#31), opening+wall for "face" (unchanged)
// Provenance legend (see RESEARCH.md for the evidence log):
//   [A] vendor datasheet / governing drawing.  [B] >=2 independent peers agree.
//   [C] reverse-engineered from a public STL/SCAD mesh (cite the artifact
//       URL) — NOT single-sourced/uncorroborated (that's //VERIFY).
//   //VERIFY marks a weak/unsourced value — never a tier it didn't earn.
//
// Keystone is a de-facto standard; expect [A]/[B]/VERIFY. opening/pitch/tmin
// (both styles) and the "lip" retention profile (keystone_latch(), #31) are
// sourced+tiered below; body depth+W/H, min_wall, tmax, and keystone_tab()
// numerics remain //VERIFY pending stronger corroboration — see RESEARCH.md.
// All three roles implemented: (1) data table + accessor functions
// (keystone_opening(), keystone_body(), keystone_plate_thickness(), keystone_pitch(),
// keystone_min_wall(), keystone_tab(), keystone_latch(), keystone_boss_footprint()),
// (2) keystone_placeholder() envelope for fit-check, and (3)
// keystone_cutout()/keystone_boss()/keystone_insert() hole-stamp/mate-reference modules.

$fn = 48;

/* [Data] — single canonical keystone profile. Tiers per docs/LIBRARY-AUTHORING.md;
   see RESEARCH.md for the full evidence log. */
function keystone_known_styles() = ["lip", "face"];
// Invariant jack face / plug cross-section [fw,fh], mm. [B] Wikipedia keystone
// module (14.5 x 16.0), corroborated across retailer/installer sources.
function keystone_face() = [14.5, 16.0];
// Panel WINDOW to cut, per retention style [ow,oh], mm:
//   "lip"  = rotate-and-snap: a RIGID HOOK (top/+Y, shallow/near-front) and a
//            FLEXIBLE LATCH (bottom/-Y, deeper) each ramp the window open as
//            you go back -- see keystone_latch() for the full profile.
//            [ow,oh] here = [width, max window height at the latch's
//            deflection-clearance plateau] -- keystone_latch("lip")[0] and
//            [6], its single source (#31, RESEARCH.md "Real latch
//            geometry", STL-mesh [C]//VERIFY -- replaces the pre-#31
//            [14.8, 20.3] community-guess placeholder).
//   "face" = face-grip (retention by plate-thickness front/rear grip):
//            [14.70, 16.40] [A] Samm Teknoloji "Suggested Panel Cutout" (pre-#28 value).
function keystone_opening(style = "lip") =
    style == "lip"  ? [keystone_latch(style)[0], keystone_latch(style)[6]] :
    style == "face" ? [14.70, 16.40] :
    assert(false, str("keystone: unknown style '", style, "'"));

// keystone_latch(style): REAL measured hook/flex-latch retention profile
// (#31, RESEARCH.md "Real latch geometry (#31, STL-mesh)"), [C]//VERIFY --
// single-mesh reading of the "Keystone Jack v2 integration aide" cutout
// negative (Printables 1027864), not cross-checked against a second
// cutout-negative model. "lip" ONLY -- "face" has no lip mechanism (grips
// the plate's flat front/rear faces instead, see keystone_tab()).
// Mechanism ([B] Wikipedia "Keystone module" corroborates the qualitative
// description): insert at an angle, a RIGID HOOK on the window's TOP/+Y edge
// rides a ramped lead-in and seats into a shallow pocket near the front;
// then the jack is rotated in and a FLEXIBLE LATCH on the BOTTOM/-Y edge
// deflects down a second ramp, deeper in, and snaps behind the bottom lip.
// NOTE: this is the OPPOSITE depth assignment from the pre-#28 keystone_tab()
// "lip" guess, which modeled the deep/flexing feature on TOP (+Y) and the
// shallow/rigid feature on BOTTOM (-Y) -- keystone_tab() is left unchanged
// here (mate-reference numerics only, mating insert geometry is backlog #31
// Task 3); keystone_latch() is the corrected, measurement-backed accessor
// this file's "lip" keystone_cutout()/keystone_boss() are built from.
// Returns [width, front_h, hook_z, hook_h, pocket_z, latch_z, latch_h], Z
// measured from the panel front (Z=0, matches this file's -Z body
// convention), all mm:
//   width    = window WIDTH (X), constant through the whole depth (no taper;
//              the mechanism is purely a height/Y-axis effect)
//   front_h  = window HEIGHT (Y) at the front, flat from Z=0
//   hook_z   = Z where the TOP/+Y hook's ~45deg ramp ends / its pocket
//              starts (ramp runs Z 0 -> hook_z, growing ONLY the top edge;
//              simplified from RESEARCH.md's separate 0.42mm front-window +
//              3.90mm ramp zones into one 4.32mm ramp starting at Z=0 --
//              this makes the modeled ramp angle slightly SHALLOWER than
//              measured, i.e. conservative for the support-free check, not
//              steeper)
//   hook_h   = window height through the hook's pocket (flat; the top
//              edge's value from here on -- bottom edge is still front_h's
//              bottom, unchanged)
//   pocket_z = Z where the hook pocket ends / the BOTTOM/-Y latch's ~45deg
//              ramp starts (top edge stays at hook_h from here on)
//   latch_z  = Z where the latch ramp ends / the deflection-clearance
//              plateau starts (ramp runs pocket_z -> latch_z, growing ONLY
//              the bottom edge)
//   latch_h  = window height at the latch's plateau (flat; MAX window --
//              also keystone_opening("lip")[1])
// keystone_cutout()/keystone_boss()/keystone_boss_footprint() below are this
// profile's sole other consumers (single source of truth -- do not
// hand-copy these numbers elsewhere).
function keystone_latch(style = "lip") =
    style == "lip" ? [14.90, 17.43, -4.32, 21.30, -5.37, -6.97, 22.90] :
    assert(false, str("keystone: keystone_latch has no lip mechanism for style '", style, "'"));

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
// tab: [hook_ledge_z, tab_thickness, hook_edge, latch_edge], per retention
// style (task #28). hook_edge/latch_edge //VERIFY: Wikipedia's "Keystone
// module" article describes the current (1995 ICC patent) mechanism as one
// fixed angled flange opposite a flexing cantilever latch — i.e. genuinely
// asymmetric front/back edges, matching the +Y/-Y split modeled here — but
// that's a single secondary source with no second independent source
// corroborating it, so it does not earn [B]. Confirm against a second
// independent source (vendor drawing or patent) before relying on the
// asymmetry split.
//   "face": hook (+Y) rides just behind the front face, latch (-Y) bumps out
//           behind the plate rear — grips the plate's flat front/rear faces
//           (pre-#28 model, values unchanged: hook_ledge_z=1.0, tab_th=1.2).
//   "lip":  hook (+Y) = flex clip snapping in behind the opening's TOP lip
//           (deep, anchored off plate_thickness in keystone_insert() like
//           face's latch); latch (-Y) = rigid fulcrum foot resting near the
//           front at the opening's BOTTOM lip (shallow, hook_ledge_z deep,
//           like face's hook). //VERIFY mate-reference-only numerics, kept
//           equal to "face"'s seed pending a real jack drawing; bounded by
//           "clean overlay both styles" (verify-scad-geometry, #28), not a
//           fixed literal.
//           CONFIRMED BACKWARDS (#31): the "lip" top/bottom depth assignment
//           above (deep/flex on TOP, shallow/rigid on BOTTOM) is now known,
//           via keystone_latch()'s real STL-mesh measurement, to be the
//           OPPOSITE of the actual mechanism (rigid hook shallow/TOP,
//           flexible latch deep/BOTTOM) -- see keystone_latch()'s doc
//           comment. This function is left as-is (mate-reference numerics
//           only; reworking keystone_insert() to match is backlog #31 Task 3)
//           -- do not read this "lip" split as correct when reworking the
//           mating insert.
function keystone_tab(style = "lip") =
    style == "face" ? [1.0, 1.2, "+Y", "-Y"] :
    style == "lip"  ? [1.0, 1.2, "+Y", "-Y"] :
    assert(false, str("keystone: unknown style '", style, "'"));

// keystone_boss_footprint(style, clearance): [w, h, y_center] rectangular
// footprint (X,Y) for keystone_boss(style) below -- the "lip" cutout's max
// envelope (keystone_latch(style) width/latch_h, clearance-grown) plus
// keystone_min_wall() wall margin per side. "lip" ONLY (keystone_boss() is a
// no-op for "face" -- nothing to size). clearance defaults to
// keystone_cutout()'s own default (0.25) -- pass the SAME clearance to both
// if overriding it, else the boss and its cutout disagree.
// y_center is NOT 0: the real mechanism's top/bottom edges are asymmetric
// (hook ramp grows the top edge only, latch ramp grows the bottom edge only
// -- see keystone_latch()), so a Y=0-centered box would under-protect
// whichever edge grew less. keystone_min_pitch() below is this footprint's
// sole other consumer (single source of truth for the boss-collision guard).
function keystone_boss_footprint(style = "lip", clearance = 0.25) =
    style == "lip" ? let(
        l = keystone_latch(style),
        w = keystone_min_wall(),
        raw_top = l[3] - l[1]/2,   // hook-pocket/latch-plateau top edge (unchanged after hook_z)
        raw_bot = raw_top - l[6],  // latch-plateau bottom edge
        top = raw_top + clearance + w,
        bot = raw_bot - clearance - w
    ) [l[0] + 2*clearance + 2*w, top - bot, (top + bot)/2] :
    assert(false, str("keystone: keystone_boss_footprint has no boss for style '", style, "'"));

/* [Fit-check] — single-source port-spacing guard. min_pitch derived once here so
   no consumer re-derives it. "lip" (#31) is boss-footprint-driven (the boss,
   not the raw opening, is what two adjacent ports must clear); "face" is
   unchanged (plain-rectangle opening + wall, no boss). */
function keystone_min_pitch(style = "lip") =
    style == "lip" ? keystone_boss_footprint(style)[0] :
    keystone_opening(style)[0] + keystone_min_wall();
function keystone_pitch_ok(pitch, style = "lip") = pitch >= keystone_min_pitch(style);
// keystone_layout_ok(xs, style): xs = ascending list of port X-centers; true
// if every adjacent gap clears min_pitch(style). (<2 ports always fits.)
function keystone_layout_ok(xs, style = "lip") =
    len(xs) < 2 ? true
    : min([for (i = [1:len(xs)-1]) xs[i] - xs[i-1]]) >= keystone_min_pitch(style);

// keystone_pitch_assert(pitch, style): hard-fail at render if a consumer's
// uniform port pitch is below min_pitch(style) (catch it here, not on the
// print bed).
module keystone_pitch_assert(pitch, style = "lip") {
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

// _keystone_lip_flat/_keystone_lip_wedge: private helpers for the "lip"
// cutout/boss below. A "flat" zone is a constant Y cross-section extruded
// between two Z bounds; a "wedge" is the hull() of two thin Y cross-sections
// at different Z, i.e. a straight-line ramp between them (this is what turns
// keystone_latch()'s per-zone Y edges into the actual ~45deg ramp faces).
module _keystone_lip_flat(z_top, z_bot, top, bot, wx) {
    translate([-wx/2, bot, z_bot]) cube([wx, top - bot, z_top - z_bot]);
}
module _keystone_lip_wedge(z0, z1, top0, bot0, top1, bot1, wx) {
    eps = 0.02;
    hull() {
        translate([-wx/2, bot0, z0 - eps/2]) cube([wx, top0 - bot0, eps]);
        translate([-wx/2, bot1, z1 - eps/2]) cube([wx, top1 - bot1, eps]);
    }
}

/* [Cutout] — plate window for a consumer difference(). "face" = plain
   rectangular through-hole (unchanged; NO undercut => support-free from any
   orientation; jack retention is by plate front-lip + rear-edge, so the
   plate thickness must sit within keystone_plate_thickness()).
   "lip" (#31) = the REAL lipped negative: a front window that necks through
   a TOP-edge rigid-hook ramp+pocket, then a BOTTOM-edge flex-latch
   ramp+plateau (see keystone_latch()), leaving real top/bottom lip material
   a hook/latch can engage -- replaces the pre-#31 plain rectangle. This full
   mechanism needs ~8.3mm of Z depth (RESEARCH.md), far more than
   keystone_plate_thickness()'s 1.5-3.0mm range, so the "lip" branch's
   Z-extent is PLATE-THICKNESS-INDEPENDENT (always cuts the full measured
   depth) -- a thin panel alone can't host the whole mechanism; pair with
   keystone_boss(plate_thickness, clearance, style) below, which adds the
   missing material behind a thin panel so the cut always lands in real
   solid:
       union() { plate; translate(p) keystone_boss(t, c, style); }
       difference() { <that>; translate(p) keystone_cutout(t, c, style); }
   (Faceplate wiring of this pattern is backlog #31 Task 4, not this module.)
   PRINT ORIENTATION (pin, "lip" only): panel FRONT face (Z=0) DOWN on the
   print bed, -Z (into the panel/boss) pointing UP during the print. Every
   "lip" ramp necks OUTWARD as Z goes more negative (deeper) -- the
   remaining lip material is thickest at the front (bed) and thins going up,
   so each layer's solid footprint is a subset of the layer below's: both
   ramps are self-supporting in this orientation, at RESEARCH.md's measured
   ~45deg angle (keystone_latch()'s Z/Y deltas are used unscaled, which
   preserves that angle exactly). Printing rear-face-down would need
   supports under both ramps -- do not do that.
   Front face at Z=0; window overcuts +1 above (folded into the front flat
   zone) and +1 past the mechanism's own rear end (folded into the rear flat
   zone, "lip" only -- "face" keeps its original +1/+1 overcut). `clearance`
   grows the window per side (each Y edge +/- clearance; X +/- clearance). */
module keystone_cutout(plate_thickness = 3.0, clearance = 0.25, style = "lip") {
    if (style == "face") {
        o = keystone_opening(style); // [ow, oh]
        wx = o[0] + 2 * clearance;
        wy = o[1] + 2 * clearance;
        translate([-wx/2, -wy/2, -(plate_thickness + 1)])
            cube([wx, wy, plate_thickness + 2]);
    } else if (style == "lip") {
        l = keystone_latch(style); // [width,front_h,hook_z,hook_h,pocket_z,latch_z,latch_h]
        wx = l[0] + 2*clearance;
        // Raw (pre-clearance) Y edges at each breakpoint -- see
        // keystone_latch()'s field doc: top grows ONLY across the hook ramp,
        // bottom grows ONLY across the latch ramp.
        raw_top_front = l[1]/2;         raw_bot_front = -l[1]/2;
        raw_top_hook  = l[3] - l[1]/2;  raw_bot_hook  = raw_bot_front;
        raw_top_latch = raw_top_hook;   raw_bot_latch = raw_top_hook - l[6];
        top_front = raw_top_front + clearance;  bot_front = raw_bot_front - clearance;
        top_hook  = raw_top_hook  + clearance;  bot_hook  = raw_bot_hook  - clearance;
        top_latch = raw_top_latch + clearance;  bot_latch = raw_bot_latch - clearance;
        plateau_depth = 1.30; // RESEARCH.md's latch-clearance-plateau span
        rear_overcut = l[5] - plateau_depth - 1; // 1mm past the mechanism's own rear end
        union() {
            _keystone_lip_flat(1, 0, top_front, bot_front, wx);                          // front overcut
            _keystone_lip_wedge(0, l[2], top_front, bot_front, top_hook, bot_hook, wx);  // hook ramp
            _keystone_lip_flat(l[2], l[4], top_hook, bot_hook, wx);                      // hook pocket
            _keystone_lip_wedge(l[4], l[5], top_hook, bot_hook, top_latch, bot_latch, wx); // latch ramp
            _keystone_lip_flat(l[5], rear_overcut, top_latch, bot_latch, wx);            // plateau + rear overcut
        }
    } else {
        assert(false, str("keystone: unknown style '", style, "'"));
    }
}

/* [Boss] — LOCAL positive material behind a thin panel (#31), pairs with
   keystone_cutout(...,"lip") (see that module's comment for the full
   union()+difference() consumer pattern). "face" is a no-op (its
   plain-rectangle mechanism already fits keystone_plate_thickness()
   unchanged -- nothing to add). "lip": a rectangular pedestal, front face
   flush with the panel front (Z=0), growing -Z the full measured mechanism
   depth (keystone_boss_footprint() sizes it -- the cutout's max envelope +
   keystone_min_wall() wall margin per side), so the "lip" cut above always
   lands in real solid regardless of `plate_thickness`.
   PRINT ORIENTATION: same as keystone_cutout() -- front face down. The
   boss's own walls are a CONSTANT rectangular footprint through its whole
   Z-depth (no taper) -- a perfectly vertical prism, 0deg from vertical, so
   it needs no chamfer to stay support-free: every boss cross-section is
   identical (nothing narrower ever sits below something wider), and the
   boss sits on the panel's own flat, fully-solid rear face (this module
   runs before the difference() that cuts the window), so there's no
   re-entrant step to bridge either. */
module keystone_boss(plate_thickness = 3.0, clearance = 0.25, style = "lip") {
    if (style == "lip") {
        fw = keystone_boss_footprint(style, clearance); // [w, h, y_center]
        plateau_depth = 1.30; // RESEARCH.md's latch-clearance-plateau span (mirrors keystone_cutout())
        mech_end = keystone_latch(style)[5] - plateau_depth; // full mechanism depth (Z, negative)
        translate([-fw[0]/2, fw[2] - fw[1]/2, mech_end])
            cube([fw[0], fw[1], -mech_end]);
    } else if (style == "face") {
        // no-op -- see module comment.
    } else {
        assert(false, str("keystone: unknown style '", style, "'"));
    }
}

/* [Insert] — geometric keystone mate-reference (NOT print-tuned; a print-ready
   flexing-latch insert is out of scope for v1, see backlog #22). Datum matches
   keystone_cutout(...,style) so keystone_insert(...,style) dropped into the
   same-style cutout overlays for a virtual mate-check. Front flange stops at
   Z=0 (grows +Z, common bezel both styles); plug passes through the window.
   Plug cross-section is ALWAYS the real jack face (keystone_face()), style-
   independent — the window it must thread is the style-varying part, not the
   jack itself (task #28 fix: previously the plug incorrectly used
   keystone_opening(), which is taller for "lip" and doesn't represent a real
   jack). `fit` = clearance the plug sits under the face, per side.
   Retention geometry (keystone_tab(style)) differs per style:
     "face": hook (+Y) rides just behind the front face; latch (-Y) bumps out
             past the window's raw edge but entirely behind the plate rear
             (open air there, not solid material) -- grips the plate's flat
             front/rear faces (pre-#28 model, unchanged).
     "lip":  fulcrum (-Y, bottom) is a shallow near-front foot filling the
             window's bottom slack (oh is taller than the jack face) up to,
             but never past, the bottom lip; flex clip (+Y, top) is a deep
             behind-rear tab filling the top slack up to, but never past, the
             top lip. Both stay within the window's raw bound -- contact is
             modeled against the lip (the window's edge wall) rather than the
             plate's flat faces. //VERIFY mate-reference-only numerics. */
module keystone_insert(plate_thickness = 3.0, fit = 0.2, style = "lip") {
    o = keystone_opening(style);  // [ow, oh] — the window THIS style's cutout leaves
    f = keystone_face();          // [fw, fh] — the real jack, style-independent
    t = keystone_tab(style);      // [hook_ledge_z, tab_thickness, hook_edge, latch_edge]
    ledge_z = t[0];
    tab_th  = t[1];
    flange  = 1.5;   // flange lip beyond the window, per side
    plug_w  = f[0] - 2*fit;  // plug cross-section: jack face, less `fit` per side
    plug_h_xy = f[1] - 2*fit;
    plug_h  = plate_thickness + 3;  // through-plug reaches 3mm behind the plate rear
    // No separate style guard here: keystone_opening(style) above already
    // asserts on an unknown style before this point is reached.
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
            // face-derived plug, which is narrower than the pre-#28 opening-
            // derived one) out to the raw window edge o[1]/2, never past it:
            // keystone_cutout()'s window Y-bound is always o[1]/2 + clearance
            // with clearance >= 0, so this guarantees the hook never collides
            // with solid frame material regardless of the consumer's
            // clearance choice. X-width o[0]-2*fit (current/unchanged) is
            // wider than the plug, so it stays connected in X too.
            translate([-(o[0]/2 - fit), plug_h_xy/2, -(ledge_z + tab_th)])
                cube([o[0] - 2*fit, o[1]/2 - plug_h_xy/2, tab_th]);
            // bottom latch bump on -Y edge, behind the plate rear: spans from
            // the raw window edge (protruding tab_th-fit further into the
            // open space behind the plate rear, exactly as before) in to the
            // plug's own -Y face (connects; the pre-#28 model's plug
            // coincided with this edge automatically since it was itself
            // opening-derived -- now it must be spanned explicitly).
            translate([-(o[0]/2 - fit), -(o[1]/2 + tab_th - fit), -(plate_thickness + tab_th)])
                cube([o[0] - 2*fit, (o[1]/2 + tab_th - fit) - plug_h_xy/2, tab_th]);
        } else { // style == "lip"
            // fulcrum foot on -Y edge (bottom): shallow, near-front (Z: 0 to
            // -ledge_z), spanning from the window's bottom lip (inset `fit` so
            // it never touches solid frame) up to the plug's own -Y face --
            // fills the window's bottom slack (oh is taller than the jack face
            // to allow rotate-and-snap insertion).
            translate([-plug_w/2, -(o[1]/2 - fit), -ledge_z])
                cube([plug_w, (o[1]/2 - fit) - plug_h_xy/2, ledge_z]);
            // flex clip on +Y edge (top): deep, behind the plate rear (Z:
            // -(plate_thickness) to -(plate_thickness+tab_th)) -- the ramp
            // that compresses through the window on insertion and snaps back
            // out once clear, catching the top lip from behind. Fills the
            // window's top slack, inset `fit` from the raw edge.
            translate([-plug_w/2, plug_h_xy/2, -(plate_thickness + tab_th)])
                cube([plug_w, (o[1]/2 - fit) - plug_h_xy/2, tab_th]);
        }
    }
}
