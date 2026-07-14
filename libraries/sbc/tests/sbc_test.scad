use <sbc/sbc.scad>;

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
function _near(a, b) = abs(a - b) < 0.6;  // tolerance for drawing rounding
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
// Unknown role asserts (negative control).
// (exercised from the bash harness via a separate bad-role file)
