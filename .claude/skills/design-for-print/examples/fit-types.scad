// Fit types: three peg-in-hole pairs (press / slip / free) at
// progressively larger per-side clearance -- concentric circles, viewed
// from top, with a visibly different annular gap per pair.
$fn = 48;
plate = 30; plate_h = 4; hole_r = 8; peg_h = 14;

module pegpair(x0, peg_r) {
    translate([x0, 0, 0]) {
        difference() {
            cube([plate, plate, plate_h]);
            translate([plate / 2, plate / 2, -1]) cylinder(h = plate_h + 2, r = hole_r);
        }
        translate([plate / 2, plate / 2, plate_h]) cylinder(h = peg_h, r = peg_r);
    }
}

pegpair(0,  7.6);  // press / interference: small gap, exaggerated for visibility
pegpair(40, 6.6);  // slip / close: medium gap
pegpair(80, 5.2);  // free / running: large, clearly-visible gap
