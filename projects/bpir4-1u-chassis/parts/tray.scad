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
use <hardware/hardware.scad>;
use <heatset/heatset.scad>;
use <_honeycomb.scad>;

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
        // Rear-wall fan bores or passive vents.
        _rear_openings(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count);
    }
}

// Rear-wall openings. Fans on: `fan_count` bores + screw holes across the
// wall, vertically centered on the interior clearance, axis rotated onto +Y
// so the (default Z-axis) fan cutters punch straight through the wall. Fans
// off: a self-supporting honeycomb hex vent over the same fan footprint
// (see the honeycomb_vent() call below).
//
// rear_wall_y(ee = enable_exhaust) is the wall's outer (rearmost) face; the
// wall itself occupies [rear_wall_y()-wall, rear_wall_y()] (see
// _tray_shell()), so every cutter below is anchored off
// `rear_wall_y(ee) - wall` (the inner face) to actually intersect the wall.
// The `ee` param (params.scad) must be threaded through explicitly from this
// module's own enable_exhaust parameter -- see params.scad's "ee defaults
// to..." comment for why a plain no-arg call can't see it.
module _rear_openings(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count) {
    yw = rear_wall_y(enable_exhaust); // rear wall outer (rearmost) face
    zc = floor_th + int_h()/2;        // vertical center of interior clearance
    if (enable_exhaust) {
        span = fan_count * fan_size;
        x0   = -span/2 + fan_size/2;  // first fan center
        for (i = [0 : fan_count-1])
            translate([x0 + i*fan_size, yw - wall, zc])
                rotate([-90, 0, 0]) {  // Z-axis cutters -> +Y, through the wall
                    fan_bore(fan_size, depth = wall);
                    fan_holes(fan_size, depth = wall);
                }
    } else {
        // Passive honeycomb: self-supporting hex vent over the same
        // fan_count*fan_size footprint the active fans would occupy
        // (X centered on 0, Z band centered on zc), cut fully through the
        // rear wall. Same rotate([90,0,0]) idiom as the faceplate band (see
        // _faceplate()): local X (honeycomb's `width`) stays chassis X;
        // local Y (honeycomb's `height`) becomes chassis Z (the fan_size
        // band around zc); local Z (honeycomb's `depth`, its extrusion /
        // cut-through axis) becomes chassis -Y, punching through the rear
        // wall — `wall + 2` gives a 1mm overcut on both faces, matching the
        // old slot cutter's overcut. Translate places the honeycomb's local
        // (0,0,0) corner at (x=-span/2, y=yw+1 [outer wall face + 1mm
        // overcut], z=zc-fan_size/2), so after rotation the cut spans
        // Y=[yw-wall-1, yw+1] through the wall and Z=[zc-fan_size/2,
        // zc+fan_size/2] centered on zc.
        span = fan_count * fan_size;
        translate([-span/2, yw + 1, zc - fan_size/2])
            rotate([90, 0, 0])
                honeycomb_vent(span, fan_size, wall + 2, honeycomb_cell, honeycomb_wall);
    }
}

// Front rack panel: full panel width, chassis-exterior height, front face on
// Y=0 growing -Y (toward the rack front). Rack mount holes + connector cutouts.
module _faceplate(ear_hole_type = ear_hole_type) {
    difference() {
        // Panel blank (own height = ext_h(); width from the library).
        translate([-panel_w()/2, -faceplate_th, 0])
            cube([panel_w(), faceplate_th, ext_h()]);
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
        // chassis position. depth clears the panel thickness.
        translate([board_x(), board_y(), board_z()])
            sbc_faceplate_cutouts(BOARD, "ymin", depth = faceplate_th + 2);
        // Intake vents ABOVE the IO portholes: a self-supporting honeycomb
        // hex-hole cutter across the connector cluster, from just above the
        // tallest connector to just below the ledge — straight cross-chassis
        // airflow over the SFP/connector tops. Replaces the old full-width
        // slot cubes (a flat, unsupported bridge spanning the whole cluster
        // width) with honeycomb_vent() (parts/_honeycomb.scad): flat-top hex
        // cells whose only bridge (the hex top edge) is a few mm, not the
        // whole band width — see _honeycomb.scad for the self-support
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
        sbc_standoffs(BOARD, standoff_h, role = "structural-mount",
            dia = _board_standoff_od(), bore = board_insert_bore());
}

tray();
