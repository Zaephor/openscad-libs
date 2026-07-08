use <rack10/rack10.scad>;

assert(rack10_u() == 44.45, "1U pitch");
assert(rack10_known_standards() == ["labrax"], "known standards");
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
assert(rack10_known_hole_types() == ["round", "m6", "10-32", "square"], "hole types");
assert(rack10_screw_clearance("m6") == 6.6, "m6 clearance");
assert(rack10_screw_clearance("10-32") == 5.0, "10-32 clearance");
// (unknown-standard + unknown-hole_type asserts are exercised by the bash
// negative controls in Task 7 — OpenSCAD cannot catch its own assert in-file.)

// --- flange envelope present ---
assert(rack10_flange_width() > 0 && rack10_flange_thickness() > 0, "flange dims");
