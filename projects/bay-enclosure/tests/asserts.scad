// asserts.scad — negative-control regression for bay-enclosure's height
// fit-assert. Rendered directly by tests/test_bay_enclosure.sh.
//
// `include` (not `use`) is required: `use` does not import variables (see
// reference_openscad_gotchas), so a `use`d bay-enclosure.scad would keep its
// OWN device_type/device_u regardless of anything set here. `include`
// inlines the file, and OpenSCAD resolves every top-level variable reference
// to the LAST textual assignment in the fully-expanded file -- so the
// overrides below MUST come AFTER the include (a pre-include override would
// be silently clobbered by bay-enclosure.scad's own default assignment,
// since that assignment would then be the last one). Verified empirically:
// an assert() positioned BEFORE a later reassignment still evaluates against
// that later value.
include <../bay-enclosure.scad>;

// bay525_fh (full-height 5.25", 82.55mm tall per drives.scad) crammed into
// device_u=1 (43.66mm rack10 exterior budget) MUST abort bay-enclosure.scad's
// own height fit-assert -- this is the negative control: if this file ever
// renders cleanly, the fit-assert has silently broken.
device_type = "bay525_fh";
device_u = 1;
