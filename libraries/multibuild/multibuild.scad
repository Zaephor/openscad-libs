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
//                    surface, for use inside a consumer difference()
// Provenance legend (see RESEARCH.md for the full Task 1 evidence log +
// checkpoint):
//   [A] fetched + read this pass (official MultiBuild docs).
//   [B] corroborated across >=2 independent peers.
//   [C] single-sourced / derived, or a named part cited but not fetched.
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
//
// Status (through Task 2): grid pitch/mount-type table (`_multibuild_table()`)
// and Role 1 accessor/grid-math functions are implemented below. The
// `multibuild_mount_placeholder()` / `multibuild_mount()` / `multibuild_hole()`
// modules (Roles 2-4) are Task 3+ (see 
// multibuild-lib-design.md for the exact API and 
// 2026-07-15-multibuild-lib-design.md for the design rationale). RESEARCH.md's
// Checkpoint findings section confirms the mechanism (Regular Snap plugging
// into a Large Hole, chosen over Threads/Peg Click/DS Snaps — see rationale
// there) fits this API shape before any geometry is written.

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
module multibuild_mount_placeholder(type) {
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
module multibuild_mount(type) {
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
