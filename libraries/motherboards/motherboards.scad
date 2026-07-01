// motherboards — PC motherboard mechanical mounting reference (mini-ITX / microATX / ATX).
// Datum: board REAR-LEFT corner at origin. +X = board WIDTH (along rear I/O edge),
// +Y = board DEPTH (rear -> front), PCB bottom on Z=0. Rear I/O edge at Y=0.
// Roles: this is a Role-1 DATA library (functions only; `use` does not import variables).
// Provenance: [A] Intel/formfactors spec drawing, [B] multi-peer, [C] reverse-engineered.
// Standoff coords reconstructed from the ATX 2.01 / microATX 1.2 dimensioned drawings
// (chained relative dims walked from a board edge); see RESEARCH.md for the closure proof.
// Units: millimeters.

$fn = 48;

/* [Data] */
function mobo_known_ff() = ["itx", "matx", "atx"];

// Board outline [width_X, depth_Y] mm.  [A] Intel ATX 2.01 Fig3 / microATX 1.2 Table 3.
// (itx 170 [B] Protocase Fig8 + Wikipedia; 243.84 = exact 9.6", 304.80 = exact 12.0".)
function mobo_size(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[1];

function mobo_thickness() = 1.57; // mm, 0.062" nominal PCB.  [A]

// Standoff clearance hole diameter. Spec "Ø.156" = 3.96mm, accepts #6-32 standoff.
// [B] microATX 1.2 Fig3 + Protocase ("accept a 6-32 thread").  //VERIFY #6-32 vs M3 standoff.
function mobo_hole_dia() = 3.96;

function mobo_pcie_pitch() = 20.32; // mm slot-to-slot (.800" TYP).  [A] ATX 2.01 §3.3.1 + Fig3.

// Rows: [ff, [width,depth], [[x,y],...standoff coords], [io_x,io_w,io_h],
//        [pcie_x,pcie_y], pcie_count]
// Standoff coords are absolute [x,y] in the corner frame above, reconstructed + closure-checked
// (RESEARCH.md). Shared holes across ff use IDENTICAL coords (microATX C,H,L,J,M == ATX; verified
// to 0.00mm). //VERIFY tags mark values whose exact letter/row did not close against the drawing.
function _mobo_table() = [
    // ---- mini-ITX 170x170 : 4-hole subset [C] (ITX addendum drawing unreachable;
    //      Protocase Fig8 corner-referenced + Wikipedia). //VERIFY front-row Y (P3/P4).
    ["itx",  [170, 170],
        [ [6.17, 4.90],      // rear-left    [C] x=170-163.83, y=170-165.10 (Protocase Fig8)
          [163.65, 4.90],    // rear-right   [C] x=170-6.35
          [6.17, 124.28],    // mid/front-left  //VERIFY [C] front-row Y (=170-45.72)
          [163.65, 124.28] ],// mid/front-right //VERIFY [C]
        [11.25, 158.75, 44.45],  // io [x_off,w,h]  //VERIFY [C] x_off (window right-justified)
        [155.83, 4.90],          // pcie first [x,y]  //VERIFY [C] ~14.17mm from right edge
        1],
    // ---- microATX 243.84x243.84 : B,C,F,H,J,L,M,R,S  (C,H,L,J,M == ATX [A]; B/R/S [C])
    ["matx", [243.84, 243.84],
        [ [16.51, 6.35],     // C   [A] == ATX C
          [16.51, 78.74],    // H   [A] == ATX H
          [16.51, 227.33],   // L   [A] == ATX L
          [140.97, 78.74],   // J   [A] == ATX J
          [140.97, 227.33],  // M   [A] == ATX M
          [237.49, 29.21],   // F   //VERIFY [C] right col = 243.84-6.35, rear+0.900
          [95.25, 6.35],     // B   //VERIFY [C] datum B, rear row, col 3.750"
          [237.49, 78.74],   // R   //VERIFY [C] new mATX right-mid
          [140.97, 6.35] ],  // S   //VERIFY [C] new mATX rear support
        [85.09, 158.75, 44.45],  // io  [A] window 6.250"[158.75] x 44.45; //VERIFY [C] x_off
        [129.67, 227.33],        // pcie first [x,y]  //VERIFY [C]
        4],
    // ---- ATX 304.80x243.84 : A,C,F,G,H,J,K,L,M  (full lettered grid [A])
    ["atx",  [304.80, 243.84],
        [ [16.51, 6.35],     // C   [A] L-col, rear row
          [140.97, 6.35],    // G   [A] m2-col, rear row
          [16.51, 78.74],    // H   [A] L-col, mid row
          [140.97, 78.74],   // J   [A] m2-col, mid row
          [298.45, 78.74],   // A   [A] R-col, mid row (A is elongated in spec)
          [16.51, 227.33],   // L   [A] L-col, front row
          [140.97, 227.33],  // M   [A] m2-col, front row
          [298.45, 227.33],  // K   [A] R-col, front row
          [298.45, 29.21] ], // F   X-col [A]-closed (R=298.45); Y row-inset //VERIFY [C]/unclosed
                             //     (0.900" rear+inset asserted, not proven by chain; mirrors matx F)
        [146.05, 158.75, 44.45], // io  [A] window 6.250"[158.75] x 44.45; //VERIFY [C] x_off
        [190.5, 227.33],         // pcie first [x,y]  //VERIFY [C]
        7],
];

function _mobo_row(ff) =
    let (rows = [for (r = _mobo_table()) if (r[0] == ff) r])
    len(rows) > 0 ? rows[0] : undef;
function _mobo_unknown(ff) = str("motherboards: unknown ff ", ff, "; known: ", mobo_known_ff());

function mobo_standoff_xy(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[2];
function mobo_io_cutout(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[3];
function mobo_pcie_first_xy(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[4]; // //VERIFY [C] varies by board
function mobo_pcie_count(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[5];

/* [Placeholder] */
// PCB envelope solid with standoff holes as keep-outs (fit checks).
// Corner datum: board in +X/+Y, bottom on Z=0.
module mobo_placeholder(ff) {
    sz = mobo_size(ff);
    t = mobo_thickness();
    difference() {
        cube([sz[0], sz[1], t]);
        for (p = mobo_standoff_xy(ff))
            translate([p[0], p[1], -1]) cylinder(h = t + 2, d = mobo_hole_dia());
    }
}

/* [Hole-stamp / cutout] */
// Standoff clearance holes; use inside a consumer difference().
module mobo_standoff_holes(ff, depth = 20, dia = -1) {
    d = dia < 0 ? mobo_hole_dia() : dia;
    for (p = mobo_standoff_xy(ff))
        translate([p[0], p[1], -1]) cylinder(h = depth + 2, d = d);
}

// Positive standoff posts (print a tray directly). Pilot bore subtracted.
module mobo_standoffs(ff, height, dia = -1, bore = -1) {
    od = dia  < 0 ? 6.0 : dia;   // post OD default //VERIFY vs hardware standoff
    bd = bore < 0 ? 2.5 : bore;  // pilot for self-tapping screw //VERIFY
    for (p = mobo_standoff_xy(ff))
        translate([p[0], p[1], 0]) difference() {
            cylinder(h = height, d = od);
            translate([0, 0, -1]) cylinder(h = height + 2, d = bd);
        }
}

// Rear I/O window as a subtraction solid at the Y=0 edge.
module mobo_io_cutout_stamp(ff, depth = 20) {
    io = mobo_io_cutout(ff); // [x_off, width, height]
    translate([io[0], -1, 0]) cube([io[1], depth + 2, io[2]]);
}

// PCIe slot openings along the rear edge, stepped by pitch.
module mobo_pcie_cutout(ff, slots, depth = 20) {
    o = mobo_pcie_first_xy(ff);
    for (i = [0 : slots - 1])
        translate([o[0] + i * mobo_pcie_pitch(), o[1], -1])
            cube([12, depth + 2, 12], center = false); // slot opening footprint //VERIFY
}

// Visual self-check when opened directly.
mobo_placeholder("atx");
