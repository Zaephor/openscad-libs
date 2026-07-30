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
// This file (Task 1 of a 4-task plan): scaffold, params, fit-asserts,
// cradle floor + side/rear walls. Faceplate/port-cutout/secure-hole
// cutters (Task 2), honeycomb vents + rear #40 tongue (Task 3), and
// docs/render (Task 4) land in later commits. See
// projects/drive-tray/drive-tray.scad for the closest shipped peer this
// design follows (_reach() placement idiom, honeycomb floor vents, #40
// tongue anchoring, the vent-vs-mount-hole clash lesson).
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
cell = 8.0; hc_wall = 1.2;   // T3 honeycomb params

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

module rack10_device_tray() {
    // Floor: full cradle width (device + fit_clearance + walls), spans
    // Y∈[0, _reach()] — reaches the #40 tongue's own root, not just the
    // device's own depth (see _reach() comment above).
    translate([-_cradle_w()/2 - wall, 0, 0])
        cube([_cradle_w() + 2*wall, _reach(), floor_th]);

    // Side walls: same Y-span as the floor, partial height
    // (retention_height, not the full 1U interior) — a rigid-box device
    // needs lateral retention, not full enclosure.
    for (sx = [-1, 1])
        translate([sx*(_cradle_w()/2 + wall) - (sx > 0 ? wall : 0), 0, 0])
            cube([wall, _reach(), retention_height]);

    // Rear wall: closes the box at _reach() — also the Task-3 tongue's
    // anchor face (no separate buttress needed later).
    translate([-_cradle_w()/2 - wall, _reach() - wall, 0])
        cube([_cradle_w() + 2*wall, wall, retention_height]);

    // Device fit-visualisation box, preview-only (% excludes from export).
    % translate([-_dw()/2, 0, floor_th]) cube(device_size);
}
rack10_device_tray();
