// drives — storage-drive mechanical reference (envelope, mount holes, connector
// positions) for 3.5"/2.5"/U.2 block drives and M.2 (2230/2242/2260/2280) cards.
// Datum: bottom-face minimum corner at the origin. +X = drive LENGTH (long axis),
// +Y = drive WIDTH, +Z = up (thickness); bottom face on Z=0.
// Two geometry-class sub-tables behind function accessors; three roles dispatch on
// drive_family(type):
//   1. Data        — functions returning constants / coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — drive_placeholder(type): envelope solid for fit checks
//   3. Holes/cutout— drive_holes(type,faces), drive_connector_cutout(type,...),
//                    drive_faceplate_cutout(type,face): mount-hole + connector stamps
//                    for a consumer difference()
// Provenance (see docs/LIBRARY-AUTHORING.md, full log in RESEARCH.md):
//   [A] governing SFF/JEDEC spec or vendor mechanical drawing fetched + read this pass.
//   [B] corroborated across >=2 independent peers.
//   [C] single-sourced / derived, OR a named standard cited but not fetched
//       this pass (marked //VERIFY (cited-not-fetched)).
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
// Units: millimeters.

$fn = 48;

/* [Data] — block drives. Coordinates per the header datum: X=0 at the
   connector end, Y=0 at the near/small-inset edge, Z=0 at the bottom face.
   See RESEARCH.md "Task 2 resolutions" for the full derivation of every
   value below. */

// 3.5" bottom mount holes, SFF-8301 Rev 1.9 Table 3-1 + Figure 3-1 — [A].
// Required row (A7=41.28) plus both mutually-optional rear rows (A6-derived
// =85.73, A13-direct=76.20) — a vendor picks one, the other, or both; all
// three rows are shipped so a consumer's cutout is compatible with any of
// them. Y columns: near=3.18 (A5), far=95.25 (A4).
function BOTTOM_35() = [
    [41.28,  3.18], [41.28, 95.25], // required row (A7)
    [85.73,  3.18], [85.73, 95.25], // optional row (A7+A6)
    [76.20,  3.18], [76.20, 95.25], // optional row (A13, direct)
]; // [A]

// 3.5" side mount holes: X positions 28.50 (A8, near) / 130.10 (A8+A9, far),
// both [A]. Z-height: re-read this pass, correcting Task 1/2's prior "gap" —
// SFF-8301 Fig 3-1's A10=6.35 is actually a HORIZONTAL (Z-axis) dimension in
// the side-view strip, not a further X-offset as previously transcribed;
// independently corroborated by Seagate's own BarraCuda manual Figure 3
// (vendor mechanical drawing citing SFF-8301/SFF-8323 conformance), which
// draws the identical .250in=6.35mm dimension in the same geometric role —
// tier [B] (2 independent peers) for the number+role. Which FACE it's
// measured from (top vs bottom) is not textually labeled in either source;
// resolved by inference from WD's side-mount-hole rendering (a 3rd source),
// which shows the PCB as a distinct slab on one side of the casting in the
// side view — PCBs mount to the bottom face on 3.5" HDDs, so the edge the
// PCB hugs is the bottom face, and that's the edge SFF/Seagate's own Z-datum
// tag sits on in both drawings. Z=6.35 from Z=0 (our bottom-face datum)
// follows directly. Face-orientation semantic //VERIFY; number+role [B].
function SIDE_35() = [
    [28.50, 6.35], [130.10, 6.35],
]; // X [A], Z [B] value/role + //VERIFY face-orientation — see RESEARCH.md Task 2 resolutions (c)

// 3.5"/2.5" SATA connector position + extent — SFF-8223 Rev 2.7 Table 3-1
// (2.5") and SFF-8323 Rev 1.6 Table 3-1 (3.5", bit-identical A2/A3/A5/A7/
// A13/A14 values, confirming these are connector-intrinsic, not
// drive-family-dependent). Position [x,y,z]: x=A7=3.50 (X-offset from the
// connector-end edge, corroborated by both specs' "nominally flush" text)
// [A], y=A13=13.43 (Y-inset from the near edge) [A], z=0 assumed (connector
// flush to bottom face) //VERIFY. Extent [w,d,h]: w=A5=4.00 (X-extent, this
// pass's own reading of the figure's dimension placement, not an explicitly
// labeled value) //VERIFY, d=A3=33.39 (Y-extent / connector body width,
// cross-checked against SFF-TA-8639's own 33.43 — 0.04mm apart, same part)
// [A], h=4.90 reused from SFF-TA-8639 Figure 5-1's directly-read pin/blade
// row height //VERIFY (applied to the plain-SATA connector too).
function C35_POS() = [3.50, 13.43, 0];    // x=[A], y=[A], z=VERIFY
function C35_EXT() = [4.00, 33.39, 4.90]; // w=VERIFY, d=[A], h=VERIFY

// 2.5" bottom mount holes — SFF-8201 Rev 3.4 Table 3-1 + Figure 3-1. Y
// columns confirmed [A] (A28=4.07 near, A28+A29=65.79 far). X reused from
// the side-hole X positions (A50/A52=14.00, A51/A53=90.60) by visual
// row-alignment in Figure 3-1 — Task 1's own inference, not independently
// re-dimensioned for the bottom holes in Table 3-1 — //VERIFY.
function BOTTOM_25() = [
    [14.00,  4.07], [14.00, 65.79], [90.60,  4.07], [90.60, 65.79],
]; // X //VERIFY, Y [A]

// 2.5" side mount holes, 9.5mm/15mm height classes — SFF-8201 Table 3-1 +
// Figure 3-1. X: 14.00 (A50/A52 near), 90.60 (A51/A53 far) — [A]. Z: 3.00
// (A23) — number is [A], but its semantic reading as "hole Z-height above
// the bottom face" is this pass's figure-layout inference, not an
// explicitly-labeled callout in the spec prose — //VERIFY.
function SIDE_25() = [ [14.00, 3.00], [90.60, 3.00] ]; // X [A], Z //VERIFY

// 2.5" side mount holes, 7mm height class. RESEARCH.md's own note ("4
// corner [bottom] holes... optional when A1 <= 7mm") only speaks to
// BOTTOM-hole optionality at the thinnest height class; it does not state
// the side-hole positions differ for 7mm drives, and no other height-keyed
// side-hole data was found in SFF-8201. Rather than fabricate an asymmetry
// the source doesn't support, this reuses the same SIDE_25 values — kept as
// a separately named function (per the brief's skeleton) in case a future
// pass finds a genuine 7mm-specific difference. //VERIFY (no-difference
// assumption, not a confirmed spec statement).
function SIDE_25_7() = SIDE_25(); // //VERIFY (see comment above)

// U.2 (SFF-TA-8639) connector — same PCB position as the SATA connector it
// replaces (SFF-8639's own abstract states it is a mechanical/pin-compatible
// superset of the SFF-8223 SATA/SAS connector location), SFF-8639's own
// slightly different width/height figures from Figure 5-1 — [A].
function U2_POS() = [3.50, 13.43, 0];    // reused from C35_POS, //VERIFY
function U2_EXT() = [4.00, 33.43, 4.90]; // 33.43 [A] (SFF-8639 Fig 5-1), rest //VERIFY

/* [Data] — card drives (M.2). Row: [type, [w,len,h], [hole x,y],
   [edge [x,y,z], [w,d,h], key]]. See RESEARCH.md Task 2 resolutions (d)/(e). */

// M.2 mounting-hole position, per length. 2280: Viking NVMe/SATA datasheets
// (Rev C / Rev A1), directly read — [A]. X = length - 1.45 (inset from the
// far/free end), Y = 11.00 (= width/2, centered). 2260/2242/2230 extrapolate
// the same 1.45mm inset unchanged — NOT independently confirmed for the
// shorter modules (RESEARCH.md Task 1 gap, carried through) — //VERIFY.
// Not exercised by the Task 2 test (only m2_2280's hole shape is asserted).
function M2_HOLE_2280() = [80.0 - 1.45, 11.00]; // [A]
function M2_HOLE_2260() = [60.0 - 1.45, 11.00]; // //VERIFY (extrapolated)
function M2_HOLE_2242() = [42.0 - 1.45, 11.00]; // //VERIFY (extrapolated)
function M2_HOLE_2230() = [30.0 - 1.45, 11.00]; // //VERIFY (extrapolated)

// M.2 card-edge (gold-finger) connector footprint. x=0 at the card's
// connector end (by convention; corroborated by the mount hole sitting near
// the *far* end at X=78.55 on an 80mm card) [C]. y=1.075, d=19.85: contact
// width 19.85mm centered on the 22.00mm card width, inset (22.00-19.85)/2
// each side — [A] (RESEARCH.md sec 5). h=0.80 reuses the confirmed PCB
// thickness (gold fingers are the PCB's own edge plating) — [A] value,
// //VERIFY on reusing it as the edge connector's own height. w=5.0 is a
// placeholder — the engagement depth along the insertion axis was NOT in
// either fetched Viking datasheet — //VERIFY (unsourced estimate), flagged
// rather than presented as confirmed. key="m" — [A], NVMe datasheet pin
// table ("Module Key M", pins 59-66).
function M2_EDGE() = [ [0, 1.075, 0], [5.0, 19.85, 0.80], "m" ];

function _block_table() = [
    ["hdd35",    [147.0, 101.6, 26.1], BOTTOM_35(), SIDE_35(),   ["sata",    C35_POS(), C35_EXT()]],
    // 100.0 (below, all four rows) is test-mandated, not a direct SFF-8201
    // transcription (spec gives 100.20 nominal / 100.45 new-Max / 101.85
    // obsolete-Max) — see RESEARCH.md "Task 2 resolutions" (a). [C]
    ["ssd25_7",  [100.0, 69.85,  7.0], BOTTOM_25(), SIDE_25_7(), ["sata",    C35_POS(), C35_EXT()]],
    ["ssd25_9",  [100.0, 69.85,  9.5], BOTTOM_25(), SIDE_25(),   ["sata",    C35_POS(), C35_EXT()]],
    ["ssd25_15", [100.0, 69.85, 15.0], BOTTOM_25(), SIDE_25(),   ["sata",    C35_POS(), C35_EXT()]],
    ["u2",       [100.0, 69.85, 15.0], BOTTOM_25(), SIDE_25(),   ["sff8639", U2_POS(),  U2_EXT()]],
];
/* [Data] — card drives (M.2). Row:
   [type, [w,len,h], [hole x,y], [edge [x,y,z], [w,d,h], key]]. Values per RESEARCH.md. */
function _card_table() = [
    ["m2_2230", [22.0, 30.0, 2.3], M2_HOLE_2230(), M2_EDGE()],
    ["m2_2242", [22.0, 42.0, 2.3], M2_HOLE_2242(), M2_EDGE()],
    ["m2_2260", [22.0, 60.0, 2.3], M2_HOLE_2260(), M2_EDGE()],
    ["m2_2280", [22.0, 80.0, 2.3], M2_HOLE_2280(), M2_EDGE()],
];

function _blk_row(type) =
    let (m = [for (e = _block_table()) if (e[0]==type) e])
    len(m)>0 ? m[0] : assert(false, str("drives: '", type, "' is not a block drive"));
function _card_row(type) =
    let (m = [for (e = _card_table()) if (e[0]==type) e])
    len(m)>0 ? m[0] : assert(false, str("drives: '", type, "' is not a card drive"));
function _is_block(type) = len([for (e=_block_table()) if (e[0]==type) 1]) > 0;
function _is_card(type)  = len([for (e=_card_table())  if (e[0]==type) 1]) > 0;

function drive_family(type) =
    _is_block(type) ? "block" :
    _is_card(type)  ? "card"  :
    assert(false, str("drives: unknown type '", type, "'"));

function drive_size(type)          = _blk_row(type)[1];
function drive_bottom_holes(type)  = _blk_row(type)[2];
function drive_side_holes(type)    = _blk_row(type)[3];
function drive_connector(type)     = _blk_row(type)[4];
function drive_card_size(type)     = _card_row(type)[1];
function drive_card_hole(type)     = _card_row(type)[2];
function drive_card_edge(type)     = _card_row(type)[3];

function drive_known_types() =
    concat([for (e = _block_table()) e[0]], [for (e = _card_table()) e[0]]);

/* [Placeholder] */
// Envelope solid in the datum frame (bottom face Z=0, min corner at origin,
// growing +X length, +Y width, +Z height). For fit checks in a consumer assembly.
module drive_placeholder(type) {
    if (drive_family(type) == "block")
        cube(drive_size(type));
    else { // card: [w,len,h] -> box along +X=len, +Y=width
        s = drive_card_size(type);   // [w, len, h]
        cube([s[1], s[0], s[2]]);    // X=len, Y=width, Z=height
    }
}

/* [Holes] */
// Mount-hole cutters for a consumer difference(). Each cutter is a cylinder on the
// hole axis, oversized in length so it fully pierces the wall it cuts.
//   faces: "bottom" | "side" | "both" (block); card family always cuts its single
//          standoff hole along -Z.
//   dia:   hole clearance diameter (default 3.4 = M3 clearance; 3.5 ~ 6-32).
//   depth: cutter length through the wall (default 40, a generous through-cut).
module drive_holes(type, faces = "bottom", dia = 3.4, depth = 40) {
    assert(faces=="bottom" || faces=="side" || faces=="both",
           str("drives: unknown faces '", faces, "'"));
    r = dia/2;
    if (drive_family(type) == "card") {
        h = drive_card_hole(type);            // [x,y] on the Z=0 face (x along len)
        translate([h[0], h[1], 0])
            cylinder(h = depth, r = r, center = true); // pierces Z=0 floor
    } else {
        s = drive_size(type);
        if (faces=="bottom" || faces=="both")
            for (p = drive_bottom_holes(type)) // [x,y] on Z=0
                translate([p[0], p[1], 0])
                    cylinder(h = depth, r = r, center = true);
        if (faces=="side" || faces=="both")
            for (p = drive_side_holes(type))   // [x,z]; one set per +/-Y wall
                for (y = [0, s[1]])
                    translate([p[0], y, p[1]])
                        rotate([90,0,0])       // axis along Y
                            cylinder(h = depth, r = r, center = true);
    }
}

// Connector opening for a consumer difference(): the connector body box grown by
// `clearance` per side. `depth` (default 0 -> 20) extends the cut outward past the
// drive's connector-end edge so a caddy/bezel wall is fully pierced.
//
// Axis/direction: RESEARCH.md's own datum convention (see "Datum convention used
// below") fixes X=0 at the CONNECTOR end for the block family, +X toward the free
// end -- and C35_POS()/U2_POS() place the SATA/SFF-8639 connector at x=A7=3.50mm,
// i.e. hard against that X=0 edge (RESEARCH.md "Task 2 resolutions (b)": "A7 =
// 3.50mm is the connector's X-offset from the connector-end edge", corroborated by
// SFF-8223/SFF-8323's "nominally flush" text). The card family's own comment on
// M2_EDGE() states the same thing independently: "x=0 at the card's connector end
// (by convention; corroborated by the mount hole sitting near the *far* end...)".
// So for BOTH families the connector/edge-contact sits at/near the LOW-X face, not
// a high-Y "back edge" as originally sketched -- the cut must grow in -X, past
// x=0, not +Y. (Checked against the live data too: drive_connector("ssd25_9")[1][0]
// = 3.50 and drive_card_edge("m2_2280")[0][0] = 0, both tiny relative to their
// ~70-150mm envelope length and ~0 relative to width -- confirms low-X, not high-Y.)
module drive_connector_cutout(type, clearance = 0.5, depth = 0) {
    dd = depth > 0 ? depth : 20;
    rec = (drive_family(type) == "card")
        ? drive_card_edge(type)            // [[x,y,z],[w,d,h],key]
        : let (c = drive_connector(type)) [c[1], c[2]];  // [[x,y,z],[w,d,h]]
    pos = rec[0]; ext = rec[1];
    translate([pos[0]-clearance-dd, pos[1]-clearance, pos[2]-clearance])
        cube([ext[0]+2*clearance+dd, ext[1]+2*clearance, ext[2]+2*clearance]);
}
