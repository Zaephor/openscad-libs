// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// rack10-device-tray — parametric 1U 10" rack tray cradling a rigid-box
// network device (GS308/GS308T/RLA-PS1 presets): floor + side/rear cradle
// walls sized from the device envelope, front open for port access, bottom
// secure-hole cutouts (screws pass UP through the tray floor into the
// device's own mounting bosses), honeycomb floor vents, rear #40
// support-plate mate. Consumes rack10/rack-support/honeycomb. Device
// envelope [B] (vendor datasheets); secure_holes //VERIFY (caliper the
// device bottom — shape only, NOT sourced positions/diameter; dia is an
// M3 screw-CLEARANCE figure, not a measured device hole).
//
// This file (Tasks 1-3 of a 4-task plan): scaffold, params, fit-asserts,
// cradle floor + side/rear walls (T1), front rack faceplate (#70
// rack10_panel() chamfered silhouette) with ear mounting holes + port
// cutout, and countersunk bottom secure-hole cutters (T2), a single square
// honeycomb floor vent field and the rear #40 rack_support_tongue() mate
// (T3). Docs/render (Task 4) lands in a later commit. See
// projects/drive-tray/drive-tray.scad for the closest shipped peer this
// design follows (_reach() placement idiom, honeycomb floor vents, #40
// tongue anchoring, the vent-vs-mount-hole clash lesson, and the
// full-height-rear-wall-as-tongue-anchor pattern this file also uses).
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;
use <honeycomb/honeycomb.scad>;

/* [Rack] */
standard = "labrax";
ear_type = "slot";           // T2 consumes this for rack10_holes()

/* [Device] — preset envelopes [B] vendor datasheets (see below);
   secure_holes //VERIFY: shape (2-hole bottom pattern) is a starting
   placeholder pending a caliper pass on the physical devices — NEITHER
   the 69.5mm spacing NOR the dia is a sourced device dimension. dia=3.4
   is an M3 clearance-hole figure for a screw passing UP through the
   TRAY's own floor into the device's factory mounting boss, not a
   measured device hole diameter. Swapping in caliper-confirmed numbers
   is a one-line default change (T2 stamps these as cutters). */
device_size  = [158, 102, 26];   // GS308 [B]; GS308T=[158,101,30] [B]; RLA-PS1=[189.6,106.6,25.6] [B]
secure_holes = [[44.25, 51, 3.4], [113.75, 51, 3.4]]; // [[x,y,dia],...] bottom-face, device-local origin //VERIFY
port_cutout  = [0, 0];            // [w,h]; [0,0] => full device face minus frame (T2)

/* [Print] */
wall = 2.4; floor_th = 3.0; faceplate_th = 3.0; fit_clearance = 0.5;
retention_height = 20; csk_dia = 8;

/* [Vent] */
cell = 8.0; hc_wall = 1.2;
// Clearance from both secure_holes (their csk_dia clearance) and the
// interior side/rear walls kept around the single floor honeycomb field
// below -- same vent_inset lesson drive-tray.scad's own header comment
// documents (a smaller inset there measurably overlapped a bottom mount
// hole by ~2mm). See _vent_y0()/_vent_x_half() below for how it's applied.
vent_inset = 10;

function _dw() = device_size[0];
function _dd() = device_size[1];
function _dh() = device_size[2];
function _cradle_w() = _dw() + 2*fit_clearance;
function _int_h()    = rack10_device_height(1) - floor_th;

// Conservative DEPTH-BUDGET for the fit-assert only — NOT a placement
// formula. Do not use this to position floor/walls/tongue (see _reach()
// below): constraints.md's ADDENDUM (point D/E) is explicit that doing so
// is the exact tongue-placement bug the plan's own Task-3 text originally
// carried, the same defect drive-tray.scad's header comment documents at
// length for its own sibling function of the same name.
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();

// Tray-body rear limit — rack-support's (#40) own consumer-contract
// placement formula: the tongue's TIP lands at rack10_rear_post_y()
// (rack_support_plate()'s mounting plane), its ROOT sits
// engagement_depth() forward of that. Floor/walls in THIS task run to
// _reach() (not _usable_depth() above), so the rear wall built here
// doubles as the Task-3 tongue's anchor face with nothing to unwind —
// the "PREFERRED simpler route" of constraints.md ADDENDUM point E.4,
// same idiom drive-tray.scad ships.
function _reach() = rack10_rear_post_y(standard) - rack_support_engagement_depth();

assert(_cradle_w() <= rack10_clear_width(standard) - 2*wall + 1e-6,
    str("rack10-device-tray: device too wide: ", _dw()));
assert(_dd() <= _usable_depth() + 1e-6,
    str("rack10-device-tray: device too deep: ", _dd()));
assert(_dh() <= _int_h() + 1e-6,
    str("rack10-device-tray: device too tall for 1U: ", _dh()));
for (h = secure_holes)
    assert(h[0] >= 0 && h[0] <= _dw() && h[1] >= 0 && h[1] <= _dd(),
        str("rack10-device-tray: secure hole [", h[0], ",", h[1], "] outside device footprint"));

// Countersunk secure-hole cutter geometry sanity: secure_holes is //VERIFY
// (caliper placeholder) and csk_dia is a Customizer-exposed default, so a
// future preset edit could silently produce a degenerate or breaching
// cone rather than a cryptic OpenSCAD error -- guard both explicitly.
// secure_holes may legitimately be [] (e.g. GS308T, desktop-mount-only);
// for() no-ops on an empty list, nothing to guard in that case.
for (h = secure_holes) {
    assert(csk_dia > h[2],
        str("rack10-device-tray: csk_dia (", csk_dia, ") must exceed secure hole dia ",
            h[2], " for a positive countersink cone height"));
    assert((csk_dia - h[2]) / 2 <= floor_th + 1e-6,
        str("rack10-device-tray: countersink cone height ", (csk_dia - h[2]) / 2,
            " exceeds floor_th ", floor_th, " -- would breach the floor's top face"));
}

// Port cutout size, deriving [0,0] => full device face minus a 3mm frame
// each side (see port_cutout comment above).
function _port_w() = port_cutout[0] > 0 ? port_cutout[0] : _dw() - 6;
function _port_h() = port_cutout[1] > 0 ? port_cutout[1] : _dh();

// Max half-width the #70 chamfered rack10_panel() silhouette allows at
// panel-local height z (z=0 panel bottom, z=rack10_device_height(1) panel
// top) -- mirrors rack10_panel_chamfer_max()'s own corner-cut geometry
// (see that function's comment in libraries/rack10/rack10.scad) so a port
// rectangle can be checked against the REAL #70 silhouette instead of the
// pre-chamfer rectangle. zc = distance to the nearer of the top/bottom
// edge; inside the chamfer band (zc < corner_chamfer) the panel narrows
// linearly toward the corner.
function _panel_max_x(z) =
    let (w = rack10_panel_width(standard), h = rack10_device_height(1),
         c = rack10_panel_corner_chamfer(), zc = min(z, h - z))
    w/2 - max(0, c - zc);

// Port-in-panel fit-asserts against the real #70 chamfered silhouette
// (constraints.md point F): checking both the port's bottom and top Z
// edges suffices because _panel_max_x() is concave in z, so its minimum
// over the port's Z-span is at one of those two endpoints.
assert(floor_th + _port_h() <= rack10_device_height(1) + 1e-6,
    str("rack10-device-tray: port cutout height ", _port_h(),
        " exceeds panel height ", rack10_device_height(1)));
assert(_port_w()/2 <= _panel_max_x(floor_th) + 1e-6
    && _port_w()/2 <= _panel_max_x(floor_th + _port_h()) + 1e-6,
    str("rack10-device-tray: port cutout width ", _port_w(),
        " clips the #70 chamfered panel corner (max half-width ",
        min(_panel_max_x(floor_th), _panel_max_x(floor_th + _port_h())), ")"));

// Honeycomb floor vent field (T3): a single SQUARE hex-cell region cut
// straight through the floor, inset clear of both the countersunk
// secure_holes and the interior side/rear walls by vent_inset. secure_holes
// (this file's presets) all sit at the SAME mid-device Y, so rather than
// splitting the field around them (which the brief's "a square honeycomb
// field" -- singular -- argues against), it's placed entirely BEHIND them,
// toward the rear wall: the floor already runs to _reach() regardless of
// device depth (see _reach()'s own comment), so there is ample open room
// back there even for a shallow device like the GS308 default. Y0 falls
// back to a flat vent_inset front margin when secure_holes is empty (the
// GS308T scenario).
function _vent_y0() = (len(secure_holes) > 0)
    ? max([for (h = secure_holes) h[1] + csk_dia/2]) + vent_inset
    : vent_inset;
function _vent_y1() = _reach() - wall - vent_inset;
function _vent_x_half() = _cradle_w()/2 - vent_inset;
function _vent_side() = min(2 * _vent_x_half(), _vent_y1() - _vent_y0());

assert(_vent_side() > 2*cell,
    str("rack10-device-tray: honeycomb vent field side ", _vent_side(),
        "mm too small to fit even one cell (cell=", cell,
        "mm) after clearing secure_holes/walls by vent_inset=", vent_inset,
        "mm -- widen the device/floor or shrink vent_inset/cell"));

// Front rack faceplate: rack10_panel() (#70 chamfered silhouette, front
// face Y=0 growing -Y -- matches this file's own Y=0 tray-floor/faceplate
// frame, see header) with ear mounting holes and a port opening framing
// the device face.
module _dt_faceplate() {
    pw = _port_w();
    ph = _port_h();
    difference() {
        rack10_panel(standard, 1, faceplate_th);
        if (ear_type == "slot") rack10_holes(standard, 1, hole_type = "slot", dia = rack10_screw_clearance("10-32"));
        else rack10_holes(standard, 1, hole_type = ear_type);
        translate([-pw/2, -faceplate_th - 1, floor_th])
            cube([pw, faceplate_th + 2, ph]);   // port opening
    }
}

module rack10_device_tray() {
    difference() {
        union() {
            // Floor: full cradle width (device + fit_clearance + walls),
            // spans Y∈[0, _reach()] — reaches the #40 tongue's own root,
            // not just the device's own depth (see _reach() comment above).
            translate([-_cradle_w()/2 - wall, 0, 0])
                cube([_cradle_w() + 2*wall, _reach(), floor_th]);

            // Side walls: same Y-span as the floor, partial height
            // (retention_height, not the full 1U interior) — a rigid-box
            // device needs lateral retention, not full enclosure.
            for (sx = [-1, 1])
                translate([sx*(_cradle_w()/2 + wall) - (sx > 0 ? wall : 0), 0, 0])
                    cube([wall, _reach(), retention_height]);

            // Rear wall: closes the box at _reach() — also the Task-3
            // tongue's anchor face (no separate buttress needed later).
            translate([-_cradle_w()/2 - wall, _reach() - wall, 0])
                cube([_cradle_w() + 2*wall, wall, retention_height]);

            // Front rack faceplate (ear holes + port cutout already cut
            // internally, see _dt_faceplate()).
            _dt_faceplate();

            // Rear #40 support tongue (T3): root at _reach(), tip lands at
            // rack10_rear_post_y(standard) -- rack-support's own consumer-
            // contract placement formula (see _reach()'s comment above).
            // The rear wall built above already spans Z in [0,
            // retention_height] (20 > the tongue's Z-band [
            // rack_support_floor_thickness(), +rack_support_rail_size()[1]]
            // = [2,12]) at this SAME X/Y footprint, so it backs the tongue's
            // ENTIRE root cross-section with solid material on every printed
            // layer -- the same "full-height wall as in-layer anchor" role
            // drive-tray.scad's own rear wall plays for its tongue, which
            // rack-support/README.md's Consumer contract explicitly
            // recognises as an alternative to a separate 45deg root gusset
            // ("What this buys is an in-layer anchor for the tongue's first
            // printed layer, the same role drive-tray's full-height rear
            // wall plays for its tongue"). No extra gusset is added here.
            // Nothing in this tray's body reaches past _reach() (the
            // tongue's own engagement span, Y in [_reach(),
            // rack10_rear_post_y(standard)], is left unfilled -- that
            // volume belongs to rack_support_plate()'s own bearing floor),
            // so rack_support_plate_keepout() is not needed either -- the
            // README's "preferred simpler route". Verified with a 0mm^3
            // intersection() probe against rack_support_plate() at the rear
            // post plane -- see tests/test_rack10_device_tray.sh.
            translate([0, _reach(), 0]) rack_support_tongue();
        }

        // Countersunk bottom secure-hole cutters: a through-hole (screw
        // shaft) plus a downward-opening countersink cone (wide end flush
        // with the flat stacking bottom at Z=0, narrowing upward into the
        // floor) so the screw head sits flush under the tray. secure_holes
        // may legitimately be [] (e.g. GS308T, desktop-mount-only) --
        // for() no-ops on an empty list, cutting nothing.
        for (h = secure_holes)
            translate([-_dw()/2 + h[0], h[1], 0]) {
                translate([0, 0, -1]) cylinder(h = floor_th + 2, d = h[2], $fn = 32);   // through-hole
                cylinder(h = (csk_dia - h[2]) / 2 + 0.01, d1 = csk_dia, d2 = h[2], $fn = 32); // countersink, opens down at z=0
            }

        // Honeycomb floor vent (T3): straight through Z (flat floor, no
        // bridge orientation change needed -- honeycomb_vent()'s own
        // self-support design handles the hex-cell ceilings, same "cuts
        // straight down through the flat floor" idiom drive-tray.scad and
        // fan-grille.scad both use). depth = floor_th + 2 / Z=-1 start
        // mirrors the same 1mm-margin oversize-cut convention the
        // secure-hole cutters above use.
        translate([-_vent_side()/2, _vent_y0(), -1])
            honeycomb_vent(_vent_side(), _vent_side(), floor_th + 2, cell, hc_wall);
    }

    // Device fit-visualisation box, preview-only (% excludes from export).
    % translate([-_dw()/2, 0, floor_th]) cube(device_size);
}
rack10_device_tray();
