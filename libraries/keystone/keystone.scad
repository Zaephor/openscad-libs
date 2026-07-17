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
//   2. Placeholder — keystone_placeholder(): jack envelope solid for fit checks
//   3. Hole-stamp  — keystone_cutout(plate_thickness, clearance, style): plate
//                    window for a consumer difference(); keystone_insert(
//                    plate_thickness, fit, style): geometric mate-reference
//                    body, plug = keystone_face() (NOT print-tuned in v1)
//   + Fit-check    — keystone_pitch()/min_pitch()/pitch_ok()/layout_ok() +
//                    keystone_pitch_assert(): single-source port-spacing guard
// Provenance legend (see RESEARCH.md for the evidence log):
//   [A] vendor datasheet / governing drawing.  [B] >=2 independent peers agree.
//   [C] reverse-engineered from a public STL/SCAD mesh (cite the artifact
//       URL) — NOT single-sourced/uncorroborated (that's //VERIFY).
//   //VERIFY marks a weak/unsourced value — never a tier it didn't earn.
//
// Keystone is a de-facto standard; expect [A]/[B]/VERIFY. opening/pitch/tmin
// are sourced+tiered below; body depth+W/H, min_wall, tmax, and tab numerics
// remain //VERIFY pending stronger corroboration or a real STL/mesh
// measurement — see RESEARCH.md.
// All three roles implemented: (1) data table + accessor functions
// (keystone_opening(), keystone_body(), keystone_plate_thickness(), keystone_pitch(),
// keystone_min_wall(), keystone_tab()), (2) keystone_placeholder() envelope for
// fit-check, and (3) keystone_cutout()/keystone_insert() hole-stamp/mate-reference modules.

$fn = 48;

/* [Data] — single canonical keystone profile. Tiers per docs/LIBRARY-AUTHORING.md;
   see RESEARCH.md for the full evidence log. */
function keystone_known_styles() = ["lip", "face"];
// Invariant jack face / plug cross-section [fw,fh], mm. [B] Wikipedia keystone
// module (14.5 x 16.0), corroborated across retailer/installer sources.
function keystone_face() = [14.5, 16.0];
// Panel WINDOW to cut, per retention style [ow,oh], mm:
//   "lip"  = rotate-and-snap: taller opening; a rigid fulcrum (bottom) catches
//            the opening's bottom lip, a flex clip (top) snaps over the top lip.
//            [14.8, 20.3] — width [B]; height 20.3 [B]//VERIFY (community, single
//            source; caliper-upgradeable — see RESEARCH.md / #16).
//   "face" = face-grip (retention by plate-thickness front/rear grip):
//            [14.70, 16.40] [A] Samm Teknoloji "Suggested Panel Cutout" (pre-#28 value).
function keystone_opening(style = "lip") =
    style == "lip"  ? [14.8, 20.3] :
    style == "face" ? [14.70, 16.40] :
    assert(false, str("keystone: unknown style '", style, "'"));
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
function keystone_tab(style = "lip") =
    style == "face" ? [1.0, 1.2, "+Y", "-Y"] :
    style == "lip"  ? [1.0, 1.2, "+Y", "-Y"] :
    assert(false, str("keystone: unknown style '", style, "'"));

/* [Fit-check] — single-source port-spacing guard. min_pitch derived once here so
   no consumer re-derives it. */
function keystone_min_pitch()   = keystone_opening()[0] + keystone_min_wall();
function keystone_pitch_ok(pitch) = pitch >= keystone_min_pitch();
// keystone_layout_ok(xs): xs = ascending list of port X-centers; true if every
// adjacent gap clears min_pitch. (<2 ports always fits.)
function keystone_layout_ok(xs) =
    len(xs) < 2 ? true
    : min([for (i = [1:len(xs)-1]) xs[i] - xs[i-1]]) >= keystone_min_pitch();

// keystone_pitch_assert(pitch): hard-fail at render if a consumer's uniform
// port pitch is below min_pitch (catch it here, not on the print bed).
module keystone_pitch_assert(pitch) {
    assert(keystone_pitch_ok(pitch),
        str("keystone: pitch ", pitch, " < min_pitch ", keystone_min_pitch()));
}

/* [Placeholder] — jack envelope: flange face at Z=0, body grows -Z. For
   fit/interference viz only (envelope is a max keep-out, not a detailed jack). */
module keystone_placeholder() {
    b = keystone_body(); // [bw, bh, bd]
    translate([-b[0]/2, -b[1]/2, -b[2]])
        cube([b[0], b[1], b[2]]);
}

/* [Cutout] — plate window for a consumer difference(). Plain rectangular
   through-hole (NO undercut => faceplate stays support-free); jack retention is
   by plate front-lip + rear-edge, so the plate thickness must sit within
   keystone_plate_thickness(). Front face at Z=0; window overcuts +1 above and
   +1 below the plate. `clearance` grows the window per side. */
module keystone_cutout(plate_thickness = 3.0, clearance = 0.25, style = "lip") {
    o = keystone_opening(style); // [ow, oh] for the chosen style
    wx = o[0] + 2 * clearance;
    wy = o[1] + 2 * clearance;
    translate([-wx/2, -wy/2, -(plate_thickness + 1)])
        cube([wx, wy, plate_thickness + 2]);
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
