// render_faceplate.scad — isolates _faceplate() for the honeycomb-vent test
// (tests/test_bpir4_honeycomb_vents.sh). `use` doesn't import variables (see
// reference_openscad_gotchas), so the cooling/ear-hole toggles + params.scad
// are re-declared/re-included here exactly as tests/asserts.scad does.
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <../parts/tray.scad>;   // for _faceplate()

_faceplate();
