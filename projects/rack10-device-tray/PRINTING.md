# Printing rack10-device-tray

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

Notes: prints support-free as designed (floor, side/rear cradle walls,
front faceplate, rear `#40` tongue, and the honeycomb floor vent all print
flat with the tray's long axis — Y, tray depth — in the build plane, per
`rack-support`'s `#40` consumer-contract print-orientation rule). The
countersunk secure-hole cutouts open **downward**, flush with the bed
face, so the countersink itself needs no support either. The rear tongue
is anchored by a full-height rear wall (doubling as the tongue's in-layer
anchor, per `rack-support/README.md`'s consumer contract) rather than a
separate buttress shelf — a modest cantilever off that wall, the same
print-time profile as `drive-tray`'s own rear tongue; not support-free-
violating, just worth watching on a first print.

Before printing for a specific device (GS308 / GS308T / RLA-PS1), caliper
the physical unit and set `secure_holes` accordingly — see README.md's
Presets section. GS308T needs no secure-hole printing decision at all
(`secure_holes = []` by design: the device has no bottom mounting holes to
screw into, so it's held by the cradle walls/floor alone).
