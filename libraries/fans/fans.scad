// fans — PC fan mechanical mounting reference.
// Default orientation: airflow along +Z; square frame centered in X/Y; bottom on Z=0.
// Roles: data functions / fan_placeholder() / fan_holes(), fan_bore().
// Mount holes carry the shared [x,y,role,dia] schema (see fan_mount_holes);
// role vocabulary + filter mirror sbc/drives/motherboards.
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

// --- hole roles (hole-role-tagging sweep; mirrors drives/sbc idiom) ---
function fans_known_hole_roles() = ["structural-mount", "component-mount", "keep-out", "alignment"];

// Distinct roles actually present in a hole list `all` (vocabulary order).
function _fan_roles_present(all) =
    [for (r = fans_known_hole_roles()) if (len([for (h = all) if (h[2] == r) h]) > 0) r];

// role must be undef (= "all"), "all", or a known role string; else caller error.
function _fan_role_ok(role) =
    is_undef(role) || role == "all" || len([for (r = fans_known_hole_roles()) if (r == role) r]) == 1;

// Four corner mount-hole tuples [x, y, role, dia] at +/- spacing/2, optionally
// role-filtered. All four corners are structural-mount (fans have no
// component/keep-out/alignment holes) so the multi-role WARNING never fires
// today, but the full validate/warn machinery ships for schema parity.
//   role a canonical role   -> only that role (silent)
//   role == "all"           -> every hole, silent
//   role == undef (omitted) -> every hole, PLUS a WARNING when >1 role present
//   role anything else      -> assert (unknown role)
function fan_mount_holes(size, role = undef) =
    assert(_fan_role_ok(role), str("fans: unknown hole role '", role, "'; known: ", fans_known_hole_roles()))
    let (h   = fan_hole_spacing(size) / 2,
         d   = fan_mount_hole_dia(size),
         all = [[-h, -h, "structural-mount", d], [ h, -h, "structural-mount", d],
                [ h,  h, "structural-mount", d], [-h,  h, "structural-mount", d]],
         present = _fan_roles_present(all),
         _warn = (is_undef(role) && len(present) > 1)
             ? echo(str("WARNING: fans ", size, "mm holes span ", len(present),
                        " roles; pass role= to filter")) : undef,
         sel = is_undef(role) ? "all" : role)
    [for (e = all) if (sel == "all" || e[2] == sel) e];

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
// Four mounting-screw holes. `role` filters by hole role (see fan_mount_holes);
// per-hole dia from the tuple unless `dia` is given explicitly. `dia<0` here
// falls back to the tuple dia (fan_mount_hole_dia(size)), not fan_hole_clearance();
// pass dia= for a looser pass-through hole.
module fan_holes(size, depth = 20, dia = -1, role = undef) {
    for (p = fan_mount_holes(size, role)) {
        d = dia < 0 ? p[3] : dia;
        translate([p[0], p[1], -1]) cylinder(h = depth + 2, d = d);
    }
}

// Circular airflow opening. //VERIFY bore diameter is design-dependent; default ~0.92*size.
module fan_bore(size, depth = 20) {
    translate([0, 0, -1]) cylinder(h = depth + 2, d = size * 0.92);
}

// Direct-open self-check.
fan_placeholder(120);
