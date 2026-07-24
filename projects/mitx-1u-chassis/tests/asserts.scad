// asserts.scad — default-params render + independent contract checks for
// mitx-1u-chassis (the fit-asserts themselves live in the main .scad,
// evaluated whenever it's rendered/included -- see that file). Rendered
// directly by tests/test_mitx_1u_chassis.sh.
//
// `include` (not `use`) is required so the main file's own top-level
// asserts actually run: `use` does not execute a used file's top-level
// statements (see reference_openscad_gotchas) -- only its module/function
// definitions are imported. Verified empirically (a `use`-only import with a
// -D override left the fit-asserts un-evaluated).
include <../mitx-1u-chassis.scad>;

// Board is mini-ITX (170x170) -- regression lock vs. a future motherboards
// data change silently altering the board this project targets.
assert(_bw() == 170 && _bd() == 170,
    str("mitx-1u: expected 170x170 mini-ITX board, got ", _bw(), "x", _bd()));

// The button sits OUTSIDE the board/IO footprint on the panel's low-X side
// (not just "somewhere on the panel" -- the off-center guard in the main
// file checks panel bounds, not this board-relative placement intent).
assert(_button_x() + button_dia/2 < _io_x0(),
    str("mitx-1u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] must sit clear of (left of) the IO cutout's low edge ", _io_x0()));

// One column of rack10 mounting holes per U is 3 holes (rack10's own 3-hole
// EIA sub-pattern) -- 2 columns x 3 rows = 6 hole positions cut into the
// faceplate. Sanity lock on the library contract this project consumes.
assert(len(rack10_hole_z(1)) == 3,
    str("mitx-1u: expected 3 hole rows per column for u=1, got ", len(rack10_hole_z(1))));

// No explicit render call needed -- the include above already re-runs
// mitx-1u-chassis.scad's own trailing mitx_1u_chassis() call (and its
// top-level fit-asserts) at defaults.
