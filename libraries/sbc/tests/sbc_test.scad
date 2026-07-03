use <sbc/sbc.scad>;

// Outline (publicly certain for Model-B).
assert(sbc_size("pi4b") == [85.6, 56], "pi4b size");
assert(sbc_size("pi5")  == [85.6, 56], "pi5 size");

// Model-B family shares the same mounting-hole rectangle.
assert(sbc_holes_xy("pi4b") == sbc_holes_xy("pi5"),  "pi4b/pi5 holes match");
assert(sbc_holes_xy("pi3b") == sbc_holes_xy("pi4b"), "pi3b/pi4b holes match");

// Every mounting hole within envelope.
module _check_holes(b) {
    sz = sbc_size(b);
    assert(len([for (p = sbc_holes_xy(b))
                if (p[0] < 0 || p[0] > sz[0] || p[1] < 0 || p[1] > sz[1]) 1]) == 0,
           str(b, " holes within envelope"));
}
for (b = sbc_known_boards()) _check_holes(b);

// Every connector box touches its named edge and is within the transverse envelope.
function _near(a, b) = abs(a - b) < 0.6;  // tolerance for drawing rounding
module _check_connectors(b) {
    sz = sbc_size(b);
    for (c = sbc_connectors(b)) {
        p = c[1]; s = c[2]; e = c[3];
        touch = e == "xmax" ? _near(p[0] + s[0], sz[0])
              : e == "xmin" ? _near(p[0], 0)
              : e == "ymax" ? _near(p[1] + s[1], sz[1])
              : e == "ymin" ? _near(p[1], 0)
              : false;
        assert(touch, str(b, " connector ", c[0], " must touch edge ", e));
        assert(p[0] >= -0.6 && p[0] + s[0] <= sz[0] + 0.6 &&
               p[1] >= -0.6 && p[1] + s[1] <= sz[1] + 0.6,
               str(b, " connector ", c[0], " within envelope"));
    }
}
for (b = sbc_known_boards()) _check_connectors(b);

// Every board has a 40-pin GPIO header named "gpio".
for (b = sbc_known_boards())
    assert(len([for (c = sbc_connectors(b)) if (c[0] == "gpio") 1]) == 1,
           str(b, " has one gpio connector"));
