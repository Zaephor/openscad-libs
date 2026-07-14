// Chamfered vs flat overhang: two wall+ledge features side by side -- one
// a sharp flat 90deg overhang ledge, one the same ledge with a 45deg
// chamfer filling the underside corner (self-supporting).
wall_t = 6; depth = 20; wall_h = 30; ledge_h = 20; ledge_len = 14; ch = 8;

module ledge(chamfer) {
    union() {
        cube([wall_t, depth, wall_h]);
        translate([wall_t, 0, ledge_h]) cube([ledge_len, depth, 6]);
        if (chamfer) {
            translate([wall_t, depth, ledge_h])
            rotate([90, 0, 0])
            linear_extrude(height = depth)
            polygon(points = [[0, 0], [0, -ch], [ch, 0]]);
        }
    }
}

ledge(false);
translate([40, 0, 0]) ledge(true);
