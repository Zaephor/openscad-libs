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
use <connectors/connectors.scad>;   // pcie_x16 body height, for _pcie_fold_z()

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
fan_pad_dia = 9;   // solid bearing pad around each fan mount screw (fans.scad fan_honeycomb_vent())
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

// PCIe slot: mobo_pcie_first_xy is [x,y] board-local (low-X edge of the
// slot), in the SAME component-up local frame as mobo_io_cutout/
// mobo_standoff_xy (motherboards.scad), so it shares _board_x() too, NOT
// board_offset alone -- verified empirically: translating this block by
// board_offset alone (the plan's original Task-1 draft) put the PCIe
// cutout's world X past the panel's own half-width entirely (a silent
// no-op cut, same failure shape as the mount-hole mirror bug -- see
// CORRECTION 2026-07-31 in the plan's Global Constraints for that one).
function _pcie_xy()      = mobo_pcie_first_xy("itx");
function _pcie_slot_x0() = _board_x() + _pcie_xy()[0];
function _pcie_slot_x1() = _pcie_slot_x0() + mobo_pcie_slot_w();
// pcie_bracket()'s own local X=0 is the card-slot CENTERLINE (its header
// datum comment), not the board corner -- so its world placement tracks
// the slot's centerline, not board_offset directly.
function _pcie_slot_cx() = _pcie_slot_x0() + mobo_pcie_slot_w()/2;

// World Z of pcie_bracket()'s own local Z=0 fold datum -- ONE value, used by
// the keep-out preview, the faceplate aperture and every bracket fit-assert
// below (an earlier revision used two different Z's for the same rigid part).
// The bracket is carried by the CARD, so its Z is set by where the card seats,
// not by anything the chassis is free to choose:
//   card's bottom edge  = board top + pcie_x16 body height
//                       = floor_th+standoff_h+mobo_thickness()+11.25 [A]
//   card's top          = that + lp_card_h
// The bracket has to span the card it carries, and has to clear the 2U
// ceiling, which pins the fold datum to a narrow band -- both ends are
// asserted below rather than left as prose:
//   lower: fold_z + bracket_height >= card top   -> fold_z >= 6.02 at defaults
//   upper: fold_z + bracket_height <= interior   -> fold_z <= 8.91 at defaults
// floor_th+standoff_h (8.0) sits inside that band and is the one value in the
// model already tied to the board's own seating plane, so it is used directly.
function _pcie_fold_z()   = floor_th + standoff_h;
function _pcie_card_z0()  = floor_th + standoff_h + mobo_thickness()
                            + connector_size("pcie_x16")[2];
function _pcie_bracket_h() = pcie_bracket_size("low-profile")[0];

// Faceplate aperture for the card's I/O, cut from the BRACKET's own window
// (pcie_bracket_window(), the same accessor pcie_bracket() cuts its own
// preview window from) -- NOT from mobo_pcie_cutout(), which models the
// board-side edge-connector slot footprint (a fixed 12mm box at board height,
// motherboards.scad's own //VERIFY [C] note) and has nothing to do with where
// a card's ports land on the panel. Cutting the old one put the aperture at
// world Z=[7,19] while the card's real I/O window sits at [25.82,69.38] --
// zero overlap, i.e. a real card's ports blocked by solid faceplate.
// [cx, cz, w, h] with cx/cz the window's CENTRE in the bracket's local frame.
function _pcie_win()    = pcie_bracket_window("low-profile");
function _pcie_ap_cx()  = _pcie_slot_cx() + _pcie_win()[0];
function _pcie_ap_cz()  = _pcie_fold_z()  + _pcie_win()[1];
function _pcie_ap_w()   = _pcie_win()[2];
function _pcie_ap_h()   = _pcie_win()[3];

// Power button: sits in the off-center gap on the panel's low-X side,
// beside the IO window (board_offset shifts the board toward +X to open
// this gap) -- same _button_x() idiom as mitx-1u-chassis.scad, centered in
// the gap between the panel's low edge and the IO's own low edge so it
// clears both by construction whenever the gap is wide enough for it.
function _button_x() = (-rack10_panel_width(standard) / 2 + _io_x0()) / 2;

// Rear shell geometry -- same idiom as mitx-1u-chassis.scad's _tongue_y()
// etc (see that file's comment block for the full "why"), scaled to this
// project's own device_u=2 / fan_size=60 defaults. _tongue_y() (NOT
// _usable_depth()) is the #40 tongue's root Y per rack_support_tongue()'s
// own consumer contract -- the two intentionally differ (see plan Global
// Constraints #2).
function _tongue_y()      = rack10_rear_post_y(standard) - rack_support_engagement_depth();
function _clear_w()       = rack10_clear_width(standard);
function _wall_top_z()    = rack10_device_height(device_u);
function _rear_center_z() = _wall_top_z() / 2;
// Gussets flank the tongue immediately, flush against the tongue's own X edge.
function _gusset_xw()   = 10;
function _gusset_x()    = rack_support_rail_size()[0] / 2 + _gusset_xw() / 2;
function _gusset_size() = 15;

// Fan/DC-in centered left/right of the tongue. mitx-1u-chassis.scad's own
// idiom (a flat -_clear_w()/4 offset) is NOT reused verbatim here: at that
// project's fan_size=40 it happened to clear the gusset, but this project's
// own fan_size=60 default (DIMS) does not -- -_clear_w()/4 = -55.5 puts the
// fan's near edge (55.5-30=25.5) INSIDE the gusset's far edge (_gusset_x()+
// _gusset_xw()/2 = 30), a real overlap caught by the fit-assert below at
// render time. This generalizes the idiom instead: derive the flank offset
// FROM the gusset's own far edge + the wider of the two hole radii + a fixed
// margin, so fan/DC-in clear the gusset by construction for any fan_size/
// dc_dia, not just the values that happened to work at 1U's smaller fan.
function _rear_flank_margin() = 2;
function _rear_flank_cx() = _gusset_x() + _gusset_xw()/2 + max(fan_size, dc_dia)/2 + _rear_flank_margin();
function _fan_cx() = -_rear_flank_cx();
function _dc_cx()  =  _rear_flank_cx();

// Front/side intake vents (Task 3): a honeycomb field per side wall, clear
// of the rear gusset/tongue zone (starts at _tongue_y()-wall-_gusset_size(),
// see the _mitx2_gusset() calls below) and vertically margined off the floor
// and open top -- same _side_vent_y0()/_side_vent_len() idiom as
// mitx-1u-chassis.scad's own side vent. BOTH walls get the same full band:
// an earlier revision pinned the right wall's band entirely above the LP-card
// keep-out to avoid "collision with the card", which a vent cannot have --
// it is a cut THROUGH the wall and occupies no interior volume at all. Nor is
// there an airflow objection: the card's own centreline sits 11.5mm inboard
// of this wall's inner face, and intake drawn past a hot card helps it.
function _side_vent_y0()      = 16;
function _side_vent_len()     = 80;
function _side_vent_zmargin() = 6;
function _side_vent_h() = _wall_top_z() - 2 * _side_vent_zmargin();

// This chassis deliberately cuts NO pcie_bracket_mount_holes(). Two
// independent reasons, both verified rather than assumed:
//   1. Z: the bracket's foot is at its local Z=[-thickness,0], i.e. world
//      Z=[7.2,8.0] at _pcie_fold_z() -- it rides at card height, 5.2mm clear
//      of the floor's top face. A Z-axis hole bored through the floor cannot
//      fasten anything up there. (An earlier revision cut the hole at the
//      floor while leaving the bracket at card height: two different Z's for
//      one rigid part, with nothing closing the gap.)
//   2. XY: the foot's screw lands at (_pcie_slot_cx(), _pcie_screw_y_lp()) =
//      (97.13, 8.65), which is 2.14mm from structural standoff C's axis
//      (98.65, 10.16) -- INSIDE that post's own 3.0mm radius. No screw
//      diameter, relief or parameter separates them; the separation is
//      invariant in board_offset (both are board-frame). Nor is this a data
//      bug: the same 1.52mm slot-centreline-to-rear-hole spacing appears on
//      atx and matx too, because rear-row mounting holes (y=10.16) sit in the
//      42.6mm bracket gap ahead of the PCIe connector body by design -- see
//      motherboards.scad's own mobo_pcie_ports() setback note ("clearing
//      every mounting hole ... matching how a real board routes standoffs
//      clear of the slots"). A real card is retained at the FAR end of its
//      bracket, against a chassis rail, not at the board's rear-edge strip.
// Card retention is therefore not modelled here; the chassis provides the
// aperture and the keep-out. tests/asserts.scad locks the reason so this gets
// revisited if the underlying geometry ever changes.
function _pcie_foot_screw_xy() = [_pcie_slot_cx(), _pcie_screw_y_lp_local()];
// _pcie_screw_y_lp() is private to pcie-bracket.scad; read the same figure off
// its public hole table instead of re-literaling it.
function _pcie_screw_y_lp_local() =
    pcie_bracket_holes_xy("low-profile", "structural-mount", pcie_screw)[0][1];
function _pcie_foot_screw_r() =
    pcie_bracket_holes("low-profile", "structural-mount", pcie_screw)[0][3] / 2;

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
// PCIe slot cutout vs. the panel's own outer bound (both edges -- opposite/
// high-X side from the IO window, per mobo_pcie_first_xy's own X-flip
// convention).
assert(_pcie_slot_x0() >= -rack10_panel_width(standard)/2 + 1e-6
    && _pcie_slot_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: PCIe slot cutout [", _pcie_slot_x0(), ",", _pcie_slot_x1(),
        "] exceeds panel +-", rack10_panel_width(standard)/2));
// Card I/O aperture vs. the panel, in BOTH axes. The X guard above is about
// the board's slot footprint; this one is about the hole actually cut, which
// is the bracket's window and is neither the same width nor the same place.
assert(_pcie_ap_cx() - _pcie_ap_w()/2 >= -rack10_panel_width(standard)/2 + 1e-6
    && _pcie_ap_cx() + _pcie_ap_w()/2 <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: PCIe card aperture [", _pcie_ap_cx()-_pcie_ap_w()/2, ",",
        _pcie_ap_cx()+_pcie_ap_w()/2, "] exceeds panel +-", rack10_panel_width(standard)/2));
assert(_pcie_ap_cz() - _pcie_ap_h()/2 >= 1e-6
    && _pcie_ap_cz() + _pcie_ap_h()/2 <= rack10_device_height(device_u) - 1e-6,
    str("mitx-2u: PCIe card aperture Z [", _pcie_ap_cz()-_pcie_ap_h()/2, ",",
        _pcie_ap_cz()+_pcie_ap_h()/2, "] exceeds faceplate height ",
        rack10_device_height(device_u)));
// The card aperture must not eat into the IO window. On mini-ITX these two
// are inherently adjacent: motherboards.scad's own ITX row models the single
// slot flush below the io span (its documented "model limit" -- the 170mm
// board's 13.87mm of rear edge past the io shield has to hold both the slot
// and mounting hole C), so the web between them is only 0.0135mm at defaults
// -- i.e. the slicer will merge the two openings into one. That is accepted
// (both are holes; the panel keeps full material above and below), but they
// must never actually OVERLAP: a data change that pushed the aperture into
// the io window would silently widen the IO opening instead of erroring.
assert(_pcie_ap_cx() - _pcie_ap_w()/2 >= _io_x1() - 1e-6,
    str("mitx-2u: PCIe card aperture low edge ", _pcie_ap_cx()-_pcie_ap_w()/2,
        " overlaps the IO window (high edge ", _io_x1(), ")"));
// The REAL bracket (pcie_bracket_size("low-profile")[0] = 79.2) must clear the
// 2U ceiling at the fold datum everything else is anchored to. The lp_card_h
// assert above only guards the //VERIFY card envelope, which is 14.8mm shorter
// than the bracket that carries it -- a standoff_h bump would have pushed the
// actual bracket through the ceiling with every other assert still green.
assert(standoff_h + _pcie_bracket_h() <= _int_h() + 1e-6,
    str("mitx-2u: standoff+LP bracket ", standoff_h + _pcie_bracket_h(),
        " > 2U interior ", _int_h(), " (the real 79.2mm bracket, not lp_card_h)"));
// ...and must actually SPAN the card it carries: the card seats on top of the
// board's PCIe connector body, so a fold datum set too low leaves the card's
// upper ports above the bracket's own top edge (and above the aperture).
assert(_pcie_fold_z() + _pcie_bracket_h() >= _pcie_card_z0() + lp_card_h - 1e-6,
    str("mitx-2u: LP bracket top ", _pcie_fold_z()+_pcie_bracket_h(),
        " does not span the card it carries (card top ", _pcie_card_z0()+lp_card_h, ")"));
// Button hole vs. the panel's own outer bounds (both edges, since it's a hole).
assert(_button_x() - button_dia/2 >= -rack10_panel_width(standard)/2 + 1e-6
    && _button_x() + button_dia/2 <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] exceeds panel +-", rack10_panel_width(standard)/2));
// fan_size must be a size fans.scad actually knows the mounting-hole
// spacing/bore for -- an unknown size would silently assert deep inside
// fan_hole_spacing() instead of at this project's own boundary.
assert(len([for (s=fan_known_sizes()) if (s==fan_size) s])>0,
    str("mitx-2u: fan_size ", fan_size, " not in ", fan_known_sizes()));
// Board must clear the rear wall's inner face (not just _usable_depth() --
// the actual rear wall sits at _tongue_y(), slightly behind _usable_depth()).
assert(_bd() <= _tongue_y() - wall - 1e-6,
    str("mitx-2u: board depth ", _bd(), " reaches into the rear wall (inner face at ",
        _tongue_y()-wall, ")"));
// Fan/DC-in must clear the tongue-flanking gussets in X (a larger fan_size
// could otherwise silently grow into the gusset it shares the rear wall with).
assert(abs(_fan_cx()) - fan_size/2 >= _gusset_x() + _gusset_xw()/2 - 1e-6,
    str("mitx-2u: fan_size ", fan_size, " at x=", _fan_cx(), " overlaps the tongue gusset"));
assert(abs(_dc_cx()) - dc_dia/2 >= _gusset_x() + _gusset_xw()/2 - 1e-6,
    str("mitx-2u: dc_dia ", dc_dia, " at x=", _dc_cx(), " overlaps the tongue gusset"));
// Fan/DC-in (at the SAME _rear_flank_cx() magnitude by construction) must
// also stay within the rear wall's own width -- _rear_flank_cx() grows
// clear of the gusset by construction but is not otherwise bounded, so a
// large enough fan_size could still walk it off the rear wall's own edge.
assert(abs(_fan_cx()) + fan_size/2 <= _clear_w()/2 - wall - 1e-6,
    str("mitx-2u: fan_size ", fan_size, " at x=", _fan_cx(), " exceeds the rear wall width (interior span +-", _clear_w()/2-wall, ")"));
// Fan must fit within the rear wall's own height.
assert(_rear_center_z() - fan_size/2 >= -1e-6 && _rear_center_z() + fan_size/2 <= _wall_top_z() + 1e-6,
    str("mitx-2u: fan_size ", fan_size, " does not fit within rear wall height ", _wall_top_z()));
// LP card keep-out (Y-extent from the front plane, at the slot X) must stay
// clear of the rear gusset/tongue zone (starts at _tongue_y()-wall-
// _gusset_size(), matching the _mitx2_gusset() calls below) -- the card
// clearance the plan brief calls out explicitly for this task.
assert(lp_card_len <= _tongue_y() - wall - _gusset_size() - 1e-6,
    str("mitx-2u: LP card length ", lp_card_len, " reaches into the rear gusset/tongue zone (starts at ",
        _tongue_y()-wall-_gusset_size(), ")"));
// The bracket's foot footprint must land within the floor slab's own interior
// span -- bounded by the foot's real half-width (pcie_bracket_size()[1]/2),
// not by `wall`, which has nothing to do with the foot's extent.
assert(_pcie_slot_cx() - pcie_bracket_size("low-profile")[1]/2 >= -rack10_clear_width(standard)/2 - 1e-6
    && _pcie_slot_cx() + pcie_bracket_size("low-profile")[1]/2 <= rack10_clear_width(standard)/2 + 1e-6,
    str("mitx-2u: PCIe bracket foot at x=", _pcie_slot_cx(),
        " overhangs the floor's interior span +-", rack10_clear_width(standard)/2));
// Side intake vents must stay clear of the rear gusset zone (starts at
// _tongue_y()-wall-_gusset_size(), matching the _mitx2_gusset() calls below)
// -- same guard as mitx-1u-chassis.scad's own side vent, shared by both walls.
assert(_side_vent_y0() + _side_vent_len() <= _tongue_y() - wall - _gusset_size() - 1e-6,
    str("mitx-2u: side intake vent [", _side_vent_y0(), ",", _side_vent_y0()+_side_vent_len(),
        "] reaches into the rear gusset zone (starts at ", _tongue_y()-wall-_gusset_size(), ")"));
module _mitx2_faceplate() {
    difference() {
        translate([-rack10_panel_width(standard)/2, -faceplate_th, 0])
            cube([rack10_panel_width(standard), faceplate_th, rack10_device_height(device_u)]);
        if (ear_type == "slot") rack10_holes(standard, device_u, hole_type="slot", dia=rack10_screw_clearance("10-32"));
        else rack10_holes(standard, device_u, hole_type=ear_type);
        // mobo_io_cutout_stamp grows +Y from the board's own local frame
        // (rear-IO edge = local Y=0); this faceplate sits at -Y (rack10
        // front-of-panel convention), so mirror the stamp in Y first or the
        // cutter never reaches it (#42 hit this exact bug -- verified here
        // empirically via intersection() against this faceplate slab: with
        // the mirror, the stamp's world-Y span fully overlaps the slab's own
        // Y=[-faceplate_th,0] span at the outer face; without it, it doesn't).
        translate([_board_x(), 0, floor_th+standoff_h])
            mirror([0, 1, 0])
                mobo_io_cutout_stamp("itx", depth=faceplate_th+2);
        // Card I/O aperture, straight from the bracket's own window (see
        // _pcie_win() above). Cut in world coordinates rather than through
        // the board-frame mirror() block: the window is bracket-frame, not
        // board-frame, and its X already tracks the slot centreline.
        translate([_pcie_ap_cx() - _pcie_ap_w()/2, -faceplate_th-1,
                   _pcie_ap_cz() - _pcie_ap_h()/2])
            cube([_pcie_ap_w(), faceplate_th+2, _pcie_ap_h()]);
        // Power button in the off-center gap beside the IO window.
        translate([_button_x(), -faceplate_th-1, rack10_device_height(device_u)/2])
            rotate([-90,0,0]) cylinder(h=faceplate_th+2, d=button_dia);
    }
}
// Floor + side walls + rear wall, unholed. Front edge overlaps Y=0 by y_eps
// (the faceplate's own rear face) so the union is a robust manifold. Side/
// rear walls run flush to _tongue_y() (rear wall's own outer face, where the
// tongue root sits) -- a plain rectangular box, no cantilever, support-free
// by construction. Same idiom as mitx-1u-chassis.scad's _mitx_shell().
module _mitx2_shell() {
    y_eps = 0.01;
    y1 = _tongue_y();
    w2 = _clear_w() / 2;
    // floor
    translate([-w2, -y_eps, 0]) cube([2*w2, y1 + y_eps, floor_th]);
    // side walls
    for (sx = [-1, 1])
        translate([sx > 0 ? w2 - wall : -w2, -y_eps, 0])
            cube([wall, y1 + y_eps, _wall_top_z()]);
    // rear wall (outer/rear face flush with the tongue root at y1)
    translate([-w2, y1 - wall, 0]) cube([2*w2, wall, _wall_top_z()]);
    // Buttress under the tongue's own cantilevered reach (y1 to rear post Y)
    // -- without this the tongue would print as an unsupported ~12mm
    // horizontal shelf anchored only at its root face. Sized to the tongue's
    // own width (rack_support_rail_size()[0]), built at
    // rack_support_floor_thickness() (the tongue's own seating datum),
    // running the tongue's full engagement_depth() -- same pattern as
    // mitx-1u-chassis.scad's _mitx_shell() (see that file's comment block
    // for the full rationale, incl. why a strip stopping short reproduces a
    // CGAL non-manifold defect).
    rw = rack_support_rail_size()[0];
    translate([-rw/2, y1, 0])
        cube([rw, rack_support_engagement_depth(), rack_support_floor_thickness()]);
}

// Support-free 45deg corner brace: right angle at (y0,z0) (rear wall's inner
// face / floor top), one leg running `size` along the floor (-Y), the other
// `size` up the wall (+Z) -- same hull-of-6-corner-spheres technique as
// mitx-1u-chassis.scad's _mitx_gusset() / rack-support.scad's own gusset.
module _mitx2_gusset(x0, xw, y0, z0, size) {
    hull()
        for (p = [[y0, z0], [y0 - size, z0], [y0, z0 + size]])
            for (dx = [x0 - xw/2, x0 + xw/2])
                translate([dx, p[0], p[1]]) sphere(r = 0.001, $fn = 6);
}

// Side-wall intake honeycomb vent (Task 3). honeycomb_vent()'s local frame
// is X=width, Y=height, Z=depth (see honeycomb.scad); rotate([90,0,90]) maps
// local (x,y,z) -> world (z,x,y) -- same idiom (and verified mapping) as
// mitx-1u-chassis.scad's own _mitx_side_vent(). `sx` mirrors _mitx2_shell()'s
// own side-wall loop convention (-1 = left, +1 = right); both walls carry the
// same field (see _side_vent_h() above for why the right wall no longer gets
// a card-constrained band).
module _mitx2_side_vent(sx) {
    w2 = _clear_w() / 2;
    x_start = (sx > 0) ? w2 - wall - 1 : -w2 - 1;   // 1mm overcut past the outer face
    translate([x_start, _side_vent_y0(), _side_vent_zmargin()])
        rotate([90, 0, 90])
            honeycomb_vent(_side_vent_len(), _side_vent_h(), wall + 2, cell, hc_wall);
}

module mitx_2u_chassis() {
    _mitx2_faceplate();
    // off-center board standoffs -- SAME _board_x() offset as the
    // faceplate's IO/PCIe cutout block above, or they drift apart.
    translate([_board_x(), 0, floor_th])
        mobo_standoffs("itx", standoff_h, role="structural-mount");
    % translate([_board_x(), 0, floor_th+standoff_h]) mobo_placeholder("itx");
    // LP card keep-out preview, tracked to the slot's own world centerline
    // (pcie_bracket()'s local X=0 datum), NOT board_offset directly.
    % translate([_pcie_slot_cx(), 0, _pcie_fold_z()]) pcie_bracket("low-profile");

    // walls/floor + rear DC-in/fan cutouts + tongue-flanking gussets.
    // No PCIe foot fastener is cut here -- see _pcie_foot_screw_xy() above.
    difference() {
        union() {
            _mitx2_shell();
            _mitx2_gusset(-_gusset_x(), _gusset_xw(), _tongue_y() - wall, floor_th, _gusset_size());
            _mitx2_gusset( _gusset_x(), _gusset_xw(), _tongue_y() - wall, floor_th, _gusset_size());
        }
        // rear fan opening: honeycomb field over the fan footprint + solid
        // bearing pads/drilled holes at the mount screws (fan_honeycomb_vent(),
        // fans/fans.scad -- #72, same treatment as mitx-1u-chassis.scad's own
        // rear fan opening; here the teardrop cap never actually engaged at
        // this project's fan_size=60 default, but carried the same landmine).
        z0 = _rear_center_z() - fan_size/2;
        translate([_fan_cx() - fan_size/2, _tongue_y() - wall - 1, z0 + fan_size])
            rotate([-90, 0, 0])
                fan_honeycomb_vent(fan_size, fan_size, wall + 2, cell, hc_wall,
                                   [[fan_size/2, fan_size/2]], fan_size, fan_pad_dia);
        // rear DC-in barrel hole, same +Y-through-the-wall orientation as
        // the faceplate's own button hole. Left plain round (not
        // teardropped): a DC barrel jack's panel-mount nut needs true
        // roundness -- see mitx-1u-chassis.scad's comment for the full
        // design-for-print rationale.
        translate([_dc_cx(), _tongue_y() - wall - 1, _rear_center_z()])
            rotate([-90, 0, 0]) cylinder(h = wall + 2, d = dc_dia);
        // intake honeycomb vents, both side walls (Task 3).
        for (sx = [-1, 1]) _mitx2_side_vent(sx);
    }
    // #40 rear-support tongue: root at _tongue_y() (flush with the rear
    // wall's outer face), projects further +Y into rack_support_plate()'s
    // channel -- see rack_support_tongue()'s consumer-contract doc comment.
    translate([0, _tongue_y(), 0]) rack_support_tongue();
}
mitx_2u_chassis();
