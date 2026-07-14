// asserts.scad — render-time invariants for the chassis geometry.
// Rendered by tests/test_bpir4_chassis_lib.sh; any failed assert -> ERROR in stderr.
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;

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

// Each faceplate vent zone (bounded by the body walls, not the wide ears) must
// fit at least one intake slot after both-end gap insets.
margin = (body_w() - board_w())/2 - wall - 2*vent_slot_gap;
assert(margin >= vent_slot_w,
    str("faceplate vent-zone margin ", margin, " < one slot width ", vent_slot_w));

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

// Render nothing (pure assert file).
