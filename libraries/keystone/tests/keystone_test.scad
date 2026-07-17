// Assert-only test for the keystone library. Run via:
//   scripts/openscad.sh --export-format stl -o /dev/null libraries/keystone/tests/keystone_test.scad
// (assert failures surface on stderr; OpenSCAD exit code on assert files is unreliable.)
use <keystone/keystone.scad>;

// --- style/decomposition invariants (task #28) ---
assert(keystone_known_styles() == ["lip", "face"], "styles list");
assert(keystone_face() == [14.5, 16.0], "jack face invariant");
assert(keystone_opening("face") == [14.70, 16.40], "face-grip opening (Samm [A])");
assert(keystone_opening("lip")  == [14.8, 20.3],  "lip opening (taller)");
assert(keystone_opening() == keystone_opening("lip"), "default style = lip");

// --- metric invariants (always hold regardless of sourced numbers) ---
o = keystone_opening();
assert(len(o) == 2 && o[0] > 0 && o[1] > 0, "opening [ow,oh] positive");

b = keystone_body();
assert(len(b) == 3 && b[0] > 0 && b[1] > 0 && b[2] > 0, "body [bw,bh,bd] positive");
// Body (jack keep-out) must cover the FACE in X,Y. The "lip" opening is
// intentionally taller than the jack (rotate-and-snap margin), so it may exceed
// the body height — compare the body to the face, not the oversized opening.
f = keystone_face();
assert(b[0] >= f[0] && b[1] >= f[1], "body at least as large as jack face in X,Y");

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

// layout_ok: a strip at nominal pitch fits; a strip below min_pitch does not.
mp = keystone_min_pitch();
assert(keystone_layout_ok([0, keystone_pitch(), 2*keystone_pitch()]) == true,
       "nominal-pitch strip fits");
assert(keystone_layout_ok([0, mp - 0.5]) == false, "sub-min gap rejected");
assert(keystone_layout_ok([0]) == true, "single port always fits");

echo("keystone_test OK");

/* [Placeholder] — smoke render; numeric bbox checked in tests/test_keystone_lib.sh */
keystone_placeholder();

/* [Cutout] — smoke render: window cut from a representative 3mm plate.
   Numeric extents checked in tests/test_keystone_lib.sh. */
translate([30, 0, 0]) difference() {
    translate([-15, -15, -3]) cube([30, 30, 3]); // stand-in faceplate
    keystone_cutout(plate_thickness = 3.0);
}

/* [Insert] — smoke render: mate-reference body. Numeric checks in the bash test. */
translate([-30, 0, 0]) keystone_insert(plate_thickness = 3.0);
