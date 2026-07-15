use <embedded/embedded.scad>;

// --- Step 1 (brief) baseline assertions ---
assert(len(embedded_known_boards()) == 5, "5 known boards");
for (b = embedded_known_boards()) {
    assert(embedded_size(b)[0] > 0 && embedded_size(b)[1] > 0, str(b, " size positive"));
    assert(embedded_thickness(b) > 0, str(b, " thickness positive"));
    for (h = embedded_holes(b))
        assert(h[2] == "structural-mount" || h[2] == "keep-out"
            || h[2] == "component-mount" || h[2] == "alignment",
            str(b, " hole role valid"));
}

// --- Additional parity checks (mirroring sbc_test.scad's structure) ---

// Every mounting hole within its board's envelope.
module _check_holes(b) {
    sz = embedded_size(b);
    assert(len([for (p = embedded_holes_xy(b))
                if (p[0] < 0 || p[0] > sz[0] || p[1] < 0 || p[1] > sz[1]) 1]) == 0,
           str(b, " holes within envelope"));
}
for (b = embedded_known_boards()) _check_holes(b);

// Every connector (lateral or "top") sits within the transverse envelope;
// every LATERAL connector box touches its named board edge. "top" connectors
// open along Z (headers, on-board modules/keep-outs), so they have no
// edge-touch check — same convention as sbc's GPIO header.
function _near(a, b) = abs(a - b) < 0.6; // tolerance for drawing/estimate rounding
_lateral_edges = ["xmin", "xmax", "ymin", "ymax"];
module _check_connectors(b) {
    sz = embedded_size(b);
    for (c = embedded_connectors(b)) {
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
for (b = embedded_known_boards()) _check_connectors(b);

// --- Board-specific invariants (Task 1 findings) ---

// Four of five boards have NO mounting holes — confirmed absence, not a gap.
for (b = ["esp32_devkitc", "esp8266_nodemcu", "esp32_c3_devkitm", "esp32_s3_devkitc"])
    assert(len(embedded_holes_xy(b)) == 0, str(b, " has no mounting holes"));

// Only wemos_d1_mini has holes: exactly 2, both structural-mount, dia 2.0mm [A].
assert(len(embedded_holes_xy("wemos_d1_mini")) == 2, "wemos_d1_mini has 2 holes");
assert(len(embedded_holes_xy("wemos_d1_mini", "structural-mount")) == 2,
    "wemos_d1_mini holes are all structural-mount");
for (h = embedded_holes("wemos_d1_mini"))
    assert(h[3] == 2.0, "wemos_d1_mini hole dia == 2.0mm [A]");

// C3/S3 kept as two independent rows (not consolidated) despite sharing width.
assert(embedded_size("esp32_c3_devkitm")[1] == embedded_size("esp32_s3_devkitc")[1],
    "c3/s3 share the 25.40mm width but are independent rows");
assert(embedded_size("esp32_c3_devkitm")[0] != embedded_size("esp32_s3_devkitc")[0],
    "c3/s3 differ in length");

// s3_devkitc has 2 micro-USB ports (usb_uart + usb_otg); every other board has 1 usb*.
assert(len([for (c = embedded_connectors("esp32_s3_devkitc")) if (c[0] == "usb_uart" || c[0] == "usb_otg") 1]) == 2,
    "s3_devkitc has usb_uart + usb_otg");

// embedded_hole_role(b, i) matches the i-th entry from embedded_holes().
// (guard the range against boards with zero holes — 4 of 5 have none.)
for (b = embedded_known_boards())
    if (len(embedded_holes(b, "all")) > 0)
        for (i = [0 : len(embedded_holes(b, "all")) - 1])
            assert(embedded_hole_role(b, i) == embedded_holes(b, "all")[i][2],
                str("embedded ", b, ": embedded_hole_role(", i, ") matches embedded_holes() role"));

// Unknown-board / unknown-role asserts are exercised from the bash harness
// (tests/test_embedded_lib.sh), not here — same split as sbc.
