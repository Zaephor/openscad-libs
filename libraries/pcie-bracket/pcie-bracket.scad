// pcie-bracket — PCIe/PCI expansion-slot I/O bracket geometry (low-profile +
// full-height card classes). Data + geometry (Task 3 adds pcie_bracket() /
// pcie_bracket_mount_holes()) — see README "Status".
// Datum (per RESEARCH.md's canonical frame, Task 1): bracket back face (mates
// the chassis rear-panel plane) on Y=0, centered on X=0 at the card-slot
// centerline, bracket foot (fold, screws to chassis) at low Z, growing +Z up
// the faceplate. mm. central $fn.
//
// Geometry frame (Task 3, derived from the header above + the plan brief's
// own pcie_bracket_mount_holes() skeleton, which cuts a hole cylinder from
// z=-depth to z=+0.02 with depth=thickness+1 -- i.e. the cut is designed to
// fully perforate material that sits in Z=[-thickness, 0], not [0,thickness]):
//   - foot (chassis-mounting flange): Z = [-thickness, 0] (bottom face at
//     -thickness, TOP face flush with the Z=0 fold datum), X = [-fw/2, fw/2],
//     Y = [0, tab_depth] (extends away from the Y=0 back plane into the
//     chassis interior, toward the rail it screws down onto).
//   - faceplate (main plate): Z = [0, height] (bottom edge at the Z=0 fold
//     datum, growing up), X = [-fw/2, fw/2], Y = [0, thickness] (thin wall at
//     the back plane).
//   These two boxes share the Z=0 fold-line plane and touch/overlap over
//   X=[-fw/2,fw/2], Y=[0,thickness] -- a real (non-zero-volume) union, no
//   coincident-face CSG risk.
//
// design-for-print pass (Task 3, per the `design-for-print` skill;
// CORRECTED post-Task-3-review -- an earlier version of this note was wrong,
// see below):
//   - Support-free orientation: this module's own modeled/reference frame
//     above (foot flat in the XY plane at Z=[-th,0], faceplate rising from
//     the shared Z=0 seam) IS the recommended print orientation -- print
//     un-rotated, straight off this header's datum, no rotate() needed. The
//     faceplate's footprint (fw x th, thin -- only `th`=0.8mm deep in Y --
//     though up to 120.65mm tall in Z) sits entirely WITHIN the foot's wider
//     footprint (fw x td=15mm deep in Y) at their shared Z=0 seam: every
//     faceplate layer has solid foot material directly below it in Y, so
//     there is no overhang and no cantilever, so the part prints support-free
//     in this un-rotated frame with no rotate() needed.
//   - An EARLIER version of this note recommended rotate([-90,0,0]) before
//     slicing, reasoning that it would lay the tall faceplate flat and turn
//     the foot into a self-supporting vertical wall ("printed-in-plane").
//     That reasoning was WRONG and was disproven by rendering it: under that
//     rotation the wide, long faceplate (up to 120.65mm) ends up balanced on
//     top of the foot's narrow 0.8mm-thin post -- a severe unsupported
//     cantilever, not a support-free print. Do NOT rotate this part before
//     slicing.
//   - The tall faceplate's tip/warp/snap risk when standing in Z (tall,
//     moderate footprint) is a real slicer-level concern, but it is not a
//     geometry problem and does not change the support-free verdict above;
//     address it at the slicer if needed (brim, orientation lock) rather
//     than by rotating the geometry.
//   - The foot/faceplate corner is a plain right-angle box join (no added
//     fillet/gusset): unlike a real 0.8mm sheet-metal fold, this reference
//     geometry is a solid box union at that corner (fully filled, not a thin
//     cantilever), so it is not a stress-riser the way a folded sheet would
//     be.
//
// Two Task-3 print-design constants below are NOT researched/tabulated data
// (RESEARCH.md's gap list, and the pcie-bracket.scad header's own note above
// pcie_bracket_size()) -- they are this task's own reasoned choices, tagged
// //VERIFY, not [B]/[C] tiered claims:
//   - _pcie_tab_depth(): the foot's Y-extent (how far it reaches into the
//     chassis from the back plane before the screw hole).
//   - _pcie_cutout_*_frac(): the card-slot cutout's size as a fraction of
//     this bracket's OWN envelope (sz[0] height / sz[1] foot_width) -- NOT
//     derived from motherboards.scad's `setback` (RESEARCH.md: different
//     measurement, see header note above pcie_bracket_size()).
//
// pcie_bracket_size(t) field order: [height, foot_width, thickness]
//   height      — bracket overall height, chassis-foot to top edge (tab-to-tab). [B]
//   foot_width  — width of the chassis-mounting foot/flange (the L-flange that
//                 screws to the case's expansion-slot rail); same figure for
//                 both bracket classes. [B]
//   thickness   — sheet-metal gauge. [C] //VERIFY
// Two fields from the plan's original skeleton row shape are DELIBERATELY
// OMITTED from this table (not silently guessed, not silently borrowed from
// another library) — see RESEARCH.md:
//   - tab_len / fold geometry: RESEARCH.md's gap list states the fold/notch
//     shape (beyond the flat foot_width figure above) was "not resolved to
//     numeric detail" from the low-resolution guideline drawings available —
//     no defensible number exists for this, so no field is carried for it.
//   - card_off (card-edge-to-bracket offset): RESEARCH.md explicitly found no
//     bracket-specific figure; the only related number is
//     `mobo_pcie_ports()`'s `setback` in `libraries/motherboards/motherboards.scad`,
//     which is a DIFFERENT measurement (motherboard rear-edge-to-connector,
//     not card-edge-to-bracket) — copying it here would misrepresent someone
//     else's measurement as this bracket's own data, so it is left out of
//     the table entirely rather than faked or mislabeled.
$fn = 48;

/* [Data] */

// M3 screw clearance — ISO 273 medium-fit series, single source of truth
// (repo convention: rack19_screw_clearance("M3") in libraries/rack19/rack19.scad's
// own comment "M3->3.4", inlined the same way in libraries/drives/RESEARCH.md).
// No shared m3_clearance() accessor exists yet repo-wide; every consumer to
// date inlines 3.4, so pcie-bracket does the same rather than invent a third
// value. [B] ISO 273 (community sources agree 6-32 UNC is more common for
// PCI/PCIe brackets, with M3 as a named alternative — RESEARCH.md "Screw"
// section; this repo has no PCIe-bracket-specific screw caliper measurement,
// so the established M3-clearance literal is used, matching the plan brief's
// own skeleton choice).
function _pcie_screw_clear() = 3.4;

// Flange/foot width — shared by both bracket classes. [B] accio.com
// (attributed to PCI-SIG), corroborated by flykantech.com's "~19mm"
// (RESEARCH.md "Full-height bracket" + "Low-profile bracket" tables).
function _pcie_foot_width() = 18.42;

// Sheet-metal thickness — read off the PL-Tronic low-profile guideline
// drawing only; no independent full-height figure was found (RESEARCH.md
// gap: "Assuming shared sheet-metal gauge across both classes is plausible
// but not confirmed this pass"). Applied to BOTH rows below as the best
// available single figure, not as a confirmed full-height measurement.
// [C] //VERIFY — single distributor drawing, guideline-only disclaimer.
function _pcie_thickness() = 0.8;

// Single structural-mount screw Y position (foot datum Z=0), full-height.
// RESEARCH.md found NO absolute screw-to-fold offset for either bracket
// class — only a relative delta between LP and FH (see below). This value
// is a REASONED PLACEHOLDER, not sourced data: single-screw brackets
// conventionally carry the screw near the top of the mounting flange/fold
// (away from the card-slot opening further up the faceplate), so it is
// placed a small distance above the Z=0 foot datum. X=0 because the plate
// is centered in X at the card-slot centerline.
// //VERIFY — placeholder pending a caliper-confirmed or fetched-spec
// absolute screw position; NOT a [B]/[C] tiered claim.
function _pcie_screw_y_fh() = 10;

// Low-profile screw Y position = the full-height placeholder above, shifted
// by the one figure RESEARCH.md DOES cite: the low-profile screw sits
// 1.35mm closer to the fold than the conventional/full-height bracket's.
// The -1.35 delta itself is [B] (RESEARCH.md "Low-profile bracket" table,
// source 1's synthesis); the base it's applied to is still the //VERIFY
// placeholder above, so this value inherits that same //VERIFY status.
function _pcie_screw_y_lp() = _pcie_screw_y_fh() - 1.35; // [B] delta only, on a //VERIFY base

// rows: [type, height, foot_width, thickness, [sx, sy]]  (see header for field-order docs
// and for the two fields deliberately not carried in this table)
function _pcie_table() = [
    ["full-height", 120.65, _pcie_foot_width(), _pcie_thickness(), [0, _pcie_screw_y_fh()]],
        // height 120.65 [B] accio.com (attributed to PCI-SIG), corroborated
        // loosely by flykantech's "approximately 120mm (118-120mm)"
        // (RESEARCH.md "Full-height bracket" table)
    ["low-profile", 79.2, _pcie_foot_width(), _pcie_thickness(), [0, _pcie_screw_y_lp()]],
        // height 79.2 [B] matches the plan brief's own seed exactly;
        // corroborated by flykantech's "typically 79.2mm"
        // (RESEARCH.md "Low-profile bracket" table)
];

function pcie_known_brackets() = [for (e = _pcie_table()) e[0]];
function pcie_known_hole_roles() = ["structural-mount", "component-mount", "keep-out", "alignment"];

function _pcie_row(t) = let (m = [for (e = _pcie_table()) if (e[0] == t) e])
    len(m) > 0 ? m[0] : assert(false, str("pcie-bracket: unknown type '", t, "'"));

// [height, foot_width, thickness] — see header for full field-order docs.
function pcie_bracket_size(t) = [_pcie_row(t)[1], _pcie_row(t)[2], _pcie_row(t)[3]];

// All holes today are the single reasoned-placeholder structural-mount screw
// (see _pcie_screw_y_fh()/_pcie_screw_y_lp() above); role vocab is the full
// repo-standard list even though only "structural-mount" is populated
// (parity with the sbc/drives hole-role sweep — see drives.scad precedent).
function pcie_bracket_holes(t, role = undef) =
    let (p = _pcie_row(t)[4], all = [[p[0], p[1], "structural-mount", _pcie_screw_clear()]])
    role == undef || role == "all" ? all
    : assert(len([for (r = pcie_known_hole_roles()) if (r == role) r]) > 0,
             str("pcie-bracket: unknown role '", role, "'"))
      [for (h = all) if (h[2] == role) h];

function pcie_bracket_holes_xy(t, role = undef) = [for (h = pcie_bracket_holes(t, role)) [h[0], h[1]]];

/* [Geometry] */

// Foot/tab Y-depth (how far the chassis-mounting flange reaches away from
// the Y=0 back plane before folding flat) -- NOT a researched dimension
// (RESEARCH.md gap: "Tab/notch geometry ... not resolved to numeric
// detail"). Chosen here as a print-design constant (design-for-print pass,
// see header): must clear the structural-mount screw's Y position with a
// real edge margin on both classes -- the farther screw sits at
// _pcie_screw_y_fh()=10mm -- so 15mm leaves >=5mm of material beyond the
// hole (comfortably more than the M3/6-32 clearance hole's own radius +
// wall), and is the same order of magnitude as typical chassis expansion-
// slot rail depths. Shared across both bracket classes, same rationale as
// the shared foot_width field. //VERIFY -- design choice, not sourced data;
// do not present as [B]/[C] tiered.
function _pcie_tab_depth() = 15;

// Card-slot cutout size, as a FRACTION of this bracket's own envelope
// (sz[0] height, sz[1] foot_width) -- deliberately not derived from
// motherboards.scad's `setback` (RESEARCH.md: that is a different,
// motherboard-side measurement -- see header note above pcie_bracket_size()).
// 0.65 width / 0.55 height leave a solid margin on all four sides (X margin
// for the vertical card-guide material either side of the slot; Z margin
// so the window stays clear of both the top edge and the Z=0 fold datum/
// foot region). //VERIFY -- design choice, not sourced data.
function _pcie_cutout_width_frac() = 0.65;
function _pcie_cutout_height_frac() = 0.55;

// Small Z epsilon so the faceplate box volumetrically overlaps the foot box
// at the Z=0 fold datum (both boxes otherwise only share a zero-volume
// face) -- avoids a coincident-face CGAL edge case in the union(). Print-
// irrelevant (0.01mm, far under nozzle resolution).
function _pcie_z_eps() = 0.01;

// Mount-hole stamp: one vertical (Z-axis) cylinder per hole entry, cut
// through the foot's thickness. Matches the plan brief's skeleton exactly:
// h[0]/h[1] are the hole's X/Y position (foot lies in the XY plane per the
// geometry-frame note above), translate(...,-depth) + height depth+0.02
// fully perforates foot material at Z=[-thickness,0] when depth=thickness+1
// (the default call site below), with epsilon clearance past both faces.
module pcie_bracket_mount_holes(type, dia = -1, depth = 6) {
    for (h = pcie_bracket_holes(type)) {
        r = (dia < 0 ? h[3] : dia) / 2;
        translate([h[0], h[1], -depth]) cylinder(h = depth + 0.02, r = r);
    }
}

// pcie_bracket(type, blank=false) -- L-bracket faceplate + chassis-mounting
// foot, in the reference/installed frame documented in the header (Z=0 fold
// datum; this un-rotated frame IS the recommended print orientation -- see
// header for the design-for-print reasoning).
// blank=true ships a solid faceplate (no card-slot cutout) -- e.g. a filler
// panel for an unused slot; blank=false (default) cuts the card-slot window.
module pcie_bracket(type, blank = false) {
    sz = pcie_bracket_size(type); // [height, foot_width, thickness]
    h = sz[0];
    fw = sz[1];
    th = sz[2];
    td = _pcie_tab_depth();
    eps = _pcie_z_eps();

    difference() {
        union() {
            // Foot: chassis-mounting flange, flat in the XY plane, Z=[-th,0].
            translate([-fw / 2, 0, -th]) cube([fw, td, th]);
            // Faceplate: main plate, standing in Z=[0,h] -- its footprint
            // (fw x th) sits within the wider foot footprint (fw x td)
            // below it, so this un-rotated frame prints support-free as-is
            // (see header design-for-print note).
            translate([-fw / 2, 0, -eps]) cube([fw, th, h + eps]);
        }
        if (!blank) {
            // Card-slot cutout: sized from THIS bracket's own envelope only
            // (see _pcie_cutout_*_frac() above), centered in X, sitting
            // within the faceplate's Z=[0,h] span with margin top/bottom so
            // it never reaches the Z=0 fold datum / foot region.
            cw = fw * _pcie_cutout_width_frac();
            ch = h * _pcie_cutout_height_frac();
            cz = (h - ch) / 2;
            translate([-cw / 2, -1, cz]) cube([cw, th + 2, ch]);
        }
        // Screw hole through the foot (Z axis, per pcie_bracket_mount_holes()).
        pcie_bracket_mount_holes(type, depth = th + 1);
    }
}
