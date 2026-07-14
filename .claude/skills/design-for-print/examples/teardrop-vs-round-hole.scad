// Teardrop vs round horizontal hole: two blocks, each with a horizontal
// (X-axis) hole through it -- one plain round, one teardrop (round
// bottom, 45deg pointed roof) -- clearly contrasted. The blocks are
// offset along Y (perpendicular to the hole axis, not collinear with it)
// so a camera looking down the shared hole axis (the renderer's "side"
// view, which looks along X) sees both hole end-views side by side
// instead of them overlapping in projection.
$fn = 48;
r = 6; bw = 14; bd = 30; bh = 30; gap = 10;

// round hole block
difference() {
    cube([bw, bd, bh]);
    translate([-1, bd / 2, bh / 2]) rotate([0, 90, 0]) cylinder(h = bw + 2, r = r);
}

// teardrop hole block, offset along Y so it doesn't overlap the round
// block's hole when viewed end-on along the shared X hole axis
translate([0, bd + gap, 0])
difference() {
    cube([bw, bd, bh]);
    translate([-1, bd / 2, bh / 2])
    rotate([0, 90, 0])
    linear_extrude(height = bw + 2)
    union() {
        circle(r = r);
        polygon(points = [
            [r / sqrt(2), r / sqrt(2)],
            [0, r * sqrt(2)],
            [-r / sqrt(2), r / sqrt(2)],
        ]);
    }
}
