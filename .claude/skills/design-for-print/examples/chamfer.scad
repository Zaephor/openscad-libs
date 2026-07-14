// Chamfer: a flat 45deg angled cut removing one edge of a block.
$fn = 32;
sx = 24; sy = 24; sz = 24;
c  = 8; // chamfer size

difference() {
    cube([sx, sy, sz]);
    // symmetric cutter centered exactly on the top-back edge (y=sy, z=sz)
    translate([sx / 2, sy, sz])
    rotate([45, 0, 0])
    cube([sx + 2, c * 2, c * 2], center = true);
}
