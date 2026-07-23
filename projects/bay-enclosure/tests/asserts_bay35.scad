// asserts_bay35.scad — positive-control preset lock: bay35 (170.0 x 101.6 x
// 25.4mm, drives.scad) at device_u=1 (43.66mm rack10 exterior budget) is one
// of the three LOCKED presets for this project (bay525_hh -> 1U [default],
// bay525_fh -> 2U, bay35 -> 1U; see ../README.md). This file's only job is
// to render clean at that preset -- a silent failure (abort) here means one
// of bay-enclosure.scad's own fit-asserts regressed against the locked
// preset.
//
// Separate file, not folded into asserts.scad: same use-scope/last-textual-
// assignment reasoning as asserts_bay525_fh.scad and asserts.scad itself
// (only one device_type/device_u pair can be live per included file).
include <../bay-enclosure.scad>;
device_type = "bay35";
device_u = 1;
