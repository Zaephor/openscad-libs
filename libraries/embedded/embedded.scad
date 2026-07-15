// embedded — ESP32/ESP8266 microcontroller dev-board mechanical reference
// (esp32_devkitc, esp8266_nodemcu, wemos_d1_mini, esp32_c3_devkitm,
// esp32_s3_devkitc). Board outline, corner radius, PCB thickness, mounting-hole
// geometry (or its documented absence), and USB/pin-header/module connector
// footprints. Schema mirrors the `sbc` library exactly (see docs/
// LIBRARY-AUTHORING.md). Mechanical mounting/clearance geometry only.
// Datum: bottom-left PCB corner at the origin, component/top side up.
// +X = board LONG edge, +Y = board SHORT edge, PCB bottom on Z=0.
// Connector exit edges: "xmin"/"xmax"/"ymin"/"ymax" (lateral — the opening
// faces out a board edge) or "top" (the opening faces +Z, up off the PCB's
// top face — pin headers, on-board modules/antenna keep-outs; no lateral
// edge is touched).
// Roles (see docs/LIBRARY-AUTHORING.md):
//   1. Data — functions returning constants / table lookups
//             (expose as functions: OpenSCAD `use` does not import variables)
//   Placeholder / hole-stamp / cutout modules are deferred to later tasks
//   (Task 3: embedded_placeholder()/embedded_mount_holes(); Task 4: connector
//   cutouts) — this file is Role-1 (data + accessors) only for now.
// Provenance: [A] vendor official mechanical drawing/datasheet (dl.espressif.com,
// espressif.com, wemos.cc), [B] multi-peer community corroboration, [C] single
// community source or derived. //VERIFY marks weak/unconfirmed values. See
// RESEARCH.md for the full source list, per-value tier breakdown, and the
// reconstruction notes for every derived (non-verbatim) coordinate below.
// Units: millimeters.

$fn = 48;

/* [Data] */
function embedded_known_boards() =
    ["esp32_devkitc", "esp8266_nodemcu", "wemos_d1_mini", "esp32_c3_devkitm", "esp32_s3_devkitc"];

// Row: [key, [x,y], corner_r, thickness, [[hx,hy,role,dia],...holes], [connectors...]]
// Connectors are [name, [x,y,z], [w,d,h], edge] — [x,y,z] is the box MINIMUM
// corner, [w,d,h] are extents along X/Y/Z, edge is "xmin"/"xmax"/"ymin"/"ymax"
// (lateral, opening faces that board edge) or "top" (opens +Z, no lateral
// edge touched). z is always embedded_thickness(b) (connectors sit on the PCB
// top face), same convention as sbc.scad.
//
// Every board here is a "stick" board (per RESEARCH.md's adopted convention):
// USB at xmin (X=0), RF module/PCB-antenna keep-out at xmax, two single-row
// 2.54mm pin headers running the long edges, both edge="top" (never lateral —
// like sbc's gpio). USB body [w,d,h] and USB-C body [w,d,h] are taken from
// connectors.scad's own [A] micro_usb ([7.72,5.48,3.96]) / usb_c ([8.94,6.90,
// 3.16]) table rows (RESEARCH.md's own connectors-lib mapping), with w/d
// swapped from that library's canonical "+Y opening" frame into this board's
// "opens along X" frame (xmin/xmax edge): board w(X-extent) = connectors-lib
// d, board d(Y-extent) = connectors-lib w. Header body length = pins x 2.54mm,
// width ~2.54mm, height ~2.5mm — all [C]//VERIFY per RESEARCH.md's own "Pin
// headers" note. Connector X/Y positions are NOT individually dimensioned in
// any source RESEARCH.md found ("Exact per-pin X/Y origins are Task 2/4's to
// finalize from the drawings" — RESEARCH.md, "Pin headers" section); every
// position below is this task's own placement estimate (centered-in-Y for
// USB, edge-inset-derived for headers, flush-to-board-end for modules),
// tagged [C]//VERIFY and NOT claimed as a verbatim drawing read. Only the
// board outline / corner radius / thickness / mounting-hole geometry / bare
// connector-body [w,d,h] extents are verbatim RESEARCH.md values.
function _embedded_table() = [
    // esp32_devkitc — ESP32-DevKitC V4 (ESP-WROOM-32, 38-pin).
    // [A] esp32_devkitc_v4_dimensions.pdf. Outline 48.26x27.94 [A]; corners
    // drawn square, no radius callout -> corner_r=0 [A]//VERIFY (real board
    // may have a small unlabelled manufacturing break). thickness: not
    // dimensioned (top-view only) -> 1.6 [C]//VERIFY nominal 2-layer stock.
    // Mounting holes: NONE [A] (drawing shows only the two header rows).
    ["esp32_devkitc", [48.26, 27.94], 0, 1.6,
        [],
        [ // usb: micro-USB on xmin, roughly centered in Y [A type]/[C pos //VERIFY,
          // drawing shows the footprint but doesn't dimension its offset].
          // Body [5.48,7.72,3.96] = connectors-lib micro_usb [A] w/d-swapped (see header note).
          ["usb", [0, 10.11, 1.6], [5.48, 7.72, 3.96], "xmin"],
          // header_l/header_r: 19 pins/row (38 total), 2.54mm pitch [A],
          // edge="top". Length 19*2.54=48.26 [A pitch/count]; row insets
          // [C]//VERIFY (RESEARCH.md: DevKitC "places rows just inside the
          // long edges", no dimensioned spacing given) — using a 1.3mm inset.
          ["header_l", [0, 1.30,  1.6], [48.26, 2.54, 2.5], "top"],
          ["header_r", [0, 24.10, 1.6], [48.26, 2.54, 2.5], "top"],
          // ESP-WROOM-32 module: 25.40x18.00mm outline [A] at the xmax end,
          // "RF Antenna" keep-out protruding a further 6.04mm [A] past the
          // module toward the board end. Reconstructed flush to the board's
          // physical xmax edge (module+keepout = 31.44mm, positioned so the
          // combined block ends at x=48.26) [C]//VERIFY position; extents [A].
          // Board-unique body (not a connectors-lib type); edge="top" (a
          // component/keep-out sitting on the PCB, not a lateral port).
          ["module",          [16.82, 4.97, 1.6], [25.40, 18.00, 3.10], "top"], // [A] extents (WROOM-32 datasheet+drawing) / [C] position //VERIFY
          ["antenna_keepout", [42.22, 4.97, 1.6], [6.04,  18.00, 3.10], "top"], // [A] length (drawing "6.04mm") / [C] Y-extent+height reused from module, position //VERIFY
        ] ],
    // esp8266_nodemcu — NodeMCU v1.0, ESP-12E (Amica, "narrow" 0.9in rows).
    // No single-vendor drawing; multi-peer [B]. Outline 49x26 [B]//VERIFY
    // (~1mm clone-to-clone variance expected). corner_r: not documented,
    // RESEARCH.md gives a ~0.5-1mm [C]//VERIFY range — using the midpoint
    // 0.75mm (not a printed callout either way). thickness: 1.6 [C]//VERIFY.
    // Mounting holes: NONE [B] (every peer describes a breadboard board).
    ["esp8266_nodemcu", [49, 26], 0.75, 1.6,
        [],
        [ // usb: micro-USB on xmin [B]. Body per connectors-lib micro_usb (see header note).
          ["usb", [0, 9.14, 1.6], [5.48, 7.72, 3.96], "xmin"],
          // header_l/header_r: 15 pins/row (30 total), 2.54mm pitch, 0.9in
          // (22.86mm [B]) row spacing -> centerline inset (26-22.86)/2=1.57,
          // row body (width 2.54) centered on each centerline.
          ["header_l", [5.45, 0.30,  1.6], [38.10, 2.54, 2.5], "top"],
          ["header_r", [5.45, 23.16, 1.6], [38.10, 2.54, 2.5], "top"],
          // ESP-12E module (~16x24mm [B] metal-can + PCB antenna at xmax end):
          // module body omitted here — RESEARCH.md gives no height/Z dimension
          // for the ESP-12E can (only a footprint range), so it is left out
          // rather than inventing a Z extent (verified-research-over-guesswork;
          // same precedent as sbc.scad omitting undimensioned features).
        ] ],
    // wemos_d1_mini — LOLIN (WEMOS) D1 mini V4.0.0 (USB-C; the ONLY board here
    // with mounting holes). [A] dim_d1_mini_v4.0.0.pdf. Outline 34.3x25.4 [A]
    // (drawing prints "34.3000"/"25.4000"). corner_r ~4.0mm [C]//VERIFY
    // (vector-reconstructed antenna-end fillet, not a printed radius callout —
    // see RESEARCH.md). thickness 1.0 [C]//VERIFY.
    ["wemos_d1_mini", [34.3, 25.4], 4.0, 1.0,
        // Mounting holes: TWO [A], the notable V4.0.0 change. Y={2.5,22.9}mm
        // and Ø2.0mm are printed drawing callouts [A]. X ~3.2mm from the xmax
        // (antenna) end [C]//VERIFY (vector-reconstructed, not printed) ->
        // X = 34.3 - 3.2 = 31.1. Role: structural-mount [A] (the drawing's own
        // designation for a mounting hole).
        [ [31.1, 2.5,  "structural-mount", 2.0],
          [31.1, 22.9, "structural-mount", 2.0] ],
        [ // usb: USB-C on xmin [A] ("Type-C USB Port"). Body [6.90,8.94,3.16] =
          // connectors-lib usb_c [A] w/d-swapped (see header note).
          ["usb", [0, 8.23, 1.0], [6.90, 8.94, 3.16], "xmin"],
          // header_l/header_r: 8 pins/row (16 total), 2.54mm pitch, 0.9in
          // (22.86mm, drawing "22.8600mm" [A]) row spacing -> centerline
          // inset (25.4-22.86)/2=1.27, row body centered on each centerline.
          ["header_l", [6.99, 0.00,  1.0], [20.32, 2.54, 2.5], "top"],
          ["header_r", [6.99, 22.86, 1.0], [20.32, 2.54, 2.5], "top"],
          // On-board ESP8266EX (QFN, no metal can) + PCB trace antenna at the
          // xmax end: omitted, no dimension of any kind given in RESEARCH.md
          // for this feature (position, extent, or height) — not fabricated.
        ] ],
    // esp32_c3_devkitm — ESP32-C3-DevKitM-1 (ESP32-C3-MINI-1, single micro-USB).
    // [A] DIMENSION_ESP32-C3-DEVKITM-1_V1_20200915AA.pdf. Outline 38.91x25.40
    // [A]. corner_r ~2mm [B]//VERIFY (visibly rounded, not dimensioned).
    // thickness 1.6 [C]//VERIFY. Mounting holes: NONE [A].
    ["esp32_c3_devkitm", [38.91, 25.40], 2, 1.6,
        [],
        [ ["usb", [0, 8.84, 1.6], [5.48, 7.72, 3.96], "xmin"], // [A] type / [C] pos //VERIFY; body per connectors-lib micro_usb
          // header_l/header_r: 15 pins/row (30 total), 2.54mm pitch, 22.86mm
          // (0.9in [A]) row spacing -> centerline inset (25.40-22.86)/2=1.27.
          ["header_l", [0.405, 0.00,  1.6], [38.10, 2.54, 2.5], "top"],
          ["header_r", [0.405, 22.86, 1.6], [38.10, 2.54, 2.5], "top"],
          // ESP32-C3-MINI-1 module: 13.2x16.6x2.4mm [A datasheet], at the xmax
          // end; "MINI-ANT-TYPED" antenna keep-out drawn protruding past the
          // board end [A] but with no printed extent -> keep-out omitted
          // (not fabricated), module body flush to the board's xmax edge
          // [C]//VERIFY position, centered in Y.
          ["module", [22.31, 6.10, 1.6], [16.6, 13.2, 2.4], "top"], // [A] extents / [C] position //VERIFY
        ] ],
    // esp32_s3_devkitc — ESP32-S3-DevKitC-1 v1.1 (ESP32-S3-WROOM-1, TWO
    // micro-USB ports). [A] DXF_ESP32-S3-DevKitC-1_V1.1_20220429.pdf. Outline
    // 62.74x25.40 [A]. corner_r ~0 square [A]//VERIFY (sharp corners drawn).
    // thickness 1.6 [C]//VERIFY. Mounting holes: NONE [A].
    ["esp32_s3_devkitc", [62.74, 25.40], 0, 1.6,
        [],
        [ // Two micro-USB ports side by side on xmin [A]: usb_uart (J2,
          // "UART", left) + usb_otg (J4, "USB", right). //VERIFY: some
          // later/clone S3-DevKitC-1 batches ship USB-C in these positions —
          // this v1.1 drawing itself shows micro-USB for both. Y split: no
          // per-port offset dimensioned, [C]//VERIFY even split of the
          // 25.40mm edge into two halves (see header note).
          ["usb_uart", [0, 2.49,  1.6], [5.48, 7.72, 3.96], "xmin"],
          ["usb_otg",  [0, 15.19, 1.6], [5.48, 7.72, 3.96], "xmin"],
          // header_l/header_r: 22 pins/row (44 total), 2.54mm pitch [A].
          // Row inset [C]//VERIFY (RESEARCH.md: S3 "places rows just inside
          // the long edges", no dimensioned spacing given) — using the same
          // 1.3mm inset as esp32_devkitc.
          ["header_l", [3.43, 1.30,  1.6], [55.88, 2.54, 2.5], "top"],
          ["header_r", [3.43, 21.56, 1.6], [55.88, 2.54, 2.5], "top"],
          // ESP32-S3-WROOM-1 module: 18x25.5x3.1mm [A datasheet], at the xmax
          // end. RESEARCH.md ALSO states the module sits "inset 1.27mm from
          // each long edge" [A], which would imply a Y-extent of 25.40-2*1.27
          // =22.86mm — inconsistent with the datasheet's own 18mm module
          // width. NOT resolving this silently: using the datasheet's direct
          // 18mm width (centered in Y), flagging the "1.27mm inset" figure as
          // likely describing a different sub-feature (not independently
          // re-derived here) — see RESEARCH.md, follow-up re-check needed.
          // "MINI-ANT-TYPEB" antenna keep-out has no printed extent -> omitted
          // (not fabricated). Position flush to the board's xmax edge, [C]//VERIFY.
          ["module", [37.24, 3.70, 1.6], [25.5, 18.0, 3.1], "top"], // [A] extents (datasheet) / [C] position //VERIFY; see inset-conflict note above
        ] ],
];

function _embedded_row(b) =
    let (rows = [for (r = _embedded_table()) if (r[0] == b) r])
    len(rows) > 0 ? rows[0] : undef;
function _embedded_unknown(b) = str("embedded: unknown board ", b, "; known: ", embedded_known_boards());

function embedded_size(b)          = let (r = _embedded_row(b)) assert(!is_undef(r), _embedded_unknown(b)) r[1];
function embedded_corner_radius(b) = let (r = _embedded_row(b)) assert(!is_undef(r), _embedded_unknown(b)) r[2];
function embedded_thickness(b)     = let (r = _embedded_row(b)) assert(!is_undef(r), _embedded_unknown(b)) r[3];
function embedded_connectors(b)    = let (r = _embedded_row(b)) assert(!is_undef(r), _embedded_unknown(b)) r[5];

// --- hole roles (parity with sbc's hole-role tagging) ---
function embedded_known_hole_roles() = ["structural-mount", "component-mount", "keep-out", "alignment"];

// Distinct roles actually present on a board's holes (order of the vocabulary).
function _embedded_roles_present(b) =
    let (hs = _embedded_row(b)[4])
    [for (rr = embedded_known_hole_roles()) if (len([for (h = hs) if (h[2] == rr) h]) > 0) rr];

// Full hole tuples [x,y,role,dia], filtered by role.
//   role a canonical role  -> only that role
//   role == "all"          -> every hole, silent (explicit intent)
//   role == undef (omitted) -> every hole, PLUS a WARNING when >1 role present
//   unknown role string    -> assert
// NOTE: no embedded board is currently classified into >1 hole-role category
// (4 of 5 have zero holes; wemos_d1_mini's 2 holes are both structural-mount),
// so the WARNING path never fires on real board data today. The full
// machinery is kept anyway for parity with sbc and to be ready if a future
// board (or a re-classification) needs it — see tests/test_embedded_lib.sh
// for the synthetic (non-board) exercise of this exact mechanism.
function embedded_holes(b, role = undef) =
    let (r = _embedded_row(b))
    assert(!is_undef(r), _embedded_unknown(b))
    let (hs = r[4],
         present = _embedded_roles_present(b),
         _warn = (is_undef(role) && len(present) > 1)
             ? echo(str("WARNING: embedded '", b, "' holes span ", len(present),
                        " role categories ", present,
                        "; no role filter selected — returning all. ",
                        "Pass a role (e.g. \"structural-mount\") or \"all\" to silence."))
             : undef,
         sel = is_undef(role) ? "all" : role)
    assert(sel == "all"
        || len([for (rr = embedded_known_hole_roles()) if (rr == sel) rr]) == 1,
        str("embedded: unknown hole role '", sel, "'; known: ", embedded_known_hole_roles()))
    sel == "all" ? hs : [for (h = hs) if (h[2] == sel) h];

// Role of the i-th hole (index into the board's full hole list).
function embedded_hole_role(b, i) =
    let (r = _embedded_row(b))
    assert(!is_undef(r), _embedded_unknown(b))
    r[4][i][2];

// Backward-compatible [x,y]-only accessor, role-filterable.
function embedded_holes_xy(b, role = undef) = [for (h = embedded_holes(b, role)) [h[0], h[1]]];
function embedded_connector(b, name) =
    let (cs = [for (c = embedded_connectors(b)) if (c[0] == name) c])
    assert(len(cs) > 0, str("embedded: board ", b, " has no connector ", name)) cs[0];
