// params.scad — the ONLY hand-typed constants for the bpir4-1u-chassis, plus
// helper functions that DERIVE everything else live from the libraries.
// Rule: no library-owned dimension is duplicated here; only values no library
// exposes are literals below. Both parts `include` this file.
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <hardware/hardware.scad>;

$fn = 48;

// ---- selectors ----
STD   = "labrax";
BOARD = "bpir4";

// ---- print / enclosure constants (NO library owns these) ----
wall         = 2.4;   // side + rear wall thickness
floor_th     = 2.0;   // tray floor (flat underside -> stackable)
lid_th       = 2.0;   // lid plate thickness
faceplate_th = 3.0;   // front rack panel thickness
standoff_h   = 5.0;   // board underside clearance above floor
stack_gap    = 0.45;  // 1U device-height gap below pitch (rack lib has no
                      // device-height fn — see spec "Library gap noted")
wall_gap     = 0.25;  // lid-to-wall running clearance per side
board_insert_bore = 3.4; // M2.5 heat-set insert OD (board standoffs) (coincidentally equals m3_clearance_mm(); unrelated — this is the M2.5 insert OD)
lid_insert_bore   = 4.2; // M3 heat-set insert OD (lid posts)
vent_slot_w   = 2.5;  // intake/lid vent slot width
vent_slot_gap = 3.0;  // gap between vent slots
boss_wall        = 3.2;  // lid-post wall thickness around the insert bore (post OD = lid_insert_bore + boss_wall)
post_edge_inset  = 6;    // lid-post inset from the front/rear interior edges
csk_head_extra   = 2.6;  // M3 countersink head dia over the clearance hole (=> ~6mm 90-deg CSK head)
lid_vent_band_w  = 60;   // width of the lid vent band over the SoC/SFP hot zone (centered, clear of posts at +/-78.7)
board_side_gap   = 1.0;  // board edge -> corner-post clearance

// ---- cooling toggle (overridable by an entry file's customizer) ----
enable_exhaust = is_undef(enable_exhaust) ? true : enable_exhaust; // false = passive
fan_size  = is_undef(fan_size)  ? 40 : fan_size;   // must be a fan_known_sizes() value
fan_count = is_undef(fan_count) ? 2  : fan_count;
fan_plenum = 12.0;     // board-rear-edge -> rear-wall gap when fans on
rear_gap   = 4.0;      // same when fans off
lid_vents  = true;

// ---- rack ear hole type (overridable by an entry file's customizer) ----
ear_hole_type = is_undef(ear_hole_type) ? "slot" : ear_hole_type; // "slot" | "10-32" | "m6" | "round"
// Clearance dia (mm) used only when ear_hole_type == "round" — rack10_holes()
// takes "round" dia literally (no library-resolved clearance the way "m6"/
// "10-32" get one). Sourced directly from the library's own m6 screw-
// clearance (6.6mm, > its 10-32 clearance of 5.0mm), so an unspecified round
// hole is provably large enough to pass either common rack-ear fastener —
// not a hand-picked literal.
ear_hole_round_dia = rack10_screw_clearance("m6");

// ---- rackpost fit-reference ----
rack_depth = -1; // <0 -> rack10_depth_preset(STD)

// ---- derived from libraries (never typed) ----
function board_w()  = sbc_size(BOARD)[0];        // 148.0
function board_d()  = sbc_size(BOARD)[1];        // 100.5
function panel_w()  = rack10_panel_width(STD);   // 254
function clear_w()  = rack10_clear_width(STD);   // 222
function ext_h()    = rack10_u() - stack_gap;    // chassis exterior height
function int_h()    = ext_h() - floor_th - lid_th;
// Lid-post OD (boss outer diameter around the heat-set insert bore). Lives
// here (not in parts/tray.scad) because body_w() below also derives from it.
function _lid_post_od() = lid_insert_bore + boss_wall; // boss OD (shared placement + geometry)
// Body hugs the board: each side carries board_side_gap + a corner post (tangent
// to the wall) + the wall. Ears bridge body_w -> panel_w. Must stay <= clear_w.
function body_w()   = board_w() + 2*(board_side_gap + _lid_post_od() + wall);
function rear_off() = enable_exhaust ? fan_plenum : rear_gap;
function int_depth()= board_d() + rear_off();    // faceplate-inner (Y=0) -> rear-wall outer face
// board placement in chassis frame:
function board_x()  = -board_w()/2;              // centered in X
function board_y()  = 0;                         // front edge on post face (Y=0)
function board_z()  = floor_th + standoff_h;     // board underside rests on the standoff tops
function rear_wall_y() = board_y() + int_depth();// outer (rearmost) face of rear wall; wall occupies [rear_wall_y()-wall, rear_wall_y()]

// Intake vent band (faceplate): starts just above the tallest ymin (front-
// edge) connector so the band clears every port, and stays inside the wall
// height the ledge leaves for the lid.
function _front_conn_max_h() =
    max([for (c = sbc_connectors(BOARD)) if (c[3] == "ymin") c[2][2]]);
function _vent_band_z0() =
    board_z() + sbc_thickness(BOARD) + _front_conn_max_h() + 1; // 1mm above tops
function rack_depth_eff() = rack_depth < 0 ? rack10_depth_preset(STD) : rack_depth;

// Fan must physically fit the 1U internal height when exhaust is on.
assert(!enable_exhaust || fan_size <= int_h() + 1e-6,
    str("params: fan_size ", fan_size, " exceeds internal height ", int_h(),
        " — reduce floor_th/lid_th or fan_size"));

// fan_size must be one of the sizes the fans library actually supports.
assert(len([for (s = fan_known_sizes()) if (s == fan_size) s]) > 0,
    str("params: fan_size ", fan_size, " not in fan_known_sizes() ", fan_known_sizes()));
