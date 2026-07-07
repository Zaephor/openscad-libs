use <rack19/rack19.scad>;

assert(rack19_u() == 44.45, "1U pitch");
assert(rack19_panel_width() == 482.6, "panel width");
assert(rack19_opening_width() == 450.85, "opening width");
assert(rack19_hole_h_span() == 465.1, "hole h span");
assert(rack19_hole_h_centers() == [-232.55, 232.55], "rail X centers");
