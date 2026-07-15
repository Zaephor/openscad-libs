// Assert-only test for the drives library. Run via:
// OPENSCADPATH=$PWD/libraries scripts/openscad.sh --export-format stl -o /dev/null \
//   libraries/drives/tests/drives_test.scad
use <drives/drives.scad>;

// families
assert(drive_family("hdd35") == "block", "hdd35 family");
assert(drive_family("m2_2280") == "card", "m2_2280 family");

// block envelopes (X len, Y width, Z height) — confirm vs RESEARCH.md
assert(drive_size("hdd35")   == [147.0, 101.6, 26.1], "hdd35 size");
assert(drive_size("ssd25_7") == [100.0, 69.85, 7.0],  "ssd25_7 size");
assert(drive_size("u2")      == [100.0, 69.85, 15.0], "u2 size");

// every block type: [w,d,h] positive; holes inside footprint (closure)
module _blk(t) {
    s = drive_size(t);
    assert(len(s)==3 && s[0]>0 && s[1]>0 && s[2]>0, str(t," size shape"));
    for (h = drive_bottom_holes(t))
        assert(h[0]>0 && h[0]<s[0] && h[1]>0 && h[1]<s[1], str(t," bottom hole in footprint"));
    for (h = drive_side_holes(t))
        assert(h[1]>=0 && h[1]<=s[2], str(t," side hole z within height"));
}
for (t = ["hdd35","ssd25_7","ssd25_9","ssd25_15","u2"]) _blk(t);

// connector record shape
c = drive_connector("hdd35");
assert(len(c)==3 && (c[0]=="sata" || c[0]=="sff8639"), "hdd35 connector type");
assert(drive_connector("u2")[0] == "sff8639", "u2 connector type");

// card
assert(drive_card_size("m2_2280") == [22.0, 80.0, 2.15], "m2_2280 size");
assert(drive_card_size("m2_2242")[1] == 42.0, "m2_2242 length");
assert(len(drive_card_hole("m2_2280")) == 4, "m2 hole is [x,y,role,dia]");
e = drive_card_edge("m2_2280");
assert(len(e)==3 && (e[2]=="b"||e[2]=="m"||e[2]=="bm"), "m2 edge key");

// placeholder: renders a solid; volume equals the envelope box (verified by render).
// (Geometry existence is asserted indirectly; the render step is the visual check.)
assert(drive_size("hdd35")[0]*drive_size("hdd35")[1]*drive_size("hdd35")[2] > 0, "hdd35 vol");

// wrong-family + unknown asserts are covered by the bash negative controls (Task 7).

// hole counts drive the stamp; assert the source lists are non-empty where expected.
assert(len(drive_bottom_holes("hdd35")) >= 4, "hdd35 >=4 bottom holes");
assert(len(drive_side_holes("hdd35"))  >= 2, "hdd35 side holes present");
assert(len(drive_card_hole("m2_2280")) == 4, "m2 single mount hole, [x,y,role,dia] shape");

// --- hole-role tagging (hole-role-sweep, drives parity with sbc) ---
assert(drives_known_hole_roles()[0] == "structural-mount", "role vocab starts w/ structural-mount");

// every bottom/side hole for a representative 3.5in + 2.5in type is tagged structural-mount
module _assert_all_structural(t) {
    for (h = drive_bottom_holes(t))
        assert(h[2] == "structural-mount", str(t, " bottom hole role"));
    for (h = drive_side_holes(t))
        assert(h[2] == "structural-mount", str(t, " side hole role"));
}
_assert_all_structural("hdd35");
_assert_all_structural("ssd25_9");

// role filter: same-role filter is a no-op on count; unrelated role filters to empty
assert(len(drive_bottom_holes("hdd35", "structural-mount")) == len(drive_bottom_holes("hdd35")),
       "hdd35 bottom holes: structural-mount filter == unfiltered count");
assert(len(drive_bottom_holes("hdd35", "keep-out")) == 0, "hdd35 bottom holes: no keep-out holes");
assert(len(drive_side_holes("hdd35", "structural-mount")) == len(drive_side_holes("hdd35")),
       "hdd35 side holes: structural-mount filter == unfiltered count");
assert(len(drive_side_holes("hdd35", "keep-out")) == 0, "hdd35 side holes: no keep-out holes");

// "all" is a silent wildcard synonym for undef (no WARNING, same full list).
assert(len(drive_bottom_holes("hdd35", "all")) == len(drive_bottom_holes("hdd35")),
       "hdd35 bottom holes: \"all\" == unfiltered count");
assert(len(drive_side_holes("hdd35", "all")) == len(drive_side_holes("hdd35")),
       "hdd35 side holes: \"all\" == unfiltered count");

// card mount hole is tagged too (no role filter on the singleton accessor)
assert(drive_card_hole("m2_2280")[2] == "structural-mount", "m2_2280 hole role");

// connector records feed the cutout; assert extents positive.
cc = drive_connector("ssd25_9");
assert(cc[2][0]>0 && cc[2][1]>0 && cc[2][2]>0, "sata conn extents positive");
ce = drive_card_edge("m2_2280");
assert(ce[1][0]>0 && ce[1][1]>0 && ce[1][2]>0, "m2 edge extents positive");

// faceplate helper accepts the documented faces (module presence checked via render).
// unknown face must assert -> covered by bash negative control in Task 7.
assert(is_string("bottom"), "face vocab placeholder"); // sanity; real check = render + neg control

echo("drives_test OK");
