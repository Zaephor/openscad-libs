// Overhang angle sweep: fins at increasing angle from vertical
// (30, 45, 60, 75 degrees) to illustrate the ~45deg self-support limit.
$fn = 0;
H = 20; thick = 6; spacing = 26;
angles = [30, 45, 60, 75];

module fin(angle) {
    L = H * tan(angle);
    linear_extrude(height = thick)
    polygon(points = [[0, 0], [0, H], [L, 0]]);
}

for (i = [0 : len(angles) - 1])
    translate([i * spacing, 0, 0]) fin(angles[i]);
