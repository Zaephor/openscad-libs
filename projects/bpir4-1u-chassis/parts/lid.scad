// lid part — flat cover, flush top, countersunk M3 into tray posts.

/* [Cooling] */
// These top-level vars are lid()'s module-param DEFAULTS (see lid() below)
// and also feed params.scad's fan_size assert at include-time — declared
// here + in each entry file; params.scad consumes only, never re-assigns.
// Of the three, only enable_exhaust actually drives lid() geometry (via
// int_depth()/_lid_post_xy()); fan_size/fan_count are accepted by lid() for
// call-site symmetry with tray() but don't change lid geometry — see lid()'s
// own comment below.
enable_exhaust = true; // false = passive (no rear fan plenum)
fan_size  = 40;        // must be a fan_known_sizes() value
fan_count = 2;

/* [Rack Ears] */
ear_hole_type = "slot"; // "slot" | "10-32" | "m6" | "round"

include <../params.scad>;
use <rack10/rack10.scad>;
use <tray.scad>;   // for _lid_post_xy() (functions import via use)
use <honeycomb/honeycomb.scad>;

module _lid_countersink() {
    // Countersunk M3 clearance: straight through-hole + a 90-degree head cone
    // flush to the top face. cs_dia is a project-chosen head-diameter
    // approximation (no library owns M3 CSK head dia). For a true 90-degree
    // included-angle cone, cone depth = radius delta = (cs_dia - hole_dia)/2
    // — NOT half of cs_dia (that would make the cone deeper than the lid and
    // remove the straight shank bore entirely).
    // M3 clearance — ISO 273 medium fit, 3.4mm [B]//VERIFY; inlined (#17, hardware lib removed).
    hole_dia = 3.4;
    cs_dia   = hole_dia + csk_head_extra; // head dia approx (M3 CSK ~6mm -> generous)
    cs_depth = (cs_dia - hole_dia) / 2;
    translate([0, 0, -1]) cylinder(h = lid_th + 2, d = hole_dia);
    // Cone: wide at the top face, narrowing down to the shank bore.
    translate([0, 0, lid_th - cs_depth])
        cylinder(h = cs_depth + 0.01, d1 = hole_dia, d2 = cs_dia);
}

// enable_exhaust drives the depth path (int_depth()/rear_wall_y(), so the lid
// shrinks with the tray in passive mode) and the post/countersink placement
// (_lid_post_xy(), shared with tray()'s posts so both stay coincident by
// construction). fan_size/fan_count are accepted ONLY so the assembly call
// site can pass all three cooling params uniformly with tray() -- lid
// geometry does NOT consume them (int_depth() has no fan_size term, and
// params.scad's fan_size assert already runs once at include-time regardless
// of what's passed here); they are otherwise inert for the lid.
module lid(enable_exhaust = enable_exhaust, fan_size = fan_size, fan_count = fan_count) {
    lip = wall/2;
    lw = body_w() - 2*lip - 2*wall_gap;                    // rests on the side shelves
    ld = int_depth(enable_exhaust) - lip - 2*wall_gap;     // rear edge on the rear shelf
    difference() {
        translate([-lw/2, board_y() + wall_gap, 0])
            cube([lw, ld, lid_th]);
        // Countersunk screw holes over each lid post (shared via _lid_post_xy(),
        // which must be called with the SAME enable_exhaust as tray()'s posts
        // so the countersinks stay coincident with the posts they seat on).
        for (p = _lid_post_xy(enable_exhaust))
            translate([p[0], p[1], 0]) _lid_countersink();
        // Optional lid vents over the hot zone (center band): a self-
        // supporting honeycomb hex-hole cutter (honeycomb/honeycomb.scad),
        // reusing the faceplate's honeycomb_cell/honeycomb_wall (params.scad)
        // for a visually consistent look. band_len mirrors the old slot
        // loop's target coverage (half the lid depth, centered on the
        // interior mid-point) rather than a new hand-picked literal.
        //
        // Axis mapping / no rotate needed: the lid is printed FLAT (see
        // PRINTING.md — its large face on the bed, lid_th the print-vertical
        // axis). honeycomb_vent()'s local frame is X=width, Y=height,
        // Z=depth (extruded along Z); here local X/Y map straight onto
        // chassis X/Y (band width / band length) and local Z (the cut-
        // through axis) maps straight onto chassis Z (lid_th) — exactly the
        // axis the old cube cutter punched through, and exactly the lid's
        // own (short) print-vertical axis, so the through-cut needs no
        // bridging regardless of hole shape. Unlike the faceplate (printed
        // with chassis Z as a TALL vertical wall, hence its rotate([90,0,0])
        // to put honeycomb_vent's bridging-sensitive "height" axis onto that
        // tall vertical run), the lid's chassis Z is only lid_th (2mm) — so
        // no rotate is used or needed here. This also preserves the hex's
        // flat-top orientation as visible looking down the lid's top face
        // (local Y's flat top edge lands on chassis Y, matching the
        // faceplate's look). honeycomb_vent()'s own assert()/echo() (see
        // that file) still verifies the worst-case boundary-hex span for
        // THIS band's actual height stays under the 5mm self-support
        // ceiling — confirmed at 4mm for this band (fully interior hex rows,
        // no boundary clipping) via tests/test_bpir4_lid_honeycomb_vents.sh.
        if (lid_vents) {
            band_len = ld * 0.5;
            cy = board_y() + int_depth(enable_exhaust)/2;
            translate([-lid_vent_band_w/2, cy - band_len/2, -1])
                honeycomb_vent(lid_vent_band_w, band_len, lid_th + 2,
                                honeycomb_cell, honeycomb_wall);
        }
    }
}

lid();
