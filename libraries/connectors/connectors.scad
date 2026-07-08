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
// Task 2 status (this commit): type table + accessor functions
// (`connector_known_types()`, `connector_size()`, `connector_opening()`)
// implemented below, values per RESEARCH.md. The `connector_body()` /
// `connector_cutout()` modules are Task 3+ (see
//  for the exact API
// and  for the
// design rationale).

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
    ["micro_hdmi",   [ 7.5,   4.5,   3.0 ], "+Y"], // [C] //VERIFY depth 4.5 from sbc Pi measurement, not re-fetched
    ["pcie_x1",      [25.0,   7.5,  11.25], "+Z"], // [C] //VERIFY Molex 87715/PCI-SIG cited-not-fetched
    ["pcie_x4",      [39.0,   7.5,  11.25], "+Z"], // [C] //VERIFY cited-not-fetched
    ["pcie_x8",      [56.0,   7.5,  11.25], "+Z"], // [C] //VERIFY cited-not-fetched
    ["pcie_x16",     [89.0,   7.5,  11.25], "+Z"], // [C] //VERIFY Molex 87715/PCI-SIG cited-not-fetched (NOT [A])
    ["gpio_2x20",    [50.8,   5.08,  8.5 ], "+Z"], // w/d [A] 2.54 pitch; h 8.5 [C] //VERIFY tall-pin variant not fetched
];
function connector_known_types() = [for (e = _connector_table()) e[0]];
function _connector_row(type) =
    let (m = [for (e = _connector_table()) if (e[0] == type) e])
    len(m) > 0 ? m[0]
    : assert(false, str("connectors: unknown type '", type, "'"));
function connector_size(type)    = _connector_row(type)[1];
function connector_opening(type) = _connector_row(type)[2];
