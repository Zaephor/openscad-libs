// Assert-only test for the motherboards library. No geometry — run via
// tests/test_motherboards_lib.sh. Structural invariants only: this file does NOT
// hardcode standoff coordinates (those are reconstructed data verified in
// RESEARCH.md); it only checks relationships that must hold regardless of the
// exact reconstruction (counts, subset, envelope) plus the publicly-certain
// board sizes and pitch.
use <motherboards/motherboards.scad>;

// Board sizes [width_X, depth_Y] mm (publicly certain dimensions; library uses the
// exact-inch mm values rather than the rounded 244/305 spec figures — see
// RESEARCH.md "Board sizes": 243.84 = exact 9.6", 304.80 = exact 12.0").
assert(mobo_size("atx")  == [304.80, 243.84], "atx size");
assert(mobo_size("matx") == [243.84, 243.84], "matx size");
assert(mobo_size("itx")  == [170, 170],       "itx size");

// PCIe pitch.
assert(mobo_pcie_pitch() == 20.32, "pcie pitch");

// Hole counts per form factor (set in Task 2 reconstruction).
assert(len(mobo_standoff_xy("itx"))  >= 4, "itx >=4 holes");
assert(len(mobo_standoff_xy("atx"))  >= len(mobo_standoff_xy("matx")), "atx superset of matx count");
assert(len(mobo_standoff_xy("matx")) >= len(mobo_standoff_xy("itx")),  "matx superset of itx count");

function _near(a, b) = abs(a[0]-b[0]) < 0.01 && abs(a[1]-b[1]) < 0.01;
function _in_set(p, set) = len([for (q = set) if (_near(p, q)) 1]) > 0;

// Subset invariant: the ATX-SHARED microATX holes are ⊆ ATX (NOT itx ⊆ atx, and NOT
// the full matx set ⊆ atx — see below for why each of those is wrong).
//
// CORRECTION #1 vs the original brief: the brief proposed "every ITX hole is an ATX
// hole". That does not hold in this library's corner datum: ITX's board-mounting
// insets (~6.2mm) differ from ATX's (16.51mm) because ITX is a much smaller board
// measured from its own corner, so ITX holes never coincide with ATX holes in
// corner coordinates (RESEARCH.md "IMPORTANT FINDING").
//
// CORRECTION #2 (found while implementing this task): asserting the FULL matx set
// ⊆ atx is also false and must not be used — matx holes F, B, R are matx-specific
// (RESEARCH.md: "Did not independently close: B, R, S... the certain microATX
// values are the five ATX-shared holes"). Only C, H, L, J, M (the first 5 rows of
// the matx table in motherboards.scad) are verified byte-identical to their ATX
// counterparts (Δ = 0.00mm, RESEARCH.md microATX closure check). The assertion
// below is scoped to exactly that verified-shared subset, not the whole matx array.
matx_shared_xy = [for (i = [0:4]) mobo_standoff_xy("matx")[i]]; // C,H,L,J,M
assert(len([for (p = matx_shared_xy) if (!_in_set(p, mobo_standoff_xy("atx"))) 1]) == 0,
       "matx ATX-shared holes (C,H,L,J,M) subset of atx");

// In-envelope: every hole within its own board outline, for ALL THREE form factors.
module _check_envelope(ff) {
    sz = mobo_size(ff);
    assert(len([for (p = mobo_standoff_xy(ff))
                if (p[0] < 0 || p[0] > sz[0] || p[1] < 0 || p[1] > sz[1]) 1]) == 0,
           str(ff, " holes within envelope"));
}
_check_envelope("atx"); _check_envelope("matx"); _check_envelope("itx");

echo("motherboards_test OK");
