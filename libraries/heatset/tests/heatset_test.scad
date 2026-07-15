// Assert-only test for the heatset library. No geometry — run via
// OPENSCADPATH=$PWD/libraries scripts/openscad.sh --export-format stl -o /dev/null libraries/heatset/tests/heatset_test.scad
use <heatset/heatset.scad>;

// full size list present, in order
assert(heatset_known_sizes() == ["M2", "M2.5", "M3", "M4", "M5", "M6"], "size list");

// per-size invariants (see RESEARCH.md for sourcing/tiers)
for (s = heatset_known_sizes()) {
    assert(heatset_insert_od(s) > 0, str(s, " insert_od > 0"));
    assert(heatset_insert_length(s) > 0, str(s, " insert_length > 0"));
    assert(heatset_pilot_dia(s) < heatset_insert_od(s), str(s, " pilot_dia < insert_od (melt-grip)"));
    assert(heatset_boss_od(s) > heatset_insert_od(s), str(s, " boss_od > insert_od"));
    assert(heatset_lead_in(s) >= 0, str(s, " lead_in >= 0"));
}

// fully-[A]/[B] fetched rows — locked exact values (RESEARCH.md canonical table)
assert(heatset_insert_od("M2") == 3.73, "M2 insert_od");
assert(heatset_insert_length("M2") == 4.00, "M2 insert_length");
assert(heatset_pilot_dia("M2") == 3.23, "M2 pilot_dia");

assert(heatset_insert_od("M6") == 8.69, "M6 insert_od");
assert(heatset_insert_length("M6") == 12.70, "M6 insert_length");
assert(heatset_pilot_dia("M6") == 8.03, "M6 pilot_dia");

// boss_od derivation: flat 2.5x insert_od per RESEARCH.md (SPIROL midpoint rule),
// table values rounded to 1 decimal — check within rounding tolerance, not exact.
for (s = heatset_known_sizes())
    assert(abs(heatset_boss_od(s) - heatset_insert_od(s) * 2.5) < 0.05,
           str(s, " boss_od ~= 2.5x insert_od"));

echo("heatset_test OK");

/* [Placeholder] — insert envelope for fit/interference checks */
heatset_placeholder("M3");
