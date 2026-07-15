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

// Render nothing (pure assert file).
