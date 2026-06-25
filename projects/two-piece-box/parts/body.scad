// body part — the box base.
module body() {
    difference() {
        cube([40, 40, 20]);
        translate([2, 2, 2]) cube([36, 36, 20]);
    }
}

body();
