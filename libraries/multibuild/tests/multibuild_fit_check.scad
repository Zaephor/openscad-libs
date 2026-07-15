use <multibuild/multibuild.scad>
// Render mount in red, hole cavity in blue-ish via a thin shell, for the
// verify-scad-geometry skill's side-profile overlap view. The mount is
// expected to extend past the hole's far face (-Z) by design (through-hole
// snap) -- the check is radial clearance, not full containment.
for (t = multibuild_known_mounts()) {
    color("red") multibuild_mount(t);
    color("blue", 0.3)
        difference() {
            translate([0, 0, -multibuild_hole_depth(t) - 2])
                cube([multibuild_hole_dia(t) + 6, multibuild_hole_dia(t) + 6, multibuild_hole_depth(t) + 2], center = true);
            multibuild_hole(t);
        }
}
