// motherboards — PC motherboard mechanical mounting reference (mini-ITX / microATX / ATX).
// Datum: board REAR-LEFT corner at origin. +X = board WIDTH (along rear I/O edge),
// +Y = board DEPTH (rear -> front), PCB bottom on Z=0. Rear I/O edge at Y=0.
// Roles: this is a Role-1 DATA library (functions only; `use` does not import variables).
// Provenance: [A] Intel/formfactors spec drawing, [B] multi-peer, [C] reverse-engineered.
// Standoff coords reconstructed from the ATX 2.01 / microATX 1.2 dimensioned drawings
// (chained relative dims walked from a board edge); see RESEARCH.md for the closure proof.
// Units: millimeters.
//
// MIRROR / HANDEDNESS: the spec drawings are MIRROR-HANDED relative to this library's
// component-side-up frame. On a real board held component-face-up with the rear I/O
// edge away from you, the I/O cluster sits at the LOW-X (origin-corner) end of the rear
// edge and the PCIe/expansion slots fill toward +X (to its right) -- confirmed against
// physical hardware. The _mobo_table() below stores coords AS CHAINED FROM THE DRAWING
// (drawing frame; every [A] chain comment there describes that frame and still closes).
// The public accessors apply a single documented X-flip (x -> width - x) so callers
// receive component-up-frame coords. See RESEARCH.md "Mirror".

use <connectors/connectors.scad>;

$fn = 48;

/* [Data] */
function mobo_known_ff() = ["itx", "matx", "atx"];

// Board outline [width_X, depth_Y] mm.  [A] Intel ATX 2.01 Fig3 / microATX 1.2 Table 3 /
// Mini-ITX Addendum 1.1 Fig3 (170x170; 243.84 = exact 9.6", 304.80 = exact 12.0").
function mobo_size(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[1];

function mobo_thickness() = 1.57; // mm, 0.062" nominal PCB.  [A]

// Standoff clearance hole diameter. Spec "Ø.156" = 3.96mm, accepts #6-32 standoff.
// [B] microATX 1.2 Fig3 + Protocase ("accept a 6-32 thread").  //VERIFY #6-32 vs M3 standoff.
function mobo_hole_dia() = 3.96;

function mobo_pcie_pitch() = 20.32; // mm slot-to-slot (.800" TYP).  [A] ATX 2.01 §3.3.1 + Fig3.

// PCIe slot-opening footprint width (the flat 12mm cube model, see mobo_pcie_cutout).
// //VERIFY [C] ~nominal, unsourced. Used by the component-up X-flip (mobo_pcie_first_xy)
// so the mirrored first-slot edge lines up with the drawing-frame last-slot far edge.
function mobo_pcie_slot_w() = 12;

// Rows: [ff, [width,depth], [[x,y],...standoff coords], [io_x,io_w,io_h],
//        [pcie_x,pcie_y], pcie_count]
// Standoff coords are absolute [x,y] in the corner frame above, reconstructed + closure-checked
// (RESEARCH.md). Shared holes across ff use IDENTICAL coords (microATX C,H,L,J,M == ATX; verified
// to 0.00mm). //VERIFY tags mark values whose exact letter/row did not close against the drawing.
function _mobo_table() = [
    // ---- mini-ITX 170x170 : holes C,F,H,J -- Mini-ITX Addendum 1.1 (Table 3 letters)
    //      + chassis reconciliation to the measured ATX/mATX rows (see RESEARCH.md Task 10).
    //      Cols: C=.250in[6.35] from left; F/J = C+6.200in = 163.83 (both share ATX col3/col4
    //      at a right-corner offset). Rows shared with ATX/mATX (measured): row1=10.16,
    //      row2=165.10 (= row1 + 6.100in -- the 6.100in is row1-referenced, NOT edge:
    //      the chain-reference error corrected in Task 10). F off-row = row1 + .900in = 33.02.
    ["itx",  [170, 170],
        [ [6.35, 10.16, "structural-mount", mobo_hole_dia()],     // C  [A] rear-left mounting hole (.250in from left, .400in from rear)
          [163.83, 33.02, "structural-mount", mobo_hole_dia()],   // F  [A] C + 6.200in col; off-row Y = row1 + .900in = 33.02
          [6.35, 165.10, "structural-mount", mobo_hole_dia()],    // H  [A] C's column, row2 (row1 + 6.100in)
          [163.83, 165.10, "structural-mount", mobo_hole_dia()] ],// J  [A] F's column, row2
        // io: near edge = C + .300in[7.52] = 13.87 [A]; width 158.75 [A] (6.250in shield);
        // 156.31mm from the right edge, aligning with ATX/mATX io in-chassis. height 44.45 [B].
        [13.87, 158.75, 44.45],  // io [x_off,w,h]  [A] x_off/w; h [B]
        // pcie: single slot, chassis-co-located with the ATX/mATX I/O-nearest slot (measured).
        // Modelled flush below the io: first_x = io_near - slot_w = 13.87 - 12 = 1.87. On this
        // 170mm board the slot and mounting hole C both compete for the low-X strip (see the
        // itx disjoint note in the test). //VERIFY [C] -- undimensioned in the Addendum.
        [1.87, 0],               // pcie first [x,y]  //VERIFY [C] io-nearest slot, flush below io; y=0 rear edge
        1],                      // count  [A] mini-ITX standard: exactly one expansion slot
    // ---- microATX 243.84x243.84 : B,C,F,H,J,L,M,R,S -- positions from DIRECT pixel
    //      measurement of microATX 1.2 Fig3 (to-scale, calibrated), reconciled to the
    //      shared chassis rows/cols (RESEARCH.md Task 10). Datum B (hole B) = 1.350in[34.29]
    //      from left. Cols C/H/L = 80.01, F/J/M = 237.49 (rightmost 0.250in from right edge).
    //      Rows 10.16 / 165.10 / 237.49 (row2/row3 are row1 + 6.100/8.950in -- row1-referenced,
    //      correcting the earlier edge-referenced grid). F off-row = row1 + .900in = 33.02.
    //      Shares ATX cols 2/3/4 at a right-corner +60.96mm offset (34.29->95.25, 80.01->140.97,
    //      237.49->298.45 = ATX cols); holes+io+slots all co-locate with ATX in-chassis.
    ["matx", [243.84, 243.84],
        [ [80.01, 10.16, "structural-mount", mobo_hole_dia()],    // C   [A] C/H/L col, rear row
          [80.01, 165.10, "structural-mount", mobo_hole_dia()],   // H   [A] row2
          [80.01, 237.49, "structural-mount", mobo_hole_dia()],   // L   [A] row3
          [237.49, 165.10, "structural-mount", mobo_hole_dia()],  // J   [A] F/J/M col, row2
          [237.49, 237.49, "structural-mount", mobo_hole_dia()],  // M   [A] row3
          [237.49, 33.02, "structural-mount", mobo_hole_dia()],   // F   [A] F/J/M col; off-row Y = row1 + .900in = 33.02
          [34.29, 10.16, "structural-mount", mobo_hole_dia()],    // B   [A] Datum B, 1.350in from left, rear row
          [13.97, 165.10, "structural-mount", mobo_hole_dia()],   // A2  [A] microATX-only left column (0.550in from left), row2
          [34.29, 165.10, "structural-mount", mobo_hole_dia()] ], // B2  [A] Datum-B column, row2
        // io: near edge = 87.53 [A] (measured; 156.31mm from right edge -> aligns with ATX io
        // in-chassis). width 158.75 [A] (6.250in shield), far edge overhangs right edge 2.44mm.
        // height 44.45 [B] (standard I/O panel).
        [87.53, 158.75, 44.45], // io  [A] near-edge measured; 156.31 from right edge
        // pcie: uniform 20.32 pitch [A]; I/O-nearest slot anchored to the measured position
        // (io_near - slot_w). count=4 (microATX "4 max"); first_x = io_near - slot_w -
        // 3*pitch = 87.53 - 12 - 60.96 = 14.57. io-side slots reproduce the measured
        // centerlines (40.9/61.3/81.5); outermost differs from the real irregular ISA gap
        // (uniform-model limit). //VERIFY [C] on the model; io-nearest anchor is measured.
        [14.57, 0],              // pcie first [x,y]  [C] uniform-pitch model, io-nearest anchored; y=0 rear
        4],                      // count  [A] microATX standard 4 expansion positions
    // ---- ATX 304.80x243.84 : 10 mounting holes -- positions from DIRECT pixel measurement
    //      of ATX 2.2 Fig3 (to-scale, calibrated), reconciled to the shared chassis grid
    //      (RESEARCH.md Task 10; the figure labels "10X MTG HOLES"). 4 columns X = 16.51 /
    //      95.25 / 140.97 / 298.45 (rightmost 0.250in from the right edge). Rows 10.16 /
    //      165.10 / 237.49 (row2/row3 = row1 + 6.100/8.950in, row1-referenced -- corrects the
    //      earlier edge-referenced grid that put them at 154.94/227.33). F off-row (right
    //      column, rear) = row1 + .900in = 33.02. Cols 3/4 (140.97, 298.45) are the standoffs
    //      microATX + mini-ITX share (right-corner aligned); io + slots co-locate in-chassis.
    ["atx",  [304.80, 243.84],
        [ [16.51, 10.16, "structural-mount", mobo_hole_dia()],    // col1 rear
          [16.51, 165.10, "structural-mount", mobo_hole_dia()],   // col1 row2
          [16.51, 237.49, "structural-mount", mobo_hole_dia()],   // col1 row3
          [95.25, 10.16, "structural-mount", mobo_hole_dia()],    // col2 (rear only)
          [140.97, 10.16, "structural-mount", mobo_hole_dia()],   // col3 rear  (shared standoff)
          [140.97, 165.10, "structural-mount", mobo_hole_dia()],  // col3 row2  (shared standoff)
          [140.97, 237.49, "structural-mount", mobo_hole_dia()],  // col3 row3
          [298.45, 33.02, "structural-mount", mobo_hole_dia()],   // col4 (rightmost) off-row rear = row1 + .900in
          [298.45, 165.10, "structural-mount", mobo_hole_dia()],  // col4 row2  (shared standoff)
          [298.45, 237.49, "structural-mount", mobo_hole_dia()] ],// col4 row3
        // io: near edge = 148.49 [A] (measured; 156.31mm from the right edge). width 158.75
        // [A] (6.250in shield), far edge overhangs the right edge by 2.44mm. height 44.45 [B].
        [148.49, 158.75, 44.45], // io  [A] near-edge measured; 156.31 from right edge
        // pcie: uniform 20.32 pitch [A]; I/O-nearest slot anchored to the measured position
        // (io_near - slot_w = 136.49, centerline 142.49 ~ measured AGP 143.4). count=7 (ATX
        // standard bracket positions); first_x = io_near - slot_w - 6*pitch = 14.57. io-side
        // slots reproduce the measured centerlines; the outermost differs from the real
        // irregular ISA gap (uniform-model limit). //VERIFY [C] model; io-nearest is measured.
        [14.57, 0],               // pcie first [x,y]  [C] uniform-pitch model, io-nearest anchored; y=0 rear
        7],                       // count  [A] ATX standard 7 expansion positions
];

function _mobo_row(ff) =
    let (rows = [for (r = _mobo_table()) if (r[0] == ff) r])
    len(rows) > 0 ? rows[0] : undef;
function _mobo_unknown(ff) = str("motherboards: unknown ff ", ff, "; known: ", mobo_known_ff());

// --- hole roles (Task 2 of the hole-role-tagging plan; mirrors sbc.scad) ---
function mobo_known_hole_roles() = ["structural-mount", "component-mount", "keep-out", "alignment"];

// All three geometry accessors apply the drawing->component-up X-flip (x -> W - x);
// see the MIRROR note at the top of this file. W = board width for the ff.

// Standoff coords, component-up frame: [x, y, role, dia]. Each drawing-frame
// [x,y,role,dia] -> [W-x, y, role, dia] (mirror flip preserves role/dia).
// role == undef (omitted) -> every hole, PLUS a WARNING when >1 role present.
// role == a canonical role string -> only that role.
function mobo_standoff_xy(ff, role = undef) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff))
    let (w = r[1][0],
         all = [ for (p = r[2]) [w - p[0], p[1], p[2], p[3]] ],
         present = [for (rr = mobo_known_hole_roles()) if (len([for (h = all) if (h[2] == rr) h]) > 0) rr])
    is_undef(role)
        ? (len(present) > 1
            ? echo(str("WARNING: motherboards '", ff, "' standoffs span ", len(present), " roles; pass role= to filter")) all
            : all)
        : [for (h = all) if (h[2] == role) h];

// Rear I/O window [x_off,width,height], component-up frame. The drawing-frame near
// (low-X) edge x0 mirrors to the far edge, so the component-up x_off = W - (x0 + width).
// This lands the I/O cluster at the LOW-X end (may go slightly negative = shield overhang
// past the origin-corner edge; ATX ~2.44mm).
function mobo_io_cutout(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff))
    let (w = r[1][0], io = r[3]) [w - io[0] - io[1], io[1], io[2]];

// First (lowest-X) PCIe slot [x,y], component-up frame. Slots march +X from here by
// pitch; mirroring the drawing-frame span means the component-up first-slot near edge =
// W - (drawing_first_x + (n-1)*pitch + slot_w), which puts the cluster on the HIGH-X side
// opposite the I/O window. y (rear edge) is unaffected by the X-flip.
function mobo_pcie_first_xy(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff))
    let (w = r[1][0], o = r[4], n = r[5])
    [w - (o[0] + (n - 1) * mobo_pcie_pitch() + mobo_pcie_slot_w()), o[1]];
function mobo_pcie_count(ff) =
    let (r = _mobo_row(ff)) assert(!is_undef(r), _mobo_unknown(ff)) r[5];

/* [Placeholder] */
// Representative rear I/O-port cluster: one block filling the I/O-shield window
// opening (158.75 x 44.45 [A]) + a nominal inward depth, on the PCB top face at
// the LOW-X (origin-corner) end of the rear (Y=0) edge. Real port layout varies by
// board — this is a placement/keep-out envelope + a visual rear-edge marker, NOT
// per-port geometry. depth/protrude are representative //VERIFY (not board-sourced).
module mobo_io_ports(ff, depth = 25, protrude = 2) {
    io = mobo_io_cutout(ff); // [x_off, width, height]
    t = mobo_thickness();
    translate([io[0], -protrude, t]) cube([io[1], depth + protrude, io[2]]);
}

// PCIe x16 slot connectors: one connector body per slot at the HIGH-X end of the rear
// edge, stepped by mobo_pcie_pitch(). Body dimensions are SOURCED from the connectors
// library (connector_size("pcie_x16") = 89.00 x 7.50 x 11.25mm), which is now this
// value's single source of truth. Tier [A]: Molex SD-87715-207 "PCI Express Edge Card
// Connector" (Wayback-fetched+read; see connectors/RESEARCH.md and this file's own
// SP1 note below for the fetch record).
// The connector runs +Y into the board (a card inserts along it, bracket at the rear)
// and is SET BACK from the rear edge by `setback` -- the connector body does not touch
// the rear edge; the card's I/O bracket occupies that gap. setback = 42.6mm [B], derived
// from a real open-source microATX design (TheGuyDanish/CM4_MATX, KiCad): rear I/O edge
// at X=38.10, the Amphenol x16 slot body near-end at X=80.70 -> 80.70-38.10 = 42.60 (its
// 20.32mm slot pitch + 10.16mm rear hole inset confirm a spec-true layout). This places
// the body at y=[42.6,131.6], clearing every mounting hole (all at y<=33 or y>=165),
// matching how a real board routes standoffs clear of the slots. See RESEARCH.md Task 12.
module mobo_pcie_ports(ff, slots = -1,
                       length = connector_size("pcie_x16")[0],   // 89.00
                       height = connector_size("pcie_x16")[2],   // 11.25
                       width  = connector_size("pcie_x16")[1],   // 7.50
                       setback = 42.6) {
    n = slots < 0 ? mobo_pcie_count(ff) : slots;
    o = mobo_pcie_first_xy(ff);
    t = mobo_thickness();
    for (i = [0 : n - 1])
        translate([o[0] + i * mobo_pcie_pitch() + (mobo_pcie_slot_w() - width) / 2, o[1] + setback, t])
            cube([width, length, height]);
}

// PCB envelope solid with standoff holes as keep-outs, PLUS the raised rear I/O-port
// block (low-X, origin corner) and PCIe slot connectors (high-X) so the corrected
// side-by-side rear layout reads in a 3D view (matches how the sbc library draws
// connector bodies). Corner datum: board in +X/+Y, bottom on Z=0.
module mobo_placeholder(ff) {
    sz = mobo_size(ff);
    t = mobo_thickness();
    difference() {
        cube([sz[0], sz[1], t]);
        for (p = mobo_standoff_xy(ff))
            translate([p[0], p[1], -1]) cylinder(h = t + 2, d = mobo_hole_dia());
    }
    mobo_io_ports(ff);   // rear I/O-port cluster (low-X, representative envelope)
    mobo_pcie_ports(ff); // PCIe slot connectors (high-X, representative bars)
}

/* [Hole-stamp / cutout] */
// Standoff clearance holes; use inside a consumer difference().
module mobo_standoff_holes(ff, depth = 20, dia = -1, role = undef) {
    d = dia < 0 ? mobo_hole_dia() : dia;
    for (p = mobo_standoff_xy(ff, role))
        translate([p[0], p[1], -1]) cylinder(h = depth + 2, d = d);
}

// Positive standoff posts (print a tray directly). Pilot bore subtracted.
module mobo_standoffs(ff, height, dia = -1, bore = -1, role = undef) {
    od = dia  < 0 ? 6.0 : dia;   // post OD default //VERIFY vs hardware standoff
    bd = bore < 0 ? 2.5 : bore;  // pilot for self-tapping screw //VERIFY
    for (p = mobo_standoff_xy(ff, role))
        translate([p[0], p[1], 0]) difference() {
            cylinder(h = height, d = od);
            translate([0, 0, -1]) cylinder(h = height + 2, d = bd);
        }
}

// Rear I/O window as a subtraction solid at the Y=0 edge.
// x_off (returned by mobo_io_cutout, component-up frame) is the drawing-chained offset
// X-flipped to the LOW-X/origin-corner end (see the MIRROR note up top), NOT a uniform
// left-justify formula: the window's low-X edge sits near, but not always exactly at,
// the board's origin-corner edge (ATX overhangs it by 2.44mm -> x_off=-2.44; microATX
// falls 14.07mm short -> x_off=14.07; see the io comments in _mobo_table() for the
// per-ff drawing chain the flip is applied to).
module mobo_io_cutout_stamp(ff, depth = 20) {
    io = mobo_io_cutout(ff); // [x_off, width, height]
    translate([io[0], -1, 0]) cube([io[1], depth + 2, io[2]]);
}

// PCIe slot openings along the rear edge, stepped by pitch.
module mobo_pcie_cutout(ff, slots, depth = 20) {
    o = mobo_pcie_first_xy(ff);
    for (i = [0 : slots - 1])
        translate([o[0] + i * mobo_pcie_pitch(), o[1], -1])
            cube([mobo_pcie_slot_w(), depth + 2, 12], center = false); // slot opening footprint //VERIFY [C] ~nominal, unsourced
}

// Visual self-check when opened directly.
mobo_placeholder("atx");
