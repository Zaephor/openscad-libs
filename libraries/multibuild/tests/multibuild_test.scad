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

// hole: test rendering for each known mount type (negative board-hole cutter)
for (t = multibuild_known_mounts()) {
    difference() {
        translate([0, 0, -multibuild_hole_depth(t) - 2])
            cube([multibuild_hole_dia(t) + 4,
                  multibuild_hole_dia(t) + 4,
                  multibuild_hole_depth(t) + 2], center = true);
        multibuild_hole(t);
    }
}

// --- Fix-Point (Multipoint) accessory-side negatives (#32) ---
// Negative-only types live in a PARALLEL hole table, never in the mount table:
// a Fix-Point has no arms/flare, so it cannot satisfy the mount asserts above.
assert(len(multibuild_known_holes()) == 2);
for (t = multibuild_known_holes()) {
    // hole-only types must NOT leak into the mount table (which the loop above
    // hard-asserts full positive-mount geometry for).
    assert(len([for (m = multibuild_known_mounts()) if (m == t) 1]) == 0);
    // accessory-side negative cutter + its positive Fix-Point placeholder render.
    multibuild_hole(t);
    multibuild_fixpoint_placeholder(t);
}

// --- MultiBin container (#32) ---
// CU / panel-pitch / tolerance: the 50mm CU grid is DISTINCT from the 25mm MU
// board grid (multibuild_grid_pitch()) -- these must not collapse to one value.
assert(multibin_cu() == 50);
assert(multibin_panel_pitch() == 50);
assert(multibin_panel_pitch() != multibuild_grid_pitch()); // 50 (CU) != 25 (MU)
assert(multibin_tolerance() == 0.25);

// Seeded Simple Walls sizes (size key = [Nx, Ny, Hz] in CU cells):
// footprint = 50*N, cavity W/D = 50*N-6, cavity H = 50*Hz-6, wall ~= 3.0.
sz_a = [2, 2, 0.5];
assert(multibin_footprint(sz_a) == [100, 100]);
assert(multibin_cavity(sz_a) == [94, 94, 19]);
assert(multibin_wall(sz_a) == 3.0);
assert(multibin_height(sz_a) == 30); // external = 50*Hz + 5

sz_b = [3, 2, 1.5];
assert(multibin_footprint(sz_b) == [150, 100]);
assert(multibin_cavity(sz_b) == [144, 94, 69]);
assert(multibin_wall(sz_b) == 3.0);
assert(multibin_height(sz_b) == 80);

// Wall-consistency: footprint - cavity == 2*wall on each XY axis (so the two
// placeholders cannot pass while mutually misaligned).
for (sz = [sz_a, sz_b]) {
    f = multibin_footprint(sz);
    c = multibin_cavity(sz);
    w = multibin_wall(sz);
    assert(abs((f[0] - c[0]) - 2 * w) < 1e-6);
    assert(abs((f[1] - c[1]) - 2 * w) < 1e-6);
    // cavity must sit strictly inside the footprint on both XY axes
    assert(c[0] < f[0] && c[1] < f[1]);
}

// Modules render for the seeded sizes (STL bbox/alignment checks live in
// tests/test_multibuild_lib.sh; unknown-size negative control lives there too).
for (sz = [sz_a, sz_b]) {
    multibin_placeholder(sz);
    multibin_cavity_cutout(sz);
}
