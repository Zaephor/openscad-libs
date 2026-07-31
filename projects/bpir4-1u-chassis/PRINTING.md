# Printing — bpir4-1u-chassis

- Printer/material: Bambu P1S, PETG.
- Orientation: tray floor-down — the floor's flat underside sits on the bed
  and the 254 mm faceplate stands upright off the front of it; lid flat.
- Supports: none needed for the tray — the rear-wall openings are a
  self-supporting honeycomb hex field in **both** fan modes, cut horizontally
  straight through the wall (there is no round bore: on this vertical wall a
  bore's axis would be horizontal, leaving an unsupported near-flat arc at its
  crown). The hex cells are flat-top, so their only bridge is the hex's top
  edge — measured worst case 4.05 mm, under the reliably-self-supporting
  bridging ceiling, and asserted at render time by `honeycomb_vent()` itself.
  Active mode also keeps a solid bearing pad around each of the 8 fan mount
  screws; the pad's underside arc and the 4.3 mm screw-hole crown are curved
  downward-facing surfaces up to 90 degrees from vertical, same order as the
  hex bridge (4.05 mm) and anchored the same way — by solid wall on both
  sides, not a progressive overhang. Every other downward-facing surface in
  those openings is a hex side facet at 30 degrees from vertical. The
  faceplate's above-IO intake vents are the same
  honeycomb pattern, and the 4
  corner lid posts are full-height square columns bonded to **both** walls
  of their corner (fillet on the two internal post-wall junctions, chamfer
  on the one exposed free edge; no angled buttress) — a constant
  cross-section extruded straight up, so it prints clean without support.
  None needed for the lid either — its flush top/bottom faces, countersinks,
  and hot-zone vent band (same honeycomb hex pattern as the faceplate,
  toggled via `lid_vents`) are all cut straight through the lid's short
  vertical (thickness) axis.
- Chamfered corners (#70), both support-free: the faceplate blank's silhouette
  corners (imported from `rack10_panel_profile()`) are a constant 45 degrees
  at every corner, same reasoning as every other rack10 faceplate. The tray's
  two rear outer vertical corners are chamfered at 1.2mm (not the faceplate's
  3.0mm — the limit here is `wall*(2 - sqrt(2))` = 1.406mm, above which the
  material left along the corner diagonal drops under the 2.4mm wall
  thickness), cut as a constant-cross-section vertical extrusion (no taper
  along Z), so it prints clean without support like the lid posts' own
  chamfer. Known and accepted consequence: above the lid ledge that corner is
  the wall/2 lid lip, so the chamfer tapers the lip to nothing across its
  last 1.2mm at each rear corner — the lid shelf is inboard and untouched, so
  the lid still seats; it just loses lip retention across ~1.2mm at those two
  corners.
- Heat-set inserts: M2.5 in the board standoffs (installed top-down), M3 in the
  lid posts. Install with a soldering iron before assembly. Both the board
  standoffs and the lid posts present a heat-set lead-in chamfer at the mouth
  (`heatset_pocket()`, #75), so an insert starts square instead of cocked. The
  board standoffs' bore already ran fully through the post and bottomed on the
  floor before this change, so relief below the insert's seat was already
  present -- #75 added only the lead-in, not new relief.
- Fasteners: M2.5 × 6 mm (board), M3 × 8 mm countersunk (lid), M3 (fans).
- Fan mode: set `enable_exhaust=false` (via the OpenSCAD Customizer's
  `[Cooling]` group, or `-D enable_exhaust=false` on the command line, or
  editing the default in `params.scad`) to print the shorter passive box if
  the board's own heatsink+fan kit is sufficient (decide on the bench). The
  toggle correctly drives both the tray's rear-wall geometry (both modes get
  the honeycomb vent; the active mode adds the fan mount screw holes and the
  solid bearing pads around them) and the lid's Y-dimension sizing (shorter body
  when fans are off) — it works from every entry point (Customizer, `-D`,
  or editing `params.scad`'s defaults).
- Interior fan mount: the rear exhaust fan mounts on the tray's INTERIOR
  rear-wall face (screwed in from inside the case), blowing through the
  honeycomb vent cut straight through the wall — not bolted to the outside
  face. Each mount screw passes through a solid bearing pad kept in the hex
  field (`fan_pad_dia`), so the M3 head seats on material rather than on the
  1.2 mm lattice.
  `fan_plenum` (the board-rear-edge -> rear-wall gap when fans are on) is
  derived from the fan's own depth (`fan_default_thickness()`, the `fans`
  library) plus a fixed clearance margin (`fan_board_gap`, `params.scad`),
  so the plenum can never be shallower than the fan actually needs — a
  render-time assert in `params.scad` fails loudly if it ever is.
