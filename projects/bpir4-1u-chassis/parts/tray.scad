// tray part — single-body chassis: floor + faceplate + walls + rear wall.
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <hardware/hardware.scad>;

// Outer shell: floor + two side walls + rear wall, with an inner ledge on the
// wall tops so the lid drops in flush. Faceplate/fans/vents added by later modules.
module _tray_shell() {
    y0 = board_y();
    dd = int_depth();
    difference() {
        union() {
            // Floor.
            translate([-body_w()/2, y0, 0]) cube([body_w(), dd, floor_th]);
            // Side walls (full exterior height).
            for (sx = [-1, 1])
                translate([sx*(body_w()/2) - (sx>0?wall:0), y0, 0])
                    cube([wall, dd, ext_h()]);
            // Rear wall (solid for now; Task 5 cuts fans/vents).
            translate([-body_w()/2, y0 + dd - wall, 0])
                cube([body_w(), wall, ext_h()]);
        }
        // lip = wall/2 outer strip kept above the shelf on the two sides + rear;
        // front stays open (over-cut -Y) — the faceplate closes the front.
        translate([-(body_w()/2 - wall/2), y0 - 1, ext_h() - lid_th])
            cube([body_w() - wall, dd - wall/2 + 1, lid_th + 1]);
    }
}

// Front rack panel: full panel width, chassis-exterior height, front face on
// Y=0 growing -Y (toward the rack front). Rack mount holes + connector cutouts.
module _faceplate() {
    difference() {
        // Panel blank (own height = ext_h(); width from the library).
        translate([-panel_w()/2, -faceplate_th, 0])
            cube([panel_w(), faceplate_th, ext_h()]);
        // Rack mounting holes — square cage-nut pattern, from the library.
        rack10_holes(STD, 1, hole_type = "square");
        // BPI-R4 front-panel connector openings (ymin edge), at the board's
        // chassis position. depth clears the panel thickness.
        translate([board_x(), board_y(), board_z()])
            sbc_faceplate_cutouts(BOARD, "ymin", depth = faceplate_th + 2);
    }
}

module tray() {
    _tray_shell();
    _faceplate();
    // Board standoff posts.
    translate([board_x(), board_y(), floor_th])
        sbc_standoffs(BOARD, standoff_h, bore = board_insert_bore);
}

tray();
