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

// --- BPI-R4 ---
assert(sbc_size("bpir4") == [148.0, 100.5], "bpir4 size");
// The 2xSFP + 4xRJ45 variant: exactly 2 sfp_* and 4 rj45_* connectors.
assert(len([for (c = sbc_connectors("bpir4")) if (_starts(c[0], "sfp"))  1]) == 2, "bpir4 has 2 sfp");
assert(len([for (c = sbc_connectors("bpir4")) if (_starts(c[0], "rj45")) 1]) == 4, "bpir4 has 4 rj45");

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
assert(sbc_connector("bpir4", "usb_1")[2] == [8.89, 23.16, 13.5],
    "bpir4 usb_1 (different, weak) stays literal");
assert(sbc_connector("bpir4", "sfp_1")[2] == [16.51, 53.98, 13.4],
    "bpir4 sfp_1 (no-peer) stays literal");
assert(sbc_connector("pi3b", "av_jack")[2] == [6, 6, 6.0],
    "pi3b av_jack (no-peer) stays literal");
