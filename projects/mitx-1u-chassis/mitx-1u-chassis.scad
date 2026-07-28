// mitx-1u-chassis — 1U 10" rack chassis for a mini-ITX board, front-IO
// appliance (IO shield + power button front), external DC-in, fan+honeycomb,
// rear #40 support mate. Consumes motherboards/rack10/rack-support/fans/honeycomb.
use <motherboards/motherboards.scad>;
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;

/* [Rack] */
standard = "labrax";
ear_type = "slot";
/* [Print] */
wall = 2.4; floor_th = 2.0; faceplate_th = 3.0;
standoff_h = 6.0; heatsink_ceiling = 25;
/* [Front] */
button_dia = 12; board_offset = 20;   // off-center X so button fits beside IO
/* [Cooling / Power] */
dc_dia = 11; fan_size = 40; cell = 8.0; hc_wall = 1.2;

function _bw()    = mobo_size("itx")[0];   // 170
function _bd()    = mobo_size("itx")[1];   // 170
function _int_h() = rack10_device_height(1) - floor_th;
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();

// World X of the board's own local origin (rear-left corner, see
// motherboards.scad's datum comment). Every board-frame feature (standoffs,
// placeholder, IO cutout) must translate by this SAME offset, or they drift
// apart -- that's exactly the bug this formula fixes vs. translating the IO
// cutout by board_offset alone (which ignores the board's own half-width).
function _board_x() = board_offset - _bw() / 2;

// IO cutout: mobo_io_cutout returns [x_off, w, h] in the board's own local
// (component-up) frame -- same frame mobo_standoff_xy/mobo_placeholder use --
// so it shares _board_x() as its world-frame offset.
function _io()    = mobo_io_cutout("itx");
function _io_x0() = _board_x() + _io()[0];              // world low (left) edge
function _io_x1() = _board_x() + _io()[0] + _io()[1];   // world high (right) edge

// Power button: sits in the off-center gap on the panel's low-X side, beside
// the IO window (board_offset shifts the board toward +X to open this gap).
// Centered in the gap between the panel's low edge and the IO's low edge so
// it clears both by construction whenever the gap is wide enough for it.
function _button_x() = (-rack10_panel_width(standard) / 2 + _io_x0()) / 2;

// Real headroom above the board's own IO-edge Z-datum, flush to the 1U
// interior ceiling. mobo_io_cutout("itx")[2] (44.45mm, the full generic
// ATX-family shield height) does not fit here -- board depth _int_h()
// interior minus standoff_h leaves less than that -- so this project cuts
// a board-specific window sized to available headroom instead of the
// library's generic envelope (spec addendum 2026-07-28: this is a
// BYO-board appliance, not a universal-shield-compatible case).
function _io_window_h() = _int_h() - standoff_h;

// Fit-asserts
assert(_bw() <= rack10_clear_width(standard) - 2*wall + 1e-6,
    str("mitx-1u: board width ", _bw(), " > usable ", rack10_clear_width(standard)-2*wall));
assert(_bd() <= _usable_depth() + 1e-6,
    str("mitx-1u: board depth ", _bd(), " > usable ", _usable_depth()));
assert(standoff_h + mobo_thickness() + heatsink_ceiling <= _int_h() + 1e-6,
    str("mitx-1u: standoff+board+heatsink ", standoff_h+mobo_thickness()+heatsink_ceiling,
        " > 1U interior ", _int_h(), " (reduce heatsink_ceiling/standoff)"));
// Off-center guard: board_offset shifts both the IO window and the button
// hole, so a bad value can walk either one off the panel. The button hole
// (both edges, since it's a hole) and the IO cutout's right edge must stay
// within +-rack10_panel_width/2.
assert(_io_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-1u: IO cutout right edge ", _io_x1(), " > panel half-width ", rack10_panel_width(standard)/2));
assert(_button_x() - button_dia/2 >= -rack10_panel_width(standard)/2 + 1e-6
    && _button_x() + button_dia/2 <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-1u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] exceeds panel +-", rack10_panel_width(standard)/2));

module _mitx_faceplate() {
    difference() {
        rack10_panel(standard, 1, faceplate_th);
        if (ear_type == "slot") rack10_holes(standard, 1, hole_type="slot", dia=rack10_screw_clearance("10-32"));
        else rack10_holes(standard, 1, hole_type=ear_type);
        // IO shield cutout at the board's IO edge (board off-center by
        // board_offset). mobo_io_cutout_stamp grows +Y from the board's own
        // local Y=0 (rear/IO edge) -- but the faceplate sits at -Y from that
        // same plane (rack10's front-of-panel convention), so mirror the
        // stamp in Y before placing it in the shared board/standoffs frame
        // (_board_x()); otherwise the cutter grows away from the faceplate
        // and never reaches it.
        translate([_board_x(), 0, floor_th + standoff_h])
            mirror([0, 1, 0])
                translate([_io()[0], -1, 0])
                    cube([_io()[1], faceplate_th + 3, _io_window_h()]);
        // power button hole in the off-center gap beside the IO window.
        translate([_button_x(), -faceplate_th - 1, rack10_device_height(1)/2])
            rotate([-90,0,0]) cylinder(h = faceplate_th + 2, d = button_dia);
    }
}
module mitx_1u_chassis() {
    _mitx_faceplate();
    // off-center board standoffs
    translate([_board_x(), 0, floor_th])
        mobo_standoffs("itx", standoff_h, role="structural-mount");
    % translate([_board_x(), 0, floor_th + standoff_h]) mobo_placeholder("itx");
    // walls/floor/rear/tongue/vents in Tasks 2-3
}
mitx_1u_chassis();
