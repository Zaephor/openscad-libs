use <rack10/rack10.scad>;

assert(rack10_u() == 44.45, "1U pitch");
assert(rack10_known_standards() == ["labrax", "deskpi", "tecmojo"], "known standards");
assert(rack10_hole_h_span("labrax") == 236.525, "labrax hole span");
// centers derived from span (compare to the derived halves, not a hand-typed
// literal, to avoid float-noise on /2):
assert(rack10_hole_h_centers("labrax") == [-236.525/2, 236.525/2], "labrax centers");
assert(rack10_clear_width("labrax") == 222, "labrax clear width");
assert(rack10_panel_width("labrax") == 254, "labrax panel width");
assert(rack10_depth_preset("labrax") == 240, "labrax depth");

// --- hole strip (per-U pattern; confirm sub-pattern in RESEARCH.md) ---
assert(rack10_u_hole_offsets() == [6.35, 22.225, 38.1], "per-U hole offsets");
assert(rack10_hole_z(1) == [6.35, 22.225, 38.1], "hole_z u=1");
assert(rack10_hole_z(2) ==
    [6.35, 22.225, 38.1, 50.8, 66.675, 82.55], "hole_z u=2");
assert(len(rack10_hole_z(3)) == 9, "hole_z count u=3");

// --- hole shapes ---
assert(rack10_square_size() == 9.5, "cage-nut square side");
assert(rack10_known_hole_types() == ["round", "m6", "10-32", "square", "slot"], "hole types");
assert(rack10_screw_clearance("m6") == 6.6, "m6 clearance");
assert(rack10_screw_clearance("10-32") == 5.0, "10-32 clearance");
// (unknown-standard + unknown-hole_type asserts are exercised by the bash
// negative controls in Task 7 — OpenSCAD cannot catch its own assert in-file.)

// --- flange envelope present ---
assert(rack10_flange_width() > 0 && rack10_flange_thickness() > 0, "flange dims");

// --- panel height math (geometry verified by the render step) ---
assert(2 * rack10_u() == 88.9, "2U height");

// --- device height / stacking gap ---
// device height derives from pitch minus the stacking gap
assert(round(rack10_device_height(1)*1e6)/1e6 == round((rack10_u() - rack10_stack_gap())*1e6)/1e6,
    "device_height u=1");
assert(round(rack10_device_height(2)*1e6)/1e6 == round((2*rack10_u() - rack10_stack_gap())*1e6)/1e6,
    "device_height u=2");
assert(rack10_stack_gap() > 0 && rack10_stack_gap() < 2, "stack_gap sane small value");

// rack10_panel() builds at device_height (geometry checked by the .sh bbox
// test; this pins the intent so a future refactor to raw pitch trips here too).
assert(rack10_device_height(1) < rack10_u(), "device_height must be under 1U pitch");

// #10 vendor rows.
assert(rack10_known_standards() == ["labrax", "deskpi", "tecmojo"], "vendor standards");
assert(rack10_hole_h_span("deskpi")  == 236.525, "deskpi span (universal 10in)");
assert(rack10_hole_h_span("tecmojo") == 236.525, "tecmojo span (universal 10in)");
assert(rack10_panel_width("deskpi")   == 281,  "deskpi panel width");
assert(rack10_clear_width("deskpi")   == 212,  "deskpi clear width");
assert(rack10_depth_preset("deskpi")  == 200,  "deskpi depth preset");
assert(rack10_panel_width("tecmojo")  == 280, "tecmojo panel width");
assert(rack10_clear_width("tecmojo")  == 210, "tecmojo clear width");
assert(rack10_depth_preset("tecmojo") == 200,   "tecmojo depth preset");
// Hole centers derive from the shared span for the new keys.
assert(rack10_hole_h_centers("deskpi") == [-236.525/2, 236.525/2], "deskpi centers");
