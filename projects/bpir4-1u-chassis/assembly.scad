// bpir4-1u-chassis — multipart assembly with exploded view + fit reference.
// Render: make render P=bpir4-1u-chassis
include <params.scad>;
use <parts/tray.scad>;
use <parts/lid.scad>;
use <sbc/sbc.scad>;

/* [Exploded View] */
explode = 0; // [0:0.01:1]

/* [Show] */
show_tray  = true;
show_lid   = true;
show_board = true; // sbc_placeholder fit reference (not a printed part)

module assembly() {
    if (show_tray) tray();
    if (show_board)
        translate([board_x(), board_y(), standoff_h])
            % sbc_placeholder(BOARD);
    if (show_lid)
        translate([0, 0, (ext_h() - lid_th) + 30 * explode])
            lid();
}

assembly();
