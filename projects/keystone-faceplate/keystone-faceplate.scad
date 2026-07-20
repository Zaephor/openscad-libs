// keystone-faceplate — parametric 1U 10-inch rack keystone faceplate.
// Standalone; N standard keystone ports on a rack10 panel. Support-free flat
// print. Render: make render P=keystone-faceplate
// PRINT ORIENTATION (port_style="lip", the default): as-modeled the panel's
// thickness (Y) is horizontal and its 1U height (Z) is vertical -- rotate
// -90deg about X in the slicer so Y becomes vertical, front face (Y=0) DOWN
// on the bed, matching keystone_cutout()/keystone_boss()'s own pin (see
// keystone.scad); printing rear-face-down needs supports under the ramps.
// port_style="face" has no such requirement (flat rectangular window, no
// undercut) -- support-free from any flat orientation.
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
// Port retention style (keystone_known_styles()): lip=taller lipped window,
// face=flush face-plate window.
port_style      = "lip";
// Preview the surrounding 10-inch rack posts (device centered in 3U). Preview
// ONLY — rendered with `%`, excluded from the printable STL. Default off.
show_rack          = false;
// Rack context front-to-back depth; 0 = the vendor's rack10_depth_preset().
rack_context_depth = 0;

$fn = 48;

keystone_faceplate(standard, port_count, port_pitch, plate_thickness,
                   port_clearance, ear_hole_type, ear_fastener, slot_travel,
                   port_style);

// Optional rack-context preview (background %; not part of the print).
if (show_rack)
    % rack10_rackpost_context(standard, 1, 1,
        rack_context_depth > 0 ? rack_context_depth : rack10_depth_preset(standard));

// Ascending port X-centers, row centered on X=0. Empty when port_count<=0.
function _kf_port_centers(port_count, port_pitch) =
    port_count <= 0 ? []
    : [for (i = [0:port_count-1]) (i - (port_count-1)/2) * port_pitch];

module keystone_faceplate(standard, port_count, port_pitch, plate_thickness,
                          port_clearance = 0.25, ear_hole_type = "slot",
                          ear_fastener = "m6", slot_travel = 4,
                          port_style = "lip") {
    // Pitch must clear the min printable port spacing for this style.
    keystone_pitch_assert(port_pitch, port_style);
    // Plate thickness must sit within the snap-retention range.
    tmin = keystone_plate_thickness()[0];
    tmax = keystone_plate_thickness()[1];
    assert(plate_thickness >= tmin && plate_thickness <= tmax,
        str("keystone-faceplate: plate_thickness ", plate_thickness,
            " outside keystone snap range [", tmin, ",", tmax, "]"));
    // Row fits: adjacent ports clear min pitch, and the outermost port's
    // physical footprint must not reach the inner ear-hole column (else a
    // port collides with an ear slot). ear column inner X =
    // rack10_hole_h_span/2; subtract the ear clearance radius so the
    // footprint stays clear of the drilled slot.
    xs = _kf_port_centers(port_count, port_pitch);
    assert(keystone_layout_ok(xs, port_style),
        str("keystone-faceplate: port pitch ", port_pitch,
            " below min for port_count ", port_count));
    // half_w = each port's max X half-extent. "standard" (incl. its "lip"
    // alias, and undef) is boss-driven, not opening-driven:
    // keystone_boss(plate_thickness, port_clearance, port_style) unions in
    // LOCAL positive material (see keystone_cutout()'s module comment for the
    // union()+difference() pattern below) that is physically wider than the
    // raw cutout window -- keystone_boss_footprint() already bakes in
    // port_clearance + wall margin, so its half-width IS the collision term
    // (mirrors keystone_min_pitch()'s same style split). "face" has no boss
    // (keystone_boss() no-ops for it) -- unchanged raw-opening + clearance
    // check. Branch on style == "face" (matching keystone.scad's own
    // internal convention, e.g. keystone_boss()'s if/else) rather than the
    // literal "lip" string, so an explicit port_style="standard" also
    // resolves to the boss branch instead of silently under-guarding via the
    // opening-only check.
    half_w = port_style == "face"
        ? keystone_opening(port_style)[0] / 2 + port_clearance
        : keystone_boss_footprint(port_style, port_clearance)[0] / 2;
    ear_col = rack10_hole_h_span(standard) / 2;
    // ear_r = ear cutout's half-width along X (the axis ear_col/outer_edge
    // measure along). "slot" elongates the clearance circle by slot_travel/2
    // further inward (rack10_holes()'s obround, hull'd along local X which
    // maps 1:1 to global X through its rotate([-90,0,0])); "square" ignores
    // the fastener dia entirely and cuts a fixed rack10_square_size() square
    // instead (see rack10_holes()) — neither matches a plain clearance-circle
    // radius.
    ear_r = ear_hole_type == "slot"   ? rack10_screw_clearance(ear_fastener) / 2 + slot_travel / 2
          : ear_hole_type == "square" ? rack10_square_size() / 2
          : rack10_screw_clearance(ear_fastener) / 2;
    outer_edge = port_count <= 0 ? 0
               : max([for (x = xs) abs(x)]) + half_w;
    assert(outer_edge <= ear_col - ear_r,
        str("keystone-faceplate: ", port_count, " ports at pitch ", port_pitch,
            " overflow (outer edge ", outer_edge, " reaches ear column ",
            ear_col - ear_r, ")"));
    // "standard"'s cutout needs ~10mm+ of Z-depth (back_wall_depth + taper,
    // RESEARCH.md/#38), far more than plate_thickness (1.5-3.0mm) --
    // keystone_boss() unions in the missing
    // material behind the thin panel at each port FIRST, so the difference()
    // below always lands its cutout in real solid (see keystone_cutout()'s
    // module comment for this exact union()+difference() consumer pattern).
    // keystone_boss() no-ops for "face" (nothing to add).
    difference() {
        union() {
            rack10_panel(standard, 1, plate_thickness);
            // Same per-port transform as the cutout loop below, so each
            // boss lands directly behind its own port's cutout.
            for (x = xs)
                translate([x, 0, rack10_device_height(1) / 2])
                    rotate([-90, 0, 0])
                        keystone_boss(plate_thickness, port_clearance, port_style);
        }
        rack10_holes(standard, 1, ear_hole_type,
            dia = rack10_screw_clearance(ear_fastener), slot_travel = slot_travel);
        // Keystone ports: row centered on X=0, vertically centered on the panel.
        // rotate([-90,0,0]) maps the cutout's oh->Z, ow->X, through-axis->+Y so
        // the window fully pierces the Y∈[-t,0] plate (see plan coordinate note).
        for (x = xs)
            translate([x, 0, rack10_device_height(1) / 2])
                rotate([-90, 0, 0])
                    keystone_cutout(plate_thickness, port_clearance, port_style);
    }
}
