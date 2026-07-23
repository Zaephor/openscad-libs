// sbc — single-board-computer mechanical reference (Raspberry Pi Model-B family:
// pi3b, pi3bplus, pi4b, pi5; Raspberry Pi Zero family: pizero, pizero2w; BananaPi
// bpir4). Board outline, mounting holes, connector footprints, the placeholder
// envelope, and the hole/cutout stamp modules all ship below.
// Datum: bottom-left PCB corner at the origin, component/top side up.
// +X = board LONG edge, +Y = board SHORT edge, PCB bottom on Z=0.
// Connector exit edges: "xmin"/"xmax"/"ymin"/"ymax" (lateral — the opening faces
// out a board edge), "top" (the opening faces +Z, up off the PCB's top face —
// e.g. the GPIO header; no lateral edge is touched), or "bottom" (Task 2 — an
// underside-mounted socket, e.g. a bottom-face M.2/mPCIe connector: [x,y] is
// still the board-frame position, but z=0 sits at the board-BOTTOM plane and
// h is a DOWNWARD protrusion, i.e. the component occupies z in [-h, 0], the
// mirror image of a "top" connector). sbc_faceplate_cutouts(b, "top") cuts
// every up-facing connector in one call, same as any lateral edge; "bottom"
// connectors are never routed to a faceplate this way in practice (there is
// no chassis panel on the underside in this library's use cases so far), but
// sbc_port_cutout(b, name) still supports "bottom" directly for a future
// caller (e.g. a chassis floor cutout) — see that module's comment.
// sbc_known_edges() lists the full vocabulary.
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
// SP2: connector bodies ([w,d,h], the 3rd element of a connector row) reconciled
// against libraries/connectors/connectors.scad's catalog are now SOURCED from
// connector_size(type) instead of a literal — see RESEARCH.md "SP2 connector
// reconcile — Task 1" for the full verdict table. Only rows the table calls
// "same" (within 0.5mm of a catalog peer, 21 rows total) are adopted this way;
// every "different"/"error"/"no-peer" body stays literal (adopting an off-peer
// value would corrupt real board data — see RESEARCH.md for why no new catalog
// type was added instead). Position [x,y,z] and the edge string are always sbc's
// own and are never replaced.
use <connectors/connectors.scad>;

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
// Body sourced from connectors' gpio_2x20 (SP2 "same" verdict: Δ = +0.20,−0.08,0.00,
// well within 0.5mm; cat h=[B] is this exact sbc reading's own SP1 upgrade, no
// downgrade). Reused byte-for-byte by pi3b/pi3bplus/pi4b/pi5 (4 "same" verdict-table
// rows from this one line) — pizero/pizero2w define their own separate gpio rows below.
function _sbc_gpio() = ["gpio", [7.1, 50.0, 1.4], connector_size("gpio_2x20"), "top"];

function _sbc_table() = [
    // [A] https://datasheets.raspberrypi.com/rpi3/raspberry-pi-3-b-mechanical-drawing.pdf
    // corner radius: [A] drawing text "CORNER RADIUS = 3.0mm". thickness: no drawing
    // dimension exists on any Model-B mechanical drawing — [C] community-nominal //VERIFY.
    ["pi3b",     [85.6, 56], 3.0, 1.4,
        [[3.5,3.5,"structural-mount",2.7],[61.5,3.5,"structural-mount",2.7],
         [3.5,52.5,"structural-mount",2.7],[61.5,52.5,"structural-mount",2.7]],
        [ _sbc_gpio(),
          // right edge (xmax) USB2 stack, 2 dual-port shells stacked over Ethernet.
          // Y-spans [A] from the drawing's own bottom-referenced "10.25/29/47/56"
          // chain; X depth (w) is the brief's standard USB-A body depth [B] (drawing
          // gives no top-view X-depth text), so x is derived (85.6 - w).
          ["usb2_1",       [68.6, 29,    1.4], connector_size("usb_a_stack2_shielded"), "xmax"], // [A] pos / body sourced from connectors usb_a_stack2_shielded (SP2 "same", exact match — this cat type was derived from this very row in SP1)
          ["usb2_2",       [68.6, 47,    1.4], [17, 9,    16.0], "xmax"], // [A] pos+body (RP-008335 Y-chain "56/47/29/10.25", drawn flush to board top edge) — SP2 verdict "different" (confirmed by source, not truncation; see RESEARCH.md), left literal
          ["rj45",         [64.6, 10.25, 1.4], connector_size("rj45_shallow"), "xmax"], // [A] pos / body sourced from connectors rj45_shallow (SP2 "same", exact match — cat type derived from this very row in SP1)
          // bottom edge (ymin): X centrelines [A] off the "3.5/10.6/32/53.5" chain,
          // converted to min-corner using standard body widths [B]/[C].
          ["microusb_pwr", [6.85, 0,     1.4], [7.5, 5.5,  2.8], "ymin"], // [A] pos / [C] body //VERIFY — SP2 verdict "different" (h fails >2x threshold vs micro_usb), left literal
          ["hdmi",         [24.5, 0,     1.4], connector_size("hdmi"), "ymin"], // [A] pos / body sourced from connectors hdmi (SP2 "same", w exactly at the 0.5mm boundary)
          ["av_jack",      [50.5, 0,     1.4], [6,   6,    6.0], "ymin"], // [A] pos+h / [C] body //VERIFY — SP2 verdict "no-peer", left literal
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpi3/raspberry-pi-3-b-plus-mechanical-drawing.pdf
    // Same connector map as pi3b — pi3bplus's own drawing repeats byte-for-byte the
    // same "10.25/29/47/56" and "3.5/10.6/32/53.5" dimension chains (cross-checked
    // directly on this drawing, not merely assumed). See RESEARCH.md.
    ["pi3bplus", [85.6, 56], 3.0, 1.4,
        [[3.5,3.5,"structural-mount",2.7],[61.5,3.5,"structural-mount",2.7],
         [3.5,52.5,"structural-mount",2.7],[61.5,52.5,"structural-mount",2.7]],
        [ _sbc_gpio(),
          ["usb2_1",       [68.6, 29,    1.4], connector_size("usb_a_stack2_shielded"), "xmax"], // [A] pos / body sourced from connectors usb_a_stack2_shielded (SP2 "same", corroborates pi3b)
          ["usb2_2",       [68.6, 47,    1.4], [17, 9,    16.0], "xmax"], // [A] pos+body, corroborates pi3b usb2_2 — SP2 verdict "different" (confirmed by source, not truncation), left literal
          ["rj45",         [64.6, 10.25, 1.4], connector_size("rj45_shallow"), "xmax"], // [A] pos / body sourced from connectors rj45_shallow (SP2 "same", corroborates pi3b)
          ["microusb_pwr", [6.85, 0,     1.4], [7.5, 5.5,  2.8], "ymin"], // [A] pos / [C] body //VERIFY — SP2 verdict "different", left literal
          ["hdmi",         [24.5, 0,     1.4], connector_size("hdmi"), "ymin"], // [A] pos / body sourced from connectors hdmi (SP2 "same", corroborates pi3b)
          ["av_jack",      [50.5, 0,     1.4], [6,   6,    6.0], "ymin"], // [A] pos+h / [C] body //VERIFY — SP2 verdict "no-peer", left literal
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-mechanical-drawing.pdf
    ["pi4b",     [85.6, 56], 3.0, 1.4,
        [[3.5,3.5,"structural-mount",2.7],[61.5,3.5,"structural-mount",2.7],
         [3.5,52.5,"structural-mount",2.7],[61.5,52.5,"structural-mount",2.7]],
        [ _sbc_gpio(),
          // right edge (xmax), top-to-bottom on the real board: rj45 (near GPIO
          // corner), usb3 stack, usb2 stack (Pi4B swapped the pi3b order) — Y-spans
          // [A] off the drawing's own "9/27/45.75/56" chain.
          ["usb2",     [68.6, 9,     1.4], connector_size("usb_a_stack2_shielded"), "xmax"], // [A] pos / body sourced from connectors usb_a_stack2_shielded (SP2 "same", matches pi3b usb2_1 exactly)
          ["usb3",     [68.6, 27,    1.4], [17, 18.75, 16.0], "xmax"], // [A]/[B] — SP2 verdict "different (marginal)", d over threshold by 0.25mm, left literal pending adjudication
          ["rj45",     [64.6, 45.75, 1.4], [21, 10.25, 13.5], "xmax"], // [A] pos+body (RP-008343 Y-chain "56/45.75/27/9", visibly shorter than the USB stacks below) — SP2 verdict "different" (confirmed by source: Pi 4B's RJ45 is genuinely a shorter jack than pi3b's, not the same part), left literal
          // bottom edge (ymin): X centrelines [A] off the "3.5/7.7/14.8/13.5/7.5"
          // chain (cumulative from the left edge: 11.2, 26.0, 39.5, 47.0).
          ["usbc_pwr", [6.7,   0, 1.4], connector_size("usb_c"), "ymin"], // [A] pos / body sourced from connectors usb_c (SP2 "same", d exactly at the 0.5mm boundary)
          ["hdmi_1",   [22.25, 0, 1.4], connector_size("micro_hdmi"), "ymin"], // [A] pos / body sourced from connectors micro_hdmi (SP2 "same", exact match — this reading is the actual grounding evidence behind cat's own SP1 upgrade)
          ["hdmi_2",   [35.75, 0, 1.4], connector_size("micro_hdmi"), "ymin"], // [A] pos / body sourced from connectors micro_hdmi (SP2 "same", same as hdmi_1)
          ["av_jack",  [50.5,  0, 1.4], [6,   6,   6.0], "ymin"], // [A] h / [C] position by analogy to pi3b's 8mm hole-offset //VERIFY — SP2 verdict "no-peer", left literal
        ] ],
    // [A] https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-mechanical-drawing.pdf
    // corner radius NOT labelled on the Pi5 drawing (unlike pi3b/pi3bplus/pi4b, which all
    // print "CORNER RADIUS = 3.0mm") — carried forward from the shared family value.
    // [B] //VERIFY corner radius against a Pi5 board/case.
    ["pi5",      [85.6, 56], 3.0, 1.4,
        [[3.5,3.5,"structural-mount",2.7],[61.5,3.5,"structural-mount",2.7],
         [3.5,52.5,"structural-mount",2.7],[61.5,52.5,"structural-mount",2.7]],
        [ _sbc_gpio(),
          // right edge (xmax): usb3 dual-port stack above a combined rj45+usb2
          // "combo" shell (real Pi5 hardware: Ethernet + 2xUSB2 share one molded
          // part). Y-spans [A] off the drawing's own "10.2/29.1/47/56" chain; rj45
          // and usb2 intentionally share the same box — see RESEARCH.md.
          ["usb3",     [68.6, 29.1, 1.4], connector_size("usb_a_stack2_shielded"), "xmax"], // [A] pos / body sourced from connectors usb_a_stack2_shielded (SP2 "same", closely corroborates pi3b/pi4b family)
          ["rj45",     [64.6, 10.2, 1.4], [21, 18.9, 16.0], "xmax"], // [A] pos /[C] extent //VERIFY rj45+usb2 combo, undimensioned split — SP2 verdict "no-peer" (combo shell, board-unique), left literal
          ["usb2",     [64.6, 10.2, 1.4], [21, 18.9, 16.0], "xmax"], // [A] pos /[C] extent //VERIFY rj45+usb2 combo, undimensioned split — SP2 verdict "no-peer", left literal
          // bottom edge (ymin): X centrelines [A] off the drawing's own explicit
          // "11.2 / 25.8 / 39.2" dimensions (Pi5 prints these directly, unlike the
          // chained values on pi3b/pi4b).
          ["usbc_pwr", [6.7,   0, 1.4], connector_size("usb_c"), "ymin"], // [A] pos / body sourced from connectors usb_c (SP2 "same", same as pi4b usbc_pwr)
          ["hdmi_1",   [22.05, 0, 1.4], connector_size("micro_hdmi"), "ymin"], // [A] pos / body sourced from connectors micro_hdmi (SP2 "same", independently corroborates pi4b's reading)
          ["hdmi_2",   [35.45, 0, 1.4], connector_size("micro_hdmi"), "ymin"], // [A] pos / body sourced from connectors micro_hdmi (SP2 "same", same as hdmi_1)
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
    // chamfer. thickness: [B] caliper 1.4mm (Task 2 revision) — supersedes the prior
    // [C] 1.6mm nominal DXF-era placeholder (no thickness dimension exists anywhere in
    // the DXF/docs/product page; the caliper reading is a direct physical measurement
    // of the actual board and is the stronger source). See RESEARCH.md "Task 2 caliper
    // revision" for the full reconciliation of every dimension this changed downstream
    // (every existing connector's z, plus the front-connector height fixes below).
    // 16 mounting holes, [A] DXF PG_ASSEMBLY_HOLE_DIAM
    // layer exact circle centers (14 at 3.0mm dia, 2 at 3.32/3.31mm dia); pattern is
    // asymmetric/component-driven, not a simple corner rectangle. Roles classified
    // from DXF `M2` silkscreen text proximity + assembly-drawing component clusters
    // (conservative, tiered): 12 component-mount, 4 structural-mount, 0 keep-out —
    // see RESEARCH.md "bpi-r4 hole roles" for the full per-hole evidence table
    // (the 4 structural-mount holes were revised up from an initial "0 structural,
    // 2 keep-out" pass after a follow-up review found they form a real 4-hole
    // rectangle, see RESEARCH.md for the full reasoning).
    // Connectors: NO refdes/component-name TEXT exists anywhere in the vendor DXF (checked
    // all layers) — every position below comes from pixel-measuring the vendor assembly
    // drawing (bpir4_assembly_p1_600.png, rendered at exactly 600dpi = 23.622px/mm,
    // calibrated against the DXF's own 148.0x100.5 outline: px x=[60,3556]->mm 0..148,
    // px y=[120,2494]->mm 100.5..0 top-to-bottom) plus component datasheets in DS/ for
    // heights not visible in a top-view drawing. Full per-connector tier + which assembly
    // refdes (CN1/CN4/CN5/CN7-CN11/CN20/CN21) backs each box are in RESEARCH.md. All
    // front-panel connectors (usb, 2xSFP, WAN rj45, 3xLAN rj45, DC jack, USB-C PD) share
    // one edge, ymin (y=0) — confirmed directly off the assembly drawing.
    ["bpir4",    [148.0, 100.5], 2.0, 1.4,
        // Roles + exact per-hole dia classified from the DXF text layers +
        // vendor assembly drawing (conservative, tiered) — see RESEARCH.md
        // "bpi-r4 hole roles". Summary: 7 holes sit 3.6-5.5mm from an `M2`
        // silkscreen TEXT (DXF-exact, [A]) -> M.2-standoff component-mount;
        // the 2 larger-dia holes (3.32/3.31mm) sit next to the FAN connector
        // / VCORE-VPROC SoC-power block ([C]//VERIFY) -> component-mount;
        // 3 more sit near other component clusters (U2/SW3/CN19, VCORE/VPROC,
        // CON2/CON3) ([C]//VERIFY) -> component-mount. The remaining 4 holes
        // — (3.5,23.5), (144.5,23.5), (3.5,97), (144.5,97) — share the SAME
        // 3.5mm/144.5mm X-columns (a real rectangle spanning Y=23.5-97, DXF-
        // exact), are each confirmed CLEAR of every identified component
        // (measured gaps 2.4-13.5mm on a follow-up re-check — one, (144.5,
        // 23.5), was originally miscalled as overlapping the tentative "CN6"
        // footprint; a tighter re-crop + a dark-row pixel scan showed CN6's
        // real top edge sits ~5.5-6.9mm below this hole, not on top of it),
        // and 2 of the 4 are literal chamfered board corners. This matches
        // this SAME library's own established corner-mount convention (used
        // for every Pi/Zero row above) and is corroborated [B] by real
        // commercial/community BPI-R4 case products existing (OpenELAB/
        // YouYeeToo/WayPonDEV metal cases, a forum-documented 3D-printed
        // case whose feet "screw into the bottom" of the PCB) — i.e. this
        // board genuinely is case-mounted via its own PCB holes in practice,
        // not merely visually isolated. Tagged `structural-mount`,
        // [B]//VERIFY (not [A]: no doc pins down which exact holes a given
        // case uses). See RESEARCH.md for the full re-review that produced
        // this (an initial pass had called these "0 structural, 2 keep-out"
        // — corrected after a human-requested follow-up check). Net: 12
        // component-mount, 4 structural-mount, 0 keep-out.
        //
        // Task 2 update: the x=129.54 column (y=15.25/35.25/53.25/65.25 —
        // the first of these 4 was previously attributed to the nearby `M2`
        // silkscreen text above; the other 3 were previously attributed to
        // nearby IC clusters: U2/SW3/CN19, VCORE/VPROC, CON2/CON3) is
        // user-confirmed to actually be ONE socket's multi-length standoff
        // set: the underside M.2 Key-M SSD's screw-boss options for
        // different card lengths (2242/2260/2280/22110-style), only one of
        // which is populated depending on which physical card length is
        // installed. This does NOT overwrite the prior per-hole IC-proximity
        // notes above (kept on record — a standoff can sit near an IC
        // cluster incidentally AND serve this role; both facts are true),
        // it supersedes them for the specific question of what these 4
        // holes are FOR. Role stays `component-mount` (unchanged) for all 4.
        // See RESEARCH.md for the length-to-hole mapping attempt (physically
        // ruled out: a 22110-length card can't fit this Y-span at all,
        // >100.5mm; a tentative/unconfirmed 2280 candidate is flagged, not
        // asserted).
        [ [129.54, 15.25,"component-mount",3.0], [3.50, 23.50,"structural-mount",3.0],
          [144.50, 23.50,"structural-mount",3.0], [75.85, 27.21,"component-mount",3.32],
          [56.25, 31.59,"component-mount",3.0], [113.54, 31.59,"component-mount",3.0],
          [129.54, 35.25,"component-mount",3.0], [129.54, 53.25,"component-mount",3.0],
          [129.54, 65.25,"component-mount",3.0], [117.75, 69.11,"component-mount",3.31],
          [47.60, 75.69,"component-mount",3.0], [57.60, 75.69,"component-mount",3.0],
          [56.25, 88.30,"component-mount",3.0], [113.54, 88.30,"component-mount",3.0],
          [3.50, 97.00,"structural-mount",3.0], [144.50, 97.00,"structural-mount",3.0] ],
        [ // Front panel, left to right, all edge="ymin" (y=0), z=1.4 (Task 2:
          // thickness caliper-revised 1.6->1.4, see RESEARCH.md; every z below
          // follows). Heights below are reconciled against the Task 2 caliper's
          // "bottom-of-board -> top-of-connector" figures: h = (bottom->top) -
          // thickness, so the model's effective top (z=thickness+h) reaches the
          // real physical top face the faceplate opening needs to expose. See
          // RESEARCH.md "Task 2 caliper revision" for the full per-connector
          // reconciliation table (incl. the one row, rj45, where the caliper
          // figure is corroboration and the prior [A] datasheet h is KEPT).
          ["usb_1",       [7.41,   0, 1.4], [8.89,  23.16, 14.1], "ymin"], // CN11 (caliper-confirmed USB3 port). [B] cols/rows pixel-measured (3 independent search windows agree on 7.41/13.8/16.3) x/w; //VERIFY width still narrow vs typical USB-A 13.6mm body. h=14.1 [B] caliper Task 2: bottom->top 15.5 - thickness 1.4 (was 13.5 [C] //VERIFY placeholder)
          ["sfp_1",       [16.3,   0, 1.4], [16.51, 53.98, 10.4], "ymin"], // CN7+CN8 cage/connector pair. [B] width cross-corroborated against sfp_2 (both exactly 16.51mm); //VERIFY depth (single detector hit, SFP0074EP cage datasheet length ~50-56mm is consistent) (SP2 #21: no-peer vs connectors sfp, literal retained). h=10.4 [B] caliper Task 2: bottom->top 11.8 - thickness 1.4 (was 13.4 [C] //VERIFY placeholder; caliper "9.5 alone" figure is the cage's own standalone body height, a corroborating cross-check, not used directly since it isn't board-bottom-referenced)
          ["sfp_2",       [34.08,  0, 1.4], [16.51, 53.98, 10.4], "ymin"], // CN9+CN20+CN10. [B] width; //VERIFY depth carried over from sfp_1 (own detector pass on this cage returned no hit — symmetric-layout assumption) (SP2 #21: no-peer vs connectors sfp, literal retained). h=10.4, same Task 2 caliper reconciliation as sfp_1 (identical cage part)
          // ONE physical 4-port ganged RJ45 block (WAN + 3x LAN); "WAN X1" silk
          // marks port 1 of the block, NOT a separate connector (hardware owner,
          // 2026-07-16). Refdes is CN21 (single component) — the earlier "CN1"
          // attribution for port 1 was a misread: CN1 is a small unrelated 2-pin
          // part (silk "+", sits under the "FAN" label) whose footprint happens
          // to sit flush against CN21's own left edge; see RESEARCH.md. 4
          // evenly-pitched ports, pitch/width/depth/height [A] from the exact
          // connector datasheet bundled in BPI-R4's own DXF export
          // (`DS/RJ45x4-HRJC-M03C01C10cNL.pdf`, Haoci "1000BASE 1X4Tab-Down
          // RJ45", P/N HRJC-M03C01C10cNL): pitch=width=13.98mm, depth=21.45mm,
          // height=13.60mm. block_x0=62.61 [B] re-derived from the BPI-R4
          // assembly drawing (dark-pixel-run detector, restricted to rows below
          // CN1's footprint so CN1's box is no longer conflated with CN21's own
          // left edge) — see RESEARCH.md. Task 2 caliper cross-check: bottom->top
          // 15.1 - thickness 1.4 = 13.7, within 0.1mm of the exact-datasheet
          // h=13.60 already stored below — treated as CORROBORATION, not a
          // replacement (never downgrade an [A] exact-part datasheet figure for
          // a lower-precision caliper total-height read that already agrees to
          // within 0.1mm). Task 2 also caliper-measured the block's overall
          // 4-port physical envelope as 58.3mm(w) x 20.9mm(d) — this is
          // corroborating context only, not a schema change: it does NOT
          // replace the per-port pitch/width (13.98, still [A]
          // datasheet-exact) or depth (21.45);
          // it narrows (does not resolve) the RESEARCH.md "unreconciled gap"
          // between the pure pitch-math block end (118.53) and the drawing's
          // detector-confirmed right edge (122.77) — 62.61+58.3=120.91 sits
          // between the two. See RESEARCH.md for the full note.
          ["rj45_1",  [62.61,   0, 1.4], [13.98, 21.45, 13.60], "ymin"], // port 1 (WAN)
          ["rj45_2",  [76.59,   0, 1.4], [13.98, 21.45, 13.60], "ymin"], // port 2 (LAN)
          ["rj45_3",  [90.57,   0, 1.4], [13.98, 21.45, 13.60], "ymin"], // port 3 (LAN)
          ["rj45_4",  [104.55,  0, 1.4], [13.98, 21.45, 13.60], "ymin"], // port 4 (LAN)
          ["dc_power_1",  [124.59,  0, 1.4], [10.03,  10.71, 10.0], "ymin"], // CN4 "DC12V" barrel jack. [B] x/y envelope pixel-detected (edges shared with rj45_4/usbc_pwr_1 boundaries); [C] //VERIFY height (no top-view Z dimension; generic barrel-jack estimate; Task 2 caliper pass did not re-measure this one)
          ["usbc_pwr_1",  [134.62,  0, 1.4], [8.94,   9.95,  3.2], "ymin"], // CN5 "PD20V" USB-C PD input. [B] left edge + top edge pixel-detected; [C] //VERIFY width (generic USB-C receptacle datasheet figure, own right-edge detector pass inconclusive — see RESEARCH.md re: CN6 proximity)
          // Non-front-panel, top face (z=thickness, opens +Z, no lateral edge):
          ["uart_1",      [8.0,    10.0, 1.4], [5.0,   10.0,  6.0], "top"], // CON1 console/UART header ("G RX TX" silkscreen labels), does not touch a lateral edge. [C] //VERIFY position (visual crop read only, not pixel-detector-confirmed — search window overlapped CN11's own edges); h=6.0 [B] from Header_PIN 2.54mm.pdf body height
          // NOTE: no Pi-style 40-pin "gpio" header is modeled for bpir4 — the DXF
          // PIN_TOP layer shows NO 2x20/2.54mm THT grid anywhere, so any 40-pin
          // Pi-HAT-compatible header on this board is undimensioned in available
          // sources. Omitted rather than invented (verified-research-over-guesswork).
          // A DIFFERENT, smaller 26-pin/2.54mm header IS caliper-confirmed — see
          // gpio26_1 below; it is NOT Pi-HAT-compatible (13 columns, not 20), hence
          // the distinct name (avoids the misleading implication sharing "gpio"
          // with the Pi family's 40-pin _sbc_gpio() would create). See RESEARCH.md.
          //
          // --- Task 2 caliper additions (rear cluster + right side + sockets) ---
          // Rear cluster: all on the ymax rear wall (y=100.5), x = each item's
          // own left edge per the caliper reading's own stated convention
          // ("x=left-edge"). d/h are NOT part of the caliper reading for the two
          // buttons/LEDs (only x + width were given) — generic small-feature
          // placeholders, tier [C]//VERIFY, flagged rather than invented from a
          // specific datasheet (no button/LED part number available). SIM/microSD
          // bodies ARE sourced from connectors' T1 types (SSOT rule).
          ["reset_1", [8.3,  100.5-3.5, 1.4], [7.5, 3.5, 4.0], "ymax"], // rear-actuated reset button. [B] caliper x/w; [C] //VERIFY d/h (generic tactile-switch keep-out estimate, no datasheet)
          ["wps_1",   [18.3, 100.5-3.5, 1.4], [7.5, 3.5, 4.0], "ymax"], // rear-actuated WPS button. [B] caliper x/w; [C] //VERIFY d/h, same estimate as reset_1
          // 3x mini-SIM (2FF) trays — caliper explicitly flags these REFERENCE-ONLY
          // (weaker confidence than the rest of this pass); w=15 caliper matches
          // connectors' sim_2ff type body [15,16.3,2.7] exactly (w), corroborating
          // the type — body sourced from connector_size() per SSOT.
          ["sim_1", [27.8, 100.5-16.3, 1.4], connector_size("sim_2ff"), "ymax"], // //VERIFY reference-only per caliper notes; [B] x + w(15, exact catalog match)
          ["sim_2", [45.8, 100.5-16.3, 1.4], connector_size("sim_2ff"), "ymax"], // //VERIFY reference-only, same basis as sim_1
          ["sim_3", [64.1, 100.5-16.3, 1.4], connector_size("sim_2ff"), "ymax"], // //VERIFY reference-only, same basis as sim_1
          // microSD: caliper w=14.6 matches connectors' microsd type DEPTH field
          // (14.5, within 0.1mm) much more closely than its WIDTH field (16.44,
          // off by 1.84mm) — read as an axis-labeling ambiguity in the caliper
          // note (which axis "width" refers to isn't stated), resolved by trusting
          // the full 3-axis datasheet-sourced catalog type over a single
          // ambiguous-axis caliper figure (SSOT: use the accessor, don't invent a
          // rotated literal to force-fit one axis).
          ["microsd_1", [81.8, 100.5-14.5, 1.4], connector_size("microsd"), "ymax"], // [B] caliper x; body from connectors microsd (see axis note above)
          // 7x status LEDs, no connector type fits a point indicator LED (why-
          // comment per SSOT: connectors.scad's catalog is panel/socket bodies,
          // not indicator lights) — board-literal, tier [C]//VERIFY for d/h (only
          // x/w/pitch are caliper-given).
          ["led_1", [99.2 + 0*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"], // [B] caliper x/pitch/w; [C] //VERIFY d/h (visible lens protrusion estimate)
          ["led_2", [99.2 + 1*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"],
          ["led_3", [99.2 + 2*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"],
          ["led_4", [99.2 + 3*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"],
          ["led_5", [99.2 + 4*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"],
          ["led_6", [99.2 + 5*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"],
          ["led_7", [99.2 + 6*6.4, 100.5-1.0, 1.4], [3.2, 1.0, 1.5], "ymax"], // 7th LED; block spans x=[99.2,140.8] (41.6mm), matches caliper's "~40wide" approx
          // Right side, both "top" face (actuated/accessed from above, not a
          // lateral edge) despite sitting near the right (xmax) wall. Y positions
          // read as "value = distance from the rear wall to the box's OWN
          // rear-facing edge" (matching the X-axis "distance from left wall to
          // the box's own left-facing edge" convention used everywhere else in
          // this row) — i.e. y_max = 100.5-value, y_min = y_max-depth. Caliper
          // does not disambiguate near-vs-far edge explicitly; flagged //VERIFY
          // for that interpretation, x/w/d themselves are [B] caliper.
          ["dip_1", [148+2-10.4, 100.5-48.6-6.5, 1.4], [10.4, 6.5, 2.5], "top"], // DIP switch bank. [B] caliper position (x reconstructed from the caliper's explicit "+2mm overhang off x=148": x_max=150, x_min=150-10.4=139.6) + w/d; [C] //VERIFY h (generic slide-switch actuator height, no datasheet) and the y-edge-reference interpretation above
          // 26-pin/2.54mm header — distinct from the Pi-HAT 40-pin "gpio" family
          // (see NOTE above uart_1). No catalog type fits (connectors' gpio_2x20
          // is sized for 40-pin/20-column; this is 26-pin/13-column) — per SSOT,
          // out of scope to add a 6th connectors type this task (connectors.scad
          // closed in Task 1), so modeled as a board-specific literal instead.
          // w=13*2.54=33.02 (13-column pin-field span, same convention
          // gpio_2x20 itself uses: nCols*pitch, no added housing margin), d=2*
          // 2.54=5.08 (2-row spacing, identical to every 2.54mm header on this
          // board/family). h=6.0 reused from uart_1's own generic 2.54mm-pitch
          // pin-header datasheet (`DS/Header_PIN 2.54mm.pdf`) rather than the
          // Pi-specific gpio_2x20 h=8.5 (that figure is grounded in the
          // Raspberry-Pi-HAT-specific header part; uart_1's h=6.0 is the more
          // relevant same-board, same-generic-header-family evidence). x placed
          // flush to the right wall (148-33.02=114.98) — caliper says "right
          // wall" without an exact number, so this exact x is [C]//VERIFY
          // placement, not caliper-measured; y per the "-rear" convention above.
          ["gpio26_1", [148-33.02, 100.5-10-5.08, 1.4], [33.02, 5.08, 6.0], "top"], // [B] caliper y(10-rear) + pin-count/pitch math; [C] //VERIFY x (flush-right assumption) and h (reused generic header figure)
          // M.2 Key-B modem socket. Caliper "14 rear/3.4 left" read the same way
          // as dip_1/gpio26_1's y convention (distance from rear to the box's
          // own rear-facing edge) and the standard "x=left-edge" convention (x is
          // the box's own left/min-corner directly) used throughout this row.
          // NOTE: this position (x=3.4, near the board's LEFT edge) does not
          // spatially match the DXF-era "(47.60,75.69)/(57.60,75.69) M.2-
          // silkscreen-text-proximity hole pair" documented in RESEARCH.md's
          // hole-role section as a candidate M.2-socket standoff — that pair
          // sits at x=47.6-57.6, ~44-54mm away. Flagged as an open discrepancy
          // in RESEARCH.md rather than silently reconciled; no new mount hole is
          // added for this socket (no caliper mounting-hole data exists for any
          // new Task 2 component — see RESEARCH.md "Task 2: no new mount holes").
          ["m2modem_1", [3.4, 100.5-14-connector_size("m2_key_b")[1], 1.4], connector_size("m2_key_b"), "top"], // [B] caliper x/y; body from connectors m2_key_b (SSOT)
          // --- Underside ("bottom" edge, Task 2) ---
          // These 3 sockets were caliper-read on the FLIPPED (underside) board,
          // where left/right swap relative to the top-view frame this whole row
          // uses (underside caliper readings use flipped left/right; front/rear
          // unaffected — see the Task 2 caliper revision section above). Mirror
          // transform applied: a flipped-frame "X right" reading -> x_board = X
          // (flipped-right = board-LEFT); a flipped-frame "X left" reading ->
          // x_board = 148-X (flipped-left = board-RIGHT). "rear" readings are
          // NOT mirrored (Y is unaffected by the left/right-swap flip). See
          // RESEARCH.md "Task 2 underside-x reconstruction" for the full
          // worked math + cross-checks that confirmed this direction (not the
          // opposite one) is correct.
          //
          // mPCIe #1/#2: caliper "4.5 right" (both) -> x_board = 4.5 (mirror).
          // Sanity-checked against board-fit: the OTHER reading direction
          // (x_max=4.5, extending -X) would put x_min at -25.4, off the board
          // entirely — impossible, so x_board=4.5 must be the MIN corner, not
          // max. y from each own "N rear" (unmirrored): y_max=100.5-N,
          // y_min=y_max-d (connectors' own mpcie depth, 8.20).
          ["mpcie_1", [4.5, 100.5-41.9-connector_size("mpcie")[1], 0], connector_size("mpcie"), "bottom"], // [B] caliper x(mirrored)/y; body from connectors mpcie (SSOT). z=0 (board-bottom plane, this library's existing global Z datum) + h protrudes -Z per the bottom convention
          ["mpcie_2", [4.5, 100.5-9.2 -connector_size("mpcie")[1], 0], connector_size("mpcie"), "bottom"], // same x as mpcie_1 (two parallel slots, same left-side column, different y) — [B] caliper x(mirrored)/y; body from connectors mpcie (SSOT)
          // M.2 Key-M SSD: caliper "7.6 left" -> x_board = 148-7.6 = 140.4
          // (mirror; the OPPOSITE direction from mpcie's "right" readings,
          // since flipped-left and flipped-right mirror to opposite board
          // sides). Cross-check against the SSD's documented board position
          // ("opposite dc_power_1", x=124.59, a right-side front-panel
          // part) — 140.4 (mirrored) lands in that same right-side region,
          // while the un-mirrored alternative (7.6, near-left) would NOT;
          // this confirms "left" readings mirror too, not just "right" ones.
          // "key-right" -> the key/insertion edge is the box's own +X side,
          // so x_board=140.4 is the MAX corner (x_min = 140.4 - connector
          // width 21.9 = 118.5). Center (129.45) matches the x=129.54
          // multi-length standoff hole column (see hole-list comment above)
          // to within 0.1mm — strong independent corroboration of this
          // reconstruction. y from caliper "~2 rear" (unmirrored, same
          // convention as m2modem_1/dip_1/gpio26_1): y_max=100.5-2=98.5,
          // y_min=98.5-connectors' own m2_key_m depth(8.7)=89.8.
          ["m2_ssd_1", [140.4-connector_size("m2_key_m")[0], 100.5-2-connector_size("m2_key_m")[1], 0], connector_size("m2_key_m"), "bottom"], // [B] caliper x(mirrored)/y; body from connectors m2_key_m (SSOT). See RESEARCH.md for the multi-length (2242/2260/2280/22110) standoff-hole discussion — this connector position is independent of which length card is ultimately installed
        ] ],
    // Raspberry Pi Zero family (pizero = Zero / Zero W / Zero WH, same mechanicals;
    // pizero2w = Zero 2 W). Connector maps below are pixel-measured off each board's
    // own drawing, calibrated against that drawing's own [A] 58x23mm hole rectangle
    // (Hough-circle-detected hole centers -> exact affine mm<->px transform), so every
    // position/extent is tier [B] (precise, corroborated methodology). Note: the three
    // ymin connectors' X-CENTRES are effectively drawing-dimensioned after all — both
    // sheets' own "3.5 / 12.4 / 41.4 / 54" chain lands within ~0.1mm of the shipped
    // minihdmi/microusb_data/microusb_pwr centres — but neither sheet dimensions
    // connector body widths/depths or prints any Z-height callout (unlike the Model-B
    // family drawings), so those extents remain pixel-measured/standard-body [B]/[C]
    // and every h below is [C] //VERIFY generic connector-body figures. Full method +
    // per-connector notes in RESEARCH.md.
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
    // RESEARCH.md). The microSD card slot is likewise omitted, but not for lack of
    // drawing evidence: this sheet DOES dimension the microSD opening, on the xmin
    // (left) edge — a box protrudes ~2mm past the outline there, with Y-dimensions
    // "16.9"/"6" printed on the left margin. It's omitted because the card HOLDER
    // BODY sits on the PCB's UNDERSIDE (z<0, opposite face from the header/SoC),
    // which this top-side connector model (every connector at z=thickness) can't
    // cleanly represent, and its Z extent isn't derivable from a top-view sheet —
    // a documented scope gap, not a missing-evidence one (see RESEARCH.md).
    ["pizero",   [65, 30], 3.0, 1.4,
        [[3.5,3.5,"structural-mount",2.7],[61.5,3.5,"structural-mount",2.7],
         [3.5,26.5,"structural-mount",2.7],[61.5,26.5,"structural-mount",2.7]],
        [ // GPIO header footprint (unpopulated on base Zero, Pi-HAT-compatible 2x20/
          // 2.54mm through-hole grid) — [B] pos/extent pixel-measured (elongated slot
          // between the two ymax-side holes, inset 1.1mm from the top/ymax edge);
          // closely matches (not blind-copied from) the Model-B family's independently
          // -sourced _sbc_gpio() figures, cross-validating both readings. h=8.5 [B]
          // carried forward from the Model-B family — same physical HAT header part,
          // no Z-height text on this sheet to read directly.
          ["gpio",          [7.1,  23.9, 1.4], connector_size("gpio_2x20"), "top"], // [B] pos / body sourced from connectors gpio_2x20 (SP2 "same", corroborates the Model-B family's _sbc_gpio() reading)
          // Bottom edge (ymin), left-to-right real layout: mini-HDMI, then the two
          // micro-USB ports nearest the right corner — [B] pos+extent pixel-measured,
          // all three boxes' bottom edges sit right on the y=0 line (snapped to 0).
          ["minihdmi",      [6.9,  0,    1.4], connector_size("mini_hdmi"), "ymin"], // [B] pos / body sourced from connectors mini_hdmi (SP2 "same", w+d both exactly at the 0.5mm boundary — cat itself is [C]//VERIFY cited-not-fetched, so this corroborates rather than upgrades; //VERIFY carried forward, see RESEARCH.md)
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
    // Connectors, own-drawing pixel-measurement (rendered at 2x source scale, at
    // high resolution for a cleaner pixel read; same hole-grid-calibrated method as
    // pizero above, independently re-run on this sheet's own hole centers, not
    // copied from the pizero row) — layout confirmed to match pizero closely
    // (mini-HDMI/microUSB pair boxes agree with pizero's to within ~0.3mm) but
    // verified on its own terms per the brief, not blind-copied. Same no-Z-height-
    // text gap as pizero, so every h below is [C] //VERIFY.
    ["pizero2w", [65, 30], 3.0, 1.4,
        [[3.5,3.5,"structural-mount",2.7],[61.5,3.5,"structural-mount",2.7],
         [3.5,26.5,"structural-mount",2.7],[61.5,26.5,"structural-mount",2.7]],
        [ // GPIO header — this sheet actually renders the 2x20 pin circles (unlike
          // pizero's plain unpopulated-slot outline), but position/extent match
          // pizero's own reading closely ([B] pixel-measured independently here).
          ["gpio",          [7.2,  23.9, 1.4], connector_size("gpio_2x20"), "top"], // [B] pos / body sourced from connectors gpio_2x20 (SP2 "same", corroborates pizero's gpio reading)
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
function sbc_connectors(b)    = let (r = _sbc_row(b)) assert(!is_undef(r), _sbc_unknown(b)) r[5];

// --- hole roles (Task: hole-role tagging) ---
function sbc_known_hole_roles() = ["structural-mount", "component-mount", "keep-out", "alignment"];

// --- connector exit edges (Task 2: bottom-face convention) ---
function sbc_known_edges() = ["xmin", "xmax", "ymin", "ymax", "top", "bottom"];

// Distinct roles actually present on a board's holes (order of the vocabulary).
function _sbc_roles_present(b) =
    let (hs = _sbc_row(b)[4])
    [for (rr = sbc_known_hole_roles()) if (len([for (h = hs) if (h[2] == rr) h]) > 0) rr];

// Full hole tuples [x,y,role,dia], filtered by role.
//   role a canonical role  -> only that role
//   role == "all"          -> every hole, silent (explicit intent)
//   role == undef (omitted) -> every hole, PLUS a WARNING when >1 role present
//   unknown role string    -> assert
function sbc_holes(b, role = undef) =
    let (r = _sbc_row(b))
    assert(!is_undef(r), _sbc_unknown(b))
    let (hs = r[4],
         present = _sbc_roles_present(b),
         _warn = (is_undef(role) && len(present) > 1)
             ? echo(str("WARNING: sbc '", b, "' holes span ", len(present),
                        " role categories ", present,
                        "; no role filter selected — returning all. ",
                        "Pass a role (e.g. \"structural-mount\") or \"all\" to silence."))
             : undef,
         sel = is_undef(role) ? "all" : role)
    assert(sel == "all"
        || len([for (rr = sbc_known_hole_roles()) if (rr == sel) rr]) == 1,
        str("sbc: unknown hole role '", sel, "'; known: ", sbc_known_hole_roles()))
    sel == "all" ? hs : [for (h = hs) if (h[2] == sel) h];

// Role of the i-th hole (index into the board's full hole list).
function sbc_hole_role(b, i) =
    let (r = _sbc_row(b))
    assert(!is_undef(r), _sbc_unknown(b))
    r[4][i][2];

// Backward-compatible [x,y]-only accessor, role-filterable.
function sbc_holes_xy(b, role = undef) = [for (h = sbc_holes(b, role)) [h[0], h[1]]];
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
            // Connector bodies. "bottom" connectors protrude -Z from z=0 (the
            // board-bottom plane) rather than growing +Z/+X/+Y from c[1] like
            // every other edge — translate down by the full height first so
            // the cube occupies z in [-h, 0], not [0, h] (which would grow
            // the wrong direction, up into the board).
            for (c = sbc_connectors(b))
                if (c[3] == "bottom")
                    translate([c[1][0], c[1][1], c[1][2] - c[2][2]]) cube(c[2]);
                else
                    translate(c[1]) cube(c[2]);
        }
        for (h = sbc_holes(b, "all"))
            translate([h[0], h[1], -1]) cylinder(h = t + 2, d = h[3]);
    }
}

/* [Hole-stamp / cutout] */
SBC_OVERLAP = 0.5; // mm back-overlap so cutouts meet the board cleanly.

// Mount clearance holes; use inside a consumer difference().
module sbc_mount_holes(b, depth = 20, role = undef, dia = -1) {
    for (h = sbc_holes(b, role))
        translate([h[0], h[1], -1])
            cylinder(h = depth + 2, d = dia < 0 ? h[3] : dia);
}

// Positive standoff posts (print a tray directly). Pilot bore subtracted.
module sbc_standoffs(b, height, role = undef, dia = -1, bore = -1) {
    od = dia  < 0 ? 6.0 : dia;   // post OD default //VERIFY [C] vs hardware standoff
    bd = bore < 0 ? 2.2 : bore;  // pilot for M2.5 self-tap //VERIFY [C]
    for (h = sbc_holes(b, role))
        translate([h[0], h[1], 0]) difference() {
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
    // "bottom" (Task 2): mirror image of "top" — the body occupies
    // z in [p[2]-s[2], p[2]] (growing -Z from the board-bottom plane), so
    // the cutout extrudes further -Z, overlapping "o" into the body's own
    // bottom face. No consumer calls this with edge="bottom" today (bottom
    // parts aren't routed through sbc_faceplate_cutouts in practice), but it
    // is supported directly so a future caller isn't blocked by an assert.
    else if (e == "bottom") translate([p[0], p[1], p[2]-s[2]-depth]) cube([s[0], s[1], depth+o]);
    else assert(false, str("sbc: connector ", name, " has bad edge ", e));
}

// All connectors on an edge → the full panel for that edge (e.g. a router faceplate).
module sbc_faceplate_cutouts(b, edge, depth = 20) {
    for (c = sbc_connectors(b)) if (c[3] == edge) sbc_port_cutout(b, c[0], depth);
}

// Visual self-check when opened directly.
sbc_placeholder("pi4b");
