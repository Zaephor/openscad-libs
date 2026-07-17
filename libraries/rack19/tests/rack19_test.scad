use <rack19/rack19.scad>;

assert(rack19_u() == 44.45, "1U pitch");
assert(rack19_panel_width() == 482.6, "panel width");
assert(rack19_opening_width() == 450.85, "opening width");
assert(rack19_hole_h_span() == 465.1, "hole h span");
assert(rack19_hole_h_centers() == [-232.55, 232.55], "rail X centers");

// --- hole strip ---
assert(rack19_u_hole_offsets() == [6.35, 22.225, 38.1], "per-U hole offsets");
// 1U: exactly the 3 offsets.
assert(rack19_hole_z(1) == [6.35, 22.225, 38.1], "hole_z u=1");
// 2U: second U shifted up by one pitch; 6 holes ascending.
assert(rack19_hole_z(2) ==
    [6.35, 22.225, 38.1, 50.8, 66.675, 82.55], "hole_z u=2");
// count == 3*u
assert(len(rack19_hole_z(5)) == 15, "hole_z count u=5");

// --- hole shapes ---
assert(rack19_square_size() == 9.5, "cage-nut square side");
assert(rack19_screw_clearance("10-32") == 5.0, "10-32 clearance");
assert(rack19_screw_clearance("12-24") == 5.6, "12-24 clearance");
assert(rack19_screw_clearance("M6")    == 6.6, "M6 clearance");
// (unknown-thread assertion is exercised by the bash negative control in Task 7 —
// OpenSCAD cannot catch its own assert() inside the same file.)

// --- depth presets ---
assert(len(rack19_known_depths()) >= 1, "at least one depth preset");
assert(rack19_depth_preset(rack19_known_depths()[0]) > 0, "preset resolves > 0");
// flange envelope present
assert(rack19_flange_width() > 0 && rack19_flange_thickness() > 0, "flange dims");

// --- panel blank differences cleanly with the hole stamp ---
// (compile-only reachability: exercised in the render step; assert the height math)
assert(2 * rack19_u() == 88.9, "2U height");

// --- device height / stacking gap ---
// device height derives from pitch minus the stacking gap
assert(round(rack19_device_height(1)*1e6)/1e6 == round((rack19_u() - rack19_stack_gap())*1e6)/1e6,
    "device_height u=1");
assert(round(rack19_device_height(2)*1e6)/1e6 == round((2*rack19_u() - rack19_stack_gap())*1e6)/1e6,
    "device_height u=2");
assert(rack19_stack_gap() > 0 && rack19_stack_gap() < 2, "stack_gap sane small value");
assert(rack19_device_height(1) < rack19_u(), "device_height must be under 1U pitch");
