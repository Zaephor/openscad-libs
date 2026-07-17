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
// NOTE: role 2 (placeholder) and role 3 (cutout/insert) are out of scope for
// this task (data + accessors only) — added in later tasks.

$fn = 48;

/* [Data] — single canonical keystone profile. Tiers per docs/LIBRARY-AUTHORING.md;
   see RESEARCH.md for the full evidence log. */
// [ow,oh] plate window (X,Y), mm. [A] Samm Teknoloji "Unshielded ISO/IEC
// Keystone Jack" mechanical drawing, "Suggested Panel Cutout - Plastic"
// (14.70 x 16.40); corroborated within ~0.3mm by the widely-cited community
// figure 14.5 x 16.0 [B]. See RESEARCH.md.
function keystone_opening()         = [14.70, 16.40];
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
