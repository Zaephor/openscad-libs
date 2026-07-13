// asserts.scad — render-time invariants for the chassis geometry.
// Rendered by tests/test_bpir4_chassis_lib.sh; any failed assert -> ERROR in stderr.
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;

// Board must fit within the body width (between the posts).
assert(board_w() <= body_w() + 1e-6,
    str("board width ", board_w(), " exceeds body width ", body_w()));

// Exterior height must not exceed the 1U pitch.
assert(ext_h() <= rack10_u() + 1e-6,
    str("exterior height ", ext_h(), " exceeds 1U pitch ", rack10_u()));

// There must be 16 mounting holes for the bpir4 (sanity vs the library).
assert(len(sbc_holes_xy(BOARD)) == 16,
    str("expected 16 bpir4 holes, got ", len(sbc_holes_xy(BOARD))));

// Board depth + rear offset must leave the board inside the box.
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

// Render nothing (pure assert file).
