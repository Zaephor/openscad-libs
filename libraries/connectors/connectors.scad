// connectors — common connector body (housing/shell) envelope reference.
// Datum: millimeters. Mounting/panel face on Z=0; centered in X.
// Opening axis is per-type: `+Y` for panel connectors (USB/RJ45/HDMI —
// the mating opening faces out of the panel), `+Z` for slot/header
// connectors (PCIe card-edge slot, GPIO pin header — the mating opening
// faces up off the board).
// `[w, d, h]` = extents along `[X, Y, Z]` — the housing/shell body, not
// just the mating opening.
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — connector_body(type): envelope solid for fit checks
//   3. Hole-stamp  — connector_cutout(type, ...): panel/board cutout for a consumer difference()
// Provenance legend (see RESEARCH.md for the full evidence log this pass):
//   [A] fetched + read this pass (vendor datasheet or governing standard).
//   [B] corroborated across >=2 independent peers.
//   [C] single-sourced / derived, OR a named standard cited but not fetched
//       this pass (marked //VERIFY (cited-not-fetched)).
//   //VERIFY marks a weak/single-sourced value pending stronger corroboration.
//
// Task 1 status (this commit): scaffold + RESEARCH.md source log only.
// The type table (`_connector_table()`), accessor functions
// (`connector_known_types()`, `connector_size()`, `connector_opening()`) and
// the `connector_body()` / `connector_cutout()` modules are Task 2+ (see
//  for the exact API
// and  for the
// design rationale). Nothing below this header is implemented yet.

$fn = 48;
