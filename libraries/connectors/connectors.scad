// connectors — common connector body (housing/shell) envelope reference.
// Datum: millimeters. Mounting/panel face on Z=0; centered in X.
// Opening axis is per-type: `+Y` for panel connectors (USB/RJ45/HDMI —
// the mating opening faces out of the panel), `+Z` for slot/header
// connectors (PCIe card-edge slot, GPIO pin header — the mating opening
// faces up off the board).
// `[w, d, h]` = extents along `[X, Y, Z]` — the housing/shell body, not
// just the mating opening.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — connector_body(type): envelope solid for fit checks
//   3. Hole-stamp  — connector_cutout(type, ...): panel/board cutout for a consumer difference()
// Provenance legend (see RESEARCH.md for the full evidence log this pass):
//   [A] fetched + read this pass (vendor datasheet or governing standard).
//   [B] corroborated across >=2 independent peers.
//   [C] single-sourced / derived, OR a named standard cited but not fetched
//       this pass (marked //VERIFY (cited-not-fetched)).
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
//
// All three roles implemented: (1) data table + accessor functions
// (`connector_known_types()`, `connector_size()`, `connector_opening()`),
// (2) connector_body() placeholder module for fit-check envelope, and
// (3) connector_cutout() hole-stamp module for panel/board openings.
// Values per RESEARCH.md.

$fn = 48;

/* [Data] — connector body table. Tiers per docs/LIBRARY-AUTHORING.md; see RESEARCH.md.
   Row: [type, [w,d,h] mm extents (X,Y,Z), opening ("+Y" panel / "+Z" slot/header)].
   Canonical frame: mounting face on Z=0, centered in X. */
function _connector_table() = [
    ["usb_a",        [13.66, 14.6,  6.94], "+Y"], // [A] Same Sky UJ2-AH-4-TH
    ["usb_a_stack2", [13.66, 14.6, 13.88], "+Y"], // [C] //VERIFY derived 2x single-port height
    ["usb_c",        [ 8.94,  6.90, 3.16], "+Y"], // [A] Same Sky UJC-H-G-SMT
    ["micro_usb",    [ 7.72,  5.48, 3.96], "+Y"], // [A] Same Sky UJ2-MBH; //VERIFY depth (5.48 shell vs 9.20 w/ solder-tail) + height (foot-inclusion)
    ["rj45",         [16.36, 30.48, 13.67], "+Y"], // [A] Bel Fuse 0813-1X1T-43-F gigabit MagJack (integrated magnetics = deep; many bare SBC jacks shallower)
    ["rj45_stack2",  [16.36, 30.48, 27.34], "+Y"], // [C] //VERIFY derived 2x height
    ["hdmi",         [14.50, 11.06,  6.17], "+Y"], // [A] Same Sky HD05-19-TH
    ["mini_hdmi",    [10.4,   7.5,   3.2 ], "+Y"], // [C] //VERIFY cited-not-fetched
    ["micro_hdmi",   [ 7.5,   4.5,   3.0 ], "+Y"], // [B] (SP1 upgrade) h=3.0 grounded by sbc.scad pi4b's [A] "Z=3.0" drawing callout (corroborated on pi5), w/d [B] standard-body estimate
    ["pcie_x1",      [25.0,   7.5,  11.25], "+Z"], // [A] Molex SD-87715-207 (PCI Express Edge Card Connector, Wayback-fetched+read)
    ["pcie_x4",      [39.0,   7.5,  11.25], "+Z"], // [A] Molex SD-87715-207 (PCI Express Edge Card Connector, Wayback-fetched+read)
    ["pcie_x8",      [56.0,   7.5,  11.25], "+Z"], // [A] Molex SD-87715-207 (PCI Express Edge Card Connector, Wayback-fetched+read)
    ["pcie_x16",     [89.0,   7.5,  11.25], "+Z"], // [A] Molex SD-87715-207 (PCI Express Edge Card Connector, Wayback-fetched+read)
    ["gpio_2x20",    [50.8,   5.08,  8.5 ], "+Z"], // w/d [A] 2.54 pitch; h 8.5 [B] (SP1 upgrade: sbc.scad pi3b/pi4b independently-corroborated "Z-Height=8.5" drawing callout)
    // --- SP1 additions (see RESEARCH.md SP1 table) ---
    ["usb_a_stack2_shielded", [17,   18,   16.0], "+Y"], // [B] sbc.scad pi3b/pi3bplus/pi4b/pi5 dual-port shielded SBC housing (corroborated across multiple boards)
    ["rj45_shallow",          [21,   18.75, 13.5], "+Y"], // [B] sbc.scad pi3b/pi3bplus rj45 (corroborated on d+h by bpir4 rj45_2/3/4), no integrated-magnetics module
    // --- SFP type (#14) ---
    ["sfp", [14.5, 48.7, 9.7], "+Y"], // [A] TE Connectivity 2007198-1, single SFP/SFP+ cage (one mechanical form factor covers both); sbc sfp_1/sfp_2 [16.51,53.98,13.4] reconciled #21: different (larger cage-pair footprint, not this single-port cage) — sbc retains its literal
    // --- Task 1 additions ---
    ["microsd",  [16.44, 14.5, 1.40], "+Y"], // [A] GCT MEM2075 (Micro SD Memory Card Connector, 1.40mm Profile, SMT push-push)
    ["sim_2ff",  [15, 16.3, 2.7], "+Y"],     // w [B] caliper (2FF mini-SIM card width); d/h [B] TE 2FF SIM connector family (2-1705300-7 / 6-way mini-SIM variant, corroborated across 2 TE listings)
    ["m2_key_b", [21.9, 8.7, 3.2], "+Z"],    // [A] TE 2199119-5 (M.2 NGFF, 0.5mm pitch, 3.2mm height, Key B, 67-position, board-to-board)
    ["m2_key_m", [21.9, 8.7, 3.2], "+Z"],    // [B] TE 2199119 series Key M variant (1-2199119-5, "M.2 0.5PITCH 3.2H KEY M"), same family as m2_key_b; envelope not independently re-fetched for the M-key part's own dimension table
    ["mpcie",    [29.90, 8.20, 5.2], "+Z"],  // [A] "0.80mm Pitch Mini PCI Express H=5.2mm Connector" customer drawing (DWG S650S5281XXXXM431XX); X cross-checked against the industry-standard Mini Card form factor 30x50.95mm [A] (card width agrees within 0.1mm; card's 50.95mm length is not part of the connector's own envelope)
];
function connector_known_types() = [for (e = _connector_table()) e[0]];
function _connector_row(type) =
    let (m = [for (e = _connector_table()) if (e[0] == type) e])
    len(m) > 0 ? m[0]
    : assert(false, str("connectors: unknown type '", type, "'"));
function connector_size(type)    = _connector_row(type)[1];
function connector_opening(type) = _connector_row(type)[2];

/* [Body] */
// Envelope solid in the canonical frame: mounting face on Z=0, centered in X,
// body growing +Y (depth) and +Z (height). For placement/fit-check in a
// consumer assembly (the consumer rotates/translates to its board edge).
module connector_body(type) {
    s = connector_size(type);
    translate([-s[0]/2, 0, 0]) cube(s);
}

/* [Cutout] */
// Faceplate opening for a consumer difference(). The opening-face cross-section
// (grown by `clearance` per side) extruded along the type's opening axis by
// `depth` (default 20, a generous through-cut). "+Y": a W x H window (X x Z)
// extruded along Y. "+Z": a W x D window (X x Y) extruded along Z.
module connector_cutout(type, clearance = 0.5, depth = 0) {
    s = connector_size(type);
    o = connector_opening(type);
    dd = depth > 0 ? depth : 20;
    if (o == "+Y")
        translate([-(s[0]/2 + clearance), -1, -clearance])
            cube([s[0] + 2*clearance, dd, s[2] + 2*clearance]);
    else // "+Z"
        translate([-(s[0]/2 + clearance), -clearance, -1])
            cube([s[0] + 2*clearance, s[1] + 2*clearance, dd]);
}
