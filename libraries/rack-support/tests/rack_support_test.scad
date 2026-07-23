use <rack-support/rack-support.scad>;
assert(rack_support_rail_size() == [40, 10], "rail size");
assert(rack_support_slot_clearance() == 0.4, "slot clearance");
assert(rack_support_engagement_depth() == 12, "engagement depth");
assert(rack_support_floor_thickness() == 2, "floor thickness");

echo("rack_support_test OK");

// plate renders; presence of the channel proven in the bash STL check.
rack_support_plate("labrax", 1);

// tongue renders clean; X/Y/Z spans proven in the bash STL check.
rack_support_tongue();
