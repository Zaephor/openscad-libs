// mitx-1u-chassis — 1U 10" rack chassis for a mini-ITX board, front-IO
// appliance (IO shield + power button front), external DC-in, fan+honeycomb,
// rear #40 support mate. Consumes motherboards/rack10/rack-support/fans/honeycomb.
use <motherboards/motherboards.scad>;
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;

/* [Rack] */
standard = "labrax";
ear_type = "slot";
/* [Print] */
wall = 2.4; floor_th = 2.0; faceplate_th = 3.0;
standoff_h = 6.0; heatsink_ceiling = 25;
/* [Front] */
button_dia = 12; board_offset = 20;   // off-center X so button fits beside IO
/* [Cooling / Power] */
dc_dia = 11; fan_size = 40; cell = 8.0; hc_wall = 1.2;

function _bw()    = mobo_size("itx")[0];   // 170
function _bd()    = mobo_size("itx")[1];   // 170
function _int_h() = rack10_device_height(1) - floor_th;
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();

// World X of the board's own local origin (rear-left corner, see
// motherboards.scad's datum comment). Every board-frame feature (standoffs,
// placeholder, IO cutout) must translate by this SAME offset, or they drift
// apart -- that's exactly the bug this formula fixes vs. translating the IO
// cutout by board_offset alone (which ignores the board's own half-width).
function _board_x() = board_offset - _bw() / 2;

// IO cutout: mobo_io_cutout returns [x_off, w, h] in the board's own local
// (component-up) frame -- same frame mobo_standoff_xy/mobo_placeholder use --
// so it shares _board_x() as its world-frame offset.
function _io()    = mobo_io_cutout("itx");
function _io_x0() = _board_x() + _io()[0];              // world low (left) edge
function _io_x1() = _board_x() + _io()[0] + _io()[1];   // world high (right) edge

// Power button: sits in the off-center gap on the panel's low-X side, beside
// the IO window (board_offset shifts the board toward +X to open this gap).
// Centered in the gap between the panel's low edge and the IO's low edge so
// it clears both by construction whenever the gap is wide enough for it.
function _button_x() = (-rack10_panel_width(standard) / 2 + _io_x0()) / 2;

// Real headroom above the board's own IO-edge Z-datum, flush to the 1U
// interior ceiling. mobo_io_cutout("itx")[2] (44.45mm, the full generic
// ATX-family shield height) does not fit here -- board depth _int_h()
// interior minus standoff_h leaves less than that -- so this project cuts
// a board-specific window sized to available headroom instead of the
// library's generic envelope (spec addendum 2026-07-28: this is a
// BYO-board appliance, not a universal-shield-compatible case).
function _io_window_h() = _int_h() - standoff_h;

// Rear shell geometry. The #40 tongue's root Y is NOT _usable_depth() --
// rack_support_tongue()'s own doc comment (rack-support.scad) states the
// consumer contract explicitly: root sits at rack10_rear_post_y(standard)
// minus rack_support_engagement_depth(), so it inserts exactly
// engagement_depth into rack_support_plate()'s channel when that plate is
// bolted at rack10_rear_post_y(standard). _usable_depth() additionally
// reserves faceplate_th as a (more conservative, unrelated) board-depth
// margin -- the two intentionally differ; don't conflate them.
function _tongue_y()      = rack10_rear_post_y(standard) - rack_support_engagement_depth();
function _clear_w()       = rack10_clear_width(standard);
function _wall_top_z()    = rack10_device_height(1);
function _rear_center_z() = _wall_top_z() / 2;
// Fan/DC-in centered left/right of the tongue, scaled off clear width so they
// stay clear of the tongue-flanking gussets across all rack10 standards.
function _fan_cx() = -_clear_w() / 4;
function _dc_cx()  =  _clear_w() / 4;
// Gussets flank the tongue immediately (brace the rear-wall/floor corner
// right where the #40 load comes in), flush against the tongue's own X edge.
function _gusset_xw()   = 10;
function _gusset_x()    = rack_support_rail_size()[0] / 2 + _gusset_xw() / 2;
function _gusset_size() = 15;

// Front intake vents (Task 3): a honeycomb field per side wall, positioned
// well clear of the rear gusset/tongue zone (which starts at
// _tongue_y()-wall-_gusset_size(), see the _mitx_gusset() calls below) and
// vertically margined off the floor and open top. Symmetric on both side
// walls so the single rear exhaust fan draws from both sides.
function _side_vent_zmargin() = 6;
function _side_vent_y0()      = 16;
function _side_vent_len()     = 80;
function _side_vent_h()       = _wall_top_z() - 2 * _side_vent_zmargin();

// Rear vent field flanking the fan (Task 3): a flat strip of otherwise-
// unused rear wall between the fan's own outboard edge and the near side
// wall's inner face -- clear of the fan's own mounting square (fan_holes()'
// screws land at that square's corners) and clear of the tongue-flanking
// gusset (which sits inboard, on the opposite side of the fan from this
// vent).
function _fan_vent_x1()  = _fan_cx() - fan_size / 2;   // fan's outboard edge
function _side_inner_x() = -_clear_w() / 2 + wall;     // left side wall inner face
function _fan_vent_w()   = 24;
function _fan_vent_cx()  = (_fan_vent_x1() + _side_inner_x()) / 2;
function _fan_vent_h()   = _wall_top_z() - 2 * _side_vent_zmargin();

// Fit-asserts
assert(_bw() <= rack10_clear_width(standard) - 2*wall + 1e-6,
    str("mitx-1u: board width ", _bw(), " > usable ", rack10_clear_width(standard)-2*wall));
assert(_bd() <= _usable_depth() + 1e-6,
    str("mitx-1u: board depth ", _bd(), " > usable ", _usable_depth()));
assert(standoff_h + mobo_thickness() + heatsink_ceiling <= _int_h() + 1e-6,
    str("mitx-1u: standoff+board+heatsink ", standoff_h+mobo_thickness()+heatsink_ceiling,
        " > 1U interior ", _int_h(), " (reduce heatsink_ceiling/standoff)"));
// Off-center guard: board_offset shifts both the IO window and the button
// hole, so a bad value can walk either one off the panel. The button hole
// (both edges, since it's a hole) and the IO cutout's right edge must stay
// within +-rack10_panel_width/2.
assert(_io_x1() <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-1u: IO cutout right edge ", _io_x1(), " > panel half-width ", rack10_panel_width(standard)/2));
assert(_button_x() - button_dia/2 >= -rack10_panel_width(standard)/2 + 1e-6
    && _button_x() + button_dia/2 <= rack10_panel_width(standard)/2 - 1e-6,
    str("mitx-1u: button hole [", _button_x()-button_dia/2, ",", _button_x()+button_dia/2,
        "] exceeds panel +-", rack10_panel_width(standard)/2));
// fan_size must be a size fans.scad actually knows the mounting-hole
// spacing/bore for -- an unknown size would silently assert deep inside
// fan_hole_spacing() instead of at this project's own boundary.
assert(len([for (s=fan_known_sizes()) if (s==fan_size) s])>0,
    str("mitx-1u: fan_size ", fan_size, " not in ", fan_known_sizes()));
// Board must clear the rear wall's inner face (not just _usable_depth() --
// the actual rear wall sits at _tongue_y(), slightly behind _usable_depth()).
assert(_bd() <= _tongue_y() - wall - 1e-6,
    str("mitx-1u: board depth ", _bd(), " reaches into the rear wall (inner face at ",
        _tongue_y()-wall, ")"));
// Fan/DC-in must clear the tongue-flanking gussets in X (a larger fan_size
// could otherwise silently grow into the gusset it shares the rear wall with).
assert(abs(_fan_cx()) - fan_size/2 >= _gusset_x() + _gusset_xw()/2 - 1e-6,
    str("mitx-1u: fan_size ", fan_size, " at x=", _fan_cx(), " overlaps the tongue gusset"));
assert(abs(_dc_cx()) - dc_dia/2 >= _gusset_x() + _gusset_xw()/2 - 1e-6,
    str("mitx-1u: dc_dia ", dc_dia, " at x=", _dc_cx(), " overlaps the tongue gusset"));
// Fan must fit within the rear wall's own height.
assert(_rear_center_z() - fan_size/2 >= -1e-6 && _rear_center_z() + fan_size/2 <= _wall_top_z() + 1e-6,
    str("mitx-1u: fan_size ", fan_size, " does not fit within rear wall height ", _wall_top_z()));
// Side intake vents must stay clear of the rear gusset zone (starts at
// _tongue_y()-wall-_gusset_size(), matching the _mitx_gusset() calls below).
assert(_side_vent_y0() + _side_vent_len() <= _tongue_y() - wall - _gusset_size() - 1e-6,
    str("mitx-1u: side intake vent [", _side_vent_y0(), ",", _side_vent_y0()+_side_vent_len(),
        "] reaches into the rear gusset zone (starts at ", _tongue_y()-wall-_gusset_size(), ")"));
// Fan-flanking rear vent must fit entirely in the gap between the side
// wall's inner face and the fan's own outboard edge (not overlap either).
assert(_fan_vent_cx() - _fan_vent_w()/2 >= _side_inner_x() + 1e-6
    && _fan_vent_cx() + _fan_vent_w()/2 <= _fan_vent_x1() - 1e-6,
    str("mitx-1u: fan-flanking vent [", _fan_vent_cx()-_fan_vent_w()/2, ",",
        _fan_vent_cx()+_fan_vent_w()/2, "] does not fit between the side wall inner face (",
        _side_inner_x(), ") and the fan's outboard edge (", _fan_vent_x1(), ")"));

module _mitx_faceplate() {
    difference() {
        rack10_panel(standard, 1, faceplate_th);
        if (ear_type == "slot") rack10_holes(standard, 1, hole_type="slot", dia=rack10_screw_clearance("10-32"));
        else rack10_holes(standard, 1, hole_type=ear_type);
        // IO shield cutout at the board's IO edge (board off-center by
        // board_offset). mobo_io_cutout_stamp grows +Y from the board's own
        // local Y=0 (rear/IO edge) -- but the faceplate sits at -Y from that
        // same plane (rack10's front-of-panel convention), so mirror the
        // stamp in Y before placing it in the shared board/standoffs frame
        // (_board_x()); otherwise the cutter grows away from the faceplate
        // and never reaches it.
        translate([_board_x(), 0, floor_th + standoff_h])
            mirror([0, 1, 0])
                translate([_io()[0], -1, 0])
                    cube([_io()[1], faceplate_th + 3, _io_window_h()]);
        // power button hole in the off-center gap beside the IO window.
        translate([_button_x(), -faceplate_th - 1, rack10_device_height(1)/2])
            rotate([-90,0,0]) cylinder(h = faceplate_th + 2, d = button_dia);
    }
}
// Floor + side walls + rear wall, unholed. Front edge overlaps Y=0 by y_eps
// (the faceplate's own rear face) so the union is a robust manifold, not an
// exactly-coincident zero-thickness touch. Side/rear walls run flush to
// _tongue_y() (the rear wall's own outer face, where the tongue root sits) --
// a plain rectangular box, no cantilever, so it's support-free by construction.
module _mitx_shell() {
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
    // -- the tongue's underside is a flat vertical end face with no overhang
    // ON ITS OWN, but nothing else in this shell reaches past y1, so without
    // this the tongue would print as a ~12mm horizontal shelf anchored only
    // at its root face: a genuine unsupported overhang. Matches
    // rack-support's own README "Buttressing" consumer contract + the exact
    // pattern rack-support/assembly.scad's reference stub tray uses: a strip
    // sized to the tongue's own width (rack_support_rail_size()[0], NOT this
    // tray's full clear width -- staying clear of rack_support_plate()'s own
    // gusset ribs outside the slot), built at rack_support_floor_thickness()
    // (the tongue's own seating datum -- single source of truth, NOT this
    // project's floor_th, which a Customizer edit could otherwise de-sync
    // from the tongue), running the tongue's full engagement_depth() so it
    // overlaps the tongue's whole underside face (a strip stopping exactly
    // at the tongue's own front face reproduces a CGAL non-manifold
    // "touching only along an edge" defect -- see that README).
    rw = rack_support_rail_size()[0];
    translate([-rw/2, y1, 0])
        cube([rw, rack_support_engagement_depth(), rack_support_floor_thickness()]);
}

// Support-free 45deg corner brace: right angle at (y0,z0) (rear wall's inner
// face / floor top), one leg running `size` along the floor (-Y), the other
// `size` up the wall (+Z) -- same hull-of-6-corner-spheres technique as
// rack-support.scad's own proven gusset (valid convex prism for any winding;
// print bed on the floor, each Z-layer's Y-footprint shrinks monotonically
// going up, so every layer is supported by a wider one below it).
module _mitx_gusset(x0, xw, y0, z0, size) {
    hull()
        for (p = [[y0, z0], [y0 - size, z0], [y0, z0 + size]])
            for (dx = [x0 - xw/2, x0 + xw/2])
                translate([dx, p[0], p[1]]) sphere(r = 0.001, $fn = 6);
}

// Teardrop bore for the fan airflow opening -- fan_bore()'s own plain
// circle (design-for-print/reference/overhangs-supports.md: fans.scad has
// no teardrop logic, it's the caller's job) is fine printed vertical, but
// here it's rotated onto +Y through a VERTICAL rear wall, i.e. a horizontal-
// axis round hole. At size*0.92 (36.8mm for the default 40mm fan) this is
// far past any plain-round-hole threshold (repo precedent treats ~5mm as
// safe, ">30mm: don't" per that reference) -- the fan doesn't care about
// true roundness (it mounts over this opening via fan_holes()'s screws
// anyway), so a 45deg teardrop roof (replacing the top arc) is the
// standard, cost-free fix. Same translate([0,0,-1])/depth+2 overshoot
// convention as fan_bore() itself. Built with the apex at local Y=-r*sqrt2
// (not +) so that after this file's usual rotate([-90,0,0]) (old Y -> new
// -Z) the roof lands pointing +Z (up) in the final printed orientation --
// see fans.scad header for the native +Z-bore frame this mirrors.
module _mitx_fan_teardrop(size, depth) {
    r = size * 0.92 / 2;
    translate([0, 0, -1])
        linear_extrude(height = depth + 2)
            hull() {
                circle(r = r);
                translate([0, -r * sqrt(2)]) circle(r = 0.001);
            }
}

// Side-wall intake honeycomb vent (Task 3). honeycomb_vent()'s local frame
// is X=width, Y=height, Z=depth (see honeycomb.scad); rotate([90,0,90]) maps
// local (x,y,z) -> world (z,x,y) [verified empirically: local depth (Z) ->
// world X, through the wall thickness; local width (X) -> world Y, along
// the wall's own length; local height (Y, the bridge-sensitive axis) ->
// world Z, vertical, so the flat-top hex still bridges the short way].
// `sx` mirrors _mitx_shell()'s own side-wall loop convention (-1 = left,
// +1 = right) -- only the depth-axis (world X) anchor differs between the
// two walls, width/height placement is identical.
module _mitx_side_vent(sx) {
    w2 = _clear_w() / 2;
    x_start = (sx > 0) ? w2 - wall - 1 : -w2 - 1;   // 1mm overcut past the outer face
    translate([x_start, _side_vent_y0(), _side_vent_zmargin()])
        rotate([90, 0, 90])
            honeycomb_vent(_side_vent_len(), _side_vent_h(), wall + 2, cell, hc_wall);
}

// Rear-wall vent flanking the fan (Task 3), same rotate([-90,0,0]) idiom as
// the fan/DC-in cutters below (native Z-bore frame -> +Y through the wall,
// see fans.scad header). Unlike those single-axis cutters (round, no
// distinct width/height), this rotation also reverses local Y
// (honeycomb_vent's height) onto world Z -- world_z = tz - local_y,
// confirmed empirically -- which only flips the field's own top/bottom
// traversal order, not its shape (a flat-top hex field is top/bottom
// symmetric), so `tz` is anchored at the vent's own intended top
// (z0 + height) to land the field at [z0, z0+height] despite the reversal.
module _mitx_rear_fan_vent() {
    z0 = _rear_center_z() - _fan_vent_h() / 2;
    translate([_fan_vent_cx() - _fan_vent_w()/2, _tongue_y() - wall - 1, z0 + _fan_vent_h()])
        rotate([-90, 0, 0])
            honeycomb_vent(_fan_vent_w(), _fan_vent_h(), wall + 2, cell, hc_wall);
}

module mitx_1u_chassis() {
    _mitx_faceplate();
    // off-center board standoffs
    translate([_board_x(), 0, floor_th])
        mobo_standoffs("itx", standoff_h, role="structural-mount");
    % translate([_board_x(), 0, floor_th + standoff_h]) mobo_placeholder("itx");

    // walls/floor + rear DC-in/fan cutouts + tongue-flanking gussets
    difference() {
        union() {
            _mitx_shell();
            _mitx_gusset(-_gusset_x(), _gusset_xw(), _tongue_y() - wall, floor_th, _gusset_size());
            _mitx_gusset( _gusset_x(), _gusset_xw(), _tongue_y() - wall, floor_th, _gusset_size());
        }
        // rear fan opening (teardropped, see _mitx_fan_teardrop) + mount
        // holes, rotated onto +Y through the rear wall (fan modules' native
        // frame: airflow along +Z -- rotate([-90,0,0]) maps that Z-bore
        // onto +Y, X stays put; see fans.scad header).
        translate([_fan_cx(), _tongue_y() - wall, _rear_center_z()])
            rotate([-90, 0, 0]) _mitx_fan_teardrop(fan_size, wall);
        translate([_fan_cx(), _tongue_y() - wall, _rear_center_z()])
            rotate([-90, 0, 0]) fan_holes(fan_size, wall);
        // rear DC-in barrel hole, same +Y-through-the-wall orientation as the
        // faceplate's own button hole (translate 1mm before the inner face,
        // rotate([-90,0,0]), height = wall + 2mm total overshoot). Left
        // plain round (not teardropped): dc_dia (11mm) sits right at the
        // repo's own "usually fine, minor droop" band top per
        // design-for-print/reference/overhangs-supports.md, and a DC barrel
        // jack's panel-mount nut needs true roundness -- unlike the fan
        // opening, a teardrop's flat roof would actually hurt fit here.
        translate([_dc_cx(), _tongue_y() - wall - 1, _rear_center_z()])
            rotate([-90, 0, 0]) cylinder(h = wall + 2, d = dc_dia);
        // intake honeycomb vents, both side walls (Task 3).
        for (sx = [-1, 1]) _mitx_side_vent(sx);
        // rear honeycomb vent field flanking the fan (Task 3).
        _mitx_rear_fan_vent();
    }
    // #40 rear-support tongue: root at _tongue_y() (flush with the rear
    // wall's outer face), projects further +Y into rack_support_plate()'s
    // channel -- see rack_support_tongue()'s consumer-contract doc comment.
    translate([0, _tongue_y(), 0]) rack_support_tongue();
}
mitx_1u_chassis();
