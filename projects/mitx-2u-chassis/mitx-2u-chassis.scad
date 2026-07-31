// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// mitx-2u-chassis — 2U 10" rack chassis for a mini-ITX board, front-IO
// appliance (IO shield + power button front) PLUS a front-faceplate
// low-profile PCIe card aperture + bracket mount, external DC-in, fan +
// honeycomb, rear #40 support mate. Same core pattern as the sibling
// mitx-1u-chassis (#42, device_u=1, no PCIe) at device_u=2. Consumes
// motherboards/rack10/rack-support/fans/honeycomb/pcie-bracket.
use <motherboards/motherboards.scad>;
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;
use <pcie-bracket/pcie-bracket.scad>;

/* [Rack] */
standard = "labrax";
ear_type = "slot";
device_u = 2;
/* [Print] */
wall = 2.4; floor_th = 2.0; faceplate_th = 3.0;
standoff_h = 6.0; heatsink_ceiling = 55;
/* [Front] */
button_dia = 12; board_offset = 20;   // off-center X so button fits beside IO
pcie_screw = "6-32";
/* [Cooling / Power] */
dc_dia = 11; fan_size = 60; cell = 8.0; hc_wall = 1.2;
/* [PCIe keep-out] */
// LP card envelope reserved above/behind the slot -- no board- or
// bracket-sourced figure exists for either dimension (pcie-bracket.scad's
// own header explicitly carries no card-length/card-envelope data, see its
// "NOTE (final-review fix, Finding 2)"); these are this project's own
// reasoned design placeholders, //VERIFY, not [B]/[C] tiered claims.
lp_card_h = 64.4; lp_card_len = 168;

function _bw() = mobo_size("itx")[0];   // 170
function _bd() = mobo_size("itx")[1];   // 170
function _int_h() = rack10_device_height(device_u) - floor_th;
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();

// World X of the board's own local origin (rear-left corner, see
// motherboards.scad's datum comment) -- same _board_x() idiom as
// mitx-1u-chassis.scad. Every board-frame feature (standoffs, placeholder,
// IO cutout, PCIe cutout) shares this SAME offset, or they drift apart from
// the actual mounted board (mitx-1u-chassis.scad's own comment on this
// formula; verified here too -- see PCIe/IO cutout comments below).
function _board_x() = board_offset - _bw() / 2;

// IO cutout: mobo_io_cutout returns [x_off, w, h] in the board's own local
// (component-up) frame -- same frame mobo_standoff_xy/mobo_placeholder use
// -- so it shares _board_x() as its world-frame offset.
function _io()    = mobo_io_cutout("itx");
function _io_x0() = _board_x() + _io()[0];              // world low (left) edge
function _io_x1() = _board_x() + _io()[0] + _io()[1];   // world high (right) edge

// First (only, slots=1) PCIe slot's world X span -- mobo_pcie_first_xy is
// in the SAME component-up local frame as mobo_io_cutout/mobo_standoff_xy
// (motherboards.scad), so it shares _board_x() too, NOT board_offset alone
// -- verified empirically: translating this block by board_offset alone
// (the plan's original Task-1 draft) puts the PCIe cutout's world X past
// the panel's own half-width entirely (a silent no-op cut, same failure
// shape as the mount-hole mirror bug -- see CORRECTION 2026-07-31 in the
// plan's Global Constraints for that one).
function _pcie_x0() = _board_x() + mobo_pcie_first_xy("itx")[0];
function _pcie_x1() = _pcie_x0() + mobo_pcie_slot_w();
function _pcie_cx()  = (_pcie_x0() + _pcie_x1()) / 2;   // slot centerline -- pcie_bracket()'s own local X=0 datum

// Power button: sits in the off-center gap on the panel's low-X side,
// beside the IO window (board_offset shifts the board toward +X to open
// this gap) -- same _button_x() idiom as mitx-1u-chassis.scad, centered in
// the gap between the panel's low edge and the IO's own low edge so it
// clears both by construction whenever the gap is wide enough for it.
function _button_x() = (-rack10_panel_width(standard) / 2 + _io_x0()) / 2;

// Fit-asserts
assert(_bw() <= rack10_clear_width(standard) - 2*wall + 1e-6,
    str("mitx-2u: board width ", _bw(), " > usable ", rack10_clear_width(standard)-2*wall));
assert(_bd() <= _usable_depth() + 1e-6,
    str("mitx-2u: board depth ", _bd(), " > usable ", _usable_depth()));
assert(standoff_h + mobo_thickness() + heatsink_ceiling <= _int_h() + 1e-6,
    str("mitx-2u: standoff+board+heatsink ", standoff_h+mobo_thickness()+heatsink_ceiling,
        " > 2U interior ", _int_h(), " (reduce heatsink_ceiling/standoff)"));
assert(standoff_h + mobo_thickness() + lp_card_h <= _int_h() + 1e-6,
    str("mitx-2u: standoff+board+LP-card ", standoff_h+mobo_thickness()+lp_card_h,
        " > 2U interior ", _int_h(), " (LP card too tall for 2U)"));
assert(lp_card_len <= _usable_depth() + 1e-6,
    str("mitx-2u: LP card length ", lp_card_len, " > usable depth ", _usable_depth(),
        " (LP card collides rear)"));
// Board footprint vs. side walls' INTERIOR faces (#42 final-review finding
// -- the off-center guard below only checks holes against the outer panel,
// not the board against the shell interior; ported to this project's own
// _board_x()).
assert(_board_x() - wall >= -rack10_clear_width(standard)/2 - 1e-6
    && _board_x() + _bw() + wall <= rack10_clear_width(standard)/2 + 1e-6,
    str("mitx-2u: board [", _board_x(), ",", _board_x()+_bw(), "] at board_offset=", board_offset,
        " collides with a side wall (interior span +-", rack10_clear_width(standard)/2 - wall, ")"));
// IO cutout right edge vs. the panel's own outer bound (mitx-1u idiom).
assert(_io_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: IO cutout right edge ", _io_x1(), " > panel half-width ", rack10_panel_width(standard)/2));
// PCIe slot cutout vs. the panel's own outer bound (opposite/high-X side
// from the IO window, per mobo_pcie_first_xy's own X-flip convention).
assert(_pcie_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: PCIe slot cutout right edge ", _pcie_x1(), " > panel half-width ", rack10_panel_width(standard)/2));
// Button hole vs. the panel's own outer bounds (both edges, since it's a hole).
assert(_button_x() - button_dia/2 >= -rack10_panel_width(standard)/2 + 1e-6
    && _button_x() + button_dia/2 <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] exceeds panel +-", rack10_panel_width(standard)/2));

module _mitx2_faceplate() {
    difference() {
        translate([-rack10_panel_width(standard)/2, -faceplate_th, 0])
            cube([rack10_panel_width(standard), faceplate_th, rack10_device_height(device_u)]);
        if (ear_type == "slot") rack10_holes(standard, device_u, hole_type="slot", dia=rack10_screw_clearance("10-32"));
        else rack10_holes(standard, device_u, hole_type=ear_type);
        // mobo_io_cutout_stamp/mobo_pcie_cutout grow +Y from the board's own
        // local frame (rear-IO edge = local Y=0); this faceplate sits at -Y
        // (rack10 front-of-panel convention), so mirror the stamps in Y
        // first or the cutters never reach it (#42 hit this exact bug on
        // the IO stamp -- verified here empirically via intersection()
        // against this faceplate slab: with the mirror, both stamps'
        // world-Y span fully overlaps the slab's own Y=[-faceplate_th,0]
        // span at the outer face; without it, they don't).
        translate([_board_x(), 0, floor_th+standoff_h])
            mirror([0, 1, 0]) {
                mobo_io_cutout_stamp("itx", depth=faceplate_th+2);
                // PCIe slot aperture (single slot) at the board's own slot X.
                mobo_pcie_cutout("itx", slots=1, depth=faceplate_th+2);
            }
        // pcie_bracket_mount_holes() is NOT cut here: per pcie-bracket.scad's
        // own header, it bores a Z-axis hole through the bracket's FOOT
        // (flat in the XY plane at Z=[-thickness,0], a floor/rail
        // fastener), not a Y-extruding faceplate through-cut like the two
        // stamps above -- verified empirically: intersection() of that
        // cutter (placed the same way as the stamps above) against this
        // faceplate slab is EMPTY at every board_offset. Task 2 cuts the
        // real hole into the floor (see CORRECTION 2026-07-31 in the plan's
        // Global Constraints).
        // Power button in the off-center gap beside the IO window.
        translate([_button_x(), -faceplate_th-1, rack10_device_height(device_u)/2])
            rotate([-90,0,0]) cylinder(h=faceplate_th+2, d=button_dia);
    }
}
module mitx_2u_chassis() {
    _mitx2_faceplate();
    // off-center board standoffs -- SAME _board_x() offset as the
    // faceplate's IO/PCIe cutout block above, or they drift apart.
    translate([_board_x(), 0, floor_th])
        mobo_standoffs("itx", standoff_h, role="structural-mount");
    % translate([_board_x(), 0, floor_th+standoff_h]) mobo_placeholder("itx");
    // LP-profile PCIe bracket keep-out preview, centered on the slot's own
    // world X -- pcie_bracket()'s local X=0 is its card-slot centerline
    // (pcie-bracket.scad header), NOT the board's own corner-frame origin,
    // so it uses _pcie_cx() here, not _board_x().
    % translate([_pcie_cx(), 0, floor_th+standoff_h]) pcie_bracket("low-profile");
    // walls/floor/rear/tongue/vents in Tasks 2-3
}
mitx_2u_chassis();
