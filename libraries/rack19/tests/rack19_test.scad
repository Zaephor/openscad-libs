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
