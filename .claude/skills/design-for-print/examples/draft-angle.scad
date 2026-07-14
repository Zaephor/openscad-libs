// Draft: a wall with a slight outward taper from base to top, contrasted
// against a draftless (vertical) wall. Angle exaggerated for visibility.
$fn = 0;
base_w = 20; depth = 6; h = 30; draft_deg = 12;
top_w = base_w + 2 * h * tan(draft_deg);

// draftless (vertical) wall, for contrast
cube([base_w, depth, h]);

// drafted wall, tapering outward with height
translate([base_w + 16, 0, 0])
linear_extrude(height = h, scale = [top_w / base_w, 1])
square([base_w, depth]);
