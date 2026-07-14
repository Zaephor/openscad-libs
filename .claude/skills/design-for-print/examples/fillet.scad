// Fillet: a curved (radiused) transition replacing one edge of a block.
$fn = 48;
sx = 24; sy = 24; sz = 24;
r  = 8; // fillet radius

union() {
    // main block minus the rounded corner strip
    cube([sx, sy - r, sz]);
    translate([0, sy - r, 0]) cube([sx, r, sz - r]);
    // rounded corner strip along the same top-back edge chamfer.scad cuts
    translate([0, sy - r, sz - r])
    rotate([0, 90, 0])
    cylinder(h = sx, r = r);
}
