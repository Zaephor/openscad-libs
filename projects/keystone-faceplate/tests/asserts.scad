// asserts.scad — render-time invariants + drift checks for the faceplate.
// Rendered by tests/test_keystone_faceplate.sh. `use` doesn't import variables,
// so params are threaded as module args (see reference_openscad_gotchas).
use <keystone/keystone.scad>;
use <rack10/rack10.scad>;
use <../keystone-faceplate.scad>;

// Drift checks: Customizer literal defaults must equal the lib accessors they
// stand in for (sanctioned duplication — Customizer needs literal defaults).
assert(keystone_pitch() == 19.05, "port_pitch default drifted from keystone_pitch()");
assert(keystone_plate_thickness()[1] == 3.0, "plate_thickness default drifted from keystone max");

// Blank plate (port_count=0) renders (full guards added in Task 5).
keystone_faceplate("labrax", 0, 19.05, 3.0);
// Positive: a realistic 6-port plate at defaults renders without tripping guards.
keystone_faceplate("labrax", 6, keystone_pitch(), keystone_plate_thickness()[1]);
