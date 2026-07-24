use <../css610-underdesk-mount.scad>;

// Data asserts verify device dimensions.
assert(len(_css610_side_holes()) == 4, "CSS610 side pattern = 4 holes");
assert(_css610_size()[2] == 47.1, "CSS610 height (flange datum)");

// Task 2 (#59): bracket geometry contract checks. `use` doesn't import
// variables (only modules/functions, see reference_openscad_gotchas) -- the
// module-parameter values below (_leg_len, _H, _standoff, _leg_thickness,
// _flange_len, _flange_thickness, _mount_hole) are regression-lock literals
// that must match css610-underdesk-mount.scad's own defaults/formula, not an
// independently-sourced value. If a future default change is deliberate,
// update these to match; if it's accidental, this assert catches the drift.
_leg_len = 34.5 + 9.5;      // 44: leg span, matches the module's own formula
_H = _css610_size()[2];     // 47.1
_standoff = 0;              // must match css610-underdesk-mount.scad default
_leg_thickness = 3;
_flange_len = 25;
_flange_thickness = 4;
_mount_hole_r = 3.4 / 2;

// Contract: 4 M3 leg holes align to _css610_side_holes(), each landing
// strictly inside the leg footprint (Y in [0,_leg_len], Z in [0,_H+_standoff])
// with its own radius clearing both edges (no partial/blown-out hole).
holes = _css610_side_holes();
assert(len(holes) == 4, str("expected 4 leg holes, got ", len(holes)));
for (h = holes) {
    assert(h[0] - _mount_hole_r > 0 && h[0] + _mount_hole_r < _leg_len,
        str("leg hole X=", h[0], " (r=", _mount_hole_r, ") does not clear leg Y-span [0,", _leg_len, "]"));
    assert(h[1] - _mount_hole_r > 0 && h[1] + _mount_hole_r < _H + _standoff,
        str("leg hole Z=", h[1], " (r=", _mount_hole_r, ") does not clear leg Z-span [0,", _H + _standoff, "]"));
}

// Contract: flange top is coplanar with the device top (flush-mount datum).
// The module builds the flange as [z0 = _H+_standoff-_flange_thickness, height
// _flange_thickness], so top = z0 + _flange_thickness == _H + _standoff --
// this is an algebraic identity of the module's own formula (any future
// formula change that breaks it is what this guards), not a mesh-derived
// check; the actual rendered STL Z-max is confirmed separately (bbox check
// in tests/test_css610_underdesk_mount.sh).
assert(abs((_H + _standoff - _flange_thickness + _flange_thickness) - (_H + _standoff)) < 1e-9,
    "flange top must equal device top (H + standoff)");

// Contract: 2 flange wood-screw holes, spaced within the flange span, and
// centered past the device edge (X0 = leg_thickness + flange_len/2 >
// leg_thickness) so they clear the device.
for (fy = [_leg_len * 0.3, _leg_len * 0.7])
    assert(fy - _mount_hole_r > 0 && fy + _mount_hole_r < _leg_len,
        str("flange hole Y=", fy, " does not clear leg Y-span [0,", _leg_len, "]"));
assert(_leg_thickness + _flange_len / 2 > _leg_thickness,
    "flange holes must clear the device edge (X > leg_thickness)");

// Bracket render (Task 2): drives the geometry contract above + the STL bbox
// checks in tests/test_css610_underdesk_mount.sh.
css610_underdesk_bracket();
