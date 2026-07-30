// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts.scad — render-time invariants for the chassis geometry.
// Rendered by tests/test_bpir4_chassis_lib.sh; any failed assert -> ERROR in stderr.
// Declared here + in each entry file; params.scad consumes only.
enable_exhaust = true; // false = passive (no rear fan plenum)
fan_size  = 40;        // must be a fan_known_sizes() value
fan_count = 2;
ear_hole_type = "slot"; // "slot" | "10-32" | "m6" | "round"
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <../parts/tray.scad>;   // for _lid_post_xy() (post-count invariant)

// Board must fit within the body width (between the posts).
assert(board_w() <= body_w() + 1e-6,
    str("board width ", board_w(), " exceeds body width ", body_w()));

// Guards stack_gap >= 0 (exterior height cannot exceed 1U pitch).
assert(ext_h() <= rack10_u() + 1e-6,
    str("exterior height ", ext_h(), " exceeds 1U pitch ", rack10_u()));

// There must be 16 mounting holes for the bpir4 (sanity vs the library).
assert(len(sbc_holes_xy(BOARD)) == 16,
    str("expected 16 bpir4 holes, got ", len(sbc_holes_xy(BOARD))));

// Guards rear_off() >= 0 (board depth fits within internal depth).
assert(int_depth() >= board_d() + 1e-6,
    str("internal depth ", int_depth(), " does not clear board depth ", board_d()));

// Internal height must clear the tallest standoff+board stack minus fans
// (fan fit is asserted in params.scad). Standoff + PCB must sit under the lid.
assert(standoff_h + sbc_thickness(BOARD) < int_h() + 1e-6,
    str("standoff+PCB ", standoff_h + sbc_thickness(BOARD),
        " exceeds internal height ", int_h()));

// Faceplate must span the full rack panel width (ears reach the posts) and be
// wider than the body (so ears overhang the clear opening).
assert(panel_w() > body_w() + 1e-6,
    str("panel width ", panel_w(), " should exceed body width ", body_w()));
// All bpir4 front connectors share the ymin edge (spec invariant).
assert(len([for (c = sbc_connectors(BOARD)) if (c[3] == "ymin") c]) >= 8,
    "expected >=8 ymin front connectors on bpir4");

// Item 6: the above-IO vent band (faceplate) must fit at least one intake
// slot between the connector tops (_vent_band_z0()) and the ledge. Supersedes
// the old side-margin-vent check now that vents sit above the connectors.
_vb_z1 = ext_h() - lid_th - vent_slot_gap;
assert(_vb_z1 - _vent_band_z0() >= vent_slot_w,
    str("vent band span (", _vb_z1 - _vent_band_z0(), ") < one slot width ", vent_slot_w));

// Lid must seat on the wall-top shelves (lip = wall/2) with positive clearance.
lip = wall/2;
lid_w = body_w() - 2*lip - 2*wall_gap;
assert(lid_w > 0 && lid_w <= body_w() - 2*lip + 1e-6,
    str("lid width ", lid_w, " must be >0 and <= lip opening ", body_w() - 2*lip));

// Item 1: the chassis mounts only the researched structural-mount subset,
// which is strictly fewer than all 16 bpir4 holes.
_struct = sbc_holes_xy(BOARD, "structural-mount");
assert(len(_struct) > 0 && len(_struct) < len(sbc_holes_xy(BOARD, "all")),
    str("structural subset (", len(_struct), ") must be >0 and < all holes"));

// Board standoff wall matches the same 1.6mm min-wall standard as the lid
// posts (heatset_min_wall) — the retrofit widened the OD (was a hardcoded
// 6.0mm sbc default / 0.8mm floor) so the M2.5 pilot bore keeps a crack-safe
// seat. Reads the SAME _board_standoff_od() the tray renders with (imported
// via `use <../parts/tray.scad>` above), so shrinking that OD — e.g.
// reverting to the 6.0mm sbc default — fails this loudly.
assert((_board_standoff_od() - board_insert_bore())/2 >= heatset_min_wall(board_insert_size) - 1e-9,
    str("board standoff wall ", (_board_standoff_od() - board_insert_bore())/2,
        " < ", heatset_min_wall(board_insert_size), "mm min"));

// Item 6: body hugs the board but still passes between the posts, and leaves
// room for a wall + a corner post beside the board.
assert(body_w() <= clear_w() + 1e-6,
    str("body_w ", body_w(), " must be <= clear_w ", clear_w()));
assert(body_w() >= board_w() + 2*wall,
    str("body_w ", body_w(), " must exceed board + 2 walls"));
// Corner post sits BESIDE the board (inner edge outboard of the board edge).
_ix = body_w()/2 - wall - _lid_post_od()/2;              // post center X (tangent to wall)
assert(_ix - _lid_post_od()/2 >= board_w()/2,
    str("corner post inner edge (", _ix - _lid_post_od()/2,
        ") must clear board edge (", board_w()/2, ")"));
// Vent band starts above the tallest front connector.
assert(_vent_band_z0() > board_z() + sbc_thickness(BOARD),
    "vent band must start above the PCB");
// Round 3 #65 final-review fix: the check above only guards against the band
// dropping below the PCB itself -- it doesn't catch the rib above the
// TALLEST INFLATED cutout top eroding thin. io_port_clearance inflates every
// ymin cutout UPWARD in Z (sbc.scad's _sbc_cutout_inflate()), so the real rib
// is measured from board_z()+thickness+_front_conn_max_h()+io_port_clearance,
// not from the nominal top. Locks the rib at >=1mm above the inflated top so
// this class of erosion (silently shrunk from the intended 1.0mm to 0.6mm
// when io_port_clearance was introduced without updating _vent_band_z0())
// can't recur if either constant changes again.
_inflated_cutout_top = board_z() + sbc_thickness(BOARD) + _front_conn_max_h() + io_port_clearance;
assert(_vent_band_z0() - _inflated_cutout_top >= 1 - 1e-6,
    str("vent-band rib above inflated cutout top (", _vent_band_z0() - _inflated_cutout_top,
        "mm) is below the intended 1mm minimum"));
// #56 Task 3 (retargeted Round 3 #65): lock the tallest ymin (front) connector
// height so a future sbc data change that re-tallens the band is caught. The
// round-3 full front-row re-caliper dropped usb_1/USB3 from h=14.1 to h=13.0,
// making the RJ45 block (h=13.60, from _sbc_bpir4_rj45_port(), see sbc.scad's
// bpir4 row) the new tallest front connector. Bound is 13.60 + 0.1mm margin.
assert(_front_conn_max_h() <= 13.7 + 1e-6,
    str("tallest front connector ", _front_conn_max_h(),
        " unexpectedly > 13.7 (front-connector height regression?)"));
// RESOLVED (Round 2 #62 Task 2b/3): the old "0.0mm gap (merged L-shaped
// opening)" note here was itself the bug -- a pixel-detected boundary that
// mis-modeled usb_1 and sfp_1 as sharing an exact edge. A physical-board
// caliper re-check (2026-07-24, see libraries/sbc/sbc.scad's bpir4 row and
// RESEARCH.md) found a real ~3.6mm gap there, matching the same
// "real-gap-not-shared-boundary" pattern already true of the
// dc_power_1/usbc_pwr_1 pair (~2.3mm). Both //VERIFY flags on the affected
// edges are dropped in sbc.scad. parts/tray.scad's _faceplate() now unions
// an explicit support wall into each gap (_io_gap_wall()/_io_gap_wall_geom())
// so the panel material there is a deliberate, verified feature rather than
// incidental cutout-box leftover -- checked below.

// Round 2 #62 Task 3: IO-gap bridge-support walls. Recomputes each wall's
// geometry via the SAME _io_gap_wall_geom() function parts/tray.scad's
// _faceplate() renders with (single source of truth -- `use`d above), and
// each connector's own cutout edges via sbc_connector() directly, then
// checks: (a) the wall band [x0,x1] sits STRICTLY inside the real gap, with
// positive clearance to both flanking connectors' cutout edges, so a
// connector's own opening is never intruded on; (b) the wall genuinely has
// positive width (material is actually present in the gap X-band, not a
// degenerate/zero-width case).
function _conn_x_edges(name) =
    let (c = sbc_connector(BOARD, name))
    [board_x() + c[1][0], board_x() + c[1][0] + c[2][0]];  // [left edge, right edge], chassis frame

_wall_usb_sfp = _io_gap_wall_geom("usb_1", "sfp_1", _io_wall_w_usb_sfp());
_wall_dc_usbc = _io_gap_wall_geom("dc_power_1", "usbc_pwr_1", _io_wall_w_dc_usbc());
_wall_rj45_dc = _io_gap_wall_geom("rj45_block", "dc_power_1", _io_wall_w_rj45_dc());
_usb1_x = _conn_x_edges("usb_1");   _sfp1_x = _conn_x_edges("sfp_1");
_dc_x   = _conn_x_edges("dc_power_1"); _usbc_x = _conn_x_edges("usbc_pwr_1");
_rjblk_x = _conn_x_edges("rj45_block");

assert(_wall_usb_sfp[1] - _wall_usb_sfp[0] > 0,
    "usb_1/sfp_1 support wall has zero/negative width");
assert(_wall_usb_sfp[0] > _usb1_x[1] && _wall_usb_sfp[1] < _sfp1_x[0],
    str("usb_1/sfp_1 support wall [", _wall_usb_sfp[0], ",", _wall_usb_sfp[1],
        "] intrudes into a connector opening (usb_1 right=", _usb1_x[1],
        ", sfp_1 left=", _sfp1_x[0], ")"));

assert(_wall_dc_usbc[1] - _wall_dc_usbc[0] > 0,
    "dc_power_1/usbc_pwr_1 support wall has zero/negative width");
assert(_wall_dc_usbc[0] > _dc_x[1] && _wall_dc_usbc[1] < _usbc_x[0],
    str("dc_power_1/usbc_pwr_1 support wall [", _wall_dc_usbc[0], ",", _wall_dc_usbc[1],
        "] intrudes into a connector opening (dc_power_1 right=", _dc_x[1],
        ", usbc_pwr_1 left=", _usbc_x[0], ")"));

// Round 3 #65: third IO gap wall (rj45_block <-> dc_power_1), same checks.
assert(_wall_rj45_dc[1] - _wall_rj45_dc[0] > 0,
    "rj45_block/dc_power_1 support wall has zero/negative width");
assert(_wall_rj45_dc[0] > _rjblk_x[1] && _wall_rj45_dc[1] < _dc_x[0],
    str("rj45_block/dc_power_1 support wall [", _wall_rj45_dc[0], ",", _wall_rj45_dc[1],
        "] intrudes into a connector opening (rj45_block right=", _rjblk_x[1],
        ", dc_power_1 left=", _dc_x[0], ")"));

// Item 4: four corner lid posts (side-midspan pair dropped).
assert(len(_lid_post_xy()) == 4, str("expected 4 corner posts, got ", len(_lid_post_xy())));

// Task 4: corner posts now bond to BOTH the side wall AND the front/rear
// wall (not just tangent to the side wall, with the old v2 front/rear
// post_edge_inset gap). Front pair (_xy[0], _xy[1]) must be tangent to the
// front interior boundary (board_y()); rear pair (_xy[2], _xy[3]) must be
// tangent to the rear wall's inner face (rear_wall_y() - wall).
_xy  = _lid_post_xy();
_od2 = _lid_post_od() / 2;
assert(abs((_xy[0][1] - _od2) - board_y()) < 1e-6,
    str("front post not tangent to front boundary: y-od/2=", _xy[0][1] - _od2,
        " board_y()=", board_y()));
assert(abs((_xy[1][1] - _od2) - board_y()) < 1e-6,
    str("front post (mirror) not tangent to front boundary: y-od/2=", _xy[1][1] - _od2,
        " board_y()=", board_y()));
assert(abs((_xy[2][1] + _od2) - (rear_wall_y() - wall)) < 1e-6,
    str("rear post not tangent to rear-wall inner face: y+od/2=", _xy[2][1] + _od2,
        " target=", rear_wall_y() - wall));
assert(abs((_xy[3][1] + _od2) - (rear_wall_y() - wall)) < 1e-6,
    str("rear post (mirror) not tangent to rear-wall inner face: y+od/2=", _xy[3][1] + _od2,
        " target=", rear_wall_y() - wall));

// --- #23 regression lock: bpir4 front RJ45 is ONE 4-port ganged block (#8
// re-model). The faceplate cuts these openings generically from
// sbc_connectors(), so this guards the faceplate opening against any sbc change
// that silently alters it. The 65.29/121.21/13.98 numbers below are EXPECTED-
// VALUE regression guards (not a data source — the data lives in sbc.scad).
// Retargeted Round 3 #65: the round-3 physical-board re-caliper of
// rj45_block (see sbc.scad's bpir4 row) shifted the port span from
// 62.61/118.53 to 65.29/121.21 — supersedes round-2's unreconciled figures.
_rj45 = [for (c = sbc_connectors(BOARD))
            if (c[3] == "ymin" &&
                (c[0] == "rj45_1" || c[0] == "rj45_2" ||
                 c[0] == "rj45_3" || c[0] == "rj45_4")) c];
assert(len(_rj45) == 4,
    str("bpir4 RJ45: expected 4 ganged ports, got ", len(_rj45)));
// Contiguous (abutting): each port x0 == previous port x0 + previous width.
for (i = [1:len(_rj45)-1])
    assert(abs(_rj45[i][1][0] - (_rj45[i-1][1][0] + _rj45[i-1][2][0])) < 1e-6,
        str("bpir4 RJ45: ports not contiguous at index ", i,
            " (x0=", _rj45[i][1][0], ")"));
// Block span (board frame) and per-port width.
assert(abs(_rj45[0][1][0] - 65.29) < 1e-6,
    str("bpir4 RJ45: block x0 ", _rj45[0][1][0], " != 65.29"));
assert(abs((_rj45[3][1][0] + _rj45[3][2][0]) - 121.21) < 1e-6,
    str("bpir4 RJ45: block x1 ", _rj45[3][1][0] + _rj45[3][2][0], " != 121.21"));
for (c = _rj45)
    assert(abs(c[2][0] - 13.98) < 1e-6,
        str("bpir4 RJ45: ", c[0], " width ", c[2][0], " != 13.98"));

// rj45_block physical envelope (the 58.5mm calipered end-to-end shell,
// wider than the 4 port pitches — see sbc.scad's bpir4 row comment). 64.0/
// 122.5 are, again, EXPECTED-VALUE regression guards over sbc-owned data,
// not the source. Also guards that the four ports sit centered inside the
// envelope (equal end-shell margin on both sides), which is what makes a
// single generically-cut opening correct for all four ports.
_rj45_block  = sbc_connector(BOARD, "rj45_block");
_rjb_x0 = _rj45_block[1][0];
_rjb_x1 = _rjb_x0 + _rj45_block[2][0];
assert(abs(_rjb_x0 - 64.0) < 1e-6,
    str("bpir4 RJ45 block envelope x0 ", _rjb_x0, " != 64.0"));
assert(abs(_rjb_x1 - 122.5) < 1e-6,
    str("bpir4 RJ45 block envelope x1 ", _rjb_x1, " != 122.5"));
_rj45_ports_x0 = _rj45[0][1][0];
_rj45_ports_x1 = _rj45[3][1][0] + _rj45[3][2][0];
assert(abs((_rj45_ports_x0 - _rjb_x0) - (_rjb_x1 - _rj45_ports_x1)) < 1e-6,
    str("bpir4 RJ45 ports not centered in block envelope: left margin ",
        _rj45_ports_x0 - _rjb_x0, "mm, right margin ", _rjb_x1 - _rj45_ports_x1, "mm"));

// Underside worst-case clearance: standoff gap must exceed the tallest
// underside module keep-out by at least underside_clearance.
// Guards the derivation standoff_h = _underside_max_hang() + underside_clearance
// (catches future re-literalizing of standoff_h); doesn't verify clearance independently.
assert(standoff_h - _underside_max_hang() >= underside_clearance - 1e-6,
    str("underside clearance ", standoff_h - _underside_max_hang(),
        " < required ", underside_clearance,
        " (max hang ", _underside_max_hang(), ", standoff ", standoff_h, ")"));

// DIP switch lever overhangs the board's right edge. Guard that the right
// interior (side-wall inner face) clears the board edge + the lever. Set-once
// switch (not accessed at runtime) -> no opening cut; this only prevents a
// future body_w() shrink from clipping it.
function _dip_lever_overhang() =
    let (dip = [for (c = sbc_connectors(BOARD)) if (c[0] == "dip_1") c])
    len(dip) > 0 ? max(0, (dip[0][1][0] + dip[0][2][0]) - board_w()) : 0;
dip_lever_overhang = _dip_lever_overhang(); // derived from sbc dip_1 row (x0 + width - board_w); currently 2.0mm
_right_wall_inner = body_w()/2 - wall;
assert(board_w()/2 + dip_lever_overhang <= _right_wall_inner + 1e-6,
    str("DIP lever (board edge ", board_w()/2, " + ", dip_lever_overhang,
        " = ", board_w()/2 + dip_lever_overhang,
        ") exceeds right wall inner face ", _right_wall_inner));

// A bottom-face module (edge="bottom") hangs into the standoff gap; if its
// footprint overlaps a corner standoff post's XY, a future installed module
// would collide with the post. Guard it (AABB overlap, board-local frame).
// FORMER KNOWN CONFLICT (#56, user-accepted 2026-07-23), RESOLVED by Round 2
// #62 Task 1: the [3.5,23.5] structural-mount post used to overlap the
// mpcie_1_card keep-out envelope by up to ~2.6mm in X, because #55 laid that
// card out with the wrong yaw (long axis along Y instead of X). Task 1's
// mPCIe yaw fix moved mpcie_1_card's footprint to x=[4.5,55.45]/y=[28.6,58.6]
// (board frame) — verified by direct computation against this same post
// (r=_board_standoff_od()/2): y+r=27.105 < the card's y0=28.6, a genuine
// 1.495mm clearance, not an overlap. All 4 structural-mount posts x all 6
// bottom-face modules were re-checked exhaustively (mpcie_1/_card,
// mpcie_2/_card, m2_ssd_1/_card) and NONE overlap any longer, so the prior
// accepted-conflict exception is dropped: this is now an unconditional hard
// assert (any future overlap — from either side re-drifting — fails loudly,
// with no silent allowance).
_bottom = [for (c = sbc_connectors(BOARD)) if (c[3] == "bottom") c];
_spost_r = _board_standoff_od()/2;
for (h = sbc_holes_xy(BOARD, "structural-mount"))
    for (m = _bottom) {
        mx0 = m[1][0]; my0 = m[1][1];
        mx1 = mx0 + m[2][0]; my1 = my0 + m[2][1];
        // post AABB = [hx-r, hx+r] x [hy-r, hy+r]
        overlap = (h[0]+_spost_r > mx0) && (h[0]-_spost_r < mx1) &&
                  (h[1]+_spost_r > my0) && (h[1]-_spost_r < my1);
        assert(!overlap,
            str("underside module ", m[0], " footprint overlaps standoff post at [",
                h[0], ",", h[1], "] — installed module would collide"));
    }

// #70: the rear outer corner chamfer must not thin the corner below the wall
// thickness. A chamfer leg c leaves (2*wall - c)/sqrt(2) of material along the
// corner diagonal, so c <= wall*(2 - sqrt(2)) = 1.406mm at wall = 2.4.
// design-for-print house-rules: never break an edge if it undersizes a wall.
assert(_tray_rear_corner_chamfer() <= wall*(2 - sqrt(2)) + 1e-9,
    str("bpir4: rear corner chamfer ", _tray_rear_corner_chamfer(),
        " exceeds the wall-thickness limit ", wall*(2 - sqrt(2))));

// Render nothing (pure assert file).
