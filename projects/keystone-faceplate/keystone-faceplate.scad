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
    // Pitch must clear the min printable port spacing.
    keystone_pitch_assert(port_pitch);
    // Plate thickness must sit within the snap-retention range.
    tmin = keystone_plate_thickness()[0];
    tmax = keystone_plate_thickness()[1];
    assert(plate_thickness >= tmin && plate_thickness <= tmax,
        str("keystone-faceplate: plate_thickness ", plate_thickness,
            " outside keystone snap range [", tmin, ",", tmax, "]"));
    // Row fits: adjacent ports clear min pitch, and the outermost port's window
    // edge must not reach the inner ear-hole column (else a port collides with
    // an ear slot). ear column inner X = rack10_hole_h_span/2; subtract the ear
    // clearance radius so the port window edge stays clear of the drilled slot.
    xs = _kf_port_centers(port_count, port_pitch);
    assert(keystone_layout_ok(xs),
        str("keystone-faceplate: port pitch ", port_pitch,
            " below min for port_count ", port_count));
    ow = keystone_opening()[0];
    ear_col = rack10_hole_h_span(standard) / 2;
    ear_r   = rack10_screw_clearance(ear_fastener) / 2;
    outer_edge = port_count <= 0 ? 0
               : max([for (x = xs) abs(x)]) + ow / 2 + port_clearance;
    assert(outer_edge <= ear_col - ear_r,
        str("keystone-faceplate: ", port_count, " ports at pitch ", port_pitch,
            " overflow (outer edge ", outer_edge, " reaches ear column ",
            ear_col - ear_r, ")"));
    difference() {
        rack10_panel(standard, 1, plate_thickness);
        rack10_holes(standard, 1, ear_hole_type,
            dia = rack10_screw_clearance(ear_fastener), slot_travel = slot_travel);
        // Keystone ports: row centered on X=0, vertically centered on the panel.
        // rotate([-90,0,0]) maps the cutout's oh->Z, ow->X, through-axis->+Y so
        // the window fully pierces the Y∈[-t,0] plate (see plan coordinate note).
        for (x = _kf_port_centers(port_count, port_pitch))
            translate([x, 0, rack10_device_height(1) / 2])
                rotate([-90, 0, 0])
                    keystone_cutout(plate_thickness, port_clearance);
    }
}
