// tray part — single-body chassis: floor + faceplate + walls + rear wall.
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
use <hardware/hardware.scad>;

// Outer shell: floor + two side walls + rear wall, with an inner ledge on the
// wall tops so the lid drops in flush. Faceplate/fans/vents added by later modules.
module _tray_shell() {
    y0 = board_y();
    dd = int_depth();
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
        _rear_openings();
    }
}

// Rear-wall openings. Fans on: `fan_count` bores + screw holes across the
// wall, vertically centered on the interior clearance, axis rotated onto +Y
// so the (default Z-axis) fan cutters punch straight through the wall. Fans
// off: a vertical passive vent-slot array.
//
// rear_wall_y() is the wall's outer (rearmost) face; the wall itself occupies
// [rear_wall_y()-wall, rear_wall_y()] (see _tray_shell()), so every cutter
// below is anchored off `rear_wall_y() - wall` (the inner face) to actually
// intersect the wall.
module _rear_openings() {
    yw = rear_wall_y();               // rear wall outer (rearmost) face
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
        // Passive slots: vertical rectangular cuts across the rear wall.
        usable = body_w() - 2*wall - 2*vent_slot_gap;
        pitch  = vent_slot_w + vent_slot_gap;
        n      = floor(usable / pitch);
        x0     = -(n-1)*pitch/2;
        for (i = [0 : n-1])
            translate([x0 + i*pitch - vent_slot_w/2, yw - wall - 1, floor_th + vent_slot_gap])
                cube([vent_slot_w, wall + 2, int_h() - 2*vent_slot_gap]);
    }
}

// Front rack panel: full panel width, chassis-exterior height, front face on
// Y=0 growing -Y (toward the rack front). Rack mount holes + connector cutouts.
module _faceplate() {
    difference() {
        // Panel blank (own height = ext_h(); width from the library).
        translate([-panel_w()/2, -faceplate_th, 0])
            cube([panel_w(), faceplate_th, ext_h()]);
        // Rack mounting holes on the ears: slot (default) for post-spacing
        // tolerance, or a round type. Width from the 10-32 screw clearance.
        if (ear_hole_type == "slot")
            rack10_holes(STD, 1, hole_type = "slot",
                         dia = rack10_screw_clearance("10-32"));
        else
            rack10_holes(STD, 1, hole_type = ear_hole_type);
        // BPI-R4 front-panel connector openings (ymin edge), at the board's
        // chassis position. depth clears the panel thickness.
        translate([board_x(), board_y(), board_z()])
            sbc_faceplate_cutouts(BOARD, "ymin", depth = faceplate_th + 2);
        // Intake vents ABOVE the IO portholes: horizontal slots across the
        // connector cluster, from just above the tallest connector to just below
        // the ledge — straight cross-chassis airflow over the SFP/connector tops.
        cl = [for (c = sbc_connectors(BOARD)) if (c[3]=="ymin") board_x()+c[1][0]];
        cr = [for (c = sbc_connectors(BOARD)) if (c[3]=="ymin") board_x()+c[1][0]+c[2][0]];
        bx0 = min(cl); bx1 = max(cr);                 // connector cluster X-span (chassis frame)
        z0 = _vent_band_z0();
        z1 = ext_h() - lid_th - vent_slot_gap;        // just below the ledge
        pitch = vent_slot_w + vent_slot_gap;
        rows = floor((z1 - z0) / pitch);
        for (i = [0 : max(rows-1, 0)])
            translate([bx0, -faceplate_th - 1, z0 + i*pitch])
                cube([bx1 - bx0, faceplate_th + 2, vent_slot_w]);
    }
}

// Internal bosses the lid screws into. M3 heat-set insert bore, top-loaded.
// Four corner posts only (side-midspan pair dropped): each sits tangent to its
// side wall, beside the board, and is buttressed to that wall so the tall thin
// boss prints support-free and does not wobble. Post top is at the ledge
// (ext_h - lid_th). _lid_post_od() lives in params.scad (body_w() derives from
// it too). The X placement is TANGENT to the side-wall inner face (post outer
// edge flush with the wall) — NOT offset by post_wall_gap. That earlier gap
// pushed the post inboard until, under the narrowed body_w(), its inner edge
// crossed the board footprint (inner edge 73.8 < board_w()/2 = 74.0 -> a 0.2mm
// collision with the SBC). Tangent placement instead leaves the board_side_gap
// (~1.0mm) the params establish: inner edge = ix - post_r clears board_w()/2.
function _lid_post_xy() =
    let (ix = body_w()/2 - wall - _lid_post_od()/2,      // tangent to side-wall inner face
         yf = board_y() + post_edge_inset,               // front pair, inside faceplate
         yr = board_y() + int_depth() - wall - post_edge_inset) // rear pair, ahead of rear wall
    [ [-ix, yf], [ix, yf], [-ix, yr], [ix, yr] ];

// Corner buttress (canonical +X side, local origin at the boss center): a
// solid wedge fusing the boss to its side wall. Built as hull() of two vertical
// reference boxes — one full-height slab overlapping into the wall, one lowered
// slab at the boss inner edge — so the top is a single up-facing ramp that
// falls away from the wall. Cross-section only SHRINKS with height (each layer
// sits fully on the one below): no underside overhang, so it prints without
// support. The wall face is at local x = +post_r (the boss is tangent to it);
// the inner edge is at local x = -post_r, clearing the board.
module _corner_buttress() {
    r   = _lid_post_od()/2;                 // boss radius; wall face at +r, inner edge at -r
    Hb  = ext_h() - lid_th - floor_th;      // boss height above the floor (top at the ledge)
    gW  = _lid_post_od();                   // gusset width in Y (~ boss OD)
    t   = 0.6;                              // thin reference-box thickness
    ov  = 0.6;                              // overlap into the wall for a watertight union
    drop = 2*r;                             // top falls ~45deg over the wall->inner run (=OD)
    hull() {
        // Full-height slab at the wall (its outer face buried in the wall).
        translate([r - t, -gW/2, 0])   cube([t + ov, gW, Hb]);
        // Lowered slab at the boss inner edge -> top ramps down away from wall.
        translate([-r, -gW/2, 0])      cube([t, gW, Hb - drop]);
    }
}

module _lid_posts() {
    Hb = ext_h() - lid_th - floor_th;       // boss height above the floor
    for (p = _lid_post_xy()) {
        sx = sign(p[0]);                    // which side wall (-1 / +1)
        translate([p[0], p[1], floor_th]) difference() {
            union() {
                cylinder(h = Hb, d = _lid_post_od());   // solid boss
                scale([sx, 1, 1]) _corner_buttress();   // wall-side wedge (mirror onto the -X wall)
            }
            // Insert bore, cut through boss AND buttress so it stays open full depth.
            translate([0, 0, -1]) cylinder(h = Hb + 2, d = lid_insert_bore);
        }
    }
}

module tray() {
    _tray_shell();
    _faceplate();
    _lid_posts();
    // Board standoff posts — only the structural-mount holes (M.2/heatsink/
    // keep-out holes are excluded; see sbc hole roles).
    translate([board_x(), board_y(), floor_th])
        sbc_standoffs(BOARD, standoff_h, role = "structural-mount", bore = board_insert_bore);
}

tray();
