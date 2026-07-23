// Assert-only test for the keystone library. Run via:
//   scripts/openscad.sh --export-format stl -o /dev/null libraries/keystone/tests/keystone_test.scad
// (assert failures surface on stderr; OpenSCAD exit code on assert files is unreliable.)
use <keystone/keystone.scad>;

// --- style/decomposition invariants (#38: "standard" replaces #31's wrong
// ramped-window "lip" guess as the canonical retention mechanism; "lip"
// becomes a deprecated alias resolving to "standard") ---
assert(keystone_known_styles() == ["standard", "face"], "styles list");
assert(keystone_face() == [14.5, 16.0], "jack face invariant");
assert(keystone_opening("face") == [14.70, 16.40], "face-grip opening (Samm [A])");

// keystone_slot("standard") -- measured channel/slit geometry (#38,
// RESEARCH.md "Standard keystone latch geometry", Model 1: "Ethernet RJ45
// keystone socket wall plate", Printables 1014552), values verbatim.
sl = keystone_slot("standard");
assert(len(sl) == 10,
       "slot [back_wall_depth,wall_thickness,mouth_w,mouth_h,top_slit_w,top_slit_len,top_slit_depth,bot_slit_w,bot_slit_len,bot_slit_depth]");
assert(sl[0] == 10.05, "back_wall_depth [C] (1014552+533549 cross-model corroboration)");
assert(sl[1] == 1.51,  "wall_thickness //VERIFY (1014552, single-model)");
assert(sl[2] == 15.3,  "mouth_w //VERIFY (1014552)");
assert(sl[3] == 18.4,  "mouth_h //VERIFY (1014552)");
assert(sl[4] == sl[2], "top_slit_w == mouth_w (slit runs the full channel width, no local narrowing -- 1014552)");
assert(sl[5] == 8.0,   "top_slit_len //VERIFY (1014552)");
assert(sl[6] == 2.05,  "top_slit_depth //VERIFY mm (same-start-depth finding is [C] jointly w/ 533549, see keystone.scad)");
assert(sl[7] == sl[2], "bot_slit_w == mouth_w (same full-width finding)");
assert(sl[8] == 6.5,   "bot_slit_len //VERIFY (1014552)");
assert(sl[9] == sl[6], "bot_slit_depth == top_slit_depth (both slits start together, [C] jointly w/ 533549 -- the finding that distinguishes \"standard\" from #31's staged \"lip\" mechanism)");

// keystone_notch("standard") -- measured jack-side fulcrum/arm geometry
// (#38, RESEARCH.md "Insert (module) geometry", Model 1: "SMA-Keystone
// Modul", Printables 366437), values verbatim.
nt = keystone_notch("standard");
assert(len(nt) == 9,
       "notch [fulcrum_base,fulcrum_protrusion,fulcrum_z,arm_thickness,arm_length,arm_root_z,topnotch_base,topnotch_protrusion,topnotch_z]");
assert(nt[0] == 2.0 && nt[1] == 1.5, "fulcrum base/protrusion //VERIFY (366437)");
assert(nt[2] == 7.1, "fulcrum_z //VERIFY (366437; midpoint of the measured 6.1-8.1mm range)");
assert(nt[3] == 1.7 && nt[4] == 14.0, "arm thickness/free-length //VERIFY (366437)");
assert(nt[5] == 20.0, "arm_root_z //VERIFY (366437; unmeasurable in 314383's unregistered Hook.stl)");
assert(nt[6] == 2.6 && nt[7] == 1.0, "topnotch base/protrusion //VERIFY (366437)");
assert(nt[8] == 7.4, "topnotch_z //VERIFY (366437; midpoint of the measured 6.1-8.7mm range)");
// Push-to-click, same-depth mechanism (RESEARCH.md "Mechanism write-up"):
// both notches must seat within their respective slit's Z-range.
assert(nt[2] >= sl[9] && nt[2] <= sl[9] + sl[8], "fulcrum_z falls inside the bottom slit's Z-range");
assert(nt[8] >= sl[6] && nt[8] <= sl[6] + sl[5], "topnotch_z falls inside the top slit's Z-range");

// --- alias resolution: "lip" is now a DEPRECATED ALIAS for "standard" (not
// a second first-class style); nullary/undefined also resolves to "standard" ---
assert(keystone_opening("lip") == keystone_opening("standard"), "opening: lip aliases to standard");
assert(keystone_opening() == keystone_opening("standard"), "opening: nullary defaults to standard");
assert(keystone_slot("lip") == keystone_slot("standard"), "slot: lip aliases to standard");
assert(keystone_notch("lip") == keystone_notch("standard"), "notch: lip aliases to standard");

// keystone_opening("standard") -- width reuses keystone_slot()'s mouth_w
// (single source, no discrepancy: the slit doesn't narrow in X); height is
// RESEARCH.md's DIRECTLY measured max window at slit onset (22.25mm,
// //VERIFY, single-model 1014552) -- NOT mouth_h + 2*wall_thickness, which
// was tried and found wrong in review: the real opening is asymmetric
// (bottom +1.5mm, top +2.35mm) and wall_thickness is a separate,
// symmetric, residual-material quantity, not the opening amount.
assert(keystone_opening("standard") == [sl[2], 22.25],
       "standard opening = [mouth_w, measured max window height @ slit onset]");
assert(keystone_opening("standard")[1] > sl[3], "standard opening height exceeds the plain (pre-slit) mouth height");

// --- keystone_boss_footprint() / style-aware min_pitch (#38 update of the
// #31 pattern to the "standard" channel) ---
bf = keystone_boss_footprint("standard");
assert(len(bf) == 3 && bf[0] > 0 && bf[1] > 0,
       "boss footprint [w,h,y_center] positive w/h");
assert(bf[0] > keystone_opening("standard")[0], "boss footprint adds wall margin beyond the raw opening");
assert(keystone_min_pitch("standard") == bf[0],
       "standard min_pitch is boss-footprint-driven, not the plain opening+wall formula");
assert(keystone_min_pitch("face") == keystone_opening("face")[0] + keystone_min_wall(),
       "face min_pitch formula unchanged");
assert(keystone_pitch() >= keystone_min_pitch("standard"),
       "nominal keystone pitch (19.05mm) still clears the boss-aware standard min_pitch");

// --- metric invariants (always hold regardless of sourced numbers) ---
o = keystone_opening();
assert(len(o) == 2 && o[0] > 0 && o[1] > 0, "opening [ow,oh] positive");

b = keystone_body();
assert(len(b) == 3 && b[0] > 0 && b[1] > 0 && b[2] > 0, "body [bw,bh,bd] positive");
// Body (jack keep-out) must cover the FACE in X,Y. The "standard" opening is
// intentionally taller than the jack (slit clearance margin), so it may
// exceed the body height -- compare the body to the face, not the opening.
f = keystone_face();
assert(b[0] >= f[0] && b[1] >= f[1], "body at least as large as jack face in X,Y");

pt = keystone_plate_thickness();
assert(len(pt) == 2 && pt[0] > 0 && pt[1] > pt[0], "plate thickness [min,max], min<max");

assert(keystone_pitch() > 0, "pitch > 0");
assert(keystone_min_wall() > 0, "min_wall > 0");

// --- fit-check identity (locks the single-source spacing rule) ---
assert(keystone_min_pitch("face") == keystone_opening("face")[0] + keystone_min_wall(),
       "min_pitch(\"face\") == opening_w + min_wall");
assert(keystone_pitch() >= keystone_min_pitch(), "nominal pitch clears default-style (standard) min_pitch");

// layout_ok: a strip at nominal pitch fits; a strip below min_pitch does not.
mp = keystone_min_pitch();
assert(keystone_layout_ok([0, keystone_pitch(), 2 * keystone_pitch()]) == true,
       "nominal-pitch strip fits");
assert(keystone_layout_ok([0, mp - 0.5]) == false, "sub-min gap rejected");
assert(keystone_layout_ok([0]) == true, "single port always fits");

// --- Flagship insert data accessors (#54 Task 1, [B] caliper, Tecmojo
// nominal -- RESEARCH.md "Flagship insert mechanism -- [B] caliper (#54)") ---
assert(keystone_insert_face()  == [14.3, 16.0], "insert face");
assert(keystone_insert_depth() == 20, "insert depth default");
assert(keystone_insert_guide_rib() == [0.8, 7.6, 1.4, 10.0], "guide rib");
assert(keystone_insert_lug()   == [7.8, 1.2, 7.0, 6.6], "retention lug");
assert(keystone_insert_latch() == [9.2, 15.0, 3.6, 5.2, 0.9, 2.2, 4.3, 3.0, 3.1], "cantilever latch");

echo("keystone_test OK");

/* [Placeholder] — smoke render; numeric bbox checked in tests/test_keystone_lib.sh */
keystone_placeholder();

/* [Cutout] — smoke render: window cut from a representative 3mm plate.
   Numeric extents checked in tests/test_keystone_lib.sh. */
translate([30, 0, 0]) difference() {
    translate([-15, -15, -3]) cube([30, 30, 3]); // stand-in faceplate
    keystone_cutout(plate_thickness = 3.0);
}

/* [Insert] — smoke render: caliper-faithful flagship insert (#54) -- default
   reference, guides-off, and tuned fit/latch_wall variants. Numeric bbox and
   feature-position checks live in tests/test_keystone_lib.sh. */
translate([-30,  0, 0]) keystone_insert();
translate([-30, 30, 0]) keystone_insert(guides = false);
translate([-30, 60, 0]) keystone_insert(fit = 0.3, latch_wall = 1.2);

/* [Boss] (#38) — smoke render: local material behind a thin 3mm plate,
   hosting the "standard" channel's full ~10mm+ depth. Numeric checks
   (footprint, cutout section) in tests/test_keystone_lib.sh. */
translate([60, 0, 0]) union() {
    translate([-15, -15, -3]) cube([30, 30, 3]); // stand-in thin faceplate
    keystone_boss(plate_thickness = 3.0, style = "standard");
}

/* [Boss+Cutout assembly] (#38) — smoke render: the real consumer pattern
   (union the boss into the plate, then difference the cutout through both)
   -- confirms the full standard channel forms in solid material even though
   the plate alone (3mm) is far thinner than the channel's own depth. */
translate([90, 0, 0]) difference() {
    union() {
        translate([-15, -15, -3]) cube([30, 30, 3]);
        keystone_boss(plate_thickness = 3.0, style = "standard");
    }
    keystone_cutout(plate_thickness = 3.0, style = "standard");
}

// keystone_boss() is a no-op for "face" (plain-rectangle cutout already fits
// keystone_plate_thickness() unchanged) -- smoke-render it anyway so a
// regression that accidentally emits geometry for "face" would show up in
// the STL bbox (not asserted numerically; visual/manifold smoke check only).
translate([120, 0, 0]) union() {
    translate([-15, -15, -3]) cube([30, 30, 3]);
    keystone_boss(plate_thickness = 3.0, style = "face");
}
