// heatset — brass heat-set threaded insert dimension reference (soldering-iron
// installed, knurled/barbed body, common 3D-printing style). Sizes M2-M6,
// "standard" (not "short") length variant. Datum: millimeters.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — heatset_placeholder(size): insert envelope solid for fit checks
//   3. Hole-stamp  — heatset_pocket(size), heatset_boss(size): pilot hole / boss for a
//                    consumer difference() and union()
// Provenance legend (see RESEARCH.md for the full evidence log this pass):
//   [A] fetched + read this pass (vendor datasheet or governing standard).
//   [B] corroborated across >=2 independent peers.
//   [C] single-sourced / derived, not vendor-specified.
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
//
// Task 2 of this pass: (1) data table + accessor functions only. Placeholder
// and hole-stamp roles are added by later tasks.

$fn = 48;

/* [Data] — per-size insert dimension table. Tiers per docs/LIBRARY-AUTHORING.md;
   see RESEARCH.md for the full sourcing/derivation log.
   Row: [size, insert_od, insert_length, pilot_dia, boss_od, lead_in] mm. */
function _heatset_table() = [
    ["M2",   3.73, 4.00, 3.23,  9.3, 0.4], // insert_od/length/pilot_dia [A]/[B] PEM SI-6; boss_od [C] //VERIFY derived 2.5x insert_od; lead_in [C] //VERIFY repo 45deg convention
    ["M2.5", 4.55, 5.74, 4.01, 11.4, 0.4], // insert_od [A] PEM; length/pilot_dia [B] PEM+ruthex/insertguide; boss_od [C] //VERIFY derived 2.5x insert_od; lead_in [C] //VERIFY repo 45deg convention
    ["M3",   4.55, 5.74, 4.01, 11.4, 0.4], // insert_od/length/pilot_dia [B] PEM+CNC Kitchen+ruthex/insertguide; boss_od [C] //VERIFY derived 2.5x insert_od; lead_in [C] //VERIFY repo 45deg convention
    ["M4",   6.17, 8.15, 5.67, 15.4, 0.4], // insert_od/length/pilot_dia [B] PEM+CNC Kitchen+ruthex/insertguide; boss_od [C] //VERIFY derived 2.5x insert_od; lead_in [C] //VERIFY repo 45deg convention
    ["M5",   6.93, 9.52, 6.43, 17.3, 0.4], // insert_od/length/pilot_dia [B] PEM+CNC Kitchen+ruthex; boss_od [C] //VERIFY derived 2.5x insert_od; lead_in [C] //VERIFY repo 45deg convention
    ["M6",   8.69, 12.70, 8.03, 21.7, 0.4], // insert_od [A] PEM; length/pilot_dia [B] PEM+ruthex/insertguide; boss_od [C] //VERIFY derived 2.5x insert_od; lead_in [C] //VERIFY repo 45deg convention
];
function heatset_known_sizes() = [for (e = _heatset_table()) e[0]];
function _heatset_row(s) =
    let (r = [for (e = _heatset_table()) if (e[0] == s) e])
    assert(len(r) == 1, str("heatset: unknown size '", s, "'")) r[0];
function heatset_insert_od(s)     = _heatset_row(s)[1];
function heatset_insert_length(s) = _heatset_row(s)[2];
function heatset_pilot_dia(s)     = _heatset_row(s)[3];
function heatset_boss_od(s)       = _heatset_row(s)[4];
function heatset_lead_in(s)       = _heatset_row(s)[5];

/* [Placeholder] — insert envelope: top (install) face at Z=0, body grows -Z.
   Knurl approximated as a plain cylinder at nominal OD. For fit/viz only. */
module heatset_placeholder(size) {
    translate([0, 0, -heatset_insert_length(size)])
        cylinder(h = heatset_insert_length(size), d = heatset_insert_od(size), $fn = 48);
}

/* [Pocket] — negative cutter for a consumer difference(): pilot bore
   (melt-grip, < insert_od) from Z=0 down to -insert_length, a top lead-in
   chamfer at the +Z mouth (widens toward +Z), and an optional melt-relief
   cavity below the seat for displaced plastic. Z=0 = install face; all
   cutting geometry extends -Z from there. */
module heatset_pocket(size, melt_relief = true) {
    li  = heatset_lead_in(size);
    len = heatset_insert_length(size);
    pd  = heatset_pilot_dia(size);
    union() {
        // pilot bore, Z=0 down to -len
        translate([0, 0, -len]) cylinder(h = len + 0.01, d = pd, $fn = 48);
        // top lead-in chamfer (mouth wider than pd by 2*li)
        translate([0, 0, -li]) cylinder(h = li + 0.01, d1 = pd, d2 = pd + 2 * li, $fn = 48);
        // melt-relief cavity below the seat for displaced plastic
        if (melt_relief)
            translate([0, 0, -len - li]) cylinder(h = li + 0.01, d = pd, $fn = 48);
    }
}
