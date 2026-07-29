// SPDX-License-Identifier: CC-BY-NC-SA-4.0
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

// #40: rear mounting plane (where a rear-support plate bolts). Nominal =
// depth_ftf; exact rear-post face offset is unmeasured (//VERIFY, inherits
// depth_ftf's [C] tier).
assert(rack10_rear_post_y("labrax") == rack10_depth_preset("labrax"), "labrax rear post y");
assert(rack10_rear_post_y("tecmojo") == rack10_depth_preset("tecmojo"), "tecmojo rear post y");

// #67: rail mounting-slot capsule, sourced (spuder [C]).
rs = rack10_rail_slot();
assert(len(rs) == 2 && rs[0] > 0 && rs[1] > 0, "rail slot [L,H] positive");
assert(rs[0] > rs[1], "rail slot elongated along its long axis");
assert(rs == [10.0, 7.0], "rail slot capsule (spuder [C])");

// --- #70: panel silhouette corner chamfer ---
pc = rack10_panel_corner_chamfer();
assert(pc > 0, "panel corner chamfer positive");
assert(2*pc < rack10_panel_width("labrax"), "chamfer under half panel width");
assert(2*pc < rack10_device_height(1), "chamfer under half panel height");
assert(abs(pc - 3.0) < 1e-9, "panel corner chamfer is 3.0 (design value, no tier)");

// Silhouette point count: 8 corners chamfered, 4 when disabled.
assert(len(rack10_panel_profile_pts(254, 43.66)) == 8, "chamfered profile has 8 points");
assert(len(rack10_panel_profile_pts(254, 43.66, 0)) == 4, "chamfer=0 profile has 4 points");

// Hole-clearance limit. labrax 1U: 127 + 43.66 - 118.2625 - 38.1 = 14.2975 (top
// corner binds; the bottom corner allows 15.0875).
assert(abs(rack10_panel_chamfer_max("labrax", 1) - 14.2975) < 1e-6,
    "labrax 1U chamfer max");
assert(pc < rack10_panel_chamfer_max("labrax", 1),
    "chosen chamfer clears the mounting-hole column");
assert(abs(rack10_panel_chamfer_max("labrax", 1, 2)
        - (rack10_panel_chamfer_max("labrax", 1) - 2)) < 1e-9,
    "chamfer max margin subtracts");
