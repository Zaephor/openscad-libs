// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// render_lid_posts.scad — isolates _lid_posts() for the corner-post
// bond-both-walls/fillet/chamfer test (tests/test_bpir4_corner_posts.sh) and
// for verify-scad-geometry overlay checks. `use` doesn't import variables
// (see reference_openscad_gotchas), so the cooling/ear-hole toggles +
// params.scad are re-declared/re-included here the same way
// tests/asserts.scad / tests/render_faceplate.scad do, minus fan_thickness:
// this file never compares a self-computed value against the render, it
// only invokes `use`d _lid_posts(), whose body resolves fan_thickness
// against parts/tray.scad's own file scope (=20) regardless of what this
// file declares — so omitting it here is safe, not an oversight.
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <../parts/tray.scad>;   // for _lid_posts()

_lid_posts();
