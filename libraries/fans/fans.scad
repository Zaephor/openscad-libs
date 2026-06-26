// fans — PC fan mechanical mounting reference.
// Default orientation: airflow along +Z; square frame centered in X/Y; bottom on Z=0.
// Roles: data functions / fan_placeholder() / fan_holes(), fan_bore().
// Provenance: [A] vendor/standard, [B] multi-peer, [C] reverse-engineered.
// Units: millimeters.

$fn = 64;

// --- Role 1: data (functions, so they resolve across `use`) ---
// Rows: [size_mm, hole_spacing_cc_mm, default_thickness_mm].
// All spacing values tier [B]: https://en.wikipedia.org/wiki/Computer_fan
// (mounting-hole center-to-center), corroborated by retailer references.
// Default thickness from common depths (10/15/25/38mm); 25mm standard for 60-140mm. [B]
function fan_table() = [
    [ 40,  32,   10],
    [ 50,  40,   10],
    [ 60,  50,   25],
    [ 70,  60,   25],
    [ 80,  71.5, 25],
    [ 92,  82.5, 25],
    [120, 105,   25],
    [140, 124.5, 25],
    [200, 154,   30],
    [220, 170,   30],
];

// Nominal case screw: M5 self-tapping. //VERIFY [B] retailer (graphicscardhub.com) — confirm vs vendor datasheet.
function fan_screw_case() = 5;
// Generous default clearance for the hole a case screw passes/threads into (loose by default; tunable).
function fan_hole_clearance() = 4.5; // (design default, not sourced)
// Fan's own mounting-hole diameter: 4.3 for >=70mm [B].
// //VERIFY 40-60mm varies ~3.2-4.3 by model; defaulting 4.3.
function fan_mount_hole_dia(size) = 4.3;

function _fan_row(size) =
    let (rows = [for (r = fan_table()) if (r[0] == size) r])
    len(rows) > 0 ? rows[0] : undef;

function fan_known_sizes() = [for (r = fan_table()) r[0]];

function fan_hole_spacing(size) =
    let (r = _fan_row(size))
    assert(!is_undef(r), str("fans: unknown size ", size, "mm; known: ", fan_known_sizes()))
    r[1];

function fan_default_thickness(size) =
    let (r = _fan_row(size))
    assert(!is_undef(r), str("fans: unknown size ", size, "mm"))
    r[2];

// Four corner mounting-hole coordinates [x, y] at +/- spacing/2.
function fan_holes_xy(size) =
    let (h = fan_hole_spacing(size) / 2)
    [[-h, -h], [h, -h], [h, h], [-h, h]];

// --- Role 2: placeholder ---
// Square frame envelope with the airflow bore removed; mounting holes as keep-outs.
module fan_placeholder(size, thickness = -1) {
    t = thickness < 0 ? fan_default_thickness(size) : thickness;
    difference() {
        translate([0, 0, t / 2]) cube([size, size, t], center = true);
        fan_bore(size, depth = t);
        fan_holes(size, depth = t, dia = fan_mount_hole_dia(size));
    }
}

// --- Role 3: stamps for a consumer difference() ---
// Four mounting-screw holes.
module fan_holes(size, depth = 20, dia = -1) {
    d = dia < 0 ? fan_hole_clearance() : dia;
    for (p = fan_holes_xy(size))
        translate([p[0], p[1], -1]) cylinder(h = depth + 2, d = d);
}

// Circular airflow opening. //VERIFY bore diameter is design-dependent; default ~0.92*size.
module fan_bore(size, depth = 20) {
    translate([0, 0, -1]) cylinder(h = depth + 2, d = size * 0.92);
}

// Direct-open self-check.
fan_placeholder(120);
