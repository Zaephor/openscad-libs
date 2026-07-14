// lid part — flat cover, flush top, countersunk M3 into tray posts.
include <../params.scad>;
use <rack10/rack10.scad>;
use <hardware/hardware.scad>;
use <tray.scad>;   // for _lid_post_xy() (functions import via use)

module _lid_countersink() {
    // Countersunk M3 clearance: straight through-hole + a 90-degree head cone
    // flush to the top face. cs_dia is a project-chosen head-diameter
    // approximation (no library owns M3 CSK head dia). For a true 90-degree
    // included-angle cone, cone depth = radius delta = (cs_dia - hole_dia)/2
    // — NOT half of cs_dia (that would make the cone deeper than the lid and
    // remove the straight shank bore entirely).
    hole_dia = m3_clearance_mm();
    cs_dia   = hole_dia + csk_head_extra; // head dia approx (M3 CSK ~6mm -> generous)
    cs_depth = (cs_dia - hole_dia) / 2;
    translate([0, 0, -1]) cylinder(h = lid_th + 2, d = hole_dia);
    // Cone: wide at the top face, narrowing down to the shank bore.
    translate([0, 0, lid_th - cs_depth])
        cylinder(h = cs_depth + 0.01, d1 = hole_dia, d2 = cs_dia);
}

module lid() {
    lip = wall/2;
    lw = body_w() - 2*lip - 2*wall_gap;    // rests on the side shelves
    ld = int_depth() - lip - 2*wall_gap;   // rear edge on the rear shelf
    difference() {
        translate([-lw/2, board_y() + wall_gap, 0])
            cube([lw, ld, lid_th]);
        // Countersunk screw holes over each lid post (shared via _lid_post_xy()).
        for (p = _lid_post_xy())
            translate([p[0], p[1], 0]) _lid_countersink();
        // Optional lid vent slots over the hot zone (center band).
        if (lid_vents) {
            pitch = vent_slot_w + vent_slot_gap;
            n = floor((ld * 0.5) / pitch);
            cy = board_y() + int_depth()/2;
            for (i = [0 : n-1])
                translate([-lid_vent_band_w/2, cy - (n-1)*pitch/2 + i*pitch, -1])
                    cube([lid_vent_band_w, vent_slot_w, lid_th + 2]);
        }
    }
}

lid();
