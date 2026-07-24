// fan-grille — flat, support-free honeycomb finger-guard for a case fan.
// Square plate at the fan footprint + solid border + a honeycomb_vent field
// over the opening + corner mount holes. Prints flat (plate_th is the short
// print-vertical axis; the honeycomb cuts straight through Z, no bridging).
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;

/* [Fan] */
fan_size = 40;   // must be in fan_known_sizes()
plate_th = 3;
/* [Vent] */
cell = 8.0;        // hex point-to-point (design/print value, carried from bpir4)
wall = 1.2;         // gap between hex holes
field_margin = 8;  // inset of the honeycomb field inboard of the mount-hole square

assert(len([for (s = fan_known_sizes()) if (s == fan_size) s]) > 0,
    str("fan-grille: fan_size ", fan_size, " not in ", fan_known_sizes()));

// fan_holes()' hole frame is centered on the fan origin (+/- fan_hole_spacing/2
// in X and Y, confirmed against fan_mount_holes() -- see fans.scad), matching
// this module's own centered plate, so no corner-anchor translation is needed.
module fan_grille(fan_size = fan_size, plate_th = plate_th, cell = cell, wall = wall,
                   field_margin = field_margin) {
    field = fan_hole_spacing(fan_size) - field_margin; // clears the corner holes
    difference() {
        translate([-fan_size/2, -fan_size/2, 0]) cube([fan_size, fan_size, plate_th]);
        // honeycomb field, centered, cut straight through Z (flat print -> no bridge)
        translate([-field/2, -field/2, -1])
            honeycomb_vent(field, field, plate_th + 2, cell, wall);
        // corner mount holes from the fans lib (single source of truth)
        fan_holes(fan_size, depth = plate_th + 2, role = "structural-mount");
    }
}
fan_grille();
