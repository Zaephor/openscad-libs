// Sharp vs. filleted internal corner: two identical L-shaped brackets
// side by side -- one with a sharp internal 90deg corner, one with a
// filleted internal corner.
$fn = 48;
leg = 24; arm = 8; h = 10; r = 6;

module l_bracket(filleted) {
    if (!filleted) {
        union() {
            cube([leg, arm, h]);
            cube([arm, leg, h]);
        }
    } else {
        union() {
            cube([leg, arm, h]);
            cube([arm, leg, h]);
            // fillet fill at the inside corner: a patch filling the notch,
            // minus a quarter-circle at its far corner, leaves a smooth
            // concave radius blending the two inner walls
            translate([arm, arm, 0])
            difference() {
                cube([r, r, h]);
                translate([r, r, -1]) cylinder(h = h + 2, r = r);
            }
        }
    }
}

l_bracket(false);
translate([40, 0, 0]) l_bracket(true);
