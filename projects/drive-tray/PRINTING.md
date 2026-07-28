# Printing drive-tray

| Setting | Recommendation |
|---|---|
| Material | PETG |
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Walls / perimeters | 3 |
| Infill | 20% gyroid |
| Print speed | 50 mm/s |
| Supports | None (support-free is a hard project constraint) |
| Orientation | Flat, open-top — floor on the bed |

Notes: prints support-free as designed (floor, walls, faceplate, rear #40
tongue, and the per-cell honeycomb floor vents all print flat with the tray's
long axis — Y, tray depth — in the build plane, per rack-support's #40
consumer-contract print-orientation rule). The rear tongue is a modest
cantilever off the rear wall (see drive-tray.scad's "NO rear buttress shelf"
comment) — a real but modest print-time risk, slightly past this repo's
~5-10mm bridging guideline; not support-free-violating, just worth watching
on a first print.
