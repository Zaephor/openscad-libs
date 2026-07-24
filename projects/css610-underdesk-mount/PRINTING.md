# Printing css610-underdesk-mount

| Setting | Recommendation |
|---|---|
| Material | PETG |
| Printer | Bambu P1S |
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Walls / perimeters | 4 minimum — the leg and flange carry the switch's full weight plus screw-in torque |
| Infill | 25% gyroid |
| Print speed | 50 mm/s |
| Supports | None — support-free by construction (see below) |
| Orientation | Upside-down relative to installed use: flange's device-facing top face down on the bed, leg rising off the bed |
| Quantity | Print 2 — one `side="L"`, one `side="R"` (see project README; both currently render as the same congruent solid with this device's data) |

Notes: print with the flange's device-facing top (model `Z = H + standoff`)
resting on the bed, not the installed orientation. That puts the
wood-screw countersink's cone opening mouth-up as build height increases
(self-supporting — its half-angle is exactly 45°) and shrinks the gusset's
cross-section monotonically with build height, so no new unsupported
material appears at any layer. The 4x M3 leg holes end up horizontal
(bored across layers) but at 3.4 mm diameter are well inside this repo's
~5 mm bridging-safe range, so no teardrop treatment is needed.

**Zero margin on the 45° features.** The gusset and the wood-screw
countersink are both cut at exactly 45°, the outer edge of PETG's safe
self-supporting band (roughly 45-50°, per this repo's `design-for-print`
skill house rules). Print with a well-tuned printer/slicer — there is no
margin below 45° to absorb calibration drift, wet filament, or aggressive
cooling settings. If either feature droops or comes out rough, that's the
likely cause.

Fasteners: the 4x M3 leg holes take machine screws bolting into the
switch's **own tapped side holes** (no nut needed — the device supplies the
threads); the 2x countersunk flange holes take **wood screws** driven up
into the desk from below.
