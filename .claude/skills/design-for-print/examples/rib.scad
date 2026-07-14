// Rib: a thin structural fin connecting two faces/walls.
wall_t = 4; span = 22; wall_h = 20; rib_t = 2;

union() {
    cube([wall_t, span + 2 * wall_t, wall_h]);
    translate([wall_t + span, 0, 0]) cube([wall_t, span + 2 * wall_t, wall_h]);
    // thin connecting rib between the two walls
    translate([wall_t, span / 2 + wall_t - rib_t / 2, 0])
        cube([span, rib_t, wall_h * 0.7]);
}
