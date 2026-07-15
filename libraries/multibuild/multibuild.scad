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
// Task 1 status (this commit): scaffold + RESEARCH.md source log +
// checkpoint only. The grid pitch/mount-type table (`_multibuild_table()`),
// accessor functions (`multibuild_grid_pitch()`, `multibuild_known_mounts()`,
// `multibuild_hole_dia()`/`multibuild_hole_depth()`, `multibuild_grid_count()`/
// `multibuild_grid_snap()`/`multibuild_grid_points()`) and the
// `multibuild_mount_placeholder()` / `multibuild_mount()` / `multibuild_hole()`
// modules are Task 2+ (see 
// design.md for the exact API and 
// multibuild-lib-design.md for the design rationale). Nothing below this
// header is implemented yet — RESEARCH.md's Checkpoint findings section
// confirms the mechanism (Regular Snap plugging into a Large Hole, chosen
// over Threads/Peg Click/DS Snaps — see rationale there) fits this API shape
// before any geometry is written.

$fn = 48;
