// Bevel: same construction as a chamfer but a larger, symmetric angled
// face on a thicker block (both top edges beveled), to read as a
// structural/visual bevel rather than a small functional edge-break.
$fn = 32;
sx = 40; sy = 24; sz = 14;
b  = 8; // bevel size (larger relative to block than chamfer.scad's c)

difference() {
    cube([sx, sy, sz]);
    translate([sx / 2, 0, sz])
    rotate([45, 0, 0])
    cube([sx + 2, b * 2, b * 2], center = true);
    translate([sx / 2, sy, sz])
    rotate([45, 0, 0])
    cube([sx + 2, b * 2, b * 2], center = true);
}
