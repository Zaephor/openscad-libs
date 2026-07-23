use <sbc/sbc.scad>;
use <connectors/connectors.scad>;

// Outline (publicly certain for Model-B).
assert(sbc_size("pi4b") == [85.6, 56], "pi4b size");
assert(sbc_size("pi5")  == [85.6, 56], "pi5 size");

// Model-B family shares the same mounting-hole rectangle.
assert(sbc_holes_xy("pi4b") == sbc_holes_xy("pi5"),  "pi4b/pi5 holes match");
assert(sbc_holes_xy("pi3b") == sbc_holes_xy("pi4b"), "pi3b/pi4b holes match");

// --- Pi Zero family ---
assert(sbc_size("pizero")   == [65, 30], "pizero size");
assert(sbc_size("pizero2w") == [65, 30], "pizero2w size");

// Every mounting hole within envelope.
module _check_holes(b) {
    sz = sbc_size(b);
    assert(len([for (p = sbc_holes_xy(b))
                if (p[0] < 0 || p[0] > sz[0] || p[1] < 0 || p[1] > sz[1]) 1]) == 0,
           str(b, " holes within envelope"));
}
for (b = sbc_known_boards()) _check_holes(b);

// Every LATERAL connector box touches its named board edge; every connector
// (lateral or "top") is within the transverse envelope. "top" (and "bottom" if
// ever used) connectors open along Z, not out a board edge, so they have no
// edge-touch check.
// Scalar OR element-wise vector compare (default tol matches the original
// scalar-only 0.6mm drawing-rounding tolerance; pass tol explicitly for the
// SP2 reconcile threshold, 0.5mm). Inclusive (<=): the reconcile rule is
// "within 0.5mm" and several verdict-table rows sit exactly AT the 0.5mm
// boundary and are still called "same" (e.g. pi4b usbc_pwr d, pi3b hdmi w).
function _near(a, b, tol = 0.6) =
    is_list(a) ? (len(a) == len(b) &&
                  len([for (i = [0:len(a)-1]) if (!(abs(a[i]-b[i]) <= tol)) 1]) == 0)
               : abs(a - b) <= tol;
_lateral_edges = ["xmin", "xmax", "ymin", "ymax"];
// bpir4 dip_1 (Task 2): caliper-confirmed to physically overhang the board's
// xmax edge by 2mm ("+2mm overhang off x=148") — a real, deliberately-modeled
// exception to the generic within-envelope check below, not a data bug.
_overhang_exceptions = [["bpir4", "dip_1"]];
function _is_overhang_exception(b, name) =
    len([for (x = _overhang_exceptions) if (x[0] == b && x[1] == name) x]) > 0;
module _check_connectors(b) {
    sz = sbc_size(b);
    for (c = sbc_connectors(b)) {
        p = c[1]; s = c[2]; e = c[3];
        is_lateral = len([for (le = _lateral_edges) if (le == e) 1]) > 0;
        if (is_lateral) {
            touch = e == "xmax" ? _near(p[0] + s[0], sz[0])
                  : e == "xmin" ? _near(p[0], 0)
                  : e == "ymax" ? _near(p[1] + s[1], sz[1])
                  : e == "ymin" ? _near(p[1], 0)
                  : false;
            assert(touch, str(b, " connector ", c[0], " must touch edge ", e));
        }
        if (!_is_overhang_exception(b, c[0]))
            assert(p[0] >= -0.6 && p[0] + s[0] <= sz[0] + 0.6 &&
                   p[1] >= -0.6 && p[1] + s[1] <= sz[1] + 0.6,
                   str(b, " connector ", c[0], " within envelope"));
    }
}
for (b = sbc_known_boards()) _check_connectors(b);

// The Raspberry Pi Model-B boards each expose exactly one 40-pin "gpio" header.
// This is a Pi-family spec feature, NOT a universal SBC invariant: e.g. bpir4
// (a router board) has no Pi-style header dimensioned in any available source,
// so it is (correctly) omitted rather than invented to satisfy a test.
for (b = ["pi3b", "pi3bplus", "pi4b", "pi5", "pizero", "pizero2w"])
    assert(len([for (c = sbc_connectors(b)) if (c[0] == "gpio") 1]) == 1,
           str(b, " has one gpio connector"));
// No board (Pi or otherwise) may declare a DUPLICATE gpio.
for (b = sbc_known_boards())
    assert(len([for (c = sbc_connectors(b)) if (c[0] == "gpio") 1]) <= 1,
           str(b, " has at most one gpio connector"));

// String prefix helper for connector name checks.
function _starts(s, p) = len(s) >= len(p) && [for (i=[0:len(p)-1]) s[i]] == [for (i=[0:len(p)-1]) p[i]];

// --- Task 2: "bottom" edge convention ---
// sbc_known_edges() must enumerate the full vocabulary including "bottom"
// (added Task 2 for underside-mounted sockets: [x,y] on board bottom, z=0 at
// the board-bottom plane, h = downward protrusion).
assert(len([for (e = sbc_known_edges()) if (e == "bottom") e]) == 1,
    "sbc_known_edges includes bottom");
assert(len([for (e = sbc_known_edges()) if (e == "top") e]) == 1,
    "sbc_known_edges includes top");

// --- BPI-R4 ---
assert(sbc_size("bpir4") == [148.0, 100.5], "bpir4 size");
// The 2xSFP + 4xRJ45 variant: exactly 2 sfp_* and 4 rj45_* connectors.
assert(len([for (c = sbc_connectors("bpir4")) if (_starts(c[0], "sfp"))  1]) == 2, "bpir4 has 2 sfp");
assert(len([for (c = sbc_connectors("bpir4")) if (_starts(c[0], "rj45")) 1]) == 4, "bpir4 has 4 rj45");
// Thickness caliper-revised Task 2: 1.6 -> 1.4.
assert(sbc_thickness("bpir4") == 1.4, "bpir4 thickness caliper-revised Task 2");

// --- Task 2: new bpir4 components ---
assert(len([for (c = sbc_connectors("bpir4")) if (_starts(c[0], "sim_")) 1]) == 3,
    "bpir4 has 3 sim_2ff (reference-only)");
assert(len([for (c = sbc_connectors("bpir4")) if (_starts(c[0], "led_")) 1]) == 7,
    "bpir4 has 7 LEDs");
for (n = ["reset_1", "wps_1", "microsd_1", "dip_1", "gpio26_1", "m2modem_1"])
    assert(len([for (c = sbc_connectors("bpir4")) if (c[0] == n) 1]) == 1,
        str("bpir4 has exactly one ", n));
// sim_2ff/microsd bodies sourced from connectors (SSOT), not literals.
assert(sbc_connector("bpir4", "sim_1")[2] == connector_size("sim_2ff"),
    "bpir4 sim_1 body sourced from connectors sim_2ff");
assert(sbc_connector("bpir4", "microsd_1")[2] == connector_size("microsd"),
    "bpir4 microsd_1 body sourced from connectors microsd");
assert(sbc_connector("bpir4", "m2modem_1")[2] == connector_size("m2_key_b"),
    "bpir4 m2modem_1 body sourced from connectors m2_key_b");

// --- Task 5: module/card keep-out envelopes (bottom sockets + m2modem_1) ---
for (n = ["m2modem_1_card", "mpcie_1_card", "mpcie_2_card", "m2_ssd_1_card"])
    assert(len([for (c = sbc_connectors("bpir4")) if (c[0] == n) 1]) == 1,
        str("bpir4 has exactly one ", n));
assert(sbc_connector("bpir4", "m2modem_1_card")[2] == connector_size("m2_modem_card"),
    "bpir4 m2modem_1_card body sourced from connectors m2_modem_card");
assert(sbc_connector("bpir4", "mpcie_1_card")[2] == connector_size("mpcie_card"),
    "bpir4 mpcie_1_card body sourced from connectors mpcie_card");
assert(sbc_connector("bpir4", "mpcie_2_card")[2] == connector_size("mpcie_card"),
    "bpir4 mpcie_2_card body sourced from connectors mpcie_card");
assert(sbc_connector("bpir4", "m2_ssd_1_card")[2] == connector_size("m2_2280_card"),
    "bpir4 m2_ssd_1_card body sourced from connectors m2_2280_card");
// Each card keep-out row shares its socket's own rear-facing y_max (and, for
// m2_ssd_1, its own key-edge x_max too) — not its min corner — since the card
// is larger than the socket and must extend inward from the socket's own
// pin/rear edge to stay within the board footprint (worst-case anchor
// simplification documented in sbc.scad).
function _ymax(c) = c[1][1] + c[2][1];
function _xmax(c) = c[1][0] + c[2][0];
_eps = 1e-6;
assert(abs(sbc_connector("bpir4", "m2modem_1_card")[1][0] - sbc_connector("bpir4", "m2modem_1")[1][0]) < _eps
    && abs(_ymax(sbc_connector("bpir4", "m2modem_1_card")) - _ymax(sbc_connector("bpir4", "m2modem_1"))) < _eps,
    "bpir4 m2modem_1_card shares m2modem_1's x_min and y_max");
assert(abs(sbc_connector("bpir4", "mpcie_1_card")[1][0] - sbc_connector("bpir4", "mpcie_1")[1][0]) < _eps
    && abs(_ymax(sbc_connector("bpir4", "mpcie_1_card")) - _ymax(sbc_connector("bpir4", "mpcie_1"))) < _eps,
    "bpir4 mpcie_1_card shares mpcie_1's x_min and y_max");
assert(abs(sbc_connector("bpir4", "mpcie_2_card")[1][0] - sbc_connector("bpir4", "mpcie_2")[1][0]) < _eps
    && abs(_ymax(sbc_connector("bpir4", "mpcie_2_card")) - _ymax(sbc_connector("bpir4", "mpcie_2"))) < _eps,
    "bpir4 mpcie_2_card shares mpcie_2's x_min and y_max");
assert(abs(_xmax(sbc_connector("bpir4", "m2_ssd_1_card")) - _xmax(sbc_connector("bpir4", "m2_ssd_1"))) < _eps
    && abs(_ymax(sbc_connector("bpir4", "m2_ssd_1_card")) - _ymax(sbc_connector("bpir4", "m2_ssd_1"))) < _eps,
    "bpir4 m2_ssd_1_card shares m2_ssd_1's x_max and y_max");
// dip_1 deliberately overhangs the board's xmax edge by 2mm (caliper-confirmed);
// gpio26_1 is NOT the Pi-family "gpio" name (distinct 26-pin/13-col part).
assert(len([for (c = sbc_connectors("bpir4")) if (c[0] == "gpio") 1]) == 0,
    "bpir4 has no Pi-style 40-pin gpio (gpio26_1 is a distinct, smaller part)");
_dip = sbc_connector("bpir4", "dip_1");
assert(_dip[1][0] + _dip[2][0] == 150.0, "bpir4 dip_1 overhangs xmax by 2mm as caliper-specified");

// --- Task 2: underside ("bottom" edge) sockets ---
// (2x mpcie + m2_ssd socket bodies) + (2x mpcie + m2_ssd card keep-out envelopes, Task 5)
_bpr_bottom = [for (c = sbc_connectors("bpir4")) if (c[3] == "bottom") c];
assert(len(_bpr_bottom) == 6, "bpir4 has 6 bottom-face rows (2x mpcie + m2_ssd sockets, plus their 3 card keep-out envelopes)");
// Bottom convention: z=0 at the board-bottom plane for every bottom connector.
for (c = _bpr_bottom)
    assert(c[1][2] == 0, str("bpir4 ", c[0], " bottom connector z must be 0 (board-bottom plane)"));
for (n = ["mpcie_1", "mpcie_2", "m2_ssd_1"])
    assert(len([for (c = sbc_connectors("bpir4")) if (c[0] == n) 1]) == 1,
        str("bpir4 has exactly one ", n));
assert(sbc_connector("bpir4", "mpcie_1")[2] == connector_size("mpcie"),
    "bpir4 mpcie_1 body sourced from connectors mpcie");
assert(sbc_connector("bpir4", "mpcie_2")[2] == connector_size("mpcie"),
    "bpir4 mpcie_2 body sourced from connectors mpcie");
assert(sbc_connector("bpir4", "m2_ssd_1")[2] == connector_size("m2_key_m"),
    "bpir4 m2_ssd_1 body sourced from connectors m2_key_m");
// mpcie_1/mpcie_2 share the same (mirrored) x — two parallel underside slots.
assert(sbc_connector("bpir4", "mpcie_1")[1][0] == sbc_connector("bpir4", "mpcie_2")[1][0],
    "bpir4 mpcie_1/mpcie_2 share the same x column");
// "a bottom connector's protrusion reads correctly" (Task 2 TDD ask): the
// placeholder cube for a "bottom" connector must occupy z in [-h, 0], i.e.
// its far (most-negative) corner is exactly -h below the board-bottom plane
// — verify the general formula sbc_placeholder() uses (translate z by
// c[1][2]-c[2][2], i.e. 0-h) independent of any single connector's own values.
_m2ssd = sbc_connector("bpir4", "m2_ssd_1");
assert(_m2ssd[1][2] - _m2ssd[2][2] == -_m2ssd[2][2],
    "bpir4 m2_ssd_1 bottom protrusion far corner is exactly -h (z=0 minus h)");

// bpir4 RJ45 is ONE physical 4-port ganged block (WAN + 3x LAN), not a lone WAN
// jack + separate 3-port block. => 4 ports, uniform width, constant pitch.
_bpr_rj45 = [for (c = sbc_connectors("bpir4")) if (_starts(c[0], "rj45")) c];
assert(len(_bpr_rj45) == 4, "bpir4 4 rj45 ports");
for (c = _bpr_rj45)
    assert(c[2][0] == _bpr_rj45[0][2][0], "bpir4 rj45 uniform port width");
for (i = [2 : len(_bpr_rj45) - 1])
    assert(abs((_bpr_rj45[i][1][0] - _bpr_rj45[i-1][1][0])
             - (_bpr_rj45[1][1][0] - _bpr_rj45[0][1][0])) < 0.001,
           "bpir4 rj45 constant pitch");
assert(sbc_connector("bpir4", "rj45_1")[2] == [13.98, 21.45, 13.60], "bpir4 ganged rj45 port body"); // locked from datasheet; //VERIFY axes noted in RESEARCH.md

// --- hole-role tagging invariants (Task 1) ---
// Every hole on every board has a valid role and a positive diameter.
for (b = sbc_known_boards())
    for (h = sbc_holes(b, "all")) {
        assert(len([for (rr = sbc_known_hole_roles()) if (rr == h[2]) rr]) == 1,
            str("sbc ", b, ": hole ", h, " has invalid role '", h[2], "'"));
        assert(h[3] > 0, str("sbc ", b, ": hole ", h, " has non-positive dia"));
    }
// Filtering: structural subset ⊆ all; for bpi-r4 it is strictly smaller than 16.
assert(len(sbc_holes_xy("bpir4", "all")) == 16, "bpir4 must have 16 holes");
assert(len(sbc_holes_xy("bpir4", "structural-mount")) < 16,
    "bpir4 structural subset must be strictly smaller than all 16 holes");
// Each Pi corner set is all-structural (4 holes).
assert(len(sbc_holes_xy("pi4b", "structural-mount")) == 4, "pi4b: 4 structural holes");

// sbc_hole_role(b, i) returns the same role as the i-th entry from sbc_holes().
assert(sbc_hole_role("pi4b", 0) == "structural-mount", "pi4b hole 0 is structural-mount");
for (b = sbc_known_boards())
    for (i = [0 : len(sbc_holes(b, "all")) - 1])
        assert(sbc_hole_role(b, i) == sbc_holes(b, "all")[i][2],
            str("sbc ", b, ": sbc_hole_role(", i, ") matches sbc_holes() role"));

// Unknown role asserts (negative control).
// (exercised from the bash harness via a separate bad-role file)

// --- SP2 Task 3: adopted connector bodies sourced from connectors' connector_size() ---
// Sanity check: the pre-retrofit literals (as recorded in RESEARCH.md's "SP2 connector
// reconcile — Task 1" verdict table) are within the 0.5mm same-verdict threshold of the
// catalog peer they now get sourced from. This isn't a regression guard on sbc.scad's
// current values (those are asserted exactly below) — it documents/locks the reconcile
// math itself so a future edit to the catalog can't silently invalidate the "same" call
// without a test noticing.
assert(_near([9, 7.4, 3.2], connector_size("usb_c"), 0.5),
    "pi4b/pi5 usbc_pwr pre-retrofit literal within 0.5mm of connectors usb_c (verdict sanity)");
assert(_near([15, 11.5, 6.5], connector_size("hdmi"), 0.5),
    "pi3b/pi3bplus hdmi pre-retrofit literal within 0.5mm of connectors hdmi (verdict sanity, w at the boundary)");
assert(_near([10.9, 7.0, 3.4], connector_size("mini_hdmi"), 0.5),
    "pizero minihdmi pre-retrofit literal within 0.5mm of connectors mini_hdmi (verdict sanity, w+d at the boundary)");

// The full 21-row "same" adoption set (RESEARCH.md verdict table) — body must now equal
// connector_size(<mapped type>) EXACTLY (post-adoption, sbc IS the catalog literal, no
// tolerance needed). Position [x,y,z] and edge are untouched by Task 3 and are already
// covered by _check_connectors() above.
_sp2_same_bodies = [
    ["pi3b",     "usb2_1",   "usb_a_stack2_shielded"],
    ["pi3b",     "rj45",     "rj45_shallow"],
    ["pi3b",     "hdmi",     "hdmi"],
    ["pi3bplus", "usb2_1",   "usb_a_stack2_shielded"],
    ["pi3bplus", "rj45",     "rj45_shallow"],
    ["pi3bplus", "hdmi",     "hdmi"],
    ["pi4b",     "usb2",     "usb_a_stack2_shielded"],
    ["pi4b",     "usbc_pwr", "usb_c"],
    ["pi4b",     "hdmi_1",   "micro_hdmi"],
    ["pi4b",     "hdmi_2",   "micro_hdmi"],
    ["pi5",      "usb3",     "usb_a_stack2_shielded"],
    ["pi5",      "usbc_pwr", "usb_c"],
    ["pi5",      "hdmi_1",   "micro_hdmi"],
    ["pi5",      "hdmi_2",   "micro_hdmi"],
    ["pizero",   "minihdmi", "mini_hdmi"],
];
for (r = _sp2_same_bodies)
    assert(sbc_connector(r[0], r[1])[2] == connector_size(r[2]),
        str("sbc ", r[0], " ", r[1], " body sourced from connectors ", r[2]));

// gpio: the shared _sbc_gpio() row (reused by pi3b/pi3bplus/pi4b/pi5) plus pizero's and
// pizero2w's own independent gpio rows — all 6 are "same" vs gpio_2x20 in the verdict
// table, even though only 3 literals exist in sbc.scad to edit (the shared fn + 2 own rows).
for (b = ["pi3b", "pi3bplus", "pi4b", "pi5", "pizero", "pizero2w"])
    assert(sbc_connector(b, "gpio")[2] == connector_size("gpio_2x20"),
        str("sbc ", b, " gpio body sourced from connectors gpio_2x20"));

// Non-"same" bodies (different/error/no-peer) must stay LITERAL, untouched by Task 3 —
// spot-check a few from each category so a future over-eager adoption gets caught.
assert(sbc_connector("pi3b", "usb2_2")[2] == [17, 9, 16.0],
    "pi3b usb2_2 (error verdict) stays literal");
assert(sbc_connector("pi4b", "usb3")[2] == [17, 18.75, 16.0],
    "pi4b usb3 (different, marginal) stays literal");
// Task 2: h revised from caliper bottom->top figures (thickness now 1.4) —
// w/d unchanged, still literal (no catalog peer), just the height reconciled.
assert(sbc_connector("bpir4", "usb_1")[2] == [8.89, 23.16, 14.1],
    "bpir4 usb_1 (different, weak) stays literal, h caliper-revised Task 2");
assert(sbc_connector("bpir4", "sfp_1")[2] == [16.51, 53.98, 10.4],
    "bpir4 sfp_1 (no-peer) stays literal, h caliper-revised Task 2");
assert(sbc_connector("pi3b", "av_jack")[2] == [6, 6, 6.0],
    "pi3b av_jack (no-peer) stays literal");
