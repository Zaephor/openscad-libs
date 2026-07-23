// asserts_bay525_fh.scad — positive-control preset lock: bay525_fh
// (full-height 5.25", 82.55mm tall, drives.scad) at device_u=2 (91.36mm
// rack10 exterior budget) is one of the three LOCKED presets for this
// project (bay525_hh -> 1U [default], bay525_fh -> 2U, bay35 -> 1U; see
// ../README.md). This file's only job is to render clean at that preset --
// a silent failure (abort) here means one of bay-enclosure.scad's own
// fit-asserts regressed against the locked preset.
//
// Separate file, not folded into asserts.scad: `include` (not `use`) is
// required to override top-level params (`use` doesn't import variables --
// see reference_openscad_gotchas), and OpenSCAD resolves every top-level
// variable to the LAST textual assignment in the fully-expanded file -- so
// only ONE device_type/device_u pair can be live per included file. See
// asserts.scad's own header for the full reasoning (it uses the same
// include-then-override idiom for its own, negative-control preset).
include <../bay-enclosure.scad>;
device_type = "bay525_fh";
device_u = 2;
