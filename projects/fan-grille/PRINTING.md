# Printing fan-grille

| Setting | Recommendation |
|---|---|
| Material | PETG |
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Walls / perimeters | 2 |
| Infill | 15% grid (the plate is thin and mostly honeycomb-cut already) |
| Print speed | 50 mm/s |
| Supports | None |
| Orientation | Flat on the bed, `plate_th` facing up (no rotation) |

Notes: The plate lies flat with `plate_th` as the print-vertical axis, so
there is no overhang or bridge in that direction. The honeycomb field cuts
straight through Z; each hex's own flat top/bottom edge is a short (<=5 mm)
self-supporting bridge by the `honeycomb` lib's design (see
`libraries/honeycomb/honeycomb.scad`) — no supports needed anywhere on the
part.
