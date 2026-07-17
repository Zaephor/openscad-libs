# Printing keystone-faceplate

| Setting | Recommendation |
|---|---|
| Material | PETG |
| Printer | Bambu P1S |
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Walls / perimeters | 3 |
| Infill | 20% gyroid |
| Print speed | 50 mm/s |
| Supports | None |
| Orientation | Flat, front face down on the bed |

Notes: printed flat, the plate's thickness axis is vertical (print Z), so
every keystone window and every ear hole/slot is a straight vertical prism
through the plate — no overhangs, no bridging, support-free by construction.

Keep `plate_thickness` within the keystone lib's snap-retention range
`[1.5, 3.0]` mm; outside that range off-the-shelf keystone jacks won't seat
and latch correctly in the printed windows.
