# Printing keystone-blank

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
| Orientation | As generated, no rotation — rear face (deepest point) down on the bed, front face up |

Notes: print AS GENERATED with no rotation — the rear face (furthest behind
the front face) sits DOWN on the bed, front face UP. The cantilever latch
(root + beam + hook) floats clear of the body except at its root; any other
orientation turns the beam into an unsupported floating shelf. Support-free
by construction in this orientation — see `libraries/keystone/keystone.scad`'s
`keystone_insert()` PRINT ORIENTATION comment for the full rationale.

`fit` and `latch_wall` are meant to be tuned on the bench: increase `fit` if
the printed insert is too tight to slot in; adjust `latch_wall` for your
material's flex compliance (thinner flexes more easily but is weaker;
`keystone_insert()` hard-fails at render if `latch_wall` grows too thick for
the latch root's own print-safety margin).
