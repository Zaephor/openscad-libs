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

## Corner mount-hole tab thickness

The 4 corner mount holes are sized in the `fans` lib for an M5 self-tapping
screw, and the plate material between each hole and the plate edge (the
"tab") scales with fan size: `tab = (fan_size - fan_hole_spacing(fan_size) -
hole_dia) / 2`. At this module's own **default `fan_size=40`, the tab is
only ~1.85 mm** — the thinnest across the whole `fan_known_sizes()` table —
so a self-tapping screw cutting fresh threads there generates real hoop
stress in that corner and can split the PETG on assembly. Go slow: hand-start
the screw and stop at the first sign of resistance, consider a
smaller-diameter fastener than the nominal M5, or pre-drill the hole slightly
before driving the screw. At `fan_size=80` the tab is already comfortably
thicker (~2.1 mm), most other sizes are >=2.85 mm, and `fan_size>=120` tabs
are >=5 mm — this caution is really only about the 40 mm default.
