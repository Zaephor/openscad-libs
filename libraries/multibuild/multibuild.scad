// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// multibuild — MultiBoard-compatible grid + mount interface.
// Datum: millimeters. Mount-feature axis = Z; feature plugs into the board
// in -Z (board mount surface at Z=0); consumer part body sits at +Z.
// Grid [x,y] lies in the Z=0 plane, centered in X/Y.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / grid math / a mount-type
//                    lookup table (expose as functions: OpenSCAD `use` does
//                    not import top-level variables)
//   2. Placeholder — multibuild_mount_placeholder(type): envelope solid for fit checks
//   3. Positive    — multibuild_mount(type): the printed connector feature on
//                    a consumer part that mates into a board hole
//   4. Negative    — multibuild_hole(type): the board-hole profile cut into a
//                    surface, for use inside a consumer difference(). Also
//                    dispatches Fix-Point accessory-side dovetail pockets (the
//                    negative-only "multipoint"/"multipoint_rail" types, listed
//                    by multibuild_known_holes(), with multibuild_fixpoint_
//                    placeholder() as the mating positive for fit-viz).
// Provenance legend (see RESEARCH.md for the full Task 1 evidence log +
// checkpoint):
//   [A] fetched + read this pass (official MultiBuild docs).
//   [B] corroborated across >=2 independent peers.
//   [C] single-sourced / derived, or a named part cited but not fetched.
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
//
// Status: grid pitch/mount-type table (`_multibuild_table()`) and all four
// roles — Role 1 accessor/grid-math functions and Roles 2-4 modules
// `multibuild_mount_placeholder()` / `multibuild_mount()` /
// `multibuild_hole()` — are fully implemented below. Also implemented: the
// MultiBin container accessors (`multibin_*` — CU-grid footprint/cavity/wall/
// height data plus `multibin_placeholder()` / `multibin_cavity_cutout()`) and
// the Fix-Point (Multipoint) accessory-side receiving negatives
// (`multibuild_known_holes()`, `multibuild_hole(type)` dispatch, and
// `multibuild_fixpoint_placeholder()` for fit-viz). RESEARCH.md documents the
// complete research evidence chain (Task 1, 1b, 1c) backing this
// implementation. Checkpoint findings confirm the Regular Snap mechanism
// (plugging into a Large Hole, chosen over Threads/Peg Click/DS Snaps) fits
// this API shape.

$fn = 48;

/* [Data] — grid pitch + mount-type table.
   Row: [type, hole_dia, hole_depth, mount_engagement, mount_arm_count,
         mount_arm_width, mount_tip_flare] — see RESEARCH.md. */
function multibuild_grid_pitch() = 25; // [A] docs.multibuild.io core-parts-documentation (MU unit)

function _multibuild_table() = [
    // hole_dia/hole_depth/mount_* all [C]//VERIFY — STL mesh measurement,
    // Printables #716558 (snap) + #1277707 (tile), single community source.
    ["snap", 22.2, 6.4, 8.6, 4, 3.0, 11.05],
];
function multibuild_known_mounts() = [for (e = _multibuild_table()) e[0]];
function _multibuild_row(type) =
    let (r = [for (e = _multibuild_table()) if (e[0] == type) e])
    assert(len(r) == 1, str("multibuild: unknown mount type '", type, "'")) r[0];
function multibuild_hole_dia(type)         = _multibuild_row(type)[1];
function multibuild_hole_depth(type)       = _multibuild_row(type)[2];
function multibuild_mount_engagement(type) = _multibuild_row(type)[3];
function multibuild_mount_arm_count(type)  = _multibuild_row(type)[4];
function multibuild_mount_arm_width(type)  = _multibuild_row(type)[5];
function multibuild_mount_tip_flare(type)  = _multibuild_row(type)[6];

// Grid-relative hole offsets (grid units) a mount instance occupies. Single-
// hole mounts = [[0,0]]. Multi-hole mounts (e.g. Peg Click, T3) list each peg's
// grid cell. Parallel accessor -- does not touch _multibuild_table()'s row schema.
function _multibuild_footprint_table() = [
    ["snap", [[0,0]]],
    // peg_click: 2-hole footprint, VERTICAL axis (Y-pair), 25mm spacing.
    // Tier: [C]/derived for the 25mm spacing magnitude, but the AXIS choice
    // itself is `//VERIFY` -- the only direct evidence is a visual read of
    // the official "Hook to Tile" Common Connections diagram (stylized
    // isometric render, not a dimensioned drawing), the same risk class as
    // a prior visual misread (octagonal vs. round Large Hole) that mesh
    // measurement later overturned. See RESEARCH.md "Two-hole spacing and
    // axis" (#36 Task 2). Flip to [[0,0],[1,0]] (horizontal) as a one-line
    // data change if a stronger source later confirms it instead (tests/docs
    // would need a matching update -- see tests/multibuild_test.scad and
    // tests/test_multibuild_lib.sh, which encode Y as the long axis).
    ["peg_click", [[0,0],[0,1]]],
];
function multibuild_mount_footprint(type) =
    let (r = [for (e = _multibuild_footprint_table()) if (e[0]==type) e[1]])
    len(r) == 1 ? r[0] : [[0,0]];   // default single-hole

// True if `type`'s footprint fits within a cols x rows grid (offsets in-range).
function multibuild_mount_fits(type, cols, rows) =
    let (fp = multibuild_mount_footprint(type))
    max([for (o=fp) o[0]]) < cols && max([for (o=fp) o[1]]) < rows
    && min([for (o=fp) o[0]]) >= 0 && min([for (o=fp) o[1]]) >= 0;

/* [Data: Fix-Point] — accessory-side receiving negatives (Fix-Point / Multipoint).
   PARALLEL to the mount table, deliberately SEPARATE: these are NEGATIVE-ONLY
   types (a Fix-Point has no positive arms/flare/mount body), so they must NOT
   be added to _multibuild_table()/multibuild_known_mounts() -- the mount test
   suite hard-asserts full positive-mount geometry (tip_flare>0, arm_count>0,
   2*tip_flare <= hole_dia) for EVERY mount, which a Fix-Point cannot satisfy.
   We model the ACCESSORY side only: the dovetail pocket an accessory cuts into
   its own face to receive a Fix-Point. The Fix-Point part's own board-side
   thread/bolt engagement is out of scope (it belongs to the official part).
   Row: [type, pos_throat, pos_max, pos_depth, neg_buried, neg_depth, slide_len]
     pos_*     = the mating Fix-Point POSITIVE dovetail (drives the placeholder)
     neg_*     = the accessory-side NEGATIVE cutter this file emits
     slide_len = nominal pocket length along the +X slide axis (viz only; a real
                 Rail length is per-part/variable).
   See RESEARCH.md "MultiBin + Fix-Point (#32)". Values [C] (STL mesh),
   caliper-upgradeable (#16); the Lite 1mm depth delta is [A]. The negative
   throat is DERIVED (not stored) -- see _multibuild_fixpoint_neg_throat(). */
function _multibuild_fixpoint_table() = [
    // Regular: mates a "Multipoint Hole"; Lite: 1mm thinner, mates a "Rail Negative".
    ["multipoint",      11.7, 15.2, 3.0, 17.0, 3.3, 16], // Regular (Multipoint Hole)
    ["multipoint_rail", 12.8, 15.2, 2.0, 17.0, 2.3, 40], // Lite Rail Negative
];
function multibuild_known_holes() = [for (e = _multibuild_fixpoint_table()) e[0]];
function _multibuild_fixpoint_row(type) =
    let (r = [for (e = _multibuild_fixpoint_table()) if (e[0] == type) e])
    assert(len(r) == 1, str("multibuild: unknown Fix-Point hole type '", type, "'")) r[0];
function _multibuild_is_hole(type) =
    len([for (e = _multibuild_fixpoint_table()) if (e[0] == type) 1]) > 0;
// Negative dovetail throat width: preserve the positive's flank angle
// (tan = ((pos_max - pos_throat)/2) / pos_depth) at the negative's buried width
// and cut depth, so the emitted pocket is a true mating dovetail, not an
// arbitrary trapezoid. neg_throat = neg_buried - neg_depth*(pos_max-pos_throat)/pos_depth.
function _multibuild_fixpoint_neg_throat(type) =
    let (r = _multibuild_fixpoint_row(type))
    r[4] - r[5] * (r[2] - r[1]) / r[3];

/* [Data: Peg Click] — 2-hole rigid-peg mount ("peg_click"), engaging the
   Tile's SMALL HOLE family (multibuild_small_hole_dia()/_depth(), 6.53mm),
   NOT the Large Hole the "snap" row in _multibuild_table() mates to. Kept as
   its OWN parallel data + module family, deliberately NOT a
   _multibuild_table() row and NOT listed in multibuild_known_mounts() --
   mirrors the Fix-Point precedent above. Reasoning (RESEARCH.md
   "Geometry-model decision", #36 Task 2): the Peg Click peg is a plain rigid
   cylinder with no arms/tip-flare, so it cannot honestly satisfy
   _multibuild_table()'s arm_count/arm_width/tip_flare schema (built for the
   Snap's compliant multi-arm mount) or the mount test suite's Snap-flavored
   geometry asserts; and its hole family is the Small Hole, not the Large
   Hole, so a _multibuild_table() row would have to duplicate
   multibuild_small_hole_dia()/_depth() rather than read them directly
   (single-source-of-truth violation). Peg LENGTH is deliberately NOT a
   table constant -- see _multibuild_peg_click_peg()'s `len` parameter and
   _multibuild_peg_click_default_len() below, mirroring the Fix-Point Rail's
   `slide_len` precedent (a real peg/hook length is per-accessory/variable;
   the official parts list ships 15/20/25/30mm + Double variants). */
// Peg diameter: [C]//VERIFY -- official Thangs part name "6.25 mm Support
// Peg" (page itself unreachable) + a tolerance-consistency argument: 6.53mm
// Small Hole bore minus 6.25mm peg = 0.28mm diametrical clearance, matching
// the official [A] 0.25mm design tolerance almost exactly (a peg toleranced
// to the spec's own clearance figure is a more coherent "click" than the
// two independently-read community pegs' looser 5-5.6mm/~1-1.5mm-clearance
// DIY fit). NOT yet caliper-confirmed to be Peg-Click-specific. RESEARCH.md
// "Peg diameter" (#36 Task 2).
function multibuild_peg_click_dia() = 6.25;
// No click-ridge/barb: two independent community sources ([B] for the
// *shape*, plain rigid cylinder, no flared arms, no printed-in barb) and no
// source found describes a barb/ridge. Modeled as a plain tolerance-fit
// cylinder in _multibuild_peg_click_peg() below -- flagged `//VERIFY`, not
// fabricated: if a future pass recovers an actual barb profile, this is the
// value to revise. RESEARCH.md "No click-ridge/barb confirmed" (#36 Task 2).
function _multibuild_peg_click_default_len() =
    multibuild_small_hole_depth() + 2;
    // [C], single search-snippet source for the "+2mm" margin specifically
    // ("extending a peg design by 2mm... since without this adaptation, the
    // hooks break off due to the thickness of the Multiboard" -- under-length
    // pegs are a known failure mode against the 6.4mm tile). The tile-
    // thickness input this reads (multibuild_small_hole_depth()) is itself
    // [C]//VERIFY (STL mesh, single community source -- see that function's
    // own note below), NOT [A] -- only the GEOMETRIC NECESSITY that a peg
    // must exceed the panel it passes through is self-evident/non-tiered,
    // not the depth value itself.
    // A DEFAULT for fit-viz/tests ONLY when the caller doesn't pass its own
    // `len` -- real consumer parts should pass their own per-instance
    // peg_len (see the module-family note above), not rely on this default.

/* [Data] — grid math off multibuild_grid_pitch(). */
function multibuild_grid_count(length) = floor(length / multibuild_grid_pitch());
function multibuild_grid_snap(length)  = round(length / multibuild_grid_pitch()) * multibuild_grid_pitch();
function multibuild_grid_points(cols, rows) =
    let (p = multibuild_grid_pitch(),
         x0 = -(cols - 1) * p / 2,
         y0 = -(rows - 1) * p / 2)
    [for (r = [0 : rows - 1]) for (c = [0 : cols - 1]) [x0 + c * p, y0 + r * p]];

/* [Placeholder] — envelope solid for fit checks. */
// Mount-feature envelope: board mount face at Z=0, feature grows -Z. For fit/viz only.
// Sized to the tip-flare span (widest point) x engagement length (the mount
// is deliberately longer than the hole is deep -- see Task 2 note).
// `peg_len` is consulted ONLY for the peg_click branch (its rigid peg has no
// stored engagement length -- see "peg_click" module family below); ignored
// (and may be left `undef`) for every _multibuild_table() type such as "snap".
module multibuild_mount_placeholder(type, peg_len = undef) {
    p = multibuild_grid_pitch();
    for (off = multibuild_mount_footprint(type))
        translate([off[0] * p, off[1] * p, 0])
            if (type == "peg_click")
                _multibuild_peg_click_placeholder_peg(
                    peg_len == undef ? _multibuild_peg_click_default_len() : peg_len);
            else
                _multibuild_mount_placeholder_peg(type);
}
module _multibuild_mount_placeholder_peg(type) {
    d = 2 * multibuild_mount_tip_flare(type);
    h = multibuild_mount_engagement(type);
    translate([0, 0, -h])
        cylinder(h = h, d = d, $fn = 48);
}

/* [Positive] — printed connector feature (shaft + flared arms) on a
   consumer part that mates into a board hole. */
// Positive mount: mates into a board hole (multibuild_hole), a through-hole
// snap-fit. Board face at Z=0, feature grows -Z. Central shaft (~half the
// arm width) plus mount_arm_count tapered arms flaring from the shaft out to
// mount_tip_flare radius at the tip -- the arm tip pokes past the far face
// of the (thinner) hole and flares there for retention, so this feature is
// deliberately taller than multibuild_hole_depth(type). Rigid static model:
// the measured at-rest tip diameter already clears the hole waist (Task 2
// note), so no compliant-flex simulation is needed for v1.
// `peg_len` is consulted ONLY for the peg_click branch (see
// multibuild_mount_placeholder()'s note above -- same dispatch shape).
module multibuild_mount(type, peg_len = undef) {
    p = multibuild_grid_pitch();
    for (off = multibuild_mount_footprint(type))
        translate([off[0] * p, off[1] * p, 0])
            if (type == "peg_click")
                _multibuild_peg_click_peg(
                    peg_len == undef ? _multibuild_peg_click_default_len() : peg_len);
            else
                _multibuild_mount_peg(type);
}
module _multibuild_mount_peg(type) {
    n  = multibuild_mount_arm_count(type);
    w  = multibuild_mount_arm_width(type);
    rf = multibuild_mount_tip_flare(type);
    h  = multibuild_mount_engagement(type);
    shaft_r = w / 2;
    // Deviation from the brief's suggested code: the brief anchors the tip
    // block's *near* (shaft-side) edge at x = rf - w/2, which places its
    // outer corner at radius sqrt((rf-w/2)^2 + (w/2)^2) < rf -- e.g. for the
    // "snap" row (rf=11.05, w=3) that lands the tip corner at r~9.68, not
    // 11.05, so the measured bbox diameter comes out ~19.1mm instead of the
    // researched ~22.1mm. Fixing that requires solving for the radial
    // placement whose *outer corner* (offset +-w/2 tangentially) lands
    // exactly on the r=rf circle: x_tip = sqrt(rf^2 - (w/2)^2).
    x_tip = sqrt(rf * rf - (w / 2) * (w / 2));
    // Deviation from the brief's suggested code: the brief's near-shaft
    // block starts exactly at x = shaft_r, i.e. tangent to the shaft
    // cylinder along a single line (only touching at y=0) rather than
    // overlapping its volume -- CGAL flagged the resulting union as a
    // non-manifold ("Object may not be a valid 2-manifold") because the arm
    // and shaft share a knife-edge instead of a solid overlap. Starting the
    // near block at the shaft's center (x=0) guarantees a genuine volume
    // overlap with the cylinder (which also spans x in [-shaft_r, shaft_r]),
    // resolving the manifold warning while keeping the same tapered-wedge
    // shape from the shaft out to the tip flare. Also widened the epsilon
    // thickness from the brief's 0.01mm to 0.1mm for numerical headroom.
    eps = 0.1;
    union() {
        // central shaft
        translate([0, 0, -h])
            cylinder(h = h, r = shaft_r, $fn = 48);
        // arms: hull a shaft-center block at Z=0 down to a tip-flare block
        // at Z=-h, arranged at even rotational increments around the shaft.
        for (a = [0 : 360 / n : 359]) {
            rotate([0, 0, a])
                hull() {
                    translate([0, -w / 2, -eps])
                        cube([shaft_r + eps, w, eps]);
                    translate([x_tip, -w / 2, -h])
                        cube([eps, w, eps]);
                }
        }
    }
}

/* [Positive/Placeholder: Peg Click] — the "peg_click" mount's own module
   family, dispatched from multibuild_mount()/multibuild_mount_placeholder()
   above (see their `type == "peg_click"` branch) instead of
   _multibuild_mount_peg()/_multibuild_mount_placeholder_peg() -- a plain
   rigid cylinder, NOT the Snap's flared-arm shape, per the "Data: Peg Click"
   note earlier in this file. Same board-face-at-Z=0/-Z-growth datum as the
   Snap mount above. `len` is a required per-instance parameter (peg length
   is deliberately not a table constant -- see that note). */
module _multibuild_peg_click_peg(len) {
    d  = multibuild_peg_click_dia();
    r  = d / 2;
    // Small lead-in chamfer at the tip (insertion ergonomics / edge-break
    // per design-for-print house rules) -- NOT the "click" mechanism itself
    // (no barb/ridge modeled, per the "No click-ridge/barb" research note)
    // and not a data-tier value. Printed pegs-up or pegs-down (the tested/
    // intended orientation), a straight cylinder has no overhang, so this is
    // a print-quality nicety, not a support-free requirement -- it does not
    // claim the geometry is overhang-free in every conceivable orientation
    // (e.g. the peg's actual in-use horizontal orientation once mounted on a
    // vertical board is a different question, out of scope for this cylinder
    // primitive's own print orientation).
    ch = 0.3;
    union() {
        translate([0, 0, -len + ch])
            cylinder(h = len - ch, r = r, $fn = 48);
        translate([0, 0, -len])
            cylinder(h = ch, r1 = r - ch, r2 = r, $fn = 48);
    }
}
module _multibuild_peg_click_placeholder_peg(len) {
    translate([0, 0, -len])
        cylinder(h = len, d = multibuild_peg_click_dia(), $fn = 48);
}

/* [Geometry helper] — dovetail prism along the +X slide axis. Cross-section
   lies in Y-Z: `throat_w` (Y) at the mouth near the face, widening to
   `buried_w` (Y) at depth `depth` (-Z). `overcut` lifts the mouth +Z above the
   face for a clean boolean when used as a cutter (0 for a solid placeholder). */
module _multibuild_dovetail(buried_w, throat_w, depth, length, overcut) {
    eps = 0.01;
    hull() {
        translate([0, 0, overcut]) cube([length, throat_w, 2 * eps], center = true);
        translate([0, 0, -depth])  cube([length, buried_w, 2 * eps], center = true);
    }
}

/* [Placeholder] — the mating Fix-Point POSITIVE dovetail (male), for fit-viz:
   the solid that should nest into multibuild_hole(type). Reference geometry,
   not a printed part, so the support-free global constraint does not apply.
   Face at Z=0, dovetail grows -Z (narrow neck at the face, wider at the tip);
   slides along +X. Length is set shorter than the pocket so the fit-check has
   +X slide clearance to observe. */
module multibuild_fixpoint_placeholder(type) {
    r = _multibuild_fixpoint_row(type);
    pos_throat = r[1]; pos_max = r[2]; pos_depth = r[3];
    plen = r[6] - 4;
    _multibuild_dovetail(pos_max, pos_throat, pos_depth, plen, 0);
}

/* [Negative] — board-hole profile OR Fix-Point accessory-side pocket, cut into
   a surface for use inside a consumer difference(). Dispatches on `type`:
   negative-only Fix-Point types (multibuild_known_holes()) are resolved from
   the parallel Fix-Point table FIRST; everything else falls through to the
   board-hole (snap) cutter, whose _multibuild_row() still asserts on an
   unknown type. `length` (optional) sets the Fix-Point pocket length along the
   +X slide axis; it is ignored by the board-hole cutter. */
// Board-hole cutter (snap etc.): board face at Z=0, cut grows -Z through the
// tile thickness. Simplified to a straight cylinder at the measured waist
// diameter (the true profile flares wider at both mouths -- this cut is the
// conservative narrow-point approximation, see RESEARCH.md).
// Fix-Point cutter (multipoint / multipoint_rail): a dovetail pocket, accessory
// face at Z=0, cut grows -Z, undercut (wider at depth) so a seated Fix-Point
// resists straight -Z/+Z pull-out and can only enter/leave by the +X slide.
// ACCESSORY-side negative ONLY -- the Fix-Point's own board-side engagement is
// out of scope. Fit-check honesty: the slide-on mate is proven for +X clearance
// only (see tests/test_multibuild_lib.sh), not for retention/engagement.
// Straight-cylinder hole cutter shared by the board-hole branch below, by
// multibuild_tile_holes(), and by multibuild_mount_holes()'s peg_click
// branch: cut grows -Z from Z=0 (translate origin), z-fudged (-0.01/+0.02
// past both faces) for a clean difference().
module _multibuild_straight_hole_cut(d, h) {
    translate([0, 0, -h - 0.01])
        cylinder(h = h + 0.02, d = d, $fn = 48);
}

module multibuild_hole(type, length = undef) {
    if (_multibuild_is_hole(type)) {
        r = _multibuild_fixpoint_row(type);
        neg_buried = r[4]; neg_depth = r[5];
        neg_throat = _multibuild_fixpoint_neg_throat(type);
        slen = (length == undef) ? r[6] : length;
        _multibuild_dovetail(neg_buried, neg_throat, neg_depth, slen, 0.5);
    } else {
        _multibuild_straight_hole_cut(multibuild_hole_dia(type), multibuild_hole_depth(type));
    }
}

/* [Negative] — multi-point receiving-hole stamp: cuts the correct board-hole
   negative at EVERY offset in multibuild_mount_footprint(type), for use
   inside a consumer difference() on the RECEIVING panel (the board/tile a
   mount plugs into) -- the counterpart to multibuild_mount()'s positive-side
   footprint loop above, sharing the same footprint accessor (single source
   of truth for placement) and the same off[0]*p/off[1]*p grid-pitch
   translate pattern. For single-hole types (e.g. "snap", footprint
   [[0,0]]), this reduces to a translate-by-zero wrapper around
   multibuild_hole(type, length), so multibuild_hole("snap")'s own
   standalone output is unchanged -- this module is additive, not a
   replacement. For "peg_click" (Small Hole family, NOT the Large Hole
   multibuild_hole() cuts for _multibuild_table() rows -- see "Data: Peg
   Click" above), each offset gets a Small Hole cut directly, since
   multibuild_hole("peg_click") would fail (peg_click is deliberately not a
   _multibuild_table() row). */
module multibuild_mount_holes(type, length = undef) {
    p = multibuild_grid_pitch();
    for (off = multibuild_mount_footprint(type))
        translate([off[0] * p, off[1] * p, 0])
            if (type == "peg_click")
                // `length` is a no-op on this branch -- the Small Hole depth
                // always comes from multibuild_small_hole_depth(), mirroring
                // multibuild_hole()'s existing length-ignoring behavior for
                // non-Fix-Point types.
                _multibuild_straight_hole_cut(multibuild_small_hole_dia(), multibuild_small_hole_depth());
            else
                multibuild_hole(type, length);
}

/* [Data: Tile] — MultiBoard Tile (25mm MU accessory panel). Multihole
   dia/depth and tile thickness are ALIASED from the existing snap-row data
   (single source of truth -- see the file-level "Single source of truth"
   convention); only the Small Hole dims/offset below are new literals. All
   holes are threaded on the real part -> modeled here as simplified straight
   cylinders (real thread profile deferred to #35), the same conservative
   convention as the existing "snap" board-hole negative above. See
   RESEARCH.md "Tile geometry (#33)". */
function multibuild_tile_thickness() = multibuild_hole_depth("snap"); // 6.4, aliased -- re-confirmed no drift (#33)
function multibuild_large_hole_dia() = multibuild_hole_dia("snap");   // 22.2, aliased -- re-confirmed no drift (#33)
// Small Hole dims: [C]//VERIFY, STL mesh (Printables #1277707 Tile), single
// community source, caliper-upgradeable (#16). RESEARCH.md "Tile geometry (#33)".
function multibuild_small_hole_dia() = 6.53; // waist/main-bore diameter
// Depth was measured INDEPENDENTLY (Z-profile scan), not assumed equal to
// multibuild_tile_thickness() -- the Small Hole was confirmed to be a
// through-hole spanning the full tile thickness, not a blind/partial pocket.
// It happens to equal the tile thickness value (6.4), but is left as its own
// literal (not an alias) so that fact stays visible and re-checkable.
function multibuild_small_hole_depth() = 6.4;
// Vector from a Multihole grid point to its nearest diagonally up-and-right
// Small Hole (measured, not idealized to the exact half-cell [12.5,12.5]).
function multibuild_small_hole_offset() = [12.61, 12.59];

// Small Hole lattice: half-pitch-diagonal-offset sublattice sharing the
// Multihole grid's pitch/orientation. Cardinality depends on the panel's
// footprint (RESEARCH.md): a Tile with flange/tab material past the nominal
// edge (Core piece) fits a full cols x rows count, while a flush-cut panel
// (Corner piece) only fits the interior (cols-1) x (rows-1) count. The
// accessory panel modeled by multibuild_tile_placeholder() below is a flush
// slab (no flange overhang) -- the Corner-piece / flush case -- so this
// implements the interior (cols-1) x (rows-1) cell-centered sublattice: one
// small hole per Multihole grid position that has a neighbor both to its
// right and above, placed at that Multihole's [x,y] plus the measured offset.
// Re-derives the same x0/y0/pitch/row-major convention as
// multibuild_grid_points() (kept inline rather than composing through it,
// since only two of the four grid-corner points are needed here).
function multibuild_tile_small_points(cols, rows) =
    let (p  = multibuild_grid_pitch(),
         x0 = -(cols - 1) * p / 2,
         y0 = -(rows - 1) * p / 2,
         off = multibuild_small_hole_offset())
    [for (r = [0 : rows - 2]) for (c = [0 : cols - 2])
        [x0 + c * p + off[0], y0 + r * p + off[1]]];

/* [Placeholder] — Tile accessory-panel envelope for fit checks. Datum matches
   the board-hole cutter below: top (mount) face at Z=0, slab grows -Z through
   the tile thickness; footprint centered on XY like multibuild_grid_points(). */
module multibuild_tile_placeholder(cols, rows) {
    p = multibuild_grid_pitch();
    w = cols * p;
    d = rows * p;
    h = multibuild_tile_thickness();
    difference() {
        translate([0, 0, -h / 2])
            cube([w, d, h], center = true);
        multibuild_tile_holes(cols, rows, "both");
    }
}

/* [Negative] — Tile accessory-panel hole-stamp: Multiholes at
   multibuild_grid_points(cols,rows) plus the Small Hole sublattice at
   multibuild_tile_small_points(cols,rows), for use inside a consumer
   difference() (e.g. multibuild_tile_placeholder() above). `which` selects
   "large" (Multiholes only), "small" (Small Holes only), or "both" (default).
   Same straight-cylinder simplification and translate/cylinder cutting style
   as multibuild_hole()'s board-hole cutter -- real thread deferred to #35. */
module multibuild_tile_holes(cols, rows, which = "both") {
    if (which == "large" || which == "both") {
        for (pt = multibuild_grid_points(cols, rows))
            translate([pt[0], pt[1], 0])
                _multibuild_straight_hole_cut(multibuild_large_hole_dia(), multibuild_tile_thickness());
    }
    if (which == "small" || which == "both") {
        for (pt = multibuild_tile_small_points(cols, rows))
            translate([pt[0], pt[1], 0])
                _multibuild_straight_hole_cut(multibuild_small_hole_dia(), multibuild_small_hole_depth());
    }
}

/* [Data: MultiBin] — 50mm CU / 50mm panel grid, DISTINCT from the 25mm MU
   board grid above. Do NOT reuse multibuild_grid_pitch() (=25) for CU-based
   sizing. See RESEARCH.md "MultiBin + Fix-Point (#32)".
   MultiBin datum differs from the mount-feature -Z convention at file top: a
   bin's floor sits at Z=0, its opening faces +Z, and its footprint is centered
   on the XY origin (see multibin_placeholder). */
function multibin_cu()          = 50;   // [A] docs.multibuild.io (CU = 50mm = 2x2 MU)
function multibin_panel_pitch() = 50;   // [A, derived from CU] Panels/Base Plates sit on the CU grid
function multibin_tolerance()   = 0.25; // [A] official design tolerance (same value as board parts)
function multibin_floor()       = 5;    // [C] Simple Walls base floor thickness (STL mesh)

// Simple Walls (standard-depth) shell family. Row:
//   [size=[Nx,Ny,Hz], [fw,fl], [cw,cl,ch], wall]
// footprint fw/fl = 50*N (edge-to-edge CU cells); cavity cw/cl = 50*N-6 (rim),
// ch = 50*Hz-6 (usable internal height to the internal rim); wall ~= 3.0mm.
// Footprint + cavity W/D are vendor-stated [A] AND mesh-confirmed [C]; cavity H
// and external height follow the vendor [A] per-CU rules. Micro sub-family and
// additional sizes deferred (see RESEARCH.md). Tier: [A]/[C].
function _multibin_table() = [
    [[2, 2, 0.5], [100, 100], [ 94, 94, 19], 3.0], // model 974493 (mesh 100x100 / 94x94)
    [[3, 2, 1.5], [150, 100], [144, 94, 69], 3.0], // model 974135 (mesh 150x100 / 144x94)
];
function _multibin_row(size) =
    let (r = [for (e = _multibin_table()) if (e[0] == size) e])
    assert(len(r) == 1, str("multibin: unknown bin size ", size)) r[0];
function multibin_footprint(size) = _multibin_row(size)[1]; // [fw, fl] external W x D
function multibin_cavity(size)    = _multibin_row(size)[2]; // [cw, cl, ch] internal W x D x H
function multibin_wall(size)      = _multibin_row(size)[3]; // rim wall thickness
function multibin_height(size)    = multibin_cu() * size[2] + multibin_floor(); // [A] external = 50*Hz + 5

/* [Placeholder] — external envelope solid (reference/viz + fit checks). This is
   reference geometry, not a printed part, so the support-free global constraint
   does not apply. */
// MultiBin datum: floor at Z=0, opening toward +Z, footprint centered on the XY
// origin (differs from the mount features' -Z convention at file top).
module multibin_placeholder(size) {
    f = multibin_footprint(size);
    h = multibin_height(size);
    translate([0, 0, h / 2])
        cube([f[0], f[1], h], center = true);
}

/* [Negative] — internal cavity cutter (reference negative for insert/divider
   design). This is negative reference geometry, not a printed part, so the
   support-free global constraint does not apply. */
// Cavity negative for the bin above: sits INSIDE the envelope with its floor at
// Z=multibin_floor() (the 5mm base) and centered on XY, so wall =
// (footprint-cavity)/2 on each axis. Same +Z-opening datum as the placeholder.
module multibin_cavity_cutout(size) {
    c = multibin_cavity(size);
    translate([0, 0, multibin_floor() + c[2] / 2])
        cube([c[0], c[1], c[2]], center = true);
}
