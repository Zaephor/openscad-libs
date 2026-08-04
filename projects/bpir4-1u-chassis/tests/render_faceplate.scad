// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// render_faceplate.scad — isolates _faceplate() for the honeycomb-vent test
// (tests/test_bpir4_honeycomb_vents.sh). `use` doesn't import variables (see
// reference_openscad_gotchas), so the cooling/ear-hole toggles + params.scad
// are re-declared/re-included here the same way tests/asserts.scad does,
// minus fan_thickness: this file never compares a self-computed value
// against the render, it only invokes `use`d _faceplate(), whose body
// resolves fan_thickness against parts/tray.scad's own file scope (=20)
// regardless of what this file declares — so omitting it here is safe, not
// an oversight.
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <../parts/tray.scad>;   // for _faceplate()

_faceplate();
