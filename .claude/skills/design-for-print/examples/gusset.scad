// Gusset: a solid triangular fill at an inside corner between two
// perpendicular walls.
wall_t = 4; wall_len = 24; wall_h = 16; g = 16;

union() {
    // wall along Y
    cube([wall_t, wall_len, wall_h]);
    // wall along X (perpendicular, meeting at the inside corner)
    cube([wall_len, wall_t, wall_h]);
    // solid triangular gusset filling the inside corner, flush to both walls
    translate([wall_t, wall_t, 0])
    linear_extrude(height = wall_h)
    polygon(points = [[0, 0], [g, 0], [0, g]]);
}
