// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// params.scad — the ONLY hand-typed constants for the bpir4-1u-chassis, plus
// helper functions that DERIVE everything else live from the libraries.
// Rule: no library-owned dimension is duplicated here; only values no library
// exposes are literals below. Both parts `include` this file.
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <heatset/heatset.scad>;

$fn = 48;

// ---- selectors ----
STD   = "labrax";
BOARD = "bpir4";

// ---- print / enclosure constants (NO library owns these) ----
wall         = 2.4;   // side + rear wall thickness
floor_th     = 2.0;   // tray floor (flat underside -> stackable)
lid_th       = 2.0;   // lid plate thickness
faceplate_th = 3.0;   // front rack panel thickness
// Underside module clearance: the board rides high enough that the worst-case
// underside keep-out (2x mini-PCIe + a double-sided M.2-2280, from the sbc
// bottom-face rows) never touches the floor. Design fit-value (design-for-print
// running clearance), NOT a measured tier. standoff_h derives from it below.
underside_clearance = 1.0;
// Max downward protrusion of any underside (edge="bottom") component, read live
// from the sbc row (#55) — never re-literal a module height here.
function _underside_max_hang() =
    max([0, for (c = sbc_connectors(BOARD)) if (c[3] == "bottom") c[2][2]]);
// Was a hand-typed 5.0 (no underside components existed). Now derived so the
// board rides above the worst-case underside keep-out (#55 bottom-face rows)
// with underside_clearance to spare — keeps the flat, stackable underside
// (no floor recesses).
standoff_h = _underside_max_hang() + underside_clearance;
// Max protrusion of any rear-edge (edge="ymax") item PAST the board's rear
// edge, 0 if none — read live from the sbc row, never re-literalled here.
// Mirrors _underside_max_hang() above, which does the same for edge="bottom".
// Derived rather than hand-set so a future inserted-media keep-out row (the
// SIM sockets are push-push and currently unmodelled) widens the rear datums
// on its own instead of silently re-creating a collision.
function _rear_media_protrusion() =
    max([0, for (c = sbc_connectors(BOARD)) if (c[3] == "ymax")
             c[1][1] + c[2][1] - sbc_size(BOARD)[1]]);
// stack_gap: 1U device-height relief below the 44.45mm pitch.
// DELIBERATE DEVIATION from rack10_stack_gap() (0.79) — do NOT "fix" this to
// consume the lib accessor; it breaks the fan. 0.45 is the MAXIMUM gap that
// still fits a 40mm fan in 1U at floor_th + lid_th = 4.0:
//     rack10_u() - floor_th - lid_th - fan_size = 44.45 - 2 - 2 - 40 = 0.45
// Adopting 0.79 leaves int_h() = 39.66 and trips the fan-fit assert below by
// 0.34mm. That assert (`fan_size <= int_h()`) is already the guard — any
// change to fan_size, floor_th, or lid_th that breaks this budget fails there,
// so no second assert is added here.
// Kept as a literal, deliberately NOT derived from the fan budget: a stacking
// gap is a property of the rack, not of whichever fan this chassis uses, and a
// larger fan_size must fail loudly at that assert rather than silently eat
// rack clearance.
// Direction of risk: a smaller gap makes the device TALLER, so this is the
// more binding-prone side of the EIA-310 figure, not the safer side. Accepted:
// it is still a real gap, and the one inspectable 10in generator applies none.
stack_gap    = 0.45;
wall_gap     = 0.25;  // lid-to-wall running clearance per side
// Heat-set insert sizes (generic brand — see #6 spec, RESEARCH.md). Bores +
// boss OD derive from the heatset lib; no local insert-dim literals.
board_insert_size = "M2.5";   // board standoff inserts
lid_insert_size   = "M3";     // lid-post inserts
function board_insert_bore() = heatset_pilot_dia(board_insert_size); // was 3.4
function lid_insert_bore()   = heatset_pilot_dia(lid_insert_size);   // was 4.2
vent_slot_w   = 2.5;  // intake/lid vent slot width
vent_slot_gap = 3.0;  // gap between vent slots
// Shared honeycomb vent geometry (honeycomb/honeycomb.scad honeycomb_vent()):
// used by the faceplate above-IO band and (per the v3 plan) the lid vents,
// so both bands look consistent. cell = hex point-to-point width; its flat
// top edge (the only true bridge in a flat-top hex -- see honeycomb/honeycomb.scad)
// is cell/2 = 4mm, safely under design-for-print's <=5mm "reliably
// self-supporting" bridge ceiling. wall = gap kept between adjacent hex
// holes, sized >= 2x a 0.4mm nozzle's line width.
honeycomb_cell = 8.0;
honeycomb_wall = 1.2;
post_edge_inset  = 6;    // lid-post inset from the front/rear interior edges
csk_head_extra   = 2.6;  // M3 countersink head dia over the clearance hole (=> ~6mm 90-deg CSK head)
lid_vent_band_w  = 60;   // width of the lid vent band over the SoC/SFP hot zone (centered, clear of posts at +/-78.7)
board_side_gap   = 1.0;  // board edge -> corner-post clearance
// Per-side running clearance between a front-panel connector's real body and
// the faceplate opening sbc_faceplate_cutouts() cuts for it (Round 3 #65).
// Design fit-value (design-for-print running clearance, consistent with this
// project's other running-clearance precedents -- wall_gap, underside_
// clearance), NOT a measured/spec tier: never cite this as [A]/[B]/[C]. Eats
// io_port_clearance off EACH side of every connector's cutout, so two
// adjacent cutouts' EFFECTIVE gap shrinks by 2x this value versus the
// connectors' nominal body-edge gap -- see parts/tray.scad's
// _io_gap_wall_geom(), which accounts for exactly this when sizing the IO
// gap bridge-support walls.
io_port_clearance = 0.4;

// ---- cooling toggle: enable_exhaust/fan_size/fan_count are declared with
// their defaults in each entry file (assembly.scad, parts/tray.scad,
// parts/lid.scad) BEFORE `include <params.scad>`; params.scad only consumes
// them below and must never re-assign them (OpenSCAD is last-assignment-wins,
// so a re-assignment here would silently discard whatever the entry file or
// the customizer set).
// NOTE: BPI-R4's stock heatsink fins run side-to-side, suboptimal for this chassis's front-intake/rear-exhaust airflow, but no alternative orientation is available.
// fan_board_gap: clearance kept between the interior-mounted fan's inner
// face and the board's rear edge. (Task 5 fix — the old fan_plenum=12.0
// literal was hand-picked and, for the only valid fan_size (40mm), put the
// fan's inner face 0.4mm INSIDE the board: it wasn't derived from the
// library's actual fan depth.)
fan_board_gap = 1.5;   // clearance between interior fan face and board rear edge
// fan_pad_dia: diameter of the solid pad kept around each fan mount screw
// where the rear-wall honeycomb would otherwise reach it. The M3 head (~5.5mm)
// must bear on material, not on the 1.2mm hex lattice. 9mm leaves a 2.35mm
// solid annulus around the 4.3mm clearance hole (fan_mount_hole_dia(40)).
// Guarded in tests/asserts.scad against the lib's own hole diameter.
fan_pad_dia = 9;       // solid bearing pad around each fan mount screw
// fan_plenum: board-rear-edge -> rear-wall gap when fans on. Derived from
// the library-owned fan depth (fan_default_thickness(fan_size) — NOT
// duplicated here as a literal) plus the wall thickness (the fan mounts on
// the wall's interior face) plus fan_board_gap, so the plenum can never
// under-clear the board regardless of fan_size (see the depth-clearance
// assert below, which makes any future under-clearance fail loudly).
fan_plenum = fan_default_thickness(fan_size) + wall + fan_board_gap + _rear_media_protrusion();
// rear_clearance: air gap kept between the rear wall's inner face and whatever
// stands furthest off the board's rear edge. Was implicit in the old
// `rear_gap = 4.0` literal (4.0 - 2.4 wall); named here so the passive mode
// states its clearance as explicitly as the active mode does via fan_board_gap.
rear_clearance = 1.6;
rear_gap       = wall + rear_clearance + _rear_media_protrusion();
lid_vents  = true;

// ---- rack ear hole type: ear_hole_type is likewise declared with its default
// in each entry file before `include <params.scad>`; params.scad only consumes it.
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
// Square lid-post side = insert bore + 2x sourced min wall (wall-based, not the
// lib's 2.5x boss_od proxy). Was lid_insert_bore + boss_wall (=7.4).
function _lid_post_od() = lid_insert_bore() + 2*heatset_min_wall(lid_insert_size);
// Body hugs the board: each side carries board_side_gap + a corner post (tangent
// to the wall) + the wall. Ears bridge body_w -> panel_w. Must stay <= clear_w.
function body_w()   = board_w() + 2*(board_side_gap + _lid_post_od() + wall);
// ee defaults to the file-global enable_exhaust so every existing no-arg call
// site (including within this file) is unchanged. The optional param exists
// because a `use`-scoped consumer (parts/tray.scad, parts/lid.scad) with its
// own enable_exhaust MODULE parameter cannot make a plain function call see
// that value -- functions only read their own file's globals, never a
// caller's module params -- so such a consumer must pass its local
// enable_exhaust through explicitly as `ee` for the depth path to respond to
// the Customizer value.
function rear_off(ee = enable_exhaust) = ee ? fan_plenum : rear_gap;
function int_depth(ee = enable_exhaust) = board_d() + rear_off(ee); // faceplate-inner (Y=0) -> rear-wall outer face
// board placement in chassis frame:
function board_x()  = -board_w()/2;              // centered in X
function board_y()  = 0;                         // front edge on post face (Y=0)
function board_z()  = floor_th + standoff_h;     // board underside rests on the standoff tops
function rear_wall_y(ee = enable_exhaust) = board_y() + int_depth(ee); // outer (rearmost) face of rear wall; wall occupies [rear_wall_y()-wall, rear_wall_y()]

// Intake vent band (faceplate): starts just above the tallest ymin (front-
// edge) connector so the band clears every port, and stays inside the wall
// height the ledge leaves for the lid.
function _front_conn_max_h() =
    max([for (c = sbc_connectors(BOARD)) if (c[3] == "ymin") c[2][2]]);
// io_port_clearance (Round 3 #65 Task 3/4) inflates every ymin faceplate
// cutout UPWARD in Z (see sbc.scad's _sbc_cutout_inflate(): "top" edge grows
// size[2] += clearance, start z unchanged) -- so the tallest INFLATED cutout
// top sits io_port_clearance above the nominal _front_conn_max_h() top. Must
// be included here or the "+1mm above tops" margin below is measured from
// the wrong (nominal, not inflated) top and silently erodes toward the
// project's 2-perimeter min rib (>=0.8mm @ 0.4mm nozzle -- see parts/
// tray.scad's _io_wall_w_rj45_dc() comment for the same 2-perimeter/0.4mm-
// nozzle precedent).
function _vent_band_z0() =
    board_z() + sbc_thickness(BOARD) + _front_conn_max_h() + io_port_clearance + 1; // 1mm above INFLATED cutout tops
function rack_depth_eff() = rack_depth < 0 ? rack10_depth_preset(STD) : rack_depth;

// Fan X centres, thermally placed rather than evenly spaced (#74).
// The shipped layout butted the pair at -20/+20, leaving 16.5mm of the SFP
// zone outside the fan footprint (~50% covered) on a board whose SFP+ thermal
// is the documented failure mode.
//   1 fan : SFP zone centre (thermal priority)
//   2 fans: SFP zone centre + RJ45 block centre, with a deliberate gap between
//   3+    : even spacing centred on the chassis -- the pre-#74 fallback, kept
//           so a non-designed fan_count still yields valid geometry
// DERIVED from the sbc rows, never typed, so a re-caliper of the board moves
// the fans with it.
function _fan_x_centres(fan_size = fan_size, fan_count = fan_count) =
    let (sfp   = [for (c = sbc_connectors(BOARD)) if (c[0] == "sfp_1" || c[0] == "sfp_2") c],
         lo    = min([for (c = sfp) board_x() + c[1][0]]),
         hi    = max([for (c = sfp) board_x() + c[1][0] + c[2][0]]),
         rj    = sbc_connector(BOARD, "rj45_block"),
         c_sfp = (lo + hi) / 2,
         c_rj  = board_x() + rj[1][0] + rj[2][0]/2)
    fan_count == 1 ? [c_sfp]
  : fan_count == 2 ? [c_sfp, c_rj]
  : [for (i = [0:fan_count-1]) -fan_count*fan_size/2 + fan_size/2 + i*fan_size];

// Union of the fan footprints -- the honeycomb band's X extent.
function _fan_band_x(fan_size = fan_size, fan_count = fan_count) =
    let (cs = _fan_x_centres(fan_size, fan_count))
    [min(cs) - fan_size/2, max(cs) + fan_size/2];

// Smallest gap between adjacent derived centres (1e9 when there is only one).
function _fan_centre_min_sep(fan_size = fan_size, fan_count = fan_count) =
    let (cs = _fan_x_centres(fan_size, fan_count))
    len(cs) < 2 ? 1e9 : min([for (i = [1:len(cs)-1]) cs[i] - cs[i-1]]);

// Fan must physically fit the 1U internal height when exhaust is on.
assert(!enable_exhaust || fan_size <= int_h() + 1e-6,
    str("params: fan_size ", fan_size, " exceeds internal height ", int_h(),
        " — reduce floor_th/lid_th or fan_size"));

// Interior-mounted fan (Task 4/5) must clear the board's rear edge: the
// fan's inner face sits at (rear_wall_y() - wall) - fan_default_thickness(
// fan_size); that must be >= board_d() (the fan sits entirely behind the
// board, not intruding into it). Catches any future under-clearing of
// fan_plenum/fan_board_gap/fan_size at render time instead of silently
// producing a colliding STL.
assert(!enable_exhaust ||
    (rear_wall_y() - wall) - fan_default_thickness(fan_size) >= board_d() - 1e-6,
    str("params: interior fan (thickness ", fan_default_thickness(fan_size),
        "mm) intrudes into the board — fan inner face is at ",
        (rear_wall_y() - wall) - fan_default_thickness(fan_size),
        " but board rear edge is at ", board_d(),
        " (gap ", (rear_wall_y() - wall) - fan_default_thickness(fan_size) - board_d(),
        "mm) — increase fan_board_gap/fan_plenum"));

// fan_size must be one of the sizes the fans library actually supports.
assert(len([for (s = fan_known_sizes()) if (s == fan_size) s]) > 0,
    str("params: fan_size ", fan_size, " not in fan_known_sizes() ", fan_known_sizes()));

// Thermally-placed fans must not overlap each other.
assert(!enable_exhaust || _fan_centre_min_sep() >= fan_size - 1e-6,
    str("params: fan_size ", fan_size, " overlaps at the derived fan centres ",
        "(separation ", _fan_centre_min_sep(), ") — reduce fan_size or fan_count"));
// The vent band must stay inside the side walls.
assert(_fan_band_x()[0] >= -(body_w()/2 - wall) - 1e-6
    && _fan_band_x()[1] <=  (body_w()/2 - wall) + 1e-6,
    str("params: fan band ", _fan_band_x(), " exceeds the interior width ",
        body_w()/2 - wall));
