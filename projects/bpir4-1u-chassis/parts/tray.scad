// tray part — single-body chassis: floor + faceplate + walls + rear wall.
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <hardware/hardware.scad>;

module tray() {
    // Floor slab: full body width, full internal depth, on Z=0.
    translate([-body_w()/2, board_y(), 0])
        cube([body_w(), int_depth(), floor_th]);

    // Board standoff posts, on top of the floor, at the board's chassis position.
    // bore = M2.5 heat-set insert OD so inserts load from the top; the floor
    // underside stays flat (no through-hole).
    translate([board_x(), board_y(), floor_th])
        sbc_standoffs(BOARD, standoff_h, bore = board_insert_bore);
}

tray();
