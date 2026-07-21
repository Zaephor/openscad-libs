// pcie-bracket library test — Task 2 (data accessors) + Task 3 (geometry).
// pcie_bracket_size(t) field order: [height, foot_width, thickness]
// (see pcie-bracket.scad header for why tab_len/card_off are NOT fields here.)
// Coarse geometry checks (bounding-height, blank-vs-windowed solid-volume)
// live in tests/test_pcie_bracket_lib.sh (STL-bbox/volume, since plain
// OpenSCAD asserts can't introspect a rendered mesh) -- not in this file.
use <pcie-bracket/pcie-bracket.scad>;

assert(pcie_known_brackets() == ["full-height", "low-profile"], "bracket list");
assert(pcie_known_hole_roles() == ["structural-mount", "component-mount", "keep-out", "alignment"], "role vocab");

// low-profile shorter than full-height (PCI-SIG Low Profile ECN ~79.2 vs CEM ~120.65, both [B] per RESEARCH.md)
assert(pcie_bracket_size("low-profile")[0] < pcie_bracket_size("full-height")[0], "LP shorter than FH");

// shared flange/foot width (index 1), both classes [B] per RESEARCH.md
assert(pcie_bracket_size("low-profile")[1] == pcie_bracket_size("full-height")[1], "foot width shared LP/FH");

// one structural-mount screw hole per bracket, valid role + positive dia
hf = pcie_bracket_holes("full-height");
assert(len(hf) == 1, "FH exactly one hole");
assert([for (h = hf) if (h[2] != "structural-mount" || h[3] <= 0) h] == [], "FH hole role/dia");

hlp = pcie_bracket_holes("low-profile");
assert(len(hlp) == 1, "LP exactly one hole");
assert([for (h = hlp) if (h[2] != "structural-mount" || h[3] <= 0) h] == [], "LP hole role/dia");

// role filter: "keep-out" is present-in-vocab but absent-in-data -> legal empty result, not an assert.
assert(pcie_bracket_holes("full-height", "keep-out") == [], "keep-out is a legal no-op filter");

// holes_xy mirrors holes() coordinate pairs only.
assert(pcie_bracket_holes_xy("full-height") == [for (h = hf) [h[0], h[1]]], "holes_xy matches holes");

// Screw-type option (final-review Finding 1): "m3" stays the default (backward
// compatible with the 2-arg call sites above); "6-32" clearance must come from
// this repo's own motherboards.scad accessor (mobo_hole_dia() == 3.96), never
// a re-literaled number, and the M3 default must not silently equal it.
assert(pcie_known_screws() == ["m3", "6-32"], "screw vocab");
assert(pcie_screw_clearance() == 3.4, "default screw clearance is m3/3.4");
assert(pcie_screw_clearance("m3") == 3.4, "m3 clearance");
assert(pcie_screw_clearance("6-32") == 3.96, "6-32 clearance == motherboards.scad's mobo_hole_dia()");
hf_632 = pcie_bracket_holes("full-height", screw = "6-32");
assert(hf_632[0][3] == 3.96, "FH hole dia switches to 6-32 clearance");
assert(hf_632[0][0] == hf[0][0] && hf_632[0][1] == hf[0][1], "screw choice does not move the hole position");
assert(pcie_bracket_holes("full-height", role = "structural-mount", screw = "6-32")[0][3] == 3.96,
       "role + screw compose correctly");

echo("pcie-bracket_test OK");
