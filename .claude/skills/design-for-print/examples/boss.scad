// Boss: a cylindrical post projecting from a floor with a bore for a
// fastener/insert, reinforced with a gusset (not freestanding) — the
// correct pattern from reference/strength-physics.md.
$fn = 48;
plate = 40; plate_h = 4;
bx = 20; by = 20; bh = 16; br = 6; bore_r = 3; bore_d = 10;
gh = 14; gl = 12; gthick = 6;

union() {
    // floor plate
    cube([plate, plate, plate_h]);
    // boss with blind bore
    translate([bx, by, plate_h])
    difference() {
        cylinder(h = bh, r = br);
        translate([0, 0, bh - bore_d]) cylinder(h = bore_d + 1, r = bore_r);
    }
    // gusset tying the boss back to the floor (overlaps boss slightly)
    translate([bx + br - 1, by - gthick / 2, 0])
    rotate([90, 0, 0])
    linear_extrude(height = gthick)
    polygon(points = [[0, plate_h], [0, plate_h + gh], [gl, plate_h]]);
}
