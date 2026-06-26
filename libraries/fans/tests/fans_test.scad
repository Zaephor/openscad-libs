// Assert-only test for the fans library. No geometry — run via test_fans_lib.sh.
use <fans/fans.scad>;

assert(fan_hole_spacing(120) == 105,  "120mm spacing should be 105");
assert(fan_hole_spacing(80)  == 71.5, "80mm spacing should be 71.5");
assert(fan_default_thickness(80) == 25, "80mm default thickness should be 25");

xy = fan_holes_xy(120);
assert(len(xy) == 4, "fan_holes_xy must return 4 coords");
assert(xy[0] == [-52.5, -52.5], "fan_holes_xy(120) corner 0");
assert(xy[2] == [ 52.5,  52.5], "fan_holes_xy(120) corner 2");
// symmetric about origin: coordinate sums are zero
assert(xy[0][0] + xy[1][0] + xy[2][0] + xy[3][0] == 0, "x symmetric");
assert(xy[0][1] + xy[1][1] + xy[2][1] + xy[3][1] == 0, "y symmetric");

echo("fans_test OK");
