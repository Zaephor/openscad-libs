# Printing bay-enclosure

| Setting | Recommendation |
|---|---|
| Material | PETG |
| Printer | Bambu P1S |
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Walls / perimeters | 3 minimum; **>= 6 (2.4mm) on the side walls and floor/buttress/tongue** — load-bearing per the `rack-support` #40 consumer contract, not cosmetic |
| Infill | 20% gyroid |
| Print speed | 50 mm/s |
| Supports | None — support-free by construction (see below) |
| Orientation | Flat, floor-down (walls vertical, Z = build height) |

Notes: the whole tray prints in one orientation with the floor on the bed
and the side walls/faceplate rising in Z. The front rack panel's ear holes
and device-face cutout are straight vertical prisms through the panel's
short (thickness) axis — no overhangs. The side-mount holes are cut
straight through the (vertical) side walls, also no overhangs. The rear
buttress that ramps the floor up to `rack_support_floor_thickness()` is a
45° self-supporting wedge (ramp run == ramp rise, at the self-support
ceiling, never past it), and the `rack_support_tongue()` it carries mates
with the separately-printed `rack_support_plate()`'s own chamfered lead-in —
neither needs supports. The one known rough spot is the unbraced center
floor/faceplate joint directly under the device (see the project README's
"Known limitation" note) — it's a sharp interior corner, not an overhang, so
it still prints support-free; it's just less reinforced than every other
internal joint in this project.

Print the rear support plate (`rack_support_plate(standard, device_u)`,
`rack-support` lib) as a **separate part**, bolted to the rack's rear posts —
it is not part of this project's own model.
