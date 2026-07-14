// Gusset vs freestanding shelf: two wall-mounted shelves side by side --
// one a freestanding flat shelf (unsupported overhang), one reinforced
// with a triangular gusset brace back to the wall.
wall_t = 6; depth = 10; wall_h = 30; shelf_len = 16; shelf_z = 22; shelf_h = 4;

module shelf(gusset) {
    union() {
        cube([wall_t, depth, wall_h]);
        translate([wall_t, 0, shelf_z]) cube([shelf_len, depth, shelf_h]);
        if (gusset) {
            translate([wall_t, 0, 0])
            rotate([90, 0, 0])
            linear_extrude(height = depth)
            polygon(points = [[0, 0], [0, shelf_z + shelf_h], [shelf_len, shelf_z + shelf_h]]);
        }
    }
}

shelf(false);
translate([40, 0, 0]) shelf(true);
