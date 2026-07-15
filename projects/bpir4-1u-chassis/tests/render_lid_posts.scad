// render_lid_posts.scad — isolates _lid_posts() for the corner-post
// bond-both-walls/fillet/chamfer test (tests/test_bpir4_corner_posts.sh) and
// for verify-scad-geometry overlay checks. `use` doesn't import variables
// (see reference_openscad_gotchas), so the cooling/ear-hole toggles +
// params.scad are re-declared/re-included here exactly as tests/asserts.scad
// / tests/render_faceplate.scad do.
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <../parts/tray.scad>;   // for _lid_posts()

_lid_posts();
