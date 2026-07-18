// Assert-only test for the keystone library. Run via:
//   scripts/openscad.sh --export-format stl -o /dev/null libraries/keystone/tests/keystone_test.scad
// (assert failures surface on stderr; OpenSCAD exit code on assert files is unreliable.)
use <keystone/keystone.scad>;

// --- style/decomposition invariants (task #28) ---
assert(keystone_known_styles() == ["lip", "face"], "styles list");
assert(keystone_face() == [14.5, 16.0], "jack face invariant");
assert(keystone_opening("face") == [14.70, 16.40], "face-grip opening (Samm [A])");
assert(keystone_opening("lip")  == [14.90, 22.90], "lip opening (#31 measured max window)");
assert(keystone_opening() == keystone_opening("lip"), "default style = lip");

// Plug cross-section is the jack FACE, not the (taller, lip) opening.
assert(keystone_tab("face")[2] == "+Y", "face tab hook edge");
assert(keystone_tab("lip")[0]  >  0,    "lip tab ledge positive");

// --- keystone_latch() (#31): measured hook/flex-latch retention profile ---
lt = keystone_latch("lip");
assert(len(lt) == 7,
       "latch [width,front_h,hook_z,hook_h,pocket_z,latch_z,latch_h]");
assert(lt[0] == keystone_opening("lip")[0] && lt[6] == keystone_opening("lip")[1],
       "latch width/max-height are keystone_opening(\"lip\")'s single source");
// Z breakpoints get monotonically deeper (more negative) front-to-back.
assert(lt[2] < 0 && lt[4] < lt[2] && lt[5] < lt[4],
       "latch Z breakpoints (hook_z, pocket_z, latch_z) monotonically deeper");
// Window height grows monotonically: front (narrowest) < hook pocket < latch plateau (widest).
assert(lt[3] > lt[1] && lt[6] > lt[3],
       "window height grows: front_h < hook_h < latch_h");
assert(lt[3] > 0 && lt[6] > 0, "hook_h/latch_h positive");

// --- keystone_boss_footprint() / style-aware min_pitch (#31) ---
bf = keystone_boss_footprint("lip");
assert(len(bf) == 3 && bf[0] > 0 && bf[1] > 0,
       "boss footprint [w,h,y_center] positive w/h");
// Footprint must be wider (X) than the raw cutout envelope alone (wall margin added).
assert(bf[0] > keystone_opening("lip")[0], "boss footprint adds wall margin beyond the raw opening");
assert(keystone_min_pitch("lip") == bf[0],
       "lip min_pitch is boss-footprint-driven (#31), not the old opening+wall formula");
assert(keystone_min_pitch("face") == keystone_opening("face")[0] + keystone_min_wall(),
       "face min_pitch formula unchanged");
assert(keystone_pitch() >= keystone_min_pitch("lip"),
       "nominal keystone pitch (19.05mm) still clears the boss-aware lip min_pitch");

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
// "face" has no boss (plain rectangle): min_pitch is still opening_w + wall.
// "lip" (#31) has a boss (see keystone_boss_footprint()): min_pitch is
// boss-footprint-driven instead -- checked in the keystone_boss_footprint()
// block above, not re-asserted here to avoid duplicating the same identity
// against two different formulas under one style-less default.
assert(keystone_min_pitch("face") == keystone_opening("face")[0] + keystone_min_wall(),
       "min_pitch(\"face\") == opening_w + min_wall");
assert(keystone_pitch() >= keystone_min_pitch(), "nominal pitch clears default-style (lip) min_pitch");

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

/* [Insert] — smoke render: mate-reference body, both styles. Numeric checks
   in the bash test. */
translate([-30, 0, 0]) keystone_insert(plate_thickness = 3.0, style = "lip");
translate([-60, 0, 0]) keystone_insert(plate_thickness = 3.0, style = "face");

/* [Boss] (#31) — smoke render: local material behind a thin 3mm plate,
   hosting the "lip" mechanism's full ~8.3mm depth. Numeric checks (footprint,
   cutout section) in tests/test_keystone_lib.sh. */
translate([60, 0, 0]) union() {
    translate([-15, -15, -3]) cube([30, 30, 3]); // stand-in thin faceplate
    keystone_boss(plate_thickness = 3.0, style = "lip");
}

/* [Boss+Cutout assembly] (#31) — smoke render: the real consumer pattern
   (union the boss into the plate, then difference the cutout through both)
   -- confirms the full lip mechanism forms in solid material even though the
   plate alone (3mm) is far thinner than the ~8.3mm mechanism depth. */
translate([90, 0, 0]) difference() {
    union() {
        translate([-15, -15, -3]) cube([30, 30, 3]);
        keystone_boss(plate_thickness = 3.0, style = "lip");
    }
    keystone_cutout(plate_thickness = 3.0, style = "lip");
}

// keystone_boss() is a no-op for "face" (plain-rectangle cutout already fits
// keystone_plate_thickness() unchanged) -- smoke-render it anyway so a
// regression that accidentally emits geometry for "face" would show up in
// the STL bbox (not asserted numerically; visual/manifold smoke check only).
translate([120, 0, 0]) union() {
    translate([-15, -15, -3]) cube([30, 30, 3]);
    keystone_boss(plate_thickness = 3.0, style = "face");
}
