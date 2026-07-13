// tray part — single-body chassis: floor + faceplate + walls + rear wall.
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <hardware/hardware.scad>;

module tray() {
    // Stub: minimal floor slab so the file renders. Filled in Task 2+.
    translate([-body_w()/2, board_y(), 0])
        cube([body_w(), int_depth(), floor_th]);
}

tray();
