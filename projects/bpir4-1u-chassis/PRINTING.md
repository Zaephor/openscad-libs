# Printing — bpir4-1u-chassis

- Printer/material: Bambu P1S, PETG.
- Orientation: tray floor-down (254 mm front face on the bed); lid flat.
- Supports: none needed for the tray — fan bores/vents stay vertical, the
  faceplate's above-IO intake vents are a self-supporting honeycomb hex
  pattern (flat-top hex cells whose only bridge, the hex top edge, is a few
  mm — well under the reliably-self-supporting bridging ceiling), and the 4
  corner lid posts are full-height square columns bonded to **both** walls
  of their corner (fillet on the two internal post-wall junctions, chamfer
  on the one exposed free edge; no angled buttress) — a constant
  cross-section extruded straight up, so it prints clean without support.
  None needed for the lid either — its flush top/bottom faces, countersinks,
  and hot-zone vent band (same honeycomb hex pattern as the faceplate,
  toggled via `lid_vents`) are all cut straight through the lid's short
  vertical (thickness) axis.
- Heat-set inserts: M2.5 in the board standoffs (installed top-down), M3 in the
  lid posts. Install with a soldering iron before assembly.
- Fasteners: M2.5 × 6 mm (board), M3 × 8 mm countersunk (lid), M3 (fans).
- Fan mode: set `enable_exhaust=false` (via the OpenSCAD Customizer's
  `[Cooling]` group, or `-D enable_exhaust=false` on the command line, or
  editing the default in `params.scad`) to print the shorter passive box if
  the board's own heatsink+fan kit is sufficient (decide on the bench). The
  toggle correctly drives both the tray's rear-wall geometry (fan bores vs.
  passive honeycomb vent) and the lid's Y-dimension sizing (shorter body
  when fans are off) — it works from every entry point (Customizer, `-D`,
  or editing `params.scad`'s defaults).
- Interior fan mount: the rear exhaust fan mounts on the tray's INTERIOR
  rear-wall face (screwed in from inside the case), with the bore/vent cut
  straight through the wall for airflow — not bolted to the outside face.
  `fan_plenum` (the board-rear-edge -> rear-wall gap when fans are on) is
  derived from the fan's own depth (`fan_default_thickness()`, the `fans`
  library) plus a fixed clearance margin (`fan_board_gap`, `params.scad`),
  so the plenum can never be shallower than the fan actually needs — a
  render-time assert in `params.scad` fails loudly if it ever is.
