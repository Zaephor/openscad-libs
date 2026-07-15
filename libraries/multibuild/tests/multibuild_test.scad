use <multibuild/multibuild.scad>

p = multibuild_grid_pitch();
assert(p > 0);

assert(len(multibuild_known_mounts()) > 0);
for (t = multibuild_known_mounts()) {
    assert(multibuild_hole_dia(t) > 0);
    assert(multibuild_hole_depth(t) > 0);
    assert(multibuild_mount_engagement(t) > 0);
    assert(multibuild_mount_arm_count(t) > 0);
    assert(multibuild_mount_arm_width(t) > 0);
    assert(multibuild_mount_tip_flare(t) > 0);
    // tip-to-tip diameter must clear the hole waist (through-hole snap-fit)
    assert(2 * multibuild_mount_tip_flare(t) <= multibuild_hole_dia(t));
}

// grid_count: floor(length / pitch)
assert(multibuild_grid_count(2.9 * p) == 2);
assert(multibuild_grid_count(3.0 * p) == 3);

// grid_snap: nearest whole multiple
assert(round(multibuild_grid_snap(2.4 * p) * 1e6) / 1e6 == round(2 * p * 1e6) / 1e6);
assert(round(multibuild_grid_snap(2.6 * p) * 1e6) / 1e6 == round(3 * p * 1e6) / 1e6);

// grid_points(2,3) -> 6 coords at pitch spacing
pts = multibuild_grid_points(2, 3);
assert(len(pts) == 6);
dx = abs(pts[1][0] - pts[0][0]);
assert(round(dx * 1e6) / 1e6 == round(p * 1e6) / 1e6);

// mount_placeholder: test rendering for each known mount type
for (t = multibuild_known_mounts()) {
    multibuild_mount_placeholder(t);
}

// mount: test rendering for each known mount type (bbox/manifold checks
// live in tests/test_multibuild_lib.sh, which measures the exported STL)
for (t = multibuild_known_mounts()) {
    multibuild_mount(t);
}
