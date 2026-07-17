// Assert-only test for the fans library. No geometry — run via test_fans_lib.sh.
use <fans/fans.scad>;

assert(fan_hole_spacing(120) == 105,  "120mm spacing should be 105");
assert(fan_hole_spacing(80)  == 71.5, "80mm spacing should be 71.5");
assert(fan_default_thickness(80) == 25, "80mm default thickness should be 25");

// --- hole-role schema parity (mirrors sbc/drives/motherboards) ---
assert(fans_known_hole_roles() == ["structural-mount","component-mount","keep-out","alignment"],
       "role vocabulary");

h = fan_mount_holes(120);
assert(len(h) == 4, "fan_mount_holes(120) => 4 corners");
d120 = fan_mount_hole_dia(120);
assert(h[0] == [-52.5, -52.5, "structural-mount", d120], "corner 0 tuple");
assert(h[2] == [ 52.5,  52.5, "structural-mount", d120], "corner 2 tuple");
for (e = h) {
    assert(e[2] == "structural-mount", "corner role");
    assert(e[3] == d120, "corner dia");
}
// symmetric about origin (index the tuple x/y)
assert(h[0][0]+h[1][0]+h[2][0]+h[3][0] == 0, "x symmetric");
assert(h[0][1]+h[1][1]+h[2][1]+h[3][1] == 0, "y symmetric");

// role filter: matching role => all 4; absent role => none (silent); "all" => 4
assert(len(fan_mount_holes(120, "structural-mount")) == 4, "filter structural => 4");
assert(len(fan_mount_holes(120, "keep-out")) == 0, "filter keep-out => 0");
assert(len(fan_mount_holes(120, "all")) == 4, "wildcard all => 4");

echo("fans_test OK");
