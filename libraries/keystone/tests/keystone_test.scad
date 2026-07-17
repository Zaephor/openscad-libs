// Assert-only test for the keystone library. Run via:
//   scripts/openscad.sh --export-format stl -o /dev/null libraries/keystone/tests/keystone_test.scad
// (assert failures surface on stderr; OpenSCAD exit code on assert files is unreliable.)
use <keystone/keystone.scad>;

// --- metric invariants (always hold regardless of sourced numbers) ---
o = keystone_opening();
assert(len(o) == 2 && o[0] > 0 && o[1] > 0, "opening [ow,oh] positive");

b = keystone_body();
assert(len(b) == 3 && b[0] > 0 && b[1] > 0 && b[2] > 0, "body [bw,bh,bd] positive");
assert(b[0] >= o[0] && b[1] >= o[1], "body at least as large as opening in X,Y");

pt = keystone_plate_thickness();
assert(len(pt) == 2 && pt[0] > 0 && pt[1] > pt[0], "plate thickness [min,max], min<max");

assert(keystone_pitch() > 0, "pitch > 0");
assert(keystone_min_wall() > 0, "min_wall > 0");

t = keystone_tab();
assert(len(t) == 4, "tab [hook_ledge_z, tab_thickness, hook_edge, latch_edge]");
assert(t[0] > 0 && t[1] > 0, "tab ledge_z & thickness positive");
assert(t[2] == "+Y" && t[3] == "-Y", "tab hook edge +Y, latch edge -Y");

// --- fit-check identity (locks the single-source spacing rule) ---
assert(keystone_min_pitch() == keystone_opening()[0] + keystone_min_wall(),
       "min_pitch == opening_w + min_wall");
assert(keystone_pitch() >= keystone_min_pitch(), "nominal pitch clears min_pitch");

echo("keystone_test OK");

/* [Placeholder] — smoke render; numeric bbox checked in tests/test_keystone_lib.sh */
keystone_placeholder();

/* [Cutout] — smoke render: window cut from a representative 3mm plate.
   Numeric extents checked in tests/test_keystone_lib.sh. */
translate([30, 0, 0]) difference() {
    translate([-15, -15, -3]) cube([30, 30, 3]); // stand-in faceplate
    keystone_cutout(plate_thickness = 3.0);
}
