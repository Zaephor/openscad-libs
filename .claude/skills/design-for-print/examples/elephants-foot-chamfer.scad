// Elephant's foot bottom chamfer: a small 45deg chamfer on a block's
// bottom outer edge to counter the elephant's-foot bulge.
$fn = 32;
sx = 24; sy = 24; sz = 20; c = 3.5;

difference() {
    cube([sx, sy, sz]);
    translate([sx / 2, 0, 0])
    rotate([-45, 0, 0])
    cube([sx + 2, c * 2, c * 2], center = true);
}
