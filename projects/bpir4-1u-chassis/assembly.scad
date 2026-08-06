// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// bpir4-1u-chassis — multipart assembly with exploded view + fit reference.
// Render: make render P=bpir4-1u-chassis

/* [Cooling] */
// Declared here + in each entry file; params.scad consumes only.
enable_exhaust = true; // toggle rear exhaust for review
fan_size  = 40;
fan_count = 2;
fan_thickness = 20;    // installed fan depth, mm; <0 -> fans-lib default. NF-A4x20 [A]

/* [Rack Ears] */
ear_hole_type = "slot"; // "slot" | "10-32" | "m6" | "round"

/* [Install Motion] */
// mm the board is retracted from its seated pose along +Y, for inspecting the
// installation motion rather than just the seated fit (#84). 0 = seated;
// board_install_travel() (params.scad) is the far end of the motion. This is
// consumed directly by assembly() below -- a view aid, not a printed
// dimension, so it needs no threading into tray()/lid().
install_offset = 0;

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
    if (show_tray) tray(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count, ear_hole_type = ear_hole_type, fan_thickness = fan_thickness);
    if (show_board)
        translate([board_x(), board_y() + install_offset, board_z()])
            % sbc_placeholder(BOARD);
    if (show_lid)
        translate([0, 0, (ext_h() - lid_th) + 30 * explode])
            lid(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count, fan_thickness = fan_thickness);
    if (show_rack)
        // Rack context: chassis (1U device) centered in a 3U window (1U pad
        // above+below) — see rack10_rackpost_context() (#7 generalize-to-core).
        % rack10_rackpost_context(STD, 1, 1, rack_depth_eff());
}

assembly();
