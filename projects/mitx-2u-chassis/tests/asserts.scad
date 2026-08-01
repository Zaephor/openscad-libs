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

// #40 tongue Y-extent regression: the tongue's tip must land exactly on
// rack10_rear_post_y(standard) -- rack_support_tongue()'s own consumer
// contract -- NOT on _usable_depth() (that fn additionally reserves
// faceplate_th as a separate, more conservative board-depth margin; the two
// intentionally differ, see _tongue_y()'s own comment in the main file).
// This also locks _tongue_y() >= _usable_depth(), i.e. the board always has
// room before the rear wall.
assert(_tongue_y() + rack_support_engagement_depth() == rack10_rear_post_y(standard),
    str("mitx-2u: tongue tip ", _tongue_y()+rack_support_engagement_depth(),
        " != rear post plane ", rack10_rear_post_y(standard)));
assert(_tongue_y() >= _usable_depth(),
    str("mitx-2u: tongue root ", _tongue_y(), " < _usable_depth() ", _usable_depth(),
        " -- rear wall would sit in front of the board's own depth budget"));

// Fan/DC-in flank-offset regression (Task 2 finding, 2026-07-31): unlike the
// sibling mitx-1u-chassis's flat -_clear_w()/4 idiom (which happened to
// clear the gusset only because that project's fan_size=40 is smaller),
// this project's own fan_size=60 default needs the generalized
// _rear_flank_cx() derivation (gusset far edge + hole radius + margin) --
// locks that the flank offset is actually DERIVED from the gusset geometry,
// not a coincidental flat fraction of clear width that could silently stop
// clearing the gusset again after an unrelated edit.
assert(_fan_cx() == -(_gusset_x() + _gusset_xw()/2 + max(fan_size, dc_dia)/2 + _rear_flank_margin()),
    str("mitx-2u: fan_cx ", _fan_cx(), " does not match the derived gusset-clearing offset"));

// LP card keep-out must sit on the OPPOSITE side (high-X) from the fan/DC-in
// flank zone, same "wrong side" regression shape as the IO-vs-PCIe-slot
// check above -- the card's own X (slot centerline) is far out toward the
// panel edge, well clear of both the fan (negative X) and DC-in (positive X,
// but close to center) by construction; this locks that _pcie_slot_cx() is
// clearly outside the +-_rear_flank_cx() flank band, not just numerically
// non-overlapping by a hair.
assert(_pcie_slot_cx() > _rear_flank_cx() + dc_dia/2,
    str("mitx-2u: PCIe slot centerline ", _pcie_slot_cx(),
        " expected clear of (right of) the DC-in flank zone (edge at ", _rear_flank_cx()+dc_dia/2, ")"));

// Fan teardrop cap regression: at THIS project's own defaults (device_u=2,
// fan_size=60) the rear wall is tall enough that the ideal 45deg apex
// (r*sqrt(2) above center) actually FITS within available headroom -- unlike
// the 1U sibling (fan_size=40, much shorter wall), the cap does not engage
// by default here. Locks that this is still true (documents why there's no
// "cap engaged" regression assert here, the mirror image of the 1U file's
// own "expected the default fan_size to need the flat-cap" lock) and that
// the flat-top span stays at exactly 0 as a result.
assert(_fan_teardrop_apex() <= _fan_teardrop_avail(),
    str("mitx-2u: expected the default fan_size to NOT need the flat-cap (ideal apex ",
        _fan_teardrop_apex(), " <= available ", _fan_teardrop_avail(),
        ") -- if this no longer holds, the flat-cap code path is untested here"));
assert(_fan_teardrop_flat_w() == 0,
    str("mitx-2u: expected zero flat-top span at defaults, got ", _fan_teardrop_flat_w()));

// The faceplate aperture must BE the bracket's own I/O window, translated --
// not merely something that happens to fall inside the panel. Locks the
// accessor-to-aperture chain end to end: X on the slot centreline (where the
// card's edge connector plugs in), Z on the ONE fold datum, size straight
// from pcie_bracket_window(). A regression that reverted to
// mobo_pcie_cutout() (a 12mm board-slot box at Z=[7,19]) would fail all four.
_win = pcie_bracket_window("low-profile");
assert(_pcie_ap_cx() == _pcie_slot_cx() + _win[0],
    str("mitx-2u: aperture X ", _pcie_ap_cx(), " is not the bracket window on the slot centreline"));
assert(_pcie_ap_cz() == _pcie_fold_z() + _win[1],
    str("mitx-2u: aperture Z ", _pcie_ap_cz(), " is not the bracket window at the fold datum ", _pcie_fold_z()));
assert(_pcie_ap_w() == _win[2] && _pcie_ap_h() == _win[3],
    str("mitx-2u: aperture size [", _pcie_ap_w(), ",", _pcie_ap_h(),
        "] != bracket window [", _win[2], ",", _win[3], "]"));
// ...and it must lie strictly WITHIN the bracket's own faceplate span, or the
// panel would be cut wider than the part it is supposed to frame.
assert(_pcie_ap_cz() - _pcie_ap_h()/2 > _pcie_fold_z()
    && _pcie_ap_cz() + _pcie_ap_h()/2 < _pcie_fold_z() + _pcie_bracket_h(),
    str("mitx-2u: aperture Z span escapes the bracket faceplate [", _pcie_fold_z(), ",",
        _pcie_fold_z()+_pcie_bracket_h(), "]"));

// Documented model limit, locked so it gets revisited rather than silently
// re-introduced: the bracket foot's structural-mount screw cannot be bored
// into this chassis's floor, because its position lands inside a board
// standoff's own post. This asserts the conflict STILL holds -- if a data
// change ever separates them, this fires and the foot fastener (dropped from
// the model, see mitx-2u-chassis.scad's _pcie_foot_screw_xy() comment)
// becomes worth adding back.
_screw = _pcie_foot_screw_xy();
_min_sep = min([for (h = mobo_standoff_xy("itx", "structural-mount"))
                 norm([_board_x() + h[0] - _screw[0], h[1] - _screw[1]])]);
assert(_min_sep < 6.0/2 + _pcie_foot_screw_r(),
    str("mitx-2u: the PCIe foot screw now clears every standoff (min separation ", _min_sep,
        " >= ", 6.0/2 + _pcie_foot_screw_r(), ") -- revisit adding the foot fastener back"));

// No explicit render call needed -- the include above already re-runs
// mitx-2u-chassis.scad's own trailing mitx_2u_chassis() call (and its
// top-level fit-asserts) at defaults.
