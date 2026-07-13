// lid part — flat cover, flush top, countersunk M3 into tray posts.
include <../params.scad>;
use <rack10/rack10.scad>;
use <hardware/hardware.scad>;

module lid() {
    // Stub: minimal plate so the file renders. Filled in Task 7.
    translate([-(body_w()/2 - wall - wall_gap), board_y(), 0])
        cube([body_w() - 2*(wall + wall_gap), int_depth(), lid_th]);
}

lid();
