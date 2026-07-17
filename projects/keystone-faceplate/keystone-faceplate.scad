// keystone-faceplate — parametric 1U 10-inch rack keystone faceplate.
// Standalone; N standard keystone ports on a rack10 panel. Support-free flat
// print. Render: make render P=keystone-faceplate
// All keystone dims from the keystone lib, all rack dims from rack10 — no
// copied literals (see docs/LIBRARY-AUTHORING.md single-source rule).
use <keystone/keystone.scad>;
use <rack10/rack10.scad>;

/* [Customizer] */
// Rack vendor key (rack10_known_standards()).
standard        = "labrax";
// Number of keystone ports; 0 = blank plate.
port_count      = 6;
// Port center-to-center, mm. Default is the keystone lib's standard pitch;
// DRIFT-CHECK: tests/asserts.scad asserts this literal == keystone_pitch().
port_pitch      = 19.05;
// Plate thickness, mm. Must sit within keystone_plate_thickness() for snap
// retention; default = that range's max. DRIFT-CHECK asserted in tests.
plate_thickness = 3.0;
// Per-side window growth handed to keystone_cutout().
port_clearance  = 0.25;
// Ear mount hole style: rack10 round/m6/10-32/square/slot.
ear_hole_type   = "slot";
// Fastener feeding the slot/round clearance dia (m6 | 10-32).
ear_fastener    = "m6";
// Obround elongation along X for slot ears; rack10 default.
slot_travel     = 4;

$fn = 48;

keystone_faceplate(standard, port_count, port_pitch, plate_thickness,
                   port_clearance, ear_hole_type, ear_fastener, slot_travel);

// Ascending port X-centers, row centered on X=0. Empty when port_count<=0.
function _kf_port_centers(port_count, port_pitch) =
    port_count <= 0 ? []
    : [for (i = [0:port_count-1]) (i - (port_count-1)/2) * port_pitch];

module keystone_faceplate(standard, port_count, port_pitch, plate_thickness,
                          port_clearance = 0.25, ear_hole_type = "slot",
                          ear_fastener = "m6", slot_travel = 4) {
    // Guards land in Task 5. Ports land in Task 4.
    difference() {
        rack10_panel(standard, 1, plate_thickness);
        rack10_holes(standard, 1, ear_hole_type,
            dia = rack10_screw_clearance(ear_fastener), slot_travel = slot_travel);
    }
}
