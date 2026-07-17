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
//   3. Hole-stamp  — keystone_cutout(plate_thickness, clearance): plate window
//                    for a consumer difference(); keystone_insert(plate_thickness):
//                    geometric mate-reference body (NOT print-tuned in v1)
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
// tab: [hook_ledge_z, tab_thickness, hook_edge, latch_edge]. hook_edge/
// latch_edge //VERIFY: Wikipedia's "Keystone module" article describes the
// current (1995 ICC patent) mechanism as one fixed angled flange opposite a
// flexing cantilever latch — i.e. genuinely asymmetric front/back edges,
// matching the +Y/-Y split modeled here — but that's a single secondary
// source with no second independent source corroborating it, so it does not
// earn [B]. Confirm against a second independent source (vendor drawing or
// patent) before relying on the asymmetry split. hook_ledge_z and
// tab_thickness //VERIFY: no numeric source found this pass; both carried
// unchanged from the task seed.
function keystone_tab()             = [1.0, 1.2, "+Y", "-Y"];

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
   flexing-latch insert is out of scope for v1). Datum matches keystone_cutout()
   so keystone_insert() dropped into keystone_cutout() overlays for a virtual
   mate-check. Front flange stops at Z=0 (grows +Z); plug passes through the
   window; top hook (+Y) engages just behind the front face; bottom latch (-Y)
   bump sits behind the plate rear. `fit` = clearance the plug sits under the
   opening, per side. */
module keystone_insert(plate_thickness = 3.0, fit = 0.2) {
    o = keystone_opening();  // [ow, oh]
    t = keystone_tab();      // [hook_ledge_z, tab_thickness, hook_edge, latch_edge]
    ledge_z = t[0];
    tab_th  = t[1];
    flange  = 1.5;   // flange lip beyond the opening, per side
    plug_h  = plate_thickness + 3;  // through-plug reaches 3mm behind the plate rear
    union() {
        // front flange: front stop, Z=0..+1.2
        translate([-(o[0]/2 + flange), -(o[1]/2 + flange), 0])
            cube([o[0] + 2*flange, o[1] + 2*flange, 1.2]);
        // through-plug: opening cross-section less `fit` per side, front to behind rear
        translate([-(o[0]/2 - fit), -(o[1]/2 - fit), -plug_h])
            cube([o[0] - 2*fit, o[1] - 2*fit, plug_h]);
        // top hook ledge on +Y edge, engaging just behind the front face. Z
        // driven by ledge_z (keystone_tab()[0]): top edge sits at -ledge_z,
        // extending tab_th further back. Y-width clamped to `fit` (NOT the full tab_th): the
        // hook starts at the plug's own +Y face (o[1]/2 - fit) and may only
        // protrude the same `fit` margin the plug is already narrowed by, so
        // its Y-max lands exactly at the raw opening edge o[1]/2 -- never past
        // it. keystone_cutout()'s window Y-bound is always o[1]/2 + clearance
        // with clearance >= 0, so this guarantees the hook never collides
        // with solid frame material regardless of the consumer's clearance
        // choice. X-width stays clamped to the plug footprint (o[0]-2*fit),
        // same narrowing rationale as the latch below -- the hook rides along
        // the plug's surface, not the full window width.
        translate([-(o[0]/2 - fit), o[1]/2 - fit, -(ledge_z + tab_th)])
            cube([o[0] - 2*fit, fit, tab_th]);
        // bottom latch bump on -Y edge, behind the plate rear
        translate([-(o[0]/2 - fit), -(o[1]/2 + tab_th - fit), -(plate_thickness + tab_th)])
            cube([o[0] - 2*fit, tab_th, tab_th]);
    }
}
