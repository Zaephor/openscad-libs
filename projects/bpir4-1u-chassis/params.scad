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
board_insert_size = "M2";     // board standoff inserts. M2 (not the earlier
                              // M2.5) because the board's own mount holes are
                              // dia 3.0: an M2 screw leaves 1.0mm of clearance
                              // vs M2.5's 0.5mm, so standoff misalignment is
                              // absorbed rather than fought. M3 is zero-
                              // clearance in a 3.0mm hole and cannot thread an
                              // M2.5 insert anyway. (#84)
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
// io_top_clearance (#85): EXTRA upward-only clearance for ports whose mating
// PLUG is taller than the connector body sbc models. Bench-derived from the
// printed part: with only io_port_clearance (0.4) the USB3 stack and both SFP
// cages fouled on insertion. Applied via sbc_port_cutout()'s top_clearance,
// which does NOT widen X -- widening X instead (by raising io_port_clearance)
// would trip _io_gap_wall_geom()'s asserts, since the rj45_block/dc_power_1
// gap is only 2.2mm against a 1.0mm wall and so caps a global clearance at
// ~0.59. Design fit-value like io_port_clearance, NOT a measured tier.
io_top_clearance = 0.5;
// Ports that get it. rj45_block is DELIBERATELY ABSENT -- it is bench-verified
// to line up correctly on the printed part, and loosening it would be a
// regression, not an improvement. A function, not a variable, so parts/
// tray.scad's `use` of this project can actually see it.
function io_top_clearance_ports() = ["usb_1", "sfp_1", "sfp_2"];
// Bias for the dc_power_1<->usbc_pwr_1 gap wall, toward dc_power_1 (#85).
// Combined with narrowing that wall 1.5 -> 1.0 this frees +0.5mm on the USB-C
// side (1.55 -> 2.05, where the plug's overmold fouled) while leaving the
// barrel-jack side at exactly its old 1.55mm.
io_wall_dc_usbc_bias = 0.25;
// io_chamfer (#85): lead-in chamfer leg on the INTERIOR face of each front
// port opening, so the board's connectors funnel into their cutouts on
// insertion instead of catching on a square edge. 1.0mm matches the repo's
// edge-break nominal (#64).
// PRINT CONSTRAINT: the faceplate prints as a VERTICAL wall, so each opening's
// top edge is already a horizontal bridge. The funnel therefore opens sideways
// and DOWNWARD only and never touches that top edge -- see _faceplate(). The
// resulting faces are two vertical planes (no overhang at all) and one
// UP-facing 45-degree ledge (an up-facing slope cannot overhang). Anything
// that changes this to also open upward puts a 45-degree overhang on the one
// feature that was already the weakest, and must be re-verified.
io_chamfer = 1.0;

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
// fan_thickness: the depth (mm) of the fan ACTUALLY installed. Declared as a
// plain top-level literal in each entry file before `include <params.scad>`
// (like enable_exhaust/fan_size/fan_count); params.scad only consumes it and
// must never assign it. A value < 0, or no declaration at all, falls back to
// the library's size-keyed default via _fan_thickness_eff() below, so any
// consumer that does not opt in is unchanged.
//
// This exists because fan_default_thickness(size) (libraries/fans/fans.scad)
// is a size-keyed LOOKUP with no data-side override: the 40mm row is fixed at
// 10mm depth. Before this parameter the chassis was hard-dimensioned for a
// 10mm fan, and — worse — the depth-clearance assert below took that same
// constant as its input, so it could not discriminate a deeper fan at all. A
// 20mm fan rendered clean, sliced clean, and collided at assembly.
//
// Deliberately NOT a new fans-library row: 20mm is one specific product's
// dimension (Noctua NF-A4x20, 40x40x20 [A] vendor datasheet) with exactly one
// consumer in this repo, so it stays project-local until a second consumer
// appears.
// ft/fs default to the file-globals so every existing no-arg call site is
// unchanged; they exist for the same reason `ee` does on rear_off() below —
// a `use`-scoped consumer's MODULE parameter cannot be seen by a plain
// function call, so tray()/lid() must pass their local values through
// explicitly for the depth path to respond to the Customizer.
function _fan_thickness_eff(ft = fan_thickness, fs = fan_size) =
    is_undef(ft) || ft < 0
        ? fan_default_thickness(fs)
        : ft;
// fan_plenum_at(): board-rear-edge -> rear-wall gap when fans on. Derived from
// the effective fan depth (_fan_thickness_eff() — NOT duplicated here as a
// literal) plus the wall thickness (the fan mounts on the wall's interior
// face) plus fan_board_gap, so the plenum can never under-clear the board
// regardless of fan_size OR fan thickness (see the depth-clearance assert
// below, which makes any future under-clearance fail loudly).
function fan_plenum_at(ft = fan_thickness, fs = fan_size) =
    _fan_thickness_eff(ft, fs) + wall + fan_board_gap + _rear_media_protrusion();
// fan_plenum: this file's own no-arg case, kept as a variable so existing
// readers (tests/asserts.scad's derivation guard, the test probes) are
// unchanged. Consumers that need a CALLER's thickness must call
// fan_plenum_at(ft, fs) instead — a variable is evaluated once in its own
// file's scope and can never respond to a module parameter.
fan_plenum = fan_plenum_at();
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
// ee/ft/fs default to the file-globals so every existing no-arg call site
// (including within this file) is unchanged. The optional params exist
// because a `use`-scoped consumer (parts/tray.scad, parts/lid.scad) with its
// own MODULE parameters cannot make a plain function call see those values
// -- functions only read their own file's globals, never a caller's module
// params -- so such a consumer must pass its local values through
// explicitly for the depth path to respond to the Customizer.
//
// ft/fs were added after a user found that editing fan_thickness in
// assembly.scad changed nothing while fan_count still worked: the other four
// cooling/ear params were already threaded as module params, fan_thickness
// was not, so tray()/lid() read parts/tray.scad's own literal and the
// consumer's value never reached the plenum. Note `-D fan_thickness=N` DOES
// work, because it sets the global in every file's scope at once -- which is
// exactly why -D cannot be used to test this threading (see
// tests/test_bpir4_lid_params.sh's Customizer-path cases).
function rear_off(ee = enable_exhaust, ft = fan_thickness, fs = fan_size) =
    ee ? fan_plenum_at(ft, fs) : rear_gap;
function int_depth(ee = enable_exhaust, ft = fan_thickness, fs = fan_size) =
    board_d() + rear_off(ee, ft, fs); // faceplate-inner (Y=0) -> rear-wall outer face
// board placement in chassis frame:
function board_x()  = -board_w()/2;              // centered in X
function board_y()  = 0;                         // front edge on post face (Y=0)
function board_z()  = floor_th + standoff_h;     // board underside rests on the standoff tops
function rear_wall_y(ee = enable_exhaust, ft = fan_thickness, fs = fan_size) =
    board_y() + int_depth(ee, ft, fs); // outer (rearmost) face of rear wall; wall occupies [rear_wall_y()-wall, rear_wall_y()]
// Top-side keep-out ceiling (#81). Mirrors _underside_max_hang() /
// _rear_media_protrusion() above: read live from the sbc rows, never
// re-literalled here. The tallest edge="top" row today is the stock SoC
// cooler (soc_cooler_1, 16.0mm above the PCB top face), but this is a max over
// ALL top rows so a taller cooler, an M.2 heatsink or a HAT is covered without
// an edit. Returns the chassis-frame Z of the highest top-side surface.
function _top_side_max_z() =
    board_z() + max([0, for (c = sbc_connectors(BOARD)) if (c[3] == "top")
                            c[1][2] + c[2][2]]);
// Name of the row that produced that max, "" if there are no top rows -- used
// only to make an assert failure name the offending part instead of a number.
function _top_side_max_name() =
    let (top = max([0, for (c = sbc_connectors(BOARD)) if (c[3] == "top")
                          c[1][2] + c[2][2]]),
         hit = [for (c = sbc_connectors(BOARD))
                    if (c[3] == "top" && abs(c[1][2] + c[2][2] - top) < 1e-9) c[0]])
    len(hit) > 0 ? hit[0] : "";
// Advisory clearance above the tallest top-side keep-out. [C] DESIGN INTENT,
// NOT a measured airflow requirement -- no CFD or thermocouple data exists.
// The free air above the cooler (lid inner face 42 - cooler top 25.6 = 16.4mm
// as built) is a SHARED BUDGET between future lid-side geometry (a vent baffle
// or duct, a vent-band re-registration) and a possible taller FANLESS cooler
// swap. Whoever spends it must state what they left.
top_side_air_gap = 2.0;

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

// Interior-mounted fan (Task 4/5) must clear the board's rear edge: the fan's
// inner face sits at (rear_wall_y() - wall) - _fan_thickness_eff(); that must
// be >= board_d() (the fan sits entirely behind the board, not intruding into
// it). Catches any future under-clearing of fan_plenum/fan_board_gap/fan_size
// at render time instead of silently producing a colliding STL.
// #79: the input is _fan_thickness_eff(), NOT fan_default_thickness(fan_size).
// It used to be the latter — a size-keyed constant — which meant this guard
// could not discriminate the fan actually installed and would pass a 20mm fan
// that sat 6.2mm inside the board.
// This does NOT mean the assert would now catch such a case by measurement:
// fan_plenum (above) derives from this SAME _fan_thickness_eff() term, so
// substituting it into rear_wall_y() here cancels the thickness out of the
// gap algebraically (GAP = fan_board_gap + _rear_media_protrusion(),
// independent of fan_thickness) — the assert is thickness-invariant by
// construction. The collision is prevented by the derivation, not caught
// after the fact; the assert's live job is catching a future
// re-literalisation of fan_plenum/fan_board_gap, paired with the derivation
// drift-guard at tests/asserts.scad:299. Setting a large fan_thickness and
// watching this NOT fire is not evidence the guard is broken.
assert(!enable_exhaust ||
    (rear_wall_y() - wall) - _fan_thickness_eff() >= board_d() - 1e-6,
    str("params: interior fan (thickness ", _fan_thickness_eff(),
        "mm) intrudes into the board — fan inner face is at ",
        (rear_wall_y() - wall) - _fan_thickness_eff(),
        " but board rear edge is at ", board_d(),
        " (gap ", (rear_wall_y() - wall) - _fan_thickness_eff() - board_d(),
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
