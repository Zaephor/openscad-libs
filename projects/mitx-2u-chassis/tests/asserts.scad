// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts.scad — default-params render + independent contract checks for
// mitx-2u-chassis (the fit-asserts themselves live in the main .scad,
// evaluated whenever it's rendered/included -- see that file). Rendered
// directly by tests/test_mitx_2u_chassis.sh. Same idiom as the sibling
// mitx-1u-chassis project's own tests/asserts.scad.
//
// `include` (not `use`) is required so the main file's own top-level
// asserts actually run: `use` does not execute a used file's top-level
// statements (see reference_openscad_gotchas) -- only its module/function
// definitions are imported.
include <../mitx-2u-chassis.scad>;

// Board is mini-ITX (170x170) -- regression lock vs. a future motherboards
// data change silently altering the board this project targets.
assert(_bw() == 170 && _bd() == 170,
    str("mitx-2u: expected 170x170 mini-ITX board, got ", _bw(), "x", _bd()));

// The button sits OUTSIDE the board/IO footprint on the panel's low-X side
// (not just "somewhere on the panel" -- the main file's own guard checks
// panel bounds, not this board-relative placement intent).
assert(_button_x() + button_dia/2 < _io_x0(),
    str("mitx-2u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] must sit clear of (left of) the IO cutout's low edge ", _io_x0()));

// PCIe slot must land on the OPPOSITE (high-X) side from the IO window --
// mobo_pcie_first_xy's own X-flip convention (motherboards.scad) puts the
// slot cluster opposite the IO cluster. A future data/formula change that
// collapsed them onto the same side (or overlapping) would otherwise pass
// every other fit-assert (both individually still fit within the panel).
assert(_pcie_slot_x0() >= _io_x1(),
    str("mitx-2u: PCIe slot [", _pcie_slot_x0(), ",", _pcie_slot_x1(),
        "] expected clear of (right of) the IO cutout's high edge ", _io_x1()));

// One column of rack10 mounting holes per U is 3 holes -- 2U -> 6 hole
// positions cut into the faceplate. Sanity lock on the library contract
// this project consumes.
assert(len(rack10_hole_z(device_u)) == 6,
    str("mitx-2u: expected 6 hole rows for device_u=2, got ", len(rack10_hole_z(device_u))));

// Board-vs-side-wall collision guard, independent of the main file's own
// off-center guard (#42 final-review finding: a bad board_offset can pass
// every OTHER assert while still shoving the board into a side wall).
assert(_board_x() - wall >= -rack10_clear_width(standard)/2
    && _board_x() + _bw() + wall <= rack10_clear_width(standard)/2,
    str("mitx-2u: board [", _board_x(), ",", _board_x()+_bw(),
        "] collides with a side wall (interior span +-", rack10_clear_width(standard)/2 - wall, ")"));

// No explicit render call needed -- the include above already re-runs
// mitx-2u-chassis.scad's own trailing mitx_2u_chassis() call (and its
// top-level fit-asserts) at defaults.
