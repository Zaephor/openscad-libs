// cable-clip — single-part project: a printable cable clip.
// Render: make render P=cable-clip

// M3 clearance — ISO 273 medium fit, 3.4mm [B]//VERIFY (named standard, not
// fetched). Inlined: the repo `hardware` lib was removed (#17).
screw_hole = 3.4;

module cable_clip() {
    difference() {
        union() {
            cube([24, 10, 4]);
            translate([12, 5, 4]) rotate([0, 90, 0])
                cylinder(h = 6, r = 6, center = true, $fn = 48);
        }
        translate([4, 5, -1]) cylinder(h = 6, d = screw_hole, $fn = 32);
        translate([20, 5, -1]) cylinder(h = 6, d = screw_hole, $fn = 32);
        translate([12, 5, 7]) rotate([0, 90, 0])
            cylinder(h = 30, r = 4, center = true, $fn = 48);
    }
}

cable_clip();
