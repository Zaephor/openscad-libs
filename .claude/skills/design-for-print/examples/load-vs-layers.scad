// Load direction vs. layer stacking: a bracket with horizontal grooves
// representing print layers stacked along Z, and an arrow showing the
// CORRECT load direction -- horizontal, across the layer stack, not a
// vertical pull along it.
$fn = 32;
sx = 10; sy = 10; sz = 30; groove_spacing = 3;

difference() {
    cube([sx, sy, sz]);
    for (z = [groove_spacing : groove_spacing : sz - groove_spacing])
        translate([-1, -1, z]) cube([sx + 2, sy + 2, 0.6]);
}

// load arrow: shaft + cone head, pointing horizontally into the block's
// side at mid-height -- load acts across the layer planes, not along them
translate([-16, sy / 2, sz / 2])
rotate([0, 90, 0])
union() {
    cylinder(h = 10, r = 1.2);
    translate([0, 0, 10]) cylinder(h = 4, r1 = 3, r2 = 0);
}
