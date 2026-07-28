// asserts.scad — negative-control regression for drive-tray's grid-width
// fit-assert. Rendered directly by tests/test_drive_tray.sh.
//
// `include` (not `use`) is required: `use` does not import variables (see
// reference_openscad_gotchas), so a `use`d drive-tray.scad would keep its
// OWN cols regardless of anything set here. `include` inlines the file, and
// OpenSCAD resolves every top-level variable reference to the LAST textual
// assignment in the fully-expanded file -- so the override below MUST come
// AFTER the include (a pre-include override would be silently clobbered by
// drive-tray.scad's own default assignment, since that assignment would
// then be the last one). Same idiom as bay-enclosure/tests/asserts.scad;
// verified empirically here too before committing.
include <../drive-tray.scad>;

// cols=9 at drive_gap=4.0/wall=2.4 blows the grid well past labrax's
// 222mm clear width -- MUST abort drive-tray.scad's own width fit-assert.
// If this file ever renders cleanly, the fit-assert has silently broken.
cols = 9;
