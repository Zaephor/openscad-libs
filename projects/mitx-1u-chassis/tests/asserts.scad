// SPDX-License-Identifier: CC-BY-NC-SA-4.0
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

// IO window is explicitly sized to available headroom, not the library's
// full generic shield height -- regression lock so a future edit can't
// silently reintroduce the oversized cutter (relying on incidental
// faceplate-blank clipping) that this fix removed.
assert(_io_window_h() < _io()[2],
    str("mitx-1u: expected the custom IO window (", _io_window_h(),
        ") to stay smaller than the generic shield height (", _io()[2], ")"));

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

// #40 tongue Y-extent regression: the tongue's tip must land exactly on
// rack10_rear_post_y(standard) -- rack_support_tongue()'s own consumer
// contract (rack-support.scad / README "Buttressing" + "Placement formula")
// -- NOT on _usable_depth() (that fn additionally reserves faceplate_th as a
// separate, more conservative board-depth margin; the two intentionally
// differ, see _tongue_y()'s own comment in the main file). This also locks
// _tongue_y() >= _usable_depth(), i.e. the board always has room before the
// rear wall.
assert(_tongue_y() + rack_support_engagement_depth() == rack10_rear_post_y(standard),
    str("mitx-1u: tongue tip ", _tongue_y()+rack_support_engagement_depth(),
        " != rear post plane ", rack10_rear_post_y(standard)));
assert(_tongue_y() >= _usable_depth(),
    str("mitx-1u: tongue root ", _tongue_y(), " < _usable_depth() ", _usable_depth(),
        " -- rear wall would sit in front of the board's own depth budget"));

// #72 regression lock: the fan opening must be a real honeycomb lattice
// with solid bearing pads at every mount screw, not a round/teardrop bore.
// tests/test_mitx_1u_chassis.sh probes fan_mount_holes(40)'s 4 corners in
// world coordinates derived from _fan_cx()/_rear_center_z() -- lock both
// here so a future change that shifts them fails with a clear message
// instead of silently desyncing from those hand-picked shell probes.
assert(_rear_center_z() == 21.83, str("mitx-1u: expected _rear_center_z()=21.83, got ", _rear_center_z()));
assert(_fan_cx() == -55.5, str("mitx-1u: expected _fan_cx()=-55.5, got ", _fan_cx()));

// Board-vs-side-wall collision guard (final-review finding, 2026-07-28):
// the main file's off-center guard only checks the IO window/button against
// the panel's OUTER bounds -- this locks the board footprint against the
// shell's INTERIOR wall faces too, independent of that check.
assert(_board_x() - wall >= -_clear_w()/2 && _board_x() + _bw() + wall <= _clear_w()/2,
    str("mitx-1u: board [", _board_x(), ",", _board_x()+_bw(),
        "] collides with a side wall (interior span +-", _clear_w()/2 - wall, ")"));

// No explicit render call needed -- the include above already re-runs
// mitx-1u-chassis.scad's own trailing mitx_1u_chassis() call (and its
// top-level fit-asserts) at defaults.
