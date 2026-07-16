use <embedded/embedded.scad>;
use <connectors/connectors.scad>;

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

// --- Task 3: placeholder + mount-hole/standoff modules ---

// Hole-stamp-count parity: embedded_mount_holes(b, role="structural-mount")
// and embedded_standoffs(b, ..., role="structural-mount") both loop over
// embedded_holes(b, "structural-mount") — this is exactly that list's length,
// which is what a pure-SCAD assert CAN check (a real bbox/geometry check
// belongs to Task 5's render harness, not here).
_embedded_expected_structural_holes = [
    ["esp32_devkitc", 0], ["esp8266_nodemcu", 0], ["wemos_d1_mini", 2],
    ["esp32_c3_devkitm", 0], ["esp32_s3_devkitc", 0]
];
for (e = _embedded_expected_structural_holes)
    assert(len(embedded_holes(e[0], "structural-mount")) == e[1],
        str("embedded ", e[0], ": mount-hole stamp count == ", e[1]));

// Compile-smoke: embedded_placeholder()/embedded_mount_holes()/
// embedded_standoffs() must render for EVERY board without error, including
// the 4 empty-hole-list boards (their mount-hole/standoff for-loops correctly
// iterate zero times and stamp nothing — a no-op, not a bug). Boards are
// spread out along X so the union stays a sane (non-overlapping) smoke shape.
module _embedded_task3_smoke() {
    boards = embedded_known_boards();
    for (i = [0 : len(boards) - 1]) {
        b = boards[i];
        off = i * 80; // fixed pitch, comfortably wider than any board here
        translate([off, 0, 0]) embedded_placeholder(b);
        translate([off, 0, 0]) embedded_mount_holes(b);
        translate([off, 0, 0]) embedded_standoffs(b, height = 5);
    }
}
_embedded_task3_smoke();

// The plan's own literal compile-smoke line (Task 3 brief, Step 1).
translate([0, -40, 0]) embedded_placeholder("esp32_devkitc");

// --- Task 4: connector cutouts + connectors-lib body sourcing ---

// Every board connector mapped to a connectors-lib type (per RESEARCH.md's
// "Connectors-lib mapping summary": every micro-USB port -> "micro_usb",
// wemos_d1_mini's USB-C -> "usb_c") must have its stored [w,d,h] body
// SOURCED from connector_size(type), not a duplicated literal. The body is
// stored w/d-swapped from connectors.scad's canonical "+Y opening" frame
// into this board's "opens along X" (xmin/xmax) frame (see embedded.scad's
// header note): board w(X) = connectors-lib d, board d(Y) = connectors-lib
// w, h unchanged. Un-swap and compare against connectors.scad's own value.
_embedded_conn_body_check = [
    ["esp32_devkitc",    "usb",      "micro_usb"],
    ["esp8266_nodemcu",  "usb",      "micro_usb"],
    ["wemos_d1_mini",    "usb",      "usb_c"],
    ["esp32_c3_devkitm", "usb",      "micro_usb"],
    ["esp32_s3_devkitc", "usb_uart", "micro_usb"],
    ["esp32_s3_devkitc", "usb_otg",  "micro_usb"],
];
for (e = _embedded_conn_body_check) {
    _b = embedded_connector(e[0], e[1])[2];
    _expect = connector_size(e[2]);
    assert(_b[0] == _expect[1] && _b[1] == _expect[0] && _b[2] == _expect[2],
        str("embedded ", e[0], " connector ", e[1],
            " body must be sourced from connector_size(\"", e[2], "\")"));
}

// Faceplate-cutout smoke: wemos_d1_mini's usb connector sits on "xmin" —
// embedded_faceplate_cutouts() must stamp it (and only lateral-edge
// connectors on that edge) into a consumer difference() with no ERROR.
module _embedded_task4_smoke() {
    difference() {
        translate([0, -5, -2]) cube([34.3 + 20, 25.4 + 10, 6]);
        embedded_faceplate_cutouts("wemos_d1_mini", "xmin", depth = 12);
        embedded_port_cutout("esp32_devkitc", "usb", depth = 12);
    }
}
translate([-60, 0, 0]) _embedded_task4_smoke();

// Bad-edge assert (parity with sbc_port_cutout's own bad-edge assert): no
// real board data can reach this branch (every connector's edge is one of
// xmin/xmax/ymin/ymax/top), so it is exercised synthetically from the bash
// harness (tests/test_embedded_lib.sh's bad_edge.scad sub-test, which
// inlines embedded_port_cutout's exact edge branching with a bogus edge
// string) rather than here.
