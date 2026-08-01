// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// tray part — single-body chassis: floor + faceplate + walls + rear wall.

/* [Cooling] */
// Declared here + in each entry file; params.scad consumes only.
enable_exhaust = true; // false = passive (no rear fan plenum)
fan_size  = 40;        // must be a fan_known_sizes() value
fan_count = 2;

/* [Rack Ears] */
ear_hole_type = "slot"; // "slot" | "10-32" | "m6" | "round"

include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <heatset/heatset.scad>;
use <honeycomb/honeycomb.scad>;

// Rear outer vertical corner chamfers. 1.2mm, NOT the faceplate's 3.0mm: the
// limit here is wall*(2 - sqrt(2)) = 1.406mm, above which the material left
// along the corner diagonal drops under the 2.4mm wall thickness (at 1.2 the
// diagonal keeps 2.546mm; at 3.0 only 1.273mm). Same leg as the lid posts'
// own chamfer, so this project carries one chamfer number for its own geometry.
// KNOWN AND ACCEPTED: above z = ext_h() - lid_th the corner is the wall/2 lid
// lip, so the chamfer tapers that lip to nothing across its last 1.2mm at each
// rear corner. The lid shelf is inboard and untouched -- the lid still seats;
// it loses lip retention across ~1.2mm at two corners. A 2.0mm radius would
// have cost 2mm of lip instead. Not a defect to "fix" later.
function _tray_rear_corner_chamfer() = 1.2;

// Outer shell: floor + two side walls + rear wall, with an inner ledge on the
// wall tops so the lid drops in flush. Faceplate/fans/vents added by later modules.
module _tray_shell(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count) {
    y0 = board_y();
    dd = int_depth(enable_exhaust);
    difference() {
        union() {
            // Floor.
            translate([-body_w()/2, y0, 0]) cube([body_w(), dd, floor_th]);
            // Side walls (full exterior height).
            for (sx = [-1, 1])
                translate([sx*(body_w()/2) - (sx>0?wall:0), y0, 0])
                    cube([wall, dd, ext_h()]);
            // Rear wall.
            translate([-body_w()/2, y0 + dd - wall, 0])
                cube([body_w(), wall, ext_h()]);
        }
        // lip = wall/2 outer strip kept above the shelf on the two sides + rear;
        // front stays open (over-cut -Y) — the faceplate closes the front.
        lip = wall/2;
        translate([-(body_w()/2 - lip), y0 - 1, ext_h() - lid_th])
            cube([body_w() - wall, dd - lip + 1, lid_th + 1]);
        // Rear-wall openings: honeycomb hex field over the fan band, both
        // fan/passive modes (see _rear_openings()).
        _rear_openings(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count);
        // Rear outer vertical corner chamfers (see _tray_rear_corner_chamfer()
        // above), full exterior height so the cut is a constant XY
        // cross-section extruded straight up -- vertical-axis only, no
        // overhang, trivially support-free. Each triangle's right-angle
        // vertex sits exactly at the corner point (+/-body_w()/2,
        // rear_wall_y(ee)); the two other legs run INTO the material
        // (-X,-Y for the +X corner; +X,-Y for the -X corner).
        c = _tray_rear_corner_chamfer();
        ry = rear_wall_y(enable_exhaust);
        for (sx = [-1, 1])
            translate([sx*body_w()/2, ry, -1])
                linear_extrude(height = ext_h() + 2)
                    polygon([[0, 0], [-sx*c, 0], [0, -c]]);
    }
}

// Rear-wall openings. BOTH fan modes cut the same self-supporting honeycomb
// hex field over the fan footprint; fans on additionally keeps a solid
// bearing pad around each mount screw and cuts the screw holes through those
// pads. The rear wall is vertical, so a round bore here would lie on a
// HORIZONTAL axis and present a 90-degree-from-vertical overhang at its
// crown -- see the honeycomb_vent() call below for why a teardrop is not the
// alternative.
//
// rear_wall_y(ee = enable_exhaust) is the wall's outer (rearmost) face; the
// wall itself occupies [rear_wall_y()-wall, rear_wall_y()] (see
// _tray_shell()), so every cutter below is anchored off
// `rear_wall_y(ee) - wall` (the inner face) to actually intersect the wall.
// The `ee` param (params.scad) must be threaded through explicitly from this
// module's own enable_exhaust parameter -- see params.scad's "ee defaults
// to..." comment for why a plain no-arg call can't see it.
module _rear_openings(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count) {
    yw   = rear_wall_y(enable_exhaust); // rear wall outer (rearmost) face
    zc   = floor_th + int_h()/2;        // vertical center of interior clearance
    cs   = _fan_x_centres(fan_size, fan_count);  // thermally placed, see params.scad
    band = _fan_band_x(fan_size, fan_count);     // [lo, hi] union of the footprints
    r_cell = honeycomb_cell/2;
    r_pad  = fan_pad_dia/2;
    difference() {
        // NOTE: _rear_openings() as a WHOLE is a cutter -- _tray_shell()
        // subtracts it from the wall -- so everything unioned/left standing
        // inside this module is VOID, and anything subtracted away from the
        // cutter here is what stays SOLID once cut from the wall. This
        // difference()'s FIRST child (_rear_honeycomb_bands()) is the base
        // void pattern; the SECOND child (the pad-fill loop below) must be
        // SUBTRACTED from it -- not unioned in -- so a filled cell is
        // REMOVED from the void mask (and therefore left solid in the
        // final wall). Unioning the fill hexes in here instead would be a
        // no-op (they're already members of the same _honeycomb_centres()
        // set the bands are built from, so union(A, subset_of_A) == A) and
        // would ALSO bypass honeycomb_vent()'s own [0,width]x[0,height]
        // boundary clip, letting an edge pad's fill hex leak past the field
        // into un-checked wall territory (#78 review fix).
        difference() {
            _rear_honeycomb_bands(cs, band, zc, fan_size, enable_exhaust);
            // Pad-fill (#78 Part A): a fastener pad is a foreign solid
            // re-added into the honeycomb field, which the field's own
            // self-check (HONEYCOMB_WORST_SPAN) does not cover -- see
            // libraries/honeycomb/README.md's "Embedded Solids" note. Fill
            // the lattice cells each pad overlaps so the pad's material
            // lands on the field's own already-safe rib/bridge geometry
            // instead of hanging bare over open lattice.
            //
            // Variant chosen (of 3 measured via a render-and-measure probe,
            // see #78 Part A task report): fill EVERY cell whose centre is
            // within r_pad + r_cell of the pad centre (not just a
            // lower-half or single-nearest-cell filter). Measured counts
            // across all 8 pads (2 fans x 4 mount holes, fan_size=40): this
            // filter gives 2-3 filled cells per pad (never 0), uniformly for
            // both the upper AND lower mount-hole rows. A lower-half-only
            // filter (candidate ii, `c[1] <= pad_local[1]`) was measured to
            // give ZERO filled cells for all 4 lower-row holes (both fans)
            // -- the nearest cell's CENTRE sits a few hundredths of a mm
            // ABOVE the pad centre even though that cell's hex body extends
            // well below it, so a naive centre-relative filter silently
            // fails to fill anything under those pads. A snap-to-lattice
            // single-nearest-cell filter (candidate iii) does fill exactly
            // one substantially-overlapping cell per pad (measured 3.5-5mm
            // of centre-to-centre margin under the r_pad+r_cell threshold),
            // but leaves other cells that also overlap the pad unfilled,
            // trading redundancy for a modest area saving. This filter (i)
            // was picked for uniform correctness across both rows over the
            // small extra material cost.
            if (enable_exhaust)
                for (cx = cs)
                    for (p = fan_mount_holes(fan_size, "structural-mount")) {
                        pad_local = [cx + p[0] - band[0], p[1] + fan_size/2];
                        centres = honeycomb_cell_centres(band[1]-band[0], fan_size,
                                                          honeycomb_cell, honeycomb_wall);
                        fill = [for (c = centres) if (norm(c - pad_local) <= r_pad + r_cell) c];
                        translate([band[0], yw + 1, zc - fan_size/2])
                            rotate([90, 0, 0])
                                for (c = fill)
                                    translate(c)
                                        linear_extrude(height = wall + 2)
                                            circle(r = r_cell, $fn = 6);
                    }
        }
        // Active only: keep a solid bearing pad around each mount screw, so the
        // M3 head/nut seats on material rather than on the 1.2mm hex lattice.
        // Pad centres come from fan_mount_holes() (single source of truth) --
        // never a retyped +/- fan_hole_spacing/2. With #74's split placement
        // the inner screws sit 27.4mm apart, so all 8 pads stay separate
        // (they merged only in the old butted layout).
        if (enable_exhaust)
            for (cx = cs)
                for (p = fan_mount_holes(fan_size, "structural-mount"))
                    translate([cx + p[0], yw - wall - 1, zc + p[1]])
                        rotate([-90, 0, 0]) cylinder(h = wall + 2, d = fan_pad_dia);
    }
    // Active only: the mount screw holes themselves, cut through the pads.
    if (enable_exhaust)
        for (cx = cs)
            translate([cx, yw - wall, zc])
                rotate([-90, 0, 0]) fan_holes(fan_size, depth = wall);
}

// Rear honeycomb field: passive mode = one band across both fans; active
// mode split into per-fan bands in Task 4 (#78 Part B). Defined here so
// Task 3's pad-fill code has a stable call site to union alongside.
//
// Honeycomb FIELD over the fan footprint -- BOTH modes -- is self-
// supporting by construction (honeycomb_vent asserts its own worst-case hex
// span against the 5mm ceiling), so the field itself needs no teardrop and
// no round bore. A 45deg teardrop of the old 36.8mm bore does NOT fit here:
// it needs r*sqrt(2)=26.02mm above zc and only 20mm is available to the lid
// ledge -- see README.
// rotate([90,0,0]) maps honeycomb_vent's local frame onto the chassis:
// local X stays chassis X; local Y (height) becomes chassis Z (the
// fan_size band around zc); local Z (depth, the cut-through axis) becomes
// chassis -Y, punching through the rear wall -- wall+2 gives a 1mm overcut
// on both faces.
// ONE wide band spanning both fans, not one per fan: the larger open area
// and better passive-mode flow were preferred over closing the ~19.4mm
// inter-fan strip, which has no fan behind it.
module _rear_honeycomb_bands(cs, band, zc, fan_size, enable_exhaust) {
    translate([band[0], rear_wall_y(enable_exhaust) + 1, zc - fan_size/2])
        rotate([90, 0, 0])
            honeycomb_vent(band[1] - band[0], fan_size, wall + 2,
                           honeycomb_cell, honeycomb_wall);
}

// IO-gap wall widths (Round 2 #62 Task 3; third wall + gap figures updated
// Round 3 #65 -- see libraries/sbc/sbc.scad's bpir4 row, whose full front-row
// re-caliper shifted every gap): print-safety design constants (design-for-
// print: kept < the EFFECTIVE gap -- i.e. after io_port_clearance (params.scad)
// eats into both flanking cutouts -- so a connector opening can never be
// intruded on; wide enough for >=2 perimeters at a 0.4mm nozzle), not
// sbc-owned data. Exposed as FUNCTIONS (not module-local variables) so
// tests/asserts.scad's `use <../parts/tray.scad>` can call the exact same
// values `_faceplate()` renders with, instead of re-typing them -- `use`
// only imports functions/modules, never plain variables (see reference_
// openscad_gotchas), so a local variable here would be invisible there.
function _io_wall_w_usb_sfp() = 2.5;  // usb_1 <-> sfp_1 gap (3.8mm real gap, Round 3 #65)
function _io_wall_w_dc_usbc() = 1.5;  // dc_power_1 <-> usbc_pwr_1 gap (4.6mm real gap, Round 3 #65)
// rj45_block <-> dc_power_1 gap (2.2mm real gap, Round 3 #65 -- this named
// wall didn't exist before the round-3 re-caliper; the block/dc figures were
// previously unreconciled). Narrowed to 1.0mm rather than the ~half-the-gap
// sizing the other two walls use: io_port_clearance (0.4mm/side) eats 0.8mm
// total out of this already-tight 2.2mm gap, leaving only 1.4mm of EFFECTIVE
// clearance -- a 1.5mm wall would clip the clearance-inflated cutout edges
// (1.5 > 1.4). 1.0mm clears (1.4 > 1.0) and still gives >2 perimeters at a
// 0.4mm nozzle.
function _io_wall_w_rj45_dc() = 1.0;

// IO-gap bridge-support wall geometry (Round 2 #62 Task 3; third wall +
// clearance-aware assert added Round 3 #65): the bpir4 board has real, small
// physical gaps between front-connector pairs -- usb_1<->sfp_1 (3.8mm),
// dc_power_1<->usbc_pwr_1 (4.6mm), and rj45_block<->dc_power_1 (2.2mm), see
// libraries/sbc/sbc.scad's bpir4 row -- that sbc_faceplate_cutouts() already
// cuts as separate boxes, incidentally leaving each gap band uncut. This
// function/module pair makes that break EXPLICIT rather than relying on the
// cutout boxes' exact edges never drifting into each other: a wall centered
// in the gap, narrower than the EFFECTIVE gap by design (`w` < gap -
// 2*clearance, asserted below) so at these tight tolerances neither
// connector's own (clearance-inflated) opening can ever be intruded on.
// Positions are computed from sbc_connector(BOARD, name) -- single source of
// truth, never hand-literaled (see #62 Task 3 brief). Z-extent: from the
// panel base (Z=0 -- already solid there for every front connector, since
// all four share the same board-local z=1.4 cutout-bottom offset) up through
// the TALLER of the two flanking cutouts' tops, so the wall intersects the
// FULL Z-height of both openings it separates, not just one -- this stays
// safely under _vent_band_z0() (>=1mm above the single tallest front
// connector overall, see params.scad).
// Returns [x0, x1, z1] (chassis frame): wall spans X in [x0,x1], Z in
// [0,z1], full panel-thickness Y -- the function is the single source of
// truth both `_io_gap_wall()` (renders it) and tests/asserts.scad (checks
// it against the connectors' own cutout edges) call.
// clearance defaults to params.scad's io_port_clearance -- a plain
// project-wide global, never module-parameter-shadowed the way enable_exhaust
// is (see params.scad's rear_off() comment for why that distinction matters
// to a `use`-scoped default-param lookup) -- the SAME per-side clearance
// sbc_faceplate_cutouts() actually applies when `_faceplate()` cuts the
// openings, so the assert below reflects the real (post-clearance) opening
// edges rather than the nominal body edges.
function _io_gap_wall_geom(name_l, name_r, w, clearance = io_port_clearance) =
    let (cl = sbc_connector(BOARD, name_l), cr = sbc_connector(BOARD, name_r),
         xl = cl[1][0] + cl[2][0],   // left connector's right edge (board-local)
         xr = cr[1][0],              // right connector's left edge (board-local)
         gap = xr - xl,
         eff_gap = gap - 2*clearance) // gap after clearance inflates both flanking cutout edges
    assert(eff_gap > w,
        str("_io_gap_wall: ", name_l, "/", name_r, " effective gap ", eff_gap,
            "mm (nominal ", gap, "mm - 2x", clearance, "mm clearance) too narrow for a ", w, "mm wall"))
    let (xc = board_x() + (xl + xr) / 2,                                 // gap midpoint, chassis X
         zt = board_z() + max(cl[1][2] + cl[2][2], cr[1][2] + cr[2][2])) // taller opening top, chassis Z
    [xc - w/2, xc + w/2, zt];

module _io_gap_wall(name_l, name_r, w) {
    g = _io_gap_wall_geom(name_l, name_r, w);
    translate([g[0], -faceplate_th, 0])
        cube([g[1] - g[0], faceplate_th, g[2]]);
}

// Front rack panel: full panel width, chassis-exterior height, front face on
// Y=0 growing -Y (toward the rack front). Rack mount holes + connector cutouts.
module _faceplate(ear_hole_type = ear_hole_type) {
    union() {
        difference() {
            // Panel blank: the rack10 library's chamfered front-elevation
            // silhouette (rack10_panel_profile), extruded to faceplate_th.
            // Sized to this chassis's OWN ext_h(), not rack10_device_height(1)
            // -- bpir4 carries a local stack_gap, and reconciling that is a
            // separate change; this call must not move the chassis height.
            // Importing the silhouette (rather than re-typing the chamfer)
            // keeps the corner in one place: rack10_panel_corner_chamfer().
            rotate([90, 0, 0])
                linear_extrude(faceplate_th)
                    rack10_panel_profile(panel_w(), ext_h());
            // Rack mounting holes on the ears: slot (default) for post-spacing
            // tolerance, or a round type. Width from the 10-32 screw clearance.
            // "round" has no library-resolved clearance (unlike "m6"/"10-32",
            // which rack10_holes() resolves internally), so its dia is supplied
            // from params.scad's ear_hole_round_dia.
            if (ear_hole_type == "slot")
                rack10_holes(STD, 1, hole_type = "slot",
                             dia = rack10_screw_clearance("10-32"));
            else if (ear_hole_type == "round")
                rack10_holes(STD, 1, hole_type = "round", dia = ear_hole_round_dia);
            else
                rack10_holes(STD, 1, hole_type = ear_hole_type);
            // BPI-R4 front-panel connector openings (ymin edge), at the board's
            // chassis position. depth clears the panel thickness. clearance
            // (Round 3 #65) widens every opening by io_port_clearance per side
            // for connector-body fit/tolerance -- see params.scad's
            // io_port_clearance comment and _io_gap_wall_geom() above, which
            // accounts for the same inflation when sizing the gap walls.
            translate([board_x(), board_y(), board_z()])
                sbc_faceplate_cutouts(BOARD, "ymin", depth = faceplate_th + 2,
                    clearance = io_port_clearance);
            // Intake vents ABOVE the IO portholes: a self-supporting honeycomb
            // hex-hole cutter across the connector cluster, from just above the
            // tallest connector to just below the ledge — straight cross-chassis
            // airflow over the SFP/connector tops. Replaces the old full-width
            // slot cubes (a flat, unsupported bridge spanning the whole cluster
            // width) with honeycomb_vent() (honeycomb/honeycomb.scad): flat-top hex
            // cells whose only bridge (the hex top edge) is a few mm, not the
            // whole band width — see honeycomb/honeycomb.scad for the self-support
            // reasoning and honeycomb_cell/honeycomb_wall in params.scad.
            cl = [for (c = sbc_connectors(BOARD)) if (c[3]=="ymin") board_x()+c[1][0]];
            cr = [for (c = sbc_connectors(BOARD)) if (c[3]=="ymin") board_x()+c[1][0]+c[2][0]];
            bx0 = min(cl); bx1 = max(cr);                 // connector cluster X-span (chassis frame)
            z0 = _vent_band_z0();
            z1 = ext_h() - lid_th - vent_slot_gap;        // just below the ledge
            // rotate([90,0,0]) maps honeycomb_vent's local (width=X, height=Y,
            // depth=Z) frame onto the chassis frame: local X stays chassis X,
            // local Y (depth, the cut-through axis) becomes chassis Y — cutting
            // through the panel thickness like the old cube's Y span — and local
            // Z (height) becomes chassis Z. translate([bx0, 1, z0]) then lands it
            // exactly where the old cube band sat (Y from -faceplate_th-1 to +1,
            // Z from z0 to z1).
            translate([bx0, 1, z0])
                rotate([90, 0, 0])
                    honeycomb_vent(bx1 - bx0, z1 - z0, faceplate_th + 2,
                                    honeycomb_cell, honeycomb_wall);
        }
        // Explicit bridge-support walls in the three real IO gaps (see
        // _io_gap_wall()/_io_gap_wall_geom() above for the reasoning).
        _io_gap_wall("usb_1", "sfp_1", _io_wall_w_usb_sfp());
        _io_gap_wall("dc_power_1", "usbc_pwr_1", _io_wall_w_dc_usbc());
        _io_gap_wall("rj45_block", "dc_power_1", _io_wall_w_rj45_dc());
    }
}

// Internal bosses the lid screws into. M3 heat-set insert bore, top-loaded.
// Four corner posts only (side-midspan pair dropped): each sits FULLY IN ITS
// CORNER, bonded to BOTH the side wall AND the front/rear wall (v3 — v2 was
// tangent to only the side wall, with a post_edge_inset gap off the front/
// rear boundary, braced by a separate angled wedge buttress; see git
// history for that design). Post top is at the ledge (ext_h - lid_th).
// _lid_post_od() lives in params.scad (body_w() derives from it too). Both
// the X and Y placement are TANGENT to their respective inner faces (post
// face flush with the wall) — NOT offset by a gap. The X side reuses the v2
// reasoning: tangent (not post_wall_gap-offset) placement is what clears the
// board under the narrowed body_w() (inner edge = ix - post_r clears
// board_w()/2 via the board_side_gap the params establish). The Y side
// mirrors that same tangent logic onto the front boundary (board_y(), the
// faceplate's inner face — see params.scad's board_y() comment) and the rear
// wall's inner face (rear_wall_y() - wall).
function _lid_post_xy(ee = enable_exhaust) =
    let (od2 = _lid_post_od()/2,
         ix  = body_w()/2 - wall - od2,        // tangent to side-wall inner face
         yf  = board_y() + od2,                // front pair, tangent to the front boundary
         yr  = rear_wall_y(ee) - wall - od2)   // rear pair, tangent to rear-wall inner face
    [ [-ix, yf], [ix, yf], [-ix, yr], [ix, yr] ];

// Canonical corner post (local origin at the post/bore center, local +X/+Y
// axes): a full-height SQUARE column, flush (bonded) to both walls at its
// +X and +Y faces — the side wall sits at local x=+r, the front/rear wall at
// local y=+r (mirror via scale([sx,sy,1]) in _lid_posts() below to reach the
// other 3 corners). Unlike v2's round boss + angled wedge buttress (built
// with a hull-of-boxes ramp), this is a constant XY cross-section extruded
// straight up: every layer sits exactly on the one below (no ramp, no
// overhang) so it is trivially support-free.
//
// The two OTHER corners of the square get different treatment:
//  - (+r,+r): fully buried where both walls' own material already meets
//    (see _tray_shell()'s corner overlap) — nothing exposed, no treatment.
//  - (-r,-r): the one FREE corner (both adjoining faces are open, facing the
//    interior) — a genuine convex edge, so it gets the CHAMFER (assembly
//    lead-in / de-burring on the exposed edge).
//  - (-r,+r) and (+r,-r): each is where one FREE face meets the OTHER wall's
//    face *continuing past the post's own footprint* (e.g. the post's free
//    -X face meeting the front/rear wall's flat inner face beyond the
//    post's X-extent) — a genuine reentrant (concave, 270-degree) corner in
//    the solid, i.e. a real stress riser, so each gets FILLETED.
// Fillet radius / chamfer leg both taken from design-for-print's
// strength-physics.md guidance for an M3 boss-to-wall junction at this scale
// (1.0-1.5mm, this repo's own precedent range). Both fillet cylinders are ADDED
// material (concave-corner fillets are filled, not cut) and stay purely in
// previously-open interior space, so neither reduces the insert-bore wall
// thickness; the chamfer is a small cut far from the bore (see report for
// the wall-thickness-floor check).
module _lid_post_corner() {
    r  = _lid_post_od()/2;             // half the square's side (= old boss radius)
    Hb = ext_h() - lid_th - floor_th;  // post height above the floor (top at the ledge)
    fr = 1.2;    // internal (concave) post<->wall junction fillet radius (mm)
    cl = 1.2;    // exposed free (inner) vertical edge chamfer leg length (mm)
    ov = 0.3;    // fillet-cylinder overlap into the square column + the wall
                 // beyond it -- a fillet tangent (touching, zero-volume-
                 // overlap) at both faces is a degenerate union for CGAL's
                 // exact arithmetic (non-manifold seam); nudging the
                 // cylinder ov past each tangent plane gives a real 3D
                 // overlap on both sides, same reasoning as v2's old wedge-
                 // buttress overlap constant (see git history).
    difference() {
        union() {
            // Square column, flush to both walls (+X, +Y local faces).
            translate([-r, -r, 0]) cube([2*r, 2*r, Hb]);
            // Fillet the two internal (concave) post<->wall junctions: a
            // cylinder tangent to both faces meeting at each notch (nudged
            // by ov for a watertight union), filling the reentrant corner
            // with a smooth curve.
            translate([-r - fr + ov,  r - fr + ov, 0]) cylinder(h = Hb, r = fr);
            translate([ r - fr + ov, -r - fr + ov, 0]) cylinder(h = Hb, r = fr);
        }
        // Chamfer the exposed free (inner) corner at (-r,-r): cuts exactly
        // the `cl`-leg triangle off that convex corner, full height.
        translate([-r, -r, -1])
            linear_extrude(height = Hb + 2)
                polygon([[0, 0], [cl, 0], [0, cl]]);
        // Heat-set insert pocket (lead-in + melt-relief) at the post top, replacing
        // the plain through-bore. Datum: install face Z=0, cuts grow -Z into the column.
        translate([0, 0, Hb]) heatset_pocket(lid_insert_size);
    }
}

module _lid_posts(enable_exhaust = enable_exhaust) {
    for (p = _lid_post_xy(enable_exhaust)) {
        sx = sign(p[0]);                                  // which side wall (-1 / +1)
        sy = (p[1] < int_depth(enable_exhaust)/2) ? -1 : 1; // front boundary (-1) or rear wall (+1)
        translate([p[0], p[1], floor_th])
            scale([sx, sy, 1]) _lid_post_corner();
    }
}

// Board standoff post OD. Wall-derived (was the implicit 6.0mm sbc default):
// bore + 2x the sourced 1.6mm min wall, matching the same standard the lid
// posts use (_lid_post_od) so the M2.5 pilot bore keeps a crack-safe seat.
// Single-sourced here so tests/asserts.scad (which `use`s this file) guards
// the ACTUAL OD the tray renders with, not a re-typed copy.
function _board_standoff_od() = board_insert_bore() + 2*heatset_min_wall(board_insert_size);

module tray(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count, ear_hole_type = ear_hole_type) {
    _tray_shell(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count);
    _faceplate(ear_hole_type = ear_hole_type);
    _lid_posts(enable_exhaust = enable_exhaust);
    // Board standoff posts — only the structural-mount holes (M.2/heatsink/
    // keep-out holes are excluded; see sbc hole roles).
    translate([board_x(), board_y(), floor_th])
        difference() {
            sbc_standoffs(BOARD, standoff_h, role = "structural-mount",
                dia = _board_standoff_od(), bore = board_insert_bore());
            // #75: heat-set lead-in at each post mouth, so an M2.5 insert starts
            // square instead of cocked. heatset_pocket() is a NEGATIVE cutter
            // (union of solid cylinders meant for a consumer difference()), so
            // it must be subtracted here, not unioned as a bare sibling. The
            // cut lands ON TOP of sbc_standoffs()' existing through-bore rather
            // than replacing it: that bore already bottoms on the floor at
            // standoff_h (6.2mm), leaving 0.46mm of relief below the 5.74mm
            // insert — MORE than heatset_pocket()'s own 0.4mm cavity — so the
            // only geometry this actually removes beyond the existing bore is
            // the 0.4mm mouth chamfer. Layering also keeps the pocket from ever
            // being the deepest cut, which matters because standoff_h is
            // derived from the board's underside keep-outs and could shrink
            // below the 6.14mm pocket depth (guarded in tests/asserts.scad).
            // Positions come from the same sbc_holes() role filter sbc_standoffs()
            // is called with, so the pockets cannot drift from their posts.
            for (h = sbc_holes(BOARD, "structural-mount"))
                translate([h[0], h[1], standoff_h]) heatset_pocket(board_insert_size);
        }
}

tray();
