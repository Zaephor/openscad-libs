// bpir4-1u-chassis — multipart assembly with exploded view + fit reference.
// Render: make render P=bpir4-1u-chassis

// Cooling + rack-ear defaults: single source of truth in defaults.scad (see
// that file re: OpenSCAD Customizer visibility tradeoff).
include <defaults.scad>;
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
show_rack  = false; // 3U rackpost reference

module assembly() {
    if (show_tray) tray();
    if (show_board)
        translate([board_x(), board_y(), board_z()])
            % sbc_placeholder(BOARD);
    if (show_lid)
        translate([0, 0, (ext_h() - lid_th) + 30 * explode])
            lid();
    if (show_rack)
        translate([0, 0, -rack10_u()])          // chassis is the middle of 3U
            % rack10_placeholder(STD, 3, rack_depth_eff());
}

assembly();
