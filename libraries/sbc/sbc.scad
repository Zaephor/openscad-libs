// sbc — single-board-computer mechanical reference (Raspberry Pi Model-B family:
// pi3b, pi3bplus, pi4b, pi5; Raspberry Pi Zero family: pizero, pizero2w; BananaPi
// bpir4). Board outline, mounting holes, connector footprints, the placeholder
// envelope, and the hole/cutout stamp modules all ship below.
// Datum: bottom-left PCB corner at the origin, component/top side up.
// +X = board LONG edge, +Y = board SHORT edge, PCB bottom on Z=0.
// Connector exit edges: "xmin"/"xmax"/"ymin"/"ymax" (lateral — the opening faces
// out a board edge) or "top" (the opening faces +Z, up off the PCB's top face —
// e.g. the GPIO header; no lateral edge is touched). sbc_faceplate_cutouts(b,
// "top") cuts every up-facing connector in one call, same as any lateral edge.
// Roles (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / table lookups
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — sbc_placeholder(b): envelope solid for fit checks
//   3. Hole-stamp / cutout — sbc_mount_holes(b), sbc_standoffs(b), sbc_port_cutout(b,
//                    name), sbc_faceplate_cutouts(b, edge): mounting holes + connector
//                    opening stamps for a consumer difference()
// Provenance: [A] vendor official mechanical drawing/STEP/DXF (raspberrypi.com,
// docs.banana-pi.org, ...), [B] multi-peer
// community corroboration, [C] single community STL/reverse-engineered. //VERIFY
// marks weak/unconfirmed values. See RESEARCH.md for full source list + notes.
// Units: millimeters.

$fn = 48;

/* [Data] */
function sbc_known_boards() = ["pi3b", "pi3bplus", "pi4b", "pi5", "bpir4", "pizero", "pizero2w"];

function sbc_hole_dia() = 2.7; // mm, M2.5 clearance.  [A] Pi4/Pi5 drawings label "Ø2.7";
    // Pi3B drawing calls out "4x M2.5 MOUNTING HOLES DRILLED TO 2.75 +/-0.05mm" (same
    // feature, 0.05mm drilling-tolerance difference from the Pi4/Pi5 label) — see RESEARCH.md.

// Row: [key, [x,y], corner_r, thickness, [[hx,hy],...holes], [connectors...]]
// Connectors are [name, [x,y,z], [w,d,h], edge].
// All four boards share the 58x49mm 4-hole rectangle inset 3.5mm and the outline below —
// confirmed directly against each board's own raspberrypi.com mechanical drawing (identical
// "85 / 58 / 29 / 3.5 / 49 / 56" dimension chain on all four; hole coords + Y outline are
// [A] exact drawing values). X outline: drawings print "85" (whole-mm rounding on all four);
// 85.6 is the widely multi-peer-corroborated precise classic figure — [B], not read directly
// off the drawing. See RESEARCH.md for the full per-value tier breakdown + sources.
// Connectors: [name, [x,y,z], [w,d,h], edge] — [x,y,z] is the box MINIMUM corner,
// [w,d,h] are extents along X/Y/Z, edge is "xmin"/"xmax"/"ymin"/"ymax" (the board
// edge the opening faces, lateral) or "top" (the opening faces +Z, no board edge).
// z is always sbc_thickness(b) (connectors sit on the PCB top face). h is read
// directly off each drawing's own "Z-Height=" / "Z=" callout where present — [A],
// very reliable, independent of the X/Y position tiering. Full per-connector
// source/tier notes (which offsets are [A] read-off-drawing vs [B] standard-body
// estimate vs [C]//VERIFY) are in RESEARCH.md; only a short tag is given inline
// here. GPIO header X/Y/edge is read directly off the pi3b drawing ([A]: header
// box left edge pixel-measured at x=7.1 against the drawing's own left-edge/hole-
// centerline dimension chain — corrected in final review; an earlier pass had
// misread "x=1.5", which is actually the AERIAL antenna connector's centerline,
// a different feature entirely. x=7.1 also matches the well-known Raspberry Pi
// HAT-spec header inset figure. y/d are read off the header box's own top/bottom
// edges relative to the board's top edge line: box spans y=50.0..55.0, i.e. inset
// 1.0mm from the board's top (ymax) edge — the header opens upward (+Z) off the
// board's top face, not out a lateral edge, so edge="top" (see header comment).
// h=8.5 from the "Z-Height=8.5"/"Z=8.5" callout printed on pi3b/pi3bplus/pi4b) and
// carried forward byte-for-byte onto pi3bplus/pi5 [B] — the 40-pin header position
// is fixed across the whole family by the Raspberry Pi HAT mechanical spec, so reuse
// here is a compatibility requirement, not a guess.
function _sbc_gpio() = ["gpio", [7.1, 50.0, 1.4], [51.0, 5.0, 8.5], "top"];

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
    // BananaPi BPI-R4 (standard variant: 2x SFP + 4x RJ45, MTK MT7988A, 4G/8G RAM —
    // RAM size doesn't change the PCB). [A] vendor mechanical DXF, "BPI-R4-Main-V11"
    // (BPI-R4-Main-V11-DXF/BPI-R4-Main-V11_TOP.dxf), via docs.banana-pi.org's
    // Google-Drive-hosted "BPI-R4 DXF file" link — see RESEARCH.md. Outline read
    // directly off the DXF's BG_DESIGN_OUTLINE polyline: bbox 148.0 x 100.5mm exactly
    // (the brief's ~148.5 figure is NOT what the drawing shows; using the confirmed
    // 148.0). Real corners are a 2x2mm 45-degree CHAMFER (an 8-point polygon), not a
    // fillet — corner_r=2.0 below is the closest approximation the shared hull()
    // rounded-rect placeholder geometry supports, //VERIFY visual-only, not a true
    // chamfer. thickness: no dimension found anywhere (DXF, docs, product page) —
    // [C] 1.6mm nominal //VERIFY (standard multilayer-PCB thickness assumption; this
    // board is a heavier router design than the RPi family's carried-forward 1.4mm,
    // not reused from those rows). 16 mounting holes, [A] DXF PG_ASSEMBLY_HOLE_DIAM
    // layer exact circle centers (14 at 3.0mm dia, 2 at ~3.3mm dia — see RESEARCH.md);
    // pattern is asymmetric/component-driven, not a simple corner rectangle.
    // Connectors: NO refdes/component-name TEXT exists anywhere in the vendor DXF (checked
    // all layers) — every position below comes from pixel-measuring the vendor assembly
    // drawing (bpir4_assembly_p1_600.png, rendered at exactly 600dpi = 23.622px/mm,
    // calibrated against the DXF's own 148.0x100.5 outline: px x=[60,3556]->mm 0..148,
    // px y=[120,2494]->mm 100.5..0 top-to-bottom) plus component datasheets in DS/ for
    // heights not visible in a top-view drawing. Full per-connector tier + which assembly
    // refdes (CN1/CN4/CN5/CN7-CN11/CN20/CN21) backs each box are in RESEARCH.md. All
    // front-panel connectors (usb, 2xSFP, WAN rj45, 3xLAN rj45, DC jack, USB-C PD) share
    // one edge, ymin (y=0) — confirmed directly off the assembly drawing.
    ["bpir4",    [148.0, 100.5], 2.0, 1.6,
        [ [129.54, 15.25], [3.50, 23.50], [144.50, 23.50], [75.85, 27.21],
          [56.25, 31.59], [113.54, 31.59], [129.54, 35.25], [129.54, 53.25],
          [129.54, 65.25], [117.75, 69.11], [47.60, 75.69], [57.60, 75.69],
          [56.25, 88.30], [113.54, 88.30], [3.50, 97.00], [144.50, 97.00] ],
        [ // Front panel, left to right, all edge="ymin" (y=0), z=1.6:
          ["usb_1",       [7.41,   0, 1.6], [8.89,  23.16, 13.5], "ymin"], // CN11. [B] cols/rows pixel-measured (3 independent search windows agree on 7.41/13.8/16.3); //VERIFY width narrow vs typical USB-A 13.6mm body — see RESEARCH.md
          ["sfp_1",       [16.3,   0, 1.6], [16.51, 53.98, 13.4], "ymin"], // CN7+CN8 cage/connector pair. [B] width cross-corroborated against sfp_2 (both exactly 16.51mm); //VERIFY depth (single detector hit, SFP0074EP cage datasheet length ~50-56mm is consistent)
          ["sfp_2",       [34.08,  0, 1.6], [16.51, 53.98, 13.4], "ymin"], // CN9+CN20+CN10. [B] width; //VERIFY depth carried over from sfp_1 (own detector pass on this cage returned no hit — symmetric-layout assumption)
          ["rj45_1",      [60.0,   0, 1.6], [8.0,   20.0,  13.5], "ymin"], // CN1 "WAN X1". [C] //VERIFY — right edge pixel-detected (62.6-63.1), left/top read visually off gridded crop; an internal line at y~10 (pin1/polarity mark, not full box border) creates residual ambiguity — see RESEARCH.md
          ["rj45_2",      [68.0,      0, 1.6], [18.2567, 19.05, 13.5], "ymin"], // CN21 "LAN X3" port 1 of 3, even trisection of the measured 54.77mm envelope. [B] envelope (both edges pixel-detected, shared with rj45_1/dc_power_1 boundaries) / [C] per-port split //VERIFY (no internal divider dimensioned)
          ["rj45_3",      [86.2567,   0, 1.6], [18.2567, 19.05, 13.5], "ymin"], // CN21 port 2 of 3 — see rj45_2
          ["rj45_4",      [104.5133,  0, 1.6], [18.2567, 19.05, 13.5], "ymin"], // CN21 port 3 of 3 — see rj45_2
          ["dc_power_1",  [124.59,  0, 1.6], [10.03,  10.71, 10.0], "ymin"], // CN4 "DC12V" barrel jack. [B] x/y envelope pixel-detected (edges shared with rj45_4/usbc_pwr_1 boundaries); [C] //VERIFY height (no top-view Z dimension; generic barrel-jack estimate)
          ["usbc_pwr_1",  [134.62,  0, 1.6], [8.94,   9.95,  3.2], "ymin"], // CN5 "PD20V" USB-C PD input. [B] left edge + top edge pixel-detected; [C] //VERIFY width (generic USB-C receptacle datasheet figure, own right-edge detector pass inconclusive — see RESEARCH.md re: CN6 proximity)
          // Non-front-panel:
          ["uart_1",      [8.0,    10.0, 1.6], [5.0,   10.0,  6.0], "top"], // CON1 console/UART header ("G RX TX" silkscreen labels), does not touch a lateral edge. [C] //VERIFY position (visual crop read only, not pixel-detector-confirmed — search window overlapped CN11's own edges); h=6.0 [B] from Header_PIN 2.54mm.pdf body height
          // NOTE: no Pi-style 40-pin "gpio" header is modeled for bpir4 — the DXF
          // PIN_TOP layer shows NO 2x20/2.54mm THT grid anywhere, so any GPIO/pin
          // header on this board is undimensioned in available sources. Omitted
          // rather than invented (verified-research-over-guesswork). See RESEARCH.md.
        ] ],
    // Raspberry Pi Zero family (pizero = Zero / Zero W / Zero WH, same mechanicals;
    // pizero2w = Zero 2 W). Connector maps below are pixel-measured off each board's
    // own drawing, calibrated against that drawing's own [A] 58x23mm hole rectangle
    // (Hough-circle-detected hole centers -> exact affine mm<->px transform), so every
    // position/extent is tier [B] (precise, corroborated methodology) even though
    // NEITHER sheet prints per-connector dimension text or Z-height callouts (unlike
    // the Model-B family drawings) — heights are therefore [C] //VERIFY generic
    // connector-body figures. Full method + per-connector notes in RESEARCH.md.
    // [A] vendor mechanical drawings, both confirmed
    // directly (not carried across boards blind): outline 65x30, corner radius
    // 3.0mm, and the 58x23mm 4-hole rectangle inset 3.5mm from ALL FOUR edges
    // (not just two — verified via the drawings' own dimension chains: X chain
    // "65 / 58 / 29" and the connector-position chain "3.5 / 12.4 / 41.4 / 54"
    // both read off the LEFT edge put the hole columns at x={3.5,61.5}, i.e.
    // 65-61.5=3.5 on the right too; Y chain "30 / 23 / 3.5" (top) + the mirrored
    // "3.5" (bottom) put the hole rows at y={3.5,26.5}, i.e. 30-26.5=3.5 on the
    // bottom too). thickness: neither drawing dimensions bare-PCB thickness (no
    // side view on either sheet) — [C] 1.4mm nominal //VERIFY, same treatment as
    // the Model-B family. See RESEARCH.md for the full per-value tier breakdown.
    // [A] https://datasheets.raspberrypi.com/rpizero/raspberry-pi-zero-mechanical-drawing.pdf
    // ("RASPBERRY PI ZERO", ref RPI-ZERO-V1_2, dated 23/09/2015). Corner radius:
    // [A] drawing text "CORNER RADIUS = 3.0mm". Hole dia callout on this sheet:
    // "4x M2.5 MOUNTING HOLES DRILLED TO 2.75 +/- 0.05mm" (same feature as the
    // Model-B rows' sbc_hole_dia(), not stored per-row).
    // Connectors, all pixel-measured [B] against this sheet's own hole grid (see
    // header note above for method); no Z-height text exists anywhere on this sheet
    // (checked the full page, incl. title block) so every h is a generic connector-
    // body estimate [C] //VERIFY. This is the RPI-ZERO-V1_2 (23/09/2015) drawing —
    // it PRE-DATES the physical CSI camera connector added in HW rev 1.3 (mid-2016);
    // the board's right edge (xmin..xmax between the two right holes) reads as a
    // plain straight line on this sheet, no connector or notch present — so "csi" is
    // deliberately omitted for this row (verified absent, not merely unsearched; see
    // RESEARCH.md). The microSD card slot is likewise omitted: real Pi Zero boards
    // mount it on the PCB's UNDERSIDE (opposite face from the header/SoC), but this
    // sheet is a single "TOP ASSEMBLY" view with no bottom view anywhere on the page
    // — there is no drawing evidence to position it from, so it's a documented gap,
    // not a guess (see RESEARCH.md).
    ["pizero",   [65, 30], 3.0, 1.4, [[3.5,3.5],[61.5,3.5],[3.5,26.5],[61.5,26.5]],
        [ // GPIO header footprint (unpopulated on base Zero, Pi-HAT-compatible 2x20/
          // 2.54mm through-hole grid) — [B] pos/extent pixel-measured (elongated slot
          // between the two ymax-side holes, inset 1.1mm from the top/ymax edge);
          // closely matches (not blind-copied from) the Model-B family's independently
          // -sourced _sbc_gpio() figures, cross-validating both readings. h=8.5 [B]
          // carried forward from the Model-B family — same physical HAT header part,
          // no Z-height text on this sheet to read directly.
          ["gpio",          [7.1,  23.9, 1.4], [51.0, 5.0, 8.5], "top"], // [B]/[B] h
          // Bottom edge (ymin), left-to-right real layout: mini-HDMI, then the two
          // micro-USB ports nearest the right corner — [B] pos+extent pixel-measured,
          // all three boxes' bottom edges sit right on the y=0 line (snapped to 0).
          ["minihdmi",      [6.9,  0,    1.4], [10.9, 7.0, 3.4], "ymin"], // [B] pos+extent / [C] h //VERIFY generic mini-HDMI (Type C) shell height
          ["microusb_data", [37.7, 0,    1.4], [7.5,  4.7, 2.8], "ymin"], // [B] pos+extent (silkscreen "USB", left of the pair) / [C] h reused from pi3b's microUSB-B figure
          ["microusb_pwr",  [50.3, 0,    1.4], [7.6,  4.7, 2.8], "ymin"], // [B] pos+extent (silkscreen "PWR IN", right of the pair, nearest the corner hole) / [C] h as above
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpizero2/raspberry-pi-zero-2-w-mechanical-drawing.pdf
    // (the rpizero2w/ path 404s; the working path is rpizero2/ — resolves to
    // pip.raspberrypi.com/documents/RP-008358-DS-raspberry-pi-zero-2-w-mechanical-drawing.pdf;
    // "Zero 2 Mechanical drawing", 2021-10-28). Matches lib.json + RESEARCH.md.
    // Outline + hole rectangle independently confirmed on THIS drawing's own dimension
    // chain (identical "65 / 29 / 23 / 3.5 x4 / 12.4 / 41.4 / 54" figures to pizero,
    // not blind-copied) — see RESEARCH.md. Corner radius: this sheet has NO
    // "CORNER RADIUS" callout anywhere (checked the full page, unlike the pizero
    // sheet) — same gap as the pi5 row above; value carried forward from pizero's
    // [A] 3.0mm, tier [B] //VERIFY here. Sheet also omits the mounting-hole-diameter
    // callout and any title block (single-view page, no logo/date/ref box).
    // Connectors, own-drawing pixel-measurement (rendered at 2x source scale via
    // pdftoppm -r 600 for a cleaner pixel read; same hole-grid-calibrated method as
    // pizero above, independently re-run on this sheet's own hole centers, not
    // copied from the pizero row) — layout confirmed to match pizero closely
    // (mini-HDMI/microUSB pair boxes agree with pizero's to within ~0.3mm) but
    // verified on its own terms per the brief, not blind-copied. Same no-Z-height-
    // text gap as pizero, so every h below is [C] //VERIFY.
    ["pizero2w", [65, 30], 3.0, 1.4, [[3.5,3.5],[61.5,3.5],[3.5,26.5],[61.5,26.5]],
        [ // GPIO header — this sheet actually renders the 2x20 pin circles (unlike
          // pizero's plain unpopulated-slot outline), but position/extent match
          // pizero's own reading closely ([B] pixel-measured independently here).
          ["gpio",          [7.2,  23.9, 1.4], [50.6, 4.9, 8.5], "top"], // [B]/[B] h carried forward, see pizero row
          // Bottom edge (ymin): same three-connector cluster as pizero, independently
          // measured on this sheet — mini-HDMI then the two micro-USB ports.
          ["minihdmi",      [7.1,  0,    1.4], [10.8, 6.8, 3.4], "ymin"], // [B] pos+extent / [C] h //VERIFY, see pizero row
          ["microusb_data", [37.7, 0,    1.4], [7.4,  4.6, 2.8], "ymin"], // [B] pos+extent (silkscreen "USB") / [C] h
          ["microusb_pwr",  [50.3, 0,    1.4], [7.4,  4.6, 2.8], "ymin"], // [B] pos+extent (silkscreen "PWR IN") / [C] h
          // CSI camera FPC connector: right edge (xmax), a distinct notch cut into
          // the board outline itself between the two right-side mounting holes
          // (stepped/tabbed channel, clearly deliberate — not present on pizero's
          // v1.2 sheet, consistent with CSI being added in HW rev 1.3). Position
          // [B] pixel-measured directly off this notch. //VERIFY: this drawing gives
          // no refdes/label confirming the notch IS the CSI connector rather than a
          // mechanical/antenna keep-out channel — flagged as the weakest-sourced
          // record in this file's Pi Zero rows (see RESEARCH.md); included per the
          // brief's allowance to map CSI "if the drawing shows it" rather than omit,
          // since position + shape strongly match the known family CSI location.
          ["csi",           [61.7, 6.9,  1.4], [3.3, 16.0, 1.5], "xmax"], // [B] pos+extent (notch) / [C] h //VERIFY generic low-profile FPC connector height
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

/* [Placeholder] */
// PCB slab (rounded corners) + connector bodies; mounting holes as keep-outs.
// Corner datum: board in +X/+Y, bottom on Z=0.
module sbc_placeholder(b) {
    sz = sbc_size(b); r = sbc_corner_radius(b); t = sbc_thickness(b);
    difference() {
        union() {
            // Rounded-rect PCB via a minkowski-free hull of 4 corner cylinders.
            hull() for (x = [r, sz[0]-r], y = [r, sz[1]-r])
                translate([x, y, 0]) cylinder(h = t, r = r);
            // Connector bodies.
            for (c = sbc_connectors(b)) translate(c[1]) cube(c[2]);
        }
        for (p = sbc_holes_xy(b))
            translate([p[0], p[1], -1]) cylinder(h = t + 2, d = sbc_hole_dia());
    }
}

/* [Hole-stamp / cutout] */
SBC_OVERLAP = 0.5; // mm back-overlap so cutouts meet the board cleanly.

// Mount clearance holes; use inside a consumer difference().
module sbc_mount_holes(b, depth = 20, dia = -1) {
    d = dia < 0 ? sbc_hole_dia() : dia;
    for (p = sbc_holes_xy(b))
        translate([p[0], p[1], -1]) cylinder(h = depth + 2, d = d);
}

// Positive standoff posts (print a tray directly). Pilot bore subtracted.
module sbc_standoffs(b, height, dia = -1, bore = -1) {
    od = dia  < 0 ? 6.0 : dia;   // post OD default //VERIFY [C] vs hardware standoff
    bd = bore < 0 ? 2.2 : bore;  // pilot for M2.5 self-tap //VERIFY [C]
    for (p = sbc_holes_xy(b))
        translate([p[0], p[1], 0]) difference() {
            cylinder(h = height, d = od);
            translate([0, 0, -1]) cylinder(h = height + 2, d = bd);
        }
}

// One connector's panel opening, extruded outward along its exit edge.
module sbc_port_cutout(b, name, depth = 20) {
    c = sbc_connector(b, name); p = c[1]; s = c[2]; e = c[3];
    o = SBC_OVERLAP;
    if      (e == "xmax") translate([p[0]+s[0]-o, p[1], p[2]]) cube([depth+o, s[1], s[2]]);
    else if (e == "xmin") translate([p[0]-depth,  p[1], p[2]]) cube([depth+o, s[1], s[2]]);
    else if (e == "ymax") translate([p[0], p[1]+s[1]-o, p[2]]) cube([s[0], depth+o, s[2]]);
    else if (e == "ymin") translate([p[0], p[1]-depth,  p[2]]) cube([s[0], depth+o, s[2]]);
    else if (e == "top")  translate([p[0], p[1], p[2]+s[2]-o]) cube([s[0], s[1], depth+o]);
    else assert(false, str("sbc: connector ", name, " has bad edge ", e));
}

// All connectors on an edge → the full panel for that edge (e.g. a router faceplate).
module sbc_faceplate_cutouts(b, edge, depth = 20) {
    for (c = sbc_connectors(b)) if (c[3] == edge) sbc_port_cutout(b, c[0], depth);
}

// Visual self-check when opened directly.
sbc_placeholder("pi4b");
