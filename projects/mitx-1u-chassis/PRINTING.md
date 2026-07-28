# Printing mitx-1u-chassis

| Setting | Recommendation |
|---|---|
| Material | PETG |
| Printer | Bambu P1S |
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Walls / perimeters | 3 minimum |
| Infill | 20% gyroid |
| Print speed | 50 mm/s |
| Supports | None — support-free by construction (see below) |
| Orientation | Floor-down, open-top up (as modeled — the floor is the bed-facing face, walls/tongue/gussets extrude straight up in +Z) |

Notes: the whole tray (floor + side walls + rear wall + tongue + gussets +
faceplate) is a single support-free print in this orientation — every
feature was verified against it individually and as a combined render across
Tasks 1-3:

- **Faceplate.** The ear holes, IO-shield cutout, and power button hole are
  all straight vertical prisms through the panel's short (thickness) axis —
  no overhangs. The board standoffs are plain cylindrical posts (pilot bore
  subtracted) printing straight up, also no overhangs.
- **Floor + walls.** Plain rectangular boxes extruded straight up from the
  bed — no cantilever, no overhang by construction.
- **Rear `#40` tongue + buttress.** The tongue's own body is a flat
  horizontal reach with no material under it from the shell alone, so a
  buttress strip (sized to the tongue's own width, at
  `rack_support_floor_thickness()`, spanning the tongue's full
  `rack_support_engagement_depth()`) fills underneath it — confirmed by a
  positive-control probe directly under the tongue's footprint
  (`tests/test_mitx_1u_chassis.sh`). Without this fix (caught during Task 2
  `verify-scad-geometry` review) the tongue would print as an unsupported
  ~12mm horizontal shelf.
- **Tongue-flanking gussets.** Support-free 45° corner braces (hull of 6
  corner spheres — same shape `rack-support.scad`'s own gusset uses):
  right angle at the rear-wall/floor corner, each leg running `size` mm,
  print-bed on the floor so every Z-layer's Y-footprint shrinks going up —
  each layer sits on a wider one below it, no support needed.
- **Rear fan bore.** Teardropped (45° roof replacing the top arc of the
  circular bore) — a plain round hole this large (36.8mm at the default
  40mm fan) on a horizontal axis through a vertical wall is well past the
  safe plain-hole span. Fan mount screw holes stay plain round (well under
  the bridging-safe threshold).
- **Rear DC-in hole.** Left plain round (11mm, near the top of the "usually
  fine, minor droop" band) — a barrel-jack panel-mount nut needs true
  roundness, so it isn't teardropped.
- **Honeycomb vents (both side walls + rear, flanking the fan).** Each field
  is oriented so the hex cell's bridge-sensitive "height" axis lands on the
  vertical (print) axis — flat-top hex cells whose only bridge (the top
  edge) is a few mm, well under the reliably-self-supporting bridging
  ceiling (`libraries/honeycomb/honeycomb.scad`). Confirmed per-field via the
  `HONEYCOMB_WORST_SPAN` check in `tests/test_mitx_1u_chassis.sh` (≤5mm on
  all three fields at default `cell`/`hc_wall`).

All of the above was confirmed with `verify-scad-geometry` renders (both
as-modeled and rotated 180° about Z for a rear-wall-facing view) across
Tasks 1-3, plus the numeric fit-asserts and hole-void probes in
`tests/test_mitx_1u_chassis.sh` — no supports anywhere in this orientation.
