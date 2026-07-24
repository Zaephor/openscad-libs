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
// NOT checked here -- an algebraic re-derivation from the module's own
// z0/height formula would be a tautology (always true regardless of what
// the module actually computes) and provide zero real verification. The
// real, mesh-derived check lives in tests/test_css610_underdesk_mount.sh's
// STL bbox check (Z-max == H+standoff == 47.1), which DOES catch a wrong
// formula (e.g. the gusset-overshoot bug caught during Task 2 review).

// Contract: 2 flange wood-screw holes, spaced within the flange span, and
// centered past the device edge (X0 = leg_thickness + flange_len/2 >
// leg_thickness) so they clear the device.
for (fy = [_leg_len * 0.3, _leg_len * 0.7])
    assert(fy - _mount_hole_r > 0 && fy + _mount_hole_r < _leg_len,
        str("flange hole Y=", fy, " does not clear leg Y-span [0,", _leg_len, "]"));
assert(_leg_thickness + _flange_len / 2 > _leg_thickness,
    "flange holes must clear the device edge (X > leg_thickness)");

// Contract (Task 3, #59): the bracket must clear the device's PHYSICAL
// envelope, not just the formal X>leg_thickness rule above. Device sits at
// X in [-_css610_size()[0], 0] flush against the leg (see the module's
// fit-viz comment / task-3-report.md verify-scad-geometry render); the
// wood-screw hole (max radius csk_dia/2=4 at its countersink mouth) must
// not cross X=0 into the device.
_csk_dia = 8;   // must match css610-underdesk-mount.scad's own csk_dia default (`use` scope, see note above)
_csk_r = _csk_dia / 2;
assert(_leg_thickness + _flange_len / 2 - _csk_r > 0,
    "flange wood-screw hole (incl. countersink) must clear the device's physical X<=0 envelope");

// L/R mirror (Task 3, #59): side="L" must render without error, and --
// because _css610_side_holes()'s Y-values (9.5, 34.5) and the wood-screw
// Y-positions (leg_len*0.3, leg_len*0.7 = 13.2, 30.8) are each symmetric
// about leg_len/2=22 -- mirroring in Y (44-y) must map each hole set onto
// itself, confirming both L and R variants align to the same device hole
// pattern (verified algebraically here; mesh-level confirmation in
// tests/test_css610_underdesk_mount.sh's L-side hole-void probes).
function _in_set(v, list) = len([for (x = list) if (abs(x - v) < 1e-9) x]) > 0;

_hole_ys = [for (h = holes) h[0]]; // [9.5, 34.5, 9.5, 34.5]
for (y = _hole_ys)
    assert(_in_set(_leg_len - y, _hole_ys),
        str("mirrored M3 hole Y=", _leg_len - y, " (from Y=", y, ") not in original hole-Y set ",
            _hole_ys, " -- L/R mirror would misalign the M3 holes"));

_wood_ys = [_leg_len * 0.3, _leg_len * 0.7]; // [13.2, 30.8]
for (y = _wood_ys)
    assert(_in_set(_leg_len - y, _wood_ys),
        str("mirrored wood-screw hole Y=", _leg_len - y, " (from Y=", y, ") not in original set ",
            _wood_ys, " -- L/R mirror would misalign the wood-screw holes"));

// Bracket render (Task 2/3): drives the geometry contract above + the STL
// bbox checks in tests/test_css610_underdesk_mount.sh. Both L and R render
// here to prove the `side` param produces valid geometry for each.
css610_underdesk_bracket(side = "R");
css610_underdesk_bracket(side = "L");
