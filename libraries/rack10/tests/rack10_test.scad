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
