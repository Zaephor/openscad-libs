// Countersink: a conical, angled recess (90deg included) over a narrower
// through-hole, for a flat/countersunk screw head.
// Modeled as an extruded cross-section profile (viewed face-on from the
// renderer's "side" view) so the taper is unambiguous — a solid CSG hole
// would be hidden inside an opaque block from any outside view.
w = 30; h = 20; thick = 12;
csk_top_r = 8; csk_d = 6;
hole_r = 3;

rotate([0, 0, 90])
rotate([90, 0, 0])
linear_extrude(height = thick)
difference() {
    square([w, h]);
    polygon(points = [
        [w / 2 - hole_r, -1],
        [w / 2 - hole_r, h - csk_d],
        [w / 2 - csk_top_r, h + 1],
        [w / 2 + csk_top_r, h + 1],
        [w / 2 + hole_r, h - csk_d],
        [w / 2 + hole_r, -1],
    ]);
}
