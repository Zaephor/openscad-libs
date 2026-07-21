// pcie-bracket — PCIe/PCI expansion-slot I/O bracket geometry (low-profile +
// full-height card classes). Pure-data library: only Data functions below
// (no placeholder/holes geometry modules yet — see README "Status").
// Datum (per RESEARCH.md's canonical frame, Task 1): bracket back face (mates
// the chassis rear-panel plane) on Y=0, centered on X=0 at the card-slot
// centerline, bracket foot (fold, screws to chassis) at low Z, growing +Z up
// the faceplate. mm. central $fn.
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
