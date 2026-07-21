use <din-rail/din-rail.scad>;
assert(din_known_rails() == ["ts35-7.5","ts35-15"], "rail list");
assert(din_rail_size("ts35-7.5")[0] == 35, "ts35 width");
assert(din_rail_size("ts35-15")[1] == 15, "ts35-15 depth");
assert(din_rail_size("ts35-7.5")[1] == 7.5, "ts35-7.5 depth");
echo("din-rail_test OK");
