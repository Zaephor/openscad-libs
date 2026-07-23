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
// #56 Task 3: lock the tallest ymin (front) connector height so a future sbc
// data change that re-tallens the band is caught. After the Task 1/2 caliper
// revision (thickness 1.6->1.4, per-connector reconciliation) the tallest
// front connector is usb_1/USB3 at h=14.1 (bottom->top 15.5 - thickness 1.4),
// NOT the old SFP h=13.4 placeholder -- SFP dropped to h=10.4 and is now the
// SHORTEST of the big front connectors. Bound is 14.1 + 0.1mm margin.
assert(_front_conn_max_h() <= 14.2 + 1e-6,
    str("tallest front connector ", _front_conn_max_h(),
        " unexpectedly > 14.2 (front-connector height regression?)"));

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
// that silently alters it. The 62.61/118.53/13.98 numbers below are EXPECTED-
// VALUE regression guards (not a data source — the data lives in sbc.scad).
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
assert(abs(_rj45[0][1][0] - 62.61) < 1e-6,
    str("bpir4 RJ45: block x0 ", _rj45[0][1][0], " != 62.61"));
assert(abs((_rj45[3][1][0] + _rj45[3][2][0]) - 118.53) < 1e-6,
    str("bpir4 RJ45: block x1 ", _rj45[3][1][0] + _rj45[3][2][0], " != 118.53"));
for (c = _rj45)
    assert(abs(c[2][0] - 13.98) < 1e-6,
        str("bpir4 RJ45: ", c[0], " width ", c[2][0], " != 13.98"));

// Underside worst-case clearance: standoff gap must exceed the tallest
// underside module keep-out by at least underside_clearance.
assert(standoff_h - _underside_max_hang() >= underside_clearance - 1e-6,
    str("underside clearance ", standoff_h - _underside_max_hang(),
        " < required ", underside_clearance,
        " (max hang ", _underside_max_hang(), ", standoff ", standoff_h, ")"));

// DIP switch lever overhangs the board's right edge by ~2mm (caliper: board
// x=148 -> ~150). Guard that the right interior (side-wall inner face) clears
// the board edge + the lever. Set-once switch (not accessed at runtime) -> no
// opening cut; this only prevents a future body_w() shrink from clipping it.
dip_lever_overhang = 2.0; // [B] caliper (#55) — lever proud of board right edge
_right_wall_inner = body_w()/2 - wall;
assert(board_w()/2 + dip_lever_overhang <= _right_wall_inner + 1e-6,
    str("DIP lever (board edge ", board_w()/2, " + ", dip_lever_overhang,
        " = ", board_w()/2 + dip_lever_overhang,
        ") exceeds right wall inner face ", _right_wall_inner));

// A bottom-face module (edge="bottom") hangs into the standoff gap; if its
// footprint overlaps a corner standoff post's XY, a future installed module
// would collide with the post. Guard it (AABB overlap, board-local frame).
// KNOWN CONFLICT (#56, user-accepted 2026-07-23): the [3.5,23.5] structural-mount
// post overlaps the mpcie_1_card keep-out envelope by up to ~2.6mm in X. This
// hole's structural-mount role is itself tier [B]//VERIFY (bpi-r4.md: "No single
// source confirms which real-world case product uses which of the 4 structural
// holes") — not a confirmed real mounting point. Accepted as a documented risk:
// if mpcie_1 (bottom-left mini-PCIe) is populated, this corner mounting point may
// be unusable/inaccessible. Any OTHER overlap is still a hard failure.
_known_keepout_conflicts = [["mpcie_1_card", 3.5, 23.5]];
_bottom = [for (c = sbc_connectors(BOARD)) if (c[3] == "bottom") c];
_spost_r = _board_standoff_od()/2;
for (h = sbc_holes_xy(BOARD, "structural-mount"))
    for (m = _bottom) {
        mx0 = m[1][0]; my0 = m[1][1];
        mx1 = mx0 + m[2][0]; my1 = my0 + m[2][1];
        // post AABB = [hx-r, hx+r] x [hy-r, hy+r]
        overlap = (h[0]+_spost_r > mx0) && (h[0]-_spost_r < mx1) &&
                  (h[1]+_spost_r > my0) && (h[1]-_spost_r < my1);
        _is_known = len([for (k = _known_keepout_conflicts)
            if (k[0] == m[0] && abs(k[1]-h[0]) < 1e-6 && abs(k[2]-h[1]) < 1e-6) k]) > 0;
        assert(!overlap || _is_known,
            str("underside module ", m[0], " footprint overlaps standoff post at [",
                h[0], ",", h[1], "] — installed module would collide"));
    }

// Render nothing (pure assert file).
