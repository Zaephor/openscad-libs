// Assert-only test for the vesa library. Run via
// scripts/openscad.sh --export-format stl -o /dev/null libraries/vesa/tests/vesa_test.scad
use <vesa/vesa.scad>;

assert(vesa_known_patterns() == ["mis-d-75","mis-d-100","mis-e"], "pattern list");
assert(vesa_known_hole_roles() == ["structural-mount","component-mount","keep-out","alignment"], "role vocab");

// MIS-D-75: 4 holes on a 75x75 square, centered → corners at +/-37.5
h75 = vesa_holes("mis-d-75");
assert(len(h75) == 4, "mis-d-75 hole count");
assert(vesa_spacing("mis-d-75") == [75,75], "mis-d-75 spacing");
// symmetric about origin
xs = [for (h=h75) h[0]]; ys = [for (h=h75) h[1]];
assert(max(xs) == -min(xs) && max(xs) == 37.5, "mis-d-75 x symmetry");
assert(max(ys) == -min(ys) && max(ys) == 37.5, "mis-d-75 y symmetry");
// all structural-mount role, positive dia
assert([for (h=h75) if (h[2]!="structural-mount"||h[3]<=0) h] == [], "mis-d-75 role/dia");

// MIS-E: 200x100
assert(vesa_spacing("mis-e") == [200,100], "mis-e spacing");
assert(len(vesa_holes("mis-e")) == 4, "mis-e hole count");

// xy convenience matches
assert(vesa_holes_xy("mis-d-100") == [for (h=vesa_holes("mis-d-100")) [h[0],h[1]]], "xy convenience");

echo("vesa_test OK");
