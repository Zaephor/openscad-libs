// sbc — single-board-computer mechanical reference (Raspberry Pi Model-B family
// this task; connectors/placeholder/stamps arrive in later tasks).
// Datum: bottom-left PCB corner at the origin, component/top side up.
// +X = board LONG edge, +Y = board SHORT edge, PCB bottom on Z=0.
// Roles (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / table lookups
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — <board>_placeholder(): envelope solid for fit checks   (Task 5)
//   3. Hole-stamp  — <board>_holes(): mounting holes for a consumer difference() (Task 6)
// Provenance: [A] raspberrypi.com official mechanical drawing/STEP, [B] multi-peer
// community corroboration, [C] single community STL/reverse-engineered. //VERIFY
// marks weak/unconfirmed values. See RESEARCH.md for full source list + notes.
// Units: millimeters.

$fn = 48;

/* [Data] */
function sbc_known_boards() = ["pi3b", "pi3bplus", "pi4b", "pi5"];

function sbc_hole_dia() = 2.7; // mm, M2.5 clearance.  [A] Pi4/Pi5 drawings label "Ø2.7";
    // Pi3B drawing calls out "4x M2.5 MOUNTING HOLES DRILLED TO 2.75 +/-0.05mm" (same
    // feature, 0.05mm drilling-tolerance difference from the Pi4/Pi5 label) — see RESEARCH.md.

// Row: [key, [x,y], corner_r, thickness, [[hx,hy],...holes], [connectors...]]
// Connectors are [name, [x,y,z], [w,d,h], edge]; added in a later task (empty for now).
// All four boards share the 58x49mm 4-hole rectangle inset 3.5mm and the outline below —
// confirmed directly against each board's own raspberrypi.com mechanical drawing (identical
// "85 / 58 / 29 / 3.5 / 49 / 56" dimension chain on all four; hole coords + Y outline are
// [A] exact drawing values). X outline: drawings print "85" (whole-mm rounding on all four);
// 85.6 is the widely multi-peer-corroborated precise classic figure — [B], not read directly
// off the drawing. See RESEARCH.md for the full per-value tier breakdown + sources.
// Connectors: [name, [x,y,z], [w,d,h], edge] — [x,y,z] is the box MINIMUM corner,
// [w,d,h] are extents along X/Y/Z, edge is the board edge the opening faces.
// z is always sbc_thickness(b) (connectors sit on the PCB top face). h is read
// directly off each drawing's own "Z-Height=" / "Z=" callout where present — [A],
// very reliable, independent of the X/Y position tiering. Full per-connector
// source/tier notes (which offsets are [A] read-off-drawing vs [B] standard-body
// estimate vs [C]//VERIFY) are in RESEARCH.md; only a short tag is given inline
// here. GPIO header X/Y is read directly off the pi3b drawing ([A]: x=1.5 from its
// own left-edge dimension chain, y forced to the ymax edge per the box convention,
// h=8.5 from the "Z-Height=8.5"/"Z=8.5" callout printed on pi3b/pi3bplus/pi4b) and
// carried forward byte-for-byte onto pi3bplus/pi5 [B] — the 40-pin header position
// is fixed across the whole family by the Raspberry Pi HAT mechanical spec, so reuse
// here is a compatibility requirement, not a guess.
function _sbc_gpio() = ["gpio", [1.5, 51.0, 1.4], [51.0, 5.0, 8.5], "ymax"];

function _sbc_table() = [
    // [A] https://datasheets.raspberrypi.com/rpi3/raspberry-pi-3-b-mechanical-drawing.pdf
    // corner radius: [A] drawing text "CORNER RADIUS = 3.0mm". thickness: no drawing
    // dimension exists on any Model-B mechanical drawing — [C] community-nominal //VERIFY.
    ["pi3b",     [85.6, 56], 3.0, 1.4, [[3.5,3.5],[61.5,3.5],[3.5,52.5],[61.5,52.5]],
        [ _sbc_gpio(),
          // right edge (xmax) USB2 stack, 2 dual-port shells stacked over Ethernet.
          // Y-spans [A] from the drawing's own bottom-referenced "10.25/29/47/56"
          // chain; X depth (w) is the brief's standard USB-A body depth [B] (drawing
          // gives no top-view X-depth text), so x is derived (85.6 - w).
          ["usb2_1",       [68.6, 29,    1.4], [17, 18,   16.0], "xmax"], // [A]/[B]
          ["usb2_2",       [68.6, 47,    1.4], [17, 9,    16.0], "xmax"], // [A]/[B] //VERIFY (see RESEARCH.md re: 9mm span)
          ["rj45",         [64.6, 10.25, 1.4], [21, 18.75, 13.5], "xmax"], // [A]/[B]
          // bottom edge (ymin): X centrelines [A] off the "3.5/10.6/32/53.5" chain,
          // converted to min-corner using standard body widths [B]/[C].
          ["microusb_pwr", [6.85, 0,     1.4], [7.5, 5.5,  2.8], "ymin"], // [A] pos / [C] body //VERIFY
          ["hdmi",         [24.5, 0,     1.4], [15,  11.5, 6.5], "ymin"], // [A] pos+h / [B] body
          ["av_jack",      [50.5, 0,     1.4], [6,   6,    6.0], "ymin"], // [A] pos+h / [C] body //VERIFY
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpi3/raspberry-pi-3-b-plus-mechanical-drawing.pdf
    // Same connector map as pi3b — pi3bplus's own drawing repeats byte-for-byte the
    // same "10.25/29/47/56" and "3.5/10.6/32/53.5" dimension chains (cross-checked
    // directly on this drawing, not merely assumed). See RESEARCH.md.
    ["pi3bplus", [85.6, 56], 3.0, 1.4, [[3.5,3.5],[61.5,3.5],[3.5,52.5],[61.5,52.5]],
        [ _sbc_gpio(),
          ["usb2_1",       [68.6, 29,    1.4], [17, 18,   16.0], "xmax"], // [A]/[B]
          ["usb2_2",       [68.6, 47,    1.4], [17, 9,    16.0], "xmax"], // [A]/[B] //VERIFY
          ["rj45",         [64.6, 10.25, 1.4], [21, 18.75, 13.5], "xmax"], // [A]/[B]
          ["microusb_pwr", [6.85, 0,     1.4], [7.5, 5.5,  2.8], "ymin"], // [A] pos / [C] body //VERIFY
          ["hdmi",         [24.5, 0,     1.4], [15,  11.5, 6.5], "ymin"], // [A] pos+h / [B] body
          ["av_jack",      [50.5, 0,     1.4], [6,   6,    6.0], "ymin"], // [A] pos+h / [C] body //VERIFY
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-mechanical-drawing.pdf
    ["pi4b",     [85.6, 56], 3.0, 1.4, [[3.5,3.5],[61.5,3.5],[3.5,52.5],[61.5,52.5]],
        [ _sbc_gpio(),
          // right edge (xmax), top-to-bottom on the real board: rj45 (near GPIO
          // corner), usb3 stack, usb2 stack (Pi4B swapped the pi3b order) — Y-spans
          // [A] off the drawing's own "9/27/45.75/56" chain.
          ["usb2",     [68.6, 9,     1.4], [17, 18,    16.0], "xmax"], // [A]/[B]
          ["usb3",     [68.6, 27,    1.4], [17, 18.75, 16.0], "xmax"], // [A]/[B]
          ["rj45",     [64.6, 45.75, 1.4], [21, 10.25, 13.5], "xmax"], // [A]/[B]
          // bottom edge (ymin): X centrelines [A] off the "3.5/7.7/14.8/13.5/7.5"
          // chain (cumulative from the left edge: 11.2, 26.0, 39.5, 47.0).
          ["usbc_pwr", [6.7,   0, 1.4], [9,   7.4, 3.2], "ymin"], // [A]
          ["hdmi_1",   [22.25, 0, 1.4], [7.5, 4.5, 3.0], "ymin"], // [A]
          ["hdmi_2",   [35.75, 0, 1.4], [7.5, 4.5, 3.0], "ymin"], // [A]
          ["av_jack",  [50.5,  0, 1.4], [6,   6,   6.0], "ymin"], // [A] h / [C] position by analogy to pi3b's 8mm hole-offset //VERIFY
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-mechanical-drawing.pdf
    // corner radius NOT labelled on the Pi5 drawing (unlike pi3b/pi3bplus/pi4b, which all
    // print "CORNER RADIUS = 3.0mm") — carried forward from the shared family value.
    // [B] //VERIFY corner radius against a Pi5 board/case.
    ["pi5",      [85.6, 56], 3.0, 1.4, [[3.5,3.5],[61.5,3.5],[3.5,52.5],[61.5,52.5]],
        [ _sbc_gpio(),
          // right edge (xmax): usb3 dual-port stack above a combined rj45+usb2
          // "combo" shell (real Pi5 hardware: Ethernet + 2xUSB2 share one molded
          // part). Y-spans [A] off the drawing's own "10.2/29.1/47/56" chain; rj45
          // and usb2 intentionally share the same box — see RESEARCH.md.
          ["usb3",     [68.6, 29.1, 1.4], [17, 17.9, 16.0], "xmax"], // [A]/[B]
          ["rj45",     [64.6, 10.2, 1.4], [21, 18.9, 16.0], "xmax"], // [A] pos /[C] extent //VERIFY rj45+usb2 combo, undimensioned split
          ["usb2",     [64.6, 10.2, 1.4], [21, 18.9, 16.0], "xmax"], // [A] pos /[C] extent //VERIFY rj45+usb2 combo, undimensioned split
          // bottom edge (ymin): X centrelines [A] off the drawing's own explicit
          // "11.2 / 25.8 / 39.2" dimensions (Pi5 prints these directly, unlike the
          // chained values on pi3b/pi4b).
          ["usbc_pwr", [6.7,   0, 1.4], [9,   7.4, 3.2], "ymin"], // [A]
          ["hdmi_1",   [22.05, 0, 1.4], [7.5, 4.5, 3.0], "ymin"], // [A]
          ["hdmi_2",   [35.45, 0, 1.4], [7.5, 4.5, 3.0], "ymin"], // [A]
          // PCIe FFC connector: seen on the drawing between micro-HDMI 2 and the
          // fan header, but no dimension text found for it — fully estimated.
          ["pcie_fpc", [44, 0, 1.4], [8, 3, 3], "ymin"], // //VERIFY [C] estimated, no drawing dimension found
          // left edge (xmin): two stacked 22-pin CSI/DSI FPC connectors. Near-edge
          // offsets [A] off the drawing's own "18.4 / 13.3" (from top edge) with "6"
          // as the gap between them; body length along Y is not dimensioned on the
          // drawing — estimated.
          ["csi_dsi_1", [0, 42.7, 1.4], [2.5, 6, 5.5], "xmin"], // [A] pos / [C] extent //VERIFY
          ["csi_dsi_2", [0, 31.6, 1.4], [2.5, 6, 5.5], "xmin"], // [A] pos / [C] extent //VERIFY
        ] ],
];

function _sbc_row(b) =
    let (rows = [for (r = _sbc_table()) if (r[0] == b) r])
    len(rows) > 0 ? rows[0] : undef;
function _sbc_unknown(b) = str("sbc: unknown board ", b, "; known: ", sbc_known_boards());

function sbc_size(b)          = let (r = _sbc_row(b)) assert(!is_undef(r), _sbc_unknown(b)) r[1];
function sbc_corner_radius(b) = let (r = _sbc_row(b)) assert(!is_undef(r), _sbc_unknown(b)) r[2];
function sbc_thickness(b)     = let (r = _sbc_row(b)) assert(!is_undef(r), _sbc_unknown(b)) r[3];
function sbc_holes_xy(b)      = let (r = _sbc_row(b)) assert(!is_undef(r), _sbc_unknown(b)) r[4];
function sbc_connectors(b)    = let (r = _sbc_row(b)) assert(!is_undef(r), _sbc_unknown(b)) r[5];
function sbc_connector(b, name) =
    let (cs = [for (c = sbc_connectors(b)) if (c[0] == name) c])
    assert(len(cs) > 0, str("sbc: board ", b, " has no connector ", name)) cs[0];

// Self-check: render nothing until Role-2 arrives (Task 5).
union() {}
