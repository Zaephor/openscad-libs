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
        // Rack mounting holes — square cage-nut pattern, from the library.
        rack10_holes(STD, 1, hole_type = "square");
        // BPI-R4 front-panel connector openings (ymin edge), at the board's
        // chassis position. depth clears the panel thickness.
        translate([board_x(), board_y(), board_z()])
            sbc_faceplate_cutouts(BOARD, "ymin", depth = faceplate_th + 2);
        // Intake vents: vertical slots in each faceplate margin (clear of the
        // board's connector band). Each side spans X in
        // [board_w/2+vent_slot_gap, body_w/2-wall-vent_slot_gap]; sides mirror.
        for (sx = [-1, 1]) {
            m_out = sx * (body_w()/2 - wall - vent_slot_gap);
            m_in  = sx * (board_w()/2 + vent_slot_gap);
            lo = min(m_out, m_in); hi = max(m_out, m_in);
            pitch = vent_slot_w + vent_slot_gap;
            n = floor((hi - lo) / pitch);
            for (i = [0 : max(n-1,0)])
                translate([lo + vent_slot_gap + i*pitch, -faceplate_th - 1,
                           floor_th + vent_slot_gap])
                    cube([vent_slot_w, faceplate_th + 2,
                          ext_h() - floor_th - lid_th - 2*vent_slot_gap]);
        }
    }
}

// Internal bosses the lid screws into. M3 heat-set insert bore, top-loaded.
// Placed at the four inner corners + front/rear mid-span (6 posts) so a wide
// lid does not bow. Post top is at the ledge (ext_h - lid_th).
function _lid_post_od() = lid_insert_bore + boss_wall; // boss OD (shared by placement + geometry)
function _lid_post_xy() =
    let (post_r = _lid_post_od() / 2,                    // post OD/2 (matches _lid_posts() OD)
         ix = body_w()/2 - wall - post_r - post_wall_gap, // printable gap to wall inner face
         y0 = board_y(),
         yf = y0 + post_edge_inset, yr = y0 + int_depth() - wall - post_edge_inset, ym = (yf + yr)/2)
    [ [-ix, yf], [ix, yf], [-ix, ym], [ix, ym], [-ix, yr], [ix, yr] ];

module _lid_posts() {
    h = ext_h() - lid_th;
    for (p = _lid_post_xy())
        translate([p[0], p[1], floor_th]) difference() {
            cylinder(h = h - floor_th, d = _lid_post_od());
            translate([0, 0, -1]) cylinder(h = h - floor_th + 2, d = lid_insert_bore);
        }
}

module tray() {
    _tray_shell();
    _faceplate();
    _lid_posts();
    // Board standoff posts.
    translate([board_x(), board_y(), floor_th])
        sbc_standoffs(BOARD, standoff_h, bore = board_insert_bore);
}

tray();
