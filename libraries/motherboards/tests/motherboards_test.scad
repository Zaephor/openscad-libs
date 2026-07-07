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

// mini-ITX holes C,F,H,J returned in the component-up frame (drawing x mirrored to
// width-x). Rows reconciled to the measured shared chassis grid (row2 = 165.10, not
// 154.94 -- see RESEARCH.md Task 10). Expected component coords:
// C(163.65,10.16) F(6.17,33.02) H(163.65,165.10) J(6.17,165.10).
ITX_HOLES_EXPECT = [[163.65,10.16],[6.17,33.02],[163.65,165.10],[6.17,165.10]];
assert(len(mobo_standoff_xy("itx")) == 4, "itx has exactly 4 holes");
for (p = mobo_standoff_xy("itx"))
    assert(_in_set(p, ITX_HOLES_EXPECT), str("itx hole ", p, " not in expected C,F,H,J set"));
for (q = ITX_HOLES_EXPECT)
    assert(_in_set(q, mobo_standoff_xy("itx")), str("expected itx hole ", q, " missing"));

// Subset invariant: the ATX-SHARED microATX holes are ⊆ ATX (NOT itx ⊆ atx, and NOT
// the full matx set ⊆ atx — see below for why each of those is wrong).
//
// CORRECTION #1 vs the original brief: the brief proposed "every ITX hole is an ATX
// hole". That does not hold in this library's corner datum: ITX's board-mounting
// insets (~6.2mm) differ from ATX's (16.51mm) because ITX is a much smaller board
// measured from its own corner, so ITX holes never coincide with ATX holes in
// corner coordinates (RESEARCH.md "IMPORTANT FINDING").
//
// (shared-hole invariant removed: matx/atx share standoffs in CHASSIS space, not in
// each board's own corner frame — see RESEARCH rear-right sharing. Task 4 adds the
// corrected invariants.)

// In-envelope: every hole within its own board outline, for ALL THREE form factors.
module _check_envelope(ff) {
    sz = mobo_size(ff);
    assert(len([for (p = mobo_standoff_xy(ff))
                if (p[0] < -0.01 || p[0] > sz[0] + 0.01 || p[1] < -0.01 || p[1] > sz[1] + 0.01) 1]) == 0,
           str(ff, " holes within envelope"));
}
_check_envelope("atx"); _check_envelope("matx"); _check_envelope("itx");

// I/O window within the board, for every ff. In the component-up frame the I/O cluster
// sits at the LOW-X (origin-corner) end, and the shield opening may extend slightly past
// that origin-corner edge (chassis feature -> negative x_off, ~-2.44mm atx / ~-1.45mm itx).
// So the overhang tolerance is on the LOW-X side; the high-X (far) edge stays within width.
IO_OVERHANG = 3.0; // mm — max overhang tolerance (low-X / origin-corner side)
module _io_in_board(ff) {
    sz = mobo_size(ff); io = mobo_io_cutout(ff); // [x_off,w,h]
    assert(io[0] >= -IO_OVERHANG, str(ff, " io x_off within origin-corner shield overhang"));
    assert(io[0] + io[1] <= sz[0] + 0.01, str(ff, " io far edge within width"));
}
for (ff = mobo_known_ff()) _io_in_board(ff);

// PCIe slot opening footprint width (matches the 12mm cube in mobo_pcie_cutout).
PCIE_SLOT_W = 12;

// PCIe slots within the board (no +X overflow), for every ff. Check the LAST
// slot's FAR edge (start + slot width), not just its start.
module _pcie_in_board(ff) {
    sz = mobo_size(ff); o = mobo_pcie_first_xy(ff); n = mobo_pcie_count(ff);
    last_edge = o[0] + (n - 1) * mobo_pcie_pitch() + PCIE_SLOT_W;
    assert(last_edge <= sz[0] + 0.01, str(ff, " pcie last slot (far edge) within width"));
    assert(o[0] >= -0.01, str(ff, " pcie first slot >= 0"));
}
for (ff = mobo_known_ff()) _pcie_in_board(ff);

// PCIe slots on the rear edge (Y=0), for every ff. This was the original bug.
for (ff = mobo_known_ff())
    assert(mobo_pcie_first_xy(ff)[1] == 0, str(ff, " pcie on rear edge (Y=0)"));

// I/O window and PCIe slot span are DISJOINT in X (the bug that started this) --
// for ATX and microATX, where the I/O panel and the multi-slot expansion bank sit at
// opposite ends of the rear edge. Each slot occupies [x, x+PCIE_SLOT_W].
module _io_pcie_disjoint(ff) {
    io = mobo_io_cutout(ff); o = mobo_pcie_first_xy(ff); n = mobo_pcie_count(ff);
    io_lo = io[0]; io_hi = io[0] + io[1];
    pcie_lo = o[0]; pcie_hi = o[0] + (n - 1) * mobo_pcie_pitch() + PCIE_SLOT_W;
    // disjoint iff one range ends before the other begins
    assert(io_hi <= pcie_lo + 0.01 || pcie_hi <= io_lo + 0.01,
           str(ff, " I/O window and PCIe slots must not overlap in X"));
}
// NOT itx: mini-ITX is too cramped for this invariant. Its single expansion slot is
// chassis-co-located with the ATX/microATX I/O-nearest slot (measured), which lands in
// the same narrow high-X strip as mounting hole C on a 170mm board -- the slot and the
// standoff genuinely coexist there on real mini-ITX boards. So itx is exempt from both
// the io/pcie-disjoint and the slot-clears-holes checks (see RESEARCH.md Task 10). The
// itx slot X is [C]//VERIFY (undimensioned in the mini-ITX Addendum).
for (ff = ["atx", "matx"]) _io_pcie_disjoint(ff);

// Chassis-consistency (the physical interoperability constraint -- RESEARCH.md Task 10):
// all three boards mount right-corner-aligned, so in the COMPONENT frame (X measured from
// the shared right edge) the standoffs they share must have the SAME X+Y. Every microATX/
// mini-ITX hole in the shared low-X region must coincide with an ATX hole (tol 0.4mm to
// absorb cross-source rounding; the ITX addendum and the ATX pixel measurement differ ~0.2).
function _near_tol(a, b, t) = abs(a[0]-b[0]) < t && abs(a[1]-b[1]) < t;
function _in_set_tol(p, set, t) = len([for (q = set) if (_near_tol(p, q, t)) 1]) > 0;
module _shares_atx_standoffs(ff) {
    atx = mobo_standoff_xy("atx");
    for (p = mobo_standoff_xy(ff))
        if (p[0] < 170) // component low-X = the shared (right-corner) columns
            assert(_in_set_tol(p, atx, 0.4),
                   str(ff, " shared standoff ", p, " does not co-locate with an ATX standoff"));
}
_shares_atx_standoffs("matx");
_shares_atx_standoffs("itx");

echo("motherboards_test OK");
