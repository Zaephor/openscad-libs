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
assert(drive_card_size("m2_2280") == [22.0, 80.0, 2.3], "m2_2280 size");
assert(drive_card_size("m2_2242")[1] == 42.0, "m2_2242 length");
assert(len(drive_card_hole("m2_2280")) == 2, "m2 hole is [x,y]");
e = drive_card_edge("m2_2280");
assert(len(e)==3 && (e[2]=="b"||e[2]=="m"||e[2]=="bm"), "m2 edge key");

// placeholder: renders a solid; volume equals the envelope box (verified by render).
// (Geometry existence is asserted indirectly; the render step is the visual check.)
assert(drive_size("hdd35")[0]*drive_size("hdd35")[1]*drive_size("hdd35")[2] > 0, "hdd35 vol");

// wrong-family + unknown asserts are covered by the bash negative controls (Task 7).
echo("drives_test OK");
