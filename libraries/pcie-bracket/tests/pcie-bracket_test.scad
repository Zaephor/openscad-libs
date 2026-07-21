// pcie-bracket library test — Task 2.
// pcie_bracket_size(t) field order: [height, foot_width, thickness]
// (see pcie-bracket.scad header for why tab_len/card_off are NOT fields here.)
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

echo("pcie-bracket_test OK");
