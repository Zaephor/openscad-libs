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

/* [Data] — tables filled in Task 2 from RESEARCH.md. */
function _block_table() = []; // [type,[w,d,h],[bottom holes],[side holes],[conn]]
function _card_table()  = []; // [type,[w,len,h],[hole x,y],[edge [xyz],[wdh],key]]

function drive_known_types() =
    concat([for (e = _block_table()) e[0]], [for (e = _card_table()) e[0]]);
