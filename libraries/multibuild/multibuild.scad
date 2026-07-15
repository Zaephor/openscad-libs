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
