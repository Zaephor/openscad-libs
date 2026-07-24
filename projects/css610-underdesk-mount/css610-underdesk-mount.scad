// css610-underdesk-mount — L-bracket (printed L+R pair) to hang a MikroTik
// CSS610-8G-2S+IN under a desk: bolts to the device side M3 pattern, top flange
// flush with the device top, wood screws up into the desk. Standalone (no libs);
// device data project-local [A] MikroTik dimensional drawing. See README.

/* [Device data — MikroTik CSS610-8G-2S+IN, [A] dimensional drawing] */
function _css610_size() = [200.9, 166.6, 47.1];  // W, D, H [A]
// side mount holes (per side): 25x25 square, X from mounting-end edge, Z from bottom. M3.
function _css610_side_holes() = [[9.5,9.5],[9.5,34.5],[34.5,9.5],[34.5,34.5]]; // [A] positions

/* [Bracket] */
leg_thickness = 3; flange_thickness = 4; gusset = 8;
mount_hole = 3.4;   // M3 clearance [A]/[B] user-confirmed
wood_screw = 4; csk_dia = 8;
flange_len = 25; standoff = 0;

assert(len(_css610_side_holes()) == 4, "CSS610 side pattern = 4 holes");
assert(_css610_size()[2] == 47.1, "CSS610 height (flange datum)");

/* [Bracket module]
 * Datum: device side plane at X=0 (leg lies flat on it), device top at
 * Z=H. Leg grows +X (into the bracket, outward from the device); flange
 * sits at the device-top plane and projects further +X (outward). The
 * device itself occupies X <= 0 (see the fit-viz envelope below) so the
 * leg is flush against the device's side face, not embedded in it.
 * VERIFIED (Task 3, #59) via verify-scad-geometry (headless STL render +
 * colored side-profile overlay of the bracket against `% cube(_css610_size())`,
 * translated to sit flush at X<=0 -- see task-3-report.md for the render
 * evidence): 4 M3 holes align to _css610_side_holes() (Y,Z straight-mapped,
 * no further transform needed); flange top is coplanar with the device top
 * (Z = H + standoff, confirmed both algebraically and via the STL bbox
 * check in tests/test_css610_underdesk_mount.sh); wood-screw holes clear
 * the device's physical edge (X0 = leg_thickness + flange_len/2 = 15.5,
 * hole extent [11.5,19.5] entirely on the +X side of the device envelope's
 * X<=0 boundary -- not just the formal X > leg_thickness contract).
 * CONTRACT: 4 M3 clearance holes align to _css610_side_holes(); flange top
 * is coplanar with the device top (Z = H + standoff); wood-screw holes
 * clear the device edge (X > leg_thickness); gusset is a 45 degree
 * (equal-leg) triangle.
 * PRINT ORIENTATION (support-free, Task 3, #59 -- see design-for-print
 * skill): print with the flange's device-facing top (model Z=H+standoff)
 * resting on the bed -- i.e. upside-down relative to the installed
 * orientation, leg rising off the bed. This lines up the countersink's
 * cone axis with the build (Z) direction, mouth-up (the cone widens as
 * print height increases -- self-supporting per the countersink glossary
 * entry, since its half-angle is exactly 45 deg), and the gusset's cross
 * section shrinks monotonically as build height increases (verified by
 * hand: at build height z, gusset X-extent is [leg_thickness, 15-z] for
 * z in [4,12] in the local flange-top-down frame -- strictly shrinking, no
 * new unsupported material ever appears). The 4 M3 holes end up
 * horizontal (bored across layers) in this orientation, but at 3.4mm
 * diameter they're well inside the ~5mm bridging-safe range this repo's
 * design-for-print skill cites, so no teardrop treatment is needed.
 * L/R MIRROR (Task 3, #59): `side` selects "R" (default, as designed) or
 * "L" (mirrored across Y). Because _css610_side_holes()'s Y-values (9.5,
 * 34.5) are symmetric about leg_len/2=22, and the wood-screw Y-positions
 * (leg_len*0.3, leg_len*0.7) are too, mirroring in Y maps this bracket's
 * hole set onto itself -- with this device's current (symmetric) data, the
 * "L" and "R" variants are congruent (literally the same solid, verified
 * in tests/asserts.scad), so one STL currently serves both sides. The
 * `side` param is still exposed/asserted so a future asymmetric hole-data
 * correction produces a correctly mirrored "L" without a module rewrite. */
module css610_underdesk_bracket(side = "R") {
    assert(side == "L" || side == "R", str("side must be \"L\" or \"R\", got \"", side, "\""));
    H = _css610_size()[2];   // 47.1
    holes = _css610_side_holes();
    // leg span: cover the hole pattern (X 9.5..34.5, Z 9.5..34.5) + margin
    // past the max hole X (mapped to leg Y below) to the top of the leg.
    // Margin (9.5) matches the pattern's own min-edge offset, same convention
    // as the hardcoded literal this replaces (34.5 + 9.5 = 44).
    leg_len = max([for (h = holes) h[0]]) + 9.5;   // along the device length (mapped to leg Y here)

    module _body() {
        difference() {
            union() {
                // vertical leg (flat against the device side): plate in the
                // Y-Z plane, leg_thickness thick in X.
                cube([leg_thickness, leg_len, H + standoff]);
                // top flange: horizontal plate at the device-top plane,
                // projecting +X (outward) past the leg's outer face.
                translate([0, 0, H + standoff - flange_thickness])
                    cube([flange_len + leg_thickness, leg_len, flange_thickness]);
                // 45deg gusset at the inside corner (leg<->flange), triangular,
                // support-free bracing under the flange overhang. Right angle at
                // the leg-face/flange-underside corner; legs run +X (along the
                // flange underside) and -Z (down the leg face) so the whole
                // triangle stays AT/BELOW the flange-underside plane (z=0 in this
                // local frame) -- it must never poke above it into/through the
                // flange (verified against brief's representative code, which
                // had the third vertex's sign flipped and punched the gusset
                // apex `gusset - flange_thickness` = 4mm above the flush flange
                // top; caught via STL bbox Z-max = 51.1 instead of the expected
                // H+standoff = 47.1).
                translate([leg_thickness, 0, H + standoff - flange_thickness])
                    rotate([-90, 0, 0]) linear_extrude(leg_len)
                        polygon([[0, 0], [gusset, 0], [0, gusset]]);
            }
            // 4x M3 clearance holes on the side pattern (through the leg, X axis).
            for (h = holes)
                translate([-1, h[0], h[1]])   // map pattern (X_edge, Z) -> (leg Y, Z)
                    rotate([0, 90, 0]) cylinder(h = leg_thickness + 2, d = mount_hole, $fn = 32);
            // 2 countersunk wood-screw holes in the flange (bored through Z),
            // spaced along the flange span; centered past the device edge so
            // the screw clears leg_thickness (X0 = leg_thickness). Screw is
            // driven UP from below the flange (accessible from underneath, per
            // the underdesk-mount orientation) so the countersink opens on the
            // flange's BOTTOM face.
            // NOTE (Task 2, #59 fix): the brief's representative code offset the
            // countersink cone by `-flange_thickness` from the `+1` baseline,
            // which left the cone's wide end 1mm short of the flange bottom
            // (H+standoff-flange_thickness) -- a solid 1mm "floor" blocked the
            // hole from ever opening through, caught via a probe at the hole
            // axis on the bottom-face Z-slice (non-empty = blocked). Fixed by
            // extending the offset an extra 1mm (+ a 0.01mm overshoot) so the
            // cone's wide end lands just past the bottom face and its narrow end
            // (matching wood_screw dia) meets the straight bore with no gap.
            for (fy = [leg_len * 0.3, leg_len * 0.7])
                translate([leg_thickness + flange_len / 2, fy, H + standoff + 1]) {
                    cylinder(h = flange_thickness + 2, d = wood_screw, center = true, $fn = 32);
                    translate([0, 0, -flange_thickness - 1.01])
                        cylinder(h = (csk_dia - wood_screw) / 2 + 0.01, d1 = csk_dia, d2 = wood_screw, $fn = 32);
                }
        }
    }

    if (side == "L")
        translate([0, leg_len, 0]) mirror([0, 1, 0]) _body();
    else
        _body();
}

// Device envelope fit-viz (preview only, `%` -- excluded from STL export).
// Placed flush against the leg's back face: the device occupies X in
// [-_css610_size()[0], 0], Y in [0, _css610_size()[1]], Z in
// [0, _css610_size()[2]], so the leg (X in [0, leg_thickness]) sits flat on
// the device's X=0 side face rather than overlapping it (Task 3, #59 fix --
// verify-scad-geometry's overlay caught the original `% cube(_css610_size())`
// with no translate rendering the device on TOP of/overlapping the bracket,
// since both started at X=0; see task-3-report.md).
translate([-_css610_size()[0], 0, 0]) % cube(_css610_size());
css610_underdesk_bracket();
