// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// rla_ps1.scad — positive-control preset check for rack10-device-tray:
// the RLA-PS1 envelope ([189.6,106.6,25.6] [B] vendor datasheet, wider AND
// deeper than the GS308 default) must still pass every fit-assert.
// Rendered directly by tests/test_rack10_device_tray.sh.
//
// `include` (not `use`) is required: `use` does not import variables (see
// reference_openscad_gotchas), so a `use`d rack10-device-tray.scad would
// keep its OWN device_size regardless of anything set here. `include`
// inlines the file, and OpenSCAD resolves every top-level variable
// reference to the LAST textual assignment in the fully-expanded file — so
// the override below MUST come AFTER the include (a pre-include override
// would be silently clobbered by rack10-device-tray.scad's own default
// assignment, since that assignment would then be the last one). Same
// idiom as drive-tray/tests/asserts.scad.
include <../rack10-device-tray.scad>;

device_size = [189.6, 106.6, 25.6]; // RLA-PS1 [B]
