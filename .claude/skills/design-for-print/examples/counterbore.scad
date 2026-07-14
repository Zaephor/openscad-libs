// Counterbore: a stepped, flat-bottomed cylindrical recess (wide) over a
// narrower through-hole, for a bolt head to sit flush/recessed.
// Modeled as an extruded cross-section profile (viewed face-on from the
// renderer's "side" view) so the step is unambiguous — a solid CSG hole
// would be hidden inside an opaque block from any outside view.
w = 30; h = 20; thick = 12;
recess_r = 8; recess_d = 6;
hole_r = 4;

rotate([0, 0, 90])
rotate([90, 0, 0])
linear_extrude(height = thick)
difference() {
    square([w, h]);
    translate([w / 2 - hole_r, -1]) square([hole_r * 2, h + 2]);
    translate([w / 2 - recess_r, h - recess_d]) square([recess_r * 2, recess_d + 1]);
}
