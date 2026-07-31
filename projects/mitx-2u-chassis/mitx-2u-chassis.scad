// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// mitx-2u-chassis — 2U 10" rack chassis for a mini-ITX board, front-IO
// appliance (IO shield + power button front) PLUS a front-faceplate
// low-profile PCIe card aperture + bracket mount, external DC-in, fan +
// honeycomb, rear #40 support mate. Same core pattern as the sibling
// mitx-1u-chassis (#42, device_u=1, no PCIe) at device_u=2. Consumes
// motherboards/rack10/rack-support/fans/honeycomb/pcie-bracket.
use <motherboards/motherboards.scad>;
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;
use <pcie-bracket/pcie-bracket.scad>;

/* [Rack] */
standard = "labrax";
ear_type = "slot";
device_u = 2;
/* [Print] */
wall = 2.4; floor_th = 2.0; faceplate_th = 3.0;
standoff_h = 6.0; heatsink_ceiling = 55;
/* [Front] */
button_dia = 12; board_offset = 20;   // off-center X so button fits beside IO
pcie_screw = "6-32";
/* [Cooling / Power] */
dc_dia = 11; fan_size = 60; cell = 8.0; hc_wall = 1.2;
/* [PCIe keep-out] */
// LP card envelope reserved above/behind the slot -- no board- or
// bracket-sourced figure exists for either dimension (pcie-bracket.scad's
// own header explicitly carries no card-length/card-envelope data, see its
// "NOTE (final-review fix, Finding 2)"); these are this project's own
// reasoned design placeholders, //VERIFY, not [B]/[C] tiered claims.
lp_card_h = 64.4; lp_card_len = 168;

function _bw() = mobo_size("itx")[0];   // 170
function _bd() = mobo_size("itx")[1];   // 170
function _int_h() = rack10_device_height(device_u) - floor_th;
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();

// World X of the board's own local origin (rear-left corner, see
// motherboards.scad's datum comment) -- same _board_x() idiom as
// mitx-1u-chassis.scad. Every board-frame feature (standoffs, placeholder,
// IO cutout, PCIe cutout) shares this SAME offset, or they drift apart from
// the actual mounted board (mitx-1u-chassis.scad's own comment on this
// formula; verified here too -- see PCIe/IO cutout comments below).
function _board_x() = board_offset - _bw() / 2;

// IO cutout: mobo_io_cutout returns [x_off, w, h] in the board's own local
// (component-up) frame -- same frame mobo_standoff_xy/mobo_placeholder use
// -- so it shares _board_x() as its world-frame offset.
function _io()    = mobo_io_cutout("itx");
function _io_x0() = _board_x() + _io()[0];              // world low (left) edge
function _io_x1() = _board_x() + _io()[0] + _io()[1];   // world high (right) edge

// PCIe slot: mobo_pcie_first_xy is [x,y] board-local (low-X edge of the
// slot), in the SAME component-up local frame as mobo_io_cutout/
// mobo_standoff_xy (motherboards.scad), so it shares _board_x() too, NOT
// board_offset alone -- verified empirically: translating this block by
// board_offset alone (the plan's original Task-1 draft) put the PCIe
// cutout's world X past the panel's own half-width entirely (a silent
// no-op cut, same failure shape as the mount-hole mirror bug -- see
// CORRECTION 2026-07-31 in the plan's Global Constraints for that one).
function _pcie_xy()      = mobo_pcie_first_xy("itx");
function _pcie_slot_x0() = _board_x() + _pcie_xy()[0];
function _pcie_slot_x1() = _pcie_slot_x0() + mobo_pcie_slot_w();
// pcie_bracket()'s own local X=0 is the card-slot CENTERLINE (its header
// datum comment), not the board corner -- so its world placement tracks
// the slot's centerline, not board_offset directly.
function _pcie_slot_cx() = _pcie_slot_x0() + mobo_pcie_slot_w()/2;

// Power button: sits in the off-center gap on the panel's low-X side,
// beside the IO window (board_offset shifts the board toward +X to open
// this gap) -- same _button_x() idiom as mitx-1u-chassis.scad, centered in
// the gap between the panel's low edge and the IO's own low edge so it
// clears both by construction whenever the gap is wide enough for it.
function _button_x() = (-rack10_panel_width(standard) / 2 + _io_x0()) / 2;

// Rear shell geometry -- same idiom as mitx-1u-chassis.scad's _tongue_y()
// etc (see that file's comment block for the full "why"), scaled to this
// project's own device_u=2 / fan_size=60 defaults. _tongue_y() (NOT
// _usable_depth()) is the #40 tongue's root Y per rack_support_tongue()'s
// own consumer contract -- the two intentionally differ (see plan Global
// Constraints #2).
function _tongue_y()      = rack10_rear_post_y(standard) - rack_support_engagement_depth();
function _clear_w()       = rack10_clear_width(standard);
function _wall_top_z()    = rack10_device_height(device_u);
function _rear_center_z() = _wall_top_z() / 2;
// Gussets flank the tongue immediately, flush against the tongue's own X edge.
function _gusset_xw()   = 10;
function _gusset_x()    = rack_support_rail_size()[0] / 2 + _gusset_xw() / 2;
function _gusset_size() = 15;

// Fan/DC-in centered left/right of the tongue. mitx-1u-chassis.scad's own
// idiom (a flat -_clear_w()/4 offset) is NOT reused verbatim here: at that
// project's fan_size=40 it happened to clear the gusset, but this project's
// own fan_size=60 default (DIMS) does not -- -_clear_w()/4 = -55.5 puts the
// fan's near edge (55.5-30=25.5) INSIDE the gusset's far edge (_gusset_x()+
// _gusset_xw()/2 = 30), a real overlap caught by the fit-assert below at
// render time. This generalizes the idiom instead: derive the flank offset
// FROM the gusset's own far edge + the wider of the two hole radii + a fixed
// margin, so fan/DC-in clear the gusset by construction for any fan_size/
// dc_dia, not just the values that happened to work at 1U's smaller fan.
function _rear_flank_margin() = 2;
function _rear_flank_cx() = _gusset_x() + _gusset_xw()/2 + max(fan_size, dc_dia)/2 + _rear_flank_margin();
function _fan_cx() = -_rear_flank_cx();
function _dc_cx()  =  _rear_flank_cx();

// Fan bore teardrop geometry (mitx-1u-chassis.scad's _mitx_fan_teardrop()
// idiom, see that file for the full "why" -- a plain 45deg teardrop's ideal
// apex, r*sqrt(2) above center, can exceed the rear wall's own headroom to
// its top edge; _mitx2_fan_teardrop() caps it below). At THIS project's own
// defaults (device_u=2, fan_size=60) the cap does not actually engage --
// _wall_top_z() is tall enough that the ideal apex fits -- but the capping
// logic is still required generally (Global Constraints #3) since a larger
// fan_size could push the ideal apex past headroom again.
function _fan_bore_r()          = fan_size * 0.92 / 2;
function _fan_teardrop_apex()   = _fan_bore_r() * sqrt(2);
function _fan_teardrop_avail()  = _wall_top_z() - _rear_center_z();
function _fan_teardrop_flat_w() = 2 * max(0, _fan_teardrop_apex() - _fan_teardrop_avail());

// PCIe bracket foot mount hole (CORRECTION 2026-07-31, see plan Global
// Constraints): unlike the Task 1 keep-out preview (translated to
// floor_th+standoff_h, board/card-slot height, purely for visualizing the
// card in place), the bracket's FOOT physically needs to rest on this
// chassis's own real floor. pcie_bracket_mount_holes() cuts a Z-axis hole
// DOWN from its own local Z=0 by `depth` -- calling it with local Z=0 mapped
// to world Z=floor_th (the floor slab's own TOP surface) and depth=floor_th+1
// cuts cleanly through the floor (Z=[0,floor_th]) with a 1mm overshoot below
// and the module's own built-in 0.02mm overshoot above. X/Y reuse the SAME
// _pcie_slot_cx()/0 anchor as the Task 1 preview (bracket's local X=0/Y=0
// datum -- slot centerline / back-plane-mates-panel plane -- is unaffected
// by this Z correction; only the bracket's OWN Z-translate differs between
// the card-visualization preview and this real floor cut). Verified
// empirically via an intersection() probe against the floor slab (see
// tests/test_mitx_2u_chassis.sh) -- the floor_th+standoff_h preview Z was
// tried first and confirmed to leave the hole floating above the floor,
// cutting nothing.
function _pcie_mount_depth() = floor_th + 1;

// Fit-asserts
assert(_bw() <= rack10_clear_width(standard) - 2*wall + 1e-6,
    str("mitx-2u: board width ", _bw(), " > usable ", rack10_clear_width(standard)-2*wall));
assert(_bd() <= _usable_depth() + 1e-6,
    str("mitx-2u: board depth ", _bd(), " > usable ", _usable_depth()));
assert(standoff_h + mobo_thickness() + heatsink_ceiling <= _int_h() + 1e-6,
    str("mitx-2u: standoff+board+heatsink ", standoff_h+mobo_thickness()+heatsink_ceiling,
        " > 2U interior ", _int_h(), " (reduce heatsink_ceiling/standoff)"));
assert(standoff_h + mobo_thickness() + lp_card_h <= _int_h() + 1e-6,
    str("mitx-2u: standoff+board+LP-card ", standoff_h+mobo_thickness()+lp_card_h,
        " > 2U interior ", _int_h(), " (LP card too tall for 2U)"));
assert(lp_card_len <= _usable_depth() + 1e-6,
    str("mitx-2u: LP card length ", lp_card_len, " > usable depth ", _usable_depth(),
        " (LP card collides rear)"));
// Board footprint vs. side walls' INTERIOR faces (#42 final-review finding
// -- the off-center guard below only checks holes against the outer panel,
// not the board against the shell interior; ported to this project's own
// _board_x()).
assert(_board_x() - wall >= -rack10_clear_width(standard)/2 - 1e-6
    && _board_x() + _bw() + wall <= rack10_clear_width(standard)/2 + 1e-6,
    str("mitx-2u: board [", _board_x(), ",", _board_x()+_bw(), "] at board_offset=", board_offset,
        " collides with a side wall (interior span +-", rack10_clear_width(standard)/2 - wall, ")"));
// IO cutout right edge vs. the panel's own outer bound (mitx-1u idiom).
assert(_io_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: IO cutout right edge ", _io_x1(), " > panel half-width ", rack10_panel_width(standard)/2));
// PCIe slot cutout vs. the panel's own outer bound (both edges -- opposite/
// high-X side from the IO window, per mobo_pcie_first_xy's own X-flip
// convention).
assert(_pcie_slot_x0() >= -rack10_panel_width(standard)/2 + 1e-6
    && _pcie_slot_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: PCIe slot cutout [", _pcie_slot_x0(), ",", _pcie_slot_x1(),
        "] exceeds panel +-", rack10_panel_width(standard)/2));
// Button hole vs. the panel's own outer bounds (both edges, since it's a hole).
assert(_button_x() - button_dia/2 >= -rack10_panel_width(standard)/2 + 1e-6
    && _button_x() + button_dia/2 <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-2u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] exceeds panel +-", rack10_panel_width(standard)/2));
// fan_size must be a size fans.scad actually knows the mounting-hole
// spacing/bore for -- an unknown size would silently assert deep inside
// fan_hole_spacing() instead of at this project's own boundary.
assert(len([for (s=fan_known_sizes()) if (s==fan_size) s])>0,
    str("mitx-2u: fan_size ", fan_size, " not in ", fan_known_sizes()));
// Board must clear the rear wall's inner face (not just _usable_depth() --
// the actual rear wall sits at _tongue_y(), slightly behind _usable_depth()).
assert(_bd() <= _tongue_y() - wall - 1e-6,
    str("mitx-2u: board depth ", _bd(), " reaches into the rear wall (inner face at ",
        _tongue_y()-wall, ")"));
// Fan/DC-in must clear the tongue-flanking gussets in X (a larger fan_size
// could otherwise silently grow into the gusset it shares the rear wall with).
assert(abs(_fan_cx()) - fan_size/2 >= _gusset_x() + _gusset_xw()/2 - 1e-6,
    str("mitx-2u: fan_size ", fan_size, " at x=", _fan_cx(), " overlaps the tongue gusset"));
assert(abs(_dc_cx()) - dc_dia/2 >= _gusset_x() + _gusset_xw()/2 - 1e-6,
    str("mitx-2u: dc_dia ", dc_dia, " at x=", _dc_cx(), " overlaps the tongue gusset"));
// Fan/DC-in (at the SAME _rear_flank_cx() magnitude by construction) must
// also stay within the rear wall's own width -- _rear_flank_cx() grows
// clear of the gusset by construction but is not otherwise bounded, so a
// large enough fan_size could still walk it off the rear wall's own edge.
assert(abs(_fan_cx()) + fan_size/2 <= _clear_w()/2 - wall - 1e-6,
    str("mitx-2u: fan_size ", fan_size, " at x=", _fan_cx(), " exceeds the rear wall width (interior span +-", _clear_w()/2-wall, ")"));
// Fan must fit within the rear wall's own height.
assert(_rear_center_z() - fan_size/2 >= -1e-6 && _rear_center_z() + fan_size/2 <= _wall_top_z() + 1e-6,
    str("mitx-2u: fan_size ", fan_size, " does not fit within rear wall height ", _wall_top_z()));
// Fan teardrop's flattened apex must stay within the safe self-bridging
// ceiling -- a larger fan_size (taller bore) could otherwise widen the flat
// top past what prints clean without support.
assert(_fan_teardrop_flat_w() <= 10 + 1e-6,
    str("mitx-2u: fan_size ", fan_size, " teardrop flat-top span ", _fan_teardrop_flat_w(),
        "mm exceeds the 10mm safe self-bridging ceiling -- reduce fan_size or add rear-wall headroom"));
// LP card keep-out (Y-extent from the front plane, at the slot X) must stay
// clear of the rear gusset/tongue zone (starts at _tongue_y()-wall-
// _gusset_size(), matching the _mitx2_gusset() calls below) -- the card
// clearance the plan brief calls out explicitly for this task.
assert(lp_card_len <= _tongue_y() - wall - _gusset_size() - 1e-6,
    str("mitx-2u: LP card length ", lp_card_len, " reaches into the rear gusset/tongue zone (starts at ",
        _tongue_y()-wall-_gusset_size(), ")"));
// PCIe floor mount hole must land within the floor slab's own interior
// footprint (side walls' interior span in X; the header-datum's Y=0 back
// plane + the bracket's own screw Y in Y) -- a stricter check than Task 1's
// panel-bound assert (rack10_panel_width > rack10_clear_width, the panel
// includes the mounting ears outside the floor's own span).
assert(_pcie_slot_cx() - wall >= -rack10_clear_width(standard)/2 - 1e-6
    && _pcie_slot_cx() + wall <= rack10_clear_width(standard)/2 + 1e-6,
    str("mitx-2u: PCIe floor mount hole x=", _pcie_slot_cx(),
        " falls outside the floor's interior span +-", rack10_clear_width(standard)/2));

module _mitx2_faceplate() {
    difference() {
        translate([-rack10_panel_width(standard)/2, -faceplate_th, 0])
            cube([rack10_panel_width(standard), faceplate_th, rack10_device_height(device_u)]);
        if (ear_type == "slot") rack10_holes(standard, device_u, hole_type="slot", dia=rack10_screw_clearance("10-32"));
        else rack10_holes(standard, device_u, hole_type=ear_type);
        // mobo_io_cutout_stamp/mobo_pcie_cutout grow +Y from the board's own
        // local frame (rear-IO edge = local Y=0); this faceplate sits at -Y
        // (rack10 front-of-panel convention), so mirror the stamps in Y
        // first or the cutters never reach it (#42 hit this exact bug on
        // the IO stamp -- verified here empirically via intersection()
        // against this faceplate slab: with the mirror, both stamps'
        // world-Y span fully overlaps the slab's own Y=[-faceplate_th,0]
        // span at the outer face; without it, they don't).
        translate([_board_x(), 0, floor_th+standoff_h])
            mirror([0, 1, 0]) {
                mobo_io_cutout_stamp("itx", depth=faceplate_th+2);
                // PCIe slot aperture (single slot) at the board's own slot X.
                mobo_pcie_cutout("itx", slots=1, depth=faceplate_th+2);
            }
        // pcie_bracket_mount_holes() is NOT cut here: per pcie-bracket.scad's
        // own header, it bores a Z-axis hole through the bracket's FOOT
        // (flat in the XY plane at Z=[-thickness,0], a floor/rail
        // fastener), not a Y-extruding faceplate through-cut like the two
        // stamps above -- verified empirically: intersection() of that
        // cutter (placed the same way as the stamps above) against this
        // faceplate slab is EMPTY at every board_offset. Task 2 cuts the
        // real hole into the floor (see CORRECTION 2026-07-31 in the plan's
        // Global Constraints).
        // Power button in the off-center gap beside the IO window.
        translate([_button_x(), -faceplate_th-1, rack10_device_height(device_u)/2])
            rotate([-90,0,0]) cylinder(h=faceplate_th+2, d=button_dia);
    }
}
// Floor + side walls + rear wall, unholed. Front edge overlaps Y=0 by y_eps
// (the faceplate's own rear face) so the union is a robust manifold. Side/
// rear walls run flush to _tongue_y() (rear wall's own outer face, where the
// tongue root sits) -- a plain rectangular box, no cantilever, support-free
// by construction. Same idiom as mitx-1u-chassis.scad's _mitx_shell().
module _mitx2_shell() {
    y_eps = 0.01;
    y1 = _tongue_y();
    w2 = _clear_w() / 2;
    // floor
    translate([-w2, -y_eps, 0]) cube([2*w2, y1 + y_eps, floor_th]);
    // side walls
    for (sx = [-1, 1])
        translate([sx > 0 ? w2 - wall : -w2, -y_eps, 0])
            cube([wall, y1 + y_eps, _wall_top_z()]);
    // rear wall (outer/rear face flush with the tongue root at y1)
    translate([-w2, y1 - wall, 0]) cube([2*w2, wall, _wall_top_z()]);
    // Buttress under the tongue's own cantilevered reach (y1 to rear post Y)
    // -- without this the tongue would print as an unsupported ~12mm
    // horizontal shelf anchored only at its root face. Sized to the tongue's
    // own width (rack_support_rail_size()[0]), built at
    // rack_support_floor_thickness() (the tongue's own seating datum),
    // running the tongue's full engagement_depth() -- same pattern as
    // mitx-1u-chassis.scad's _mitx_shell() (see that file's comment block
    // for the full rationale, incl. why a strip stopping short reproduces a
    // CGAL non-manifold defect).
    rw = rack_support_rail_size()[0];
    translate([-rw/2, y1, 0])
        cube([rw, rack_support_engagement_depth(), rack_support_floor_thickness()]);
}

// Support-free 45deg corner brace: right angle at (y0,z0) (rear wall's inner
// face / floor top), one leg running `size` along the floor (-Y), the other
// `size` up the wall (+Z) -- same hull-of-6-corner-spheres technique as
// mitx-1u-chassis.scad's _mitx_gusset() / rack-support.scad's own gusset.
module _mitx2_gusset(x0, xw, y0, z0, size) {
    hull()
        for (p = [[y0, z0], [y0 - size, z0], [y0, z0 + size]])
            for (dx = [x0 - xw/2, x0 + xw/2])
                translate([dx, p[0], p[1]]) sphere(r = 0.001, $fn = 6);
}

// Teardrop bore for the fan airflow opening through the vertical rear wall
// -- same idiom (and Y/Z-frame convention) as mitx-1u-chassis.scad's
// _mitx_fan_teardrop(); see that module's comment block for the full "why"
// (fan_bore()'s plain circle has no teardrop logic; `max_reach` caps the
// ideal 45deg apex at the available rear-wall headroom instead of letting it
// punch through the wall's own top edge).
module _mitx2_fan_teardrop(size, depth, max_reach) {
    r = size * 0.92 / 2;
    reach = min(r * sqrt(2), max_reach);
    translate([0, 0, -1])
        linear_extrude(height = depth + 2)
            hull() {
                circle(r = r);
                translate([0, -reach]) circle(r = 0.001);
            }
}

module mitx_2u_chassis() {
    _mitx2_faceplate();
    // off-center board standoffs -- SAME _board_x() offset as the
    // faceplate's IO/PCIe cutout block above, or they drift apart.
    translate([_board_x(), 0, floor_th])
        mobo_standoffs("itx", standoff_h, role="structural-mount");
    % translate([_board_x(), 0, floor_th+standoff_h]) mobo_placeholder("itx");
    // LP card keep-out preview, tracked to the slot's own world centerline
    // (pcie_bracket()'s local X=0 datum), NOT board_offset directly.
    % translate([_pcie_slot_cx(), 0, floor_th+standoff_h]) pcie_bracket("low-profile");

    // walls/floor + rear DC-in/fan cutouts + PCIe floor mount hole +
    // tongue-flanking gussets.
    difference() {
        union() {
            _mitx2_shell();
            _mitx2_gusset(-_gusset_x(), _gusset_xw(), _tongue_y() - wall, floor_th, _gusset_size());
            _mitx2_gusset( _gusset_x(), _gusset_xw(), _tongue_y() - wall, floor_th, _gusset_size());
        }
        // rear fan opening (teardropped, apex-capped) + mount holes, rotated
        // onto +Y through the rear wall (fan modules' native frame: airflow
        // along +Z -- rotate([-90,0,0]) maps that Z-bore onto +Y, X stays put).
        translate([_fan_cx(), _tongue_y() - wall, _rear_center_z()])
            rotate([-90, 0, 0]) _mitx2_fan_teardrop(fan_size, wall, _fan_teardrop_avail());
        translate([_fan_cx(), _tongue_y() - wall, _rear_center_z()])
            rotate([-90, 0, 0]) fan_holes(fan_size, wall);
        // rear DC-in barrel hole, same +Y-through-the-wall orientation as
        // the faceplate's own button hole. Left plain round (not
        // teardropped): a DC barrel jack's panel-mount nut needs true
        // roundness -- see mitx-1u-chassis.scad's comment for the full
        // design-for-print rationale.
        translate([_dc_cx(), _tongue_y() - wall - 1, _rear_center_z()])
            rotate([-90, 0, 0]) cylinder(h = wall + 2, d = dc_dia);
        // PCIe bracket foot mount hole -- Z-axis cut into the FLOOR (see
        // _pcie_mount_depth()'s comment above for the Z-datum this uses vs.
        // the Task 1 keep-out preview's floor_th+standoff_h).
        translate([_pcie_slot_cx(), 0, floor_th])
            pcie_bracket_mount_holes("low-profile", depth=_pcie_mount_depth(), screw=pcie_screw);
    }
    // #40 rear-support tongue: root at _tongue_y() (flush with the rear
    // wall's outer face), projects further +Y into rack_support_plate()'s
    // channel -- see rack_support_tongue()'s consumer-contract doc comment.
    translate([0, _tongue_y(), 0]) rack_support_tongue();
    // vents in Task 3
}
mitx_2u_chassis();
