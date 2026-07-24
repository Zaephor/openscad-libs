# honeycomb — evidence source log

Provenance and evidence log for the `honeycomb_vent()` self-supporting hex-hole
vent cutter. This is a **design-tier library** — no hardware measurement involved.
The module implements geometric vent-cutting logic tuned for reliable bridging per
design-for-print guidelines.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` the authoritative governing standard/spec itself fetched and read directly.
- `[B]` corroborated across >=2 independent peers.
- `[C]` single-sourced / derived, or a named standard cited but not fetched.
- `[D]` design-tier only (not measured; hand-tuned at design time).
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

## Design Tiers and Sources Consulted

### Bridging Span Ceiling (5mm)

| Dimension | Value | Tier | Source |
|---|---|---|---|
| Max safe bridge span (extrusion direction) | 5 mm | [D] | design-for-print skill: "<=5mm is reliably self-supporting, minimal-to-no sag" |

**Justification:** The 5mm ceiling is a design guideline from the design-for-print
skill reference, which summarizes common FDM print reliability. Flat-top hexagons
naturally expose a flat span (the hex's top/bottom edge) in the bridging direction;
this span equals `cell/2` when hexes are fully interior and larger when clipped at
boundaries. The module's self-support constraint ensures no clipped boundary hex
exposes more than 5mm in this direction.

**Parameter tuning:** With `cell=8mm` and `wall=1.2mm`, the worst-case boundary
span is approximately 4mm, safely under the 5mm ceiling. Callers can trade vent
density (thinner wall) for boundary safety margin (smaller cell) as needed.

### Flat-Top Hexagon Geometry and Orientation

| Aspect | Value | Tier | Source |
|---|---|---|---|
| Hexagon orientation (vertices vs flat edges) | Flat-top (horizontal edge at top/bottom) | [D] | OpenSCAD `circle(r, $fn=6)` places vertices at 0/60/120/180/240/300°, yielding flat edges at top/bottom. |
| Circumradius ↔ cell relationship | cell = 2 × circumradius | [D] | Standard regular hexagon geometry (cell is point-to-point width). |
| Flat-to-flat height | cell × sqrt(3) / 2 | [D] | Derived from regular hexagon formula h = r × sqrt(3), where r = cell/2. |
| Column pitch (horizontal hex-center spacing) | 0.75 × cell + wall | [D] | Flat-top hex column-packing geometry (standard hex-grid math). |
| Row pitch (vertical hex-center spacing within a column) | hex_flat_to_flat_height + wall | [D] | Vertical stacking of hexes with gap = wall. |

**Justification:** Flat-top hexagons are the standard orientation for honeycomb
look-alike vents (real honeycomb, bee nests, industrial grilles). They expose a
natural flat span in the bridging direction, making them ideal for the <=5mm
self-support constraint. Pointy-top hexagons would require zero bridging (vertex
taper) but are less aesthetically common and not modeled here.

### Boundary Clipping and Self-Support Safety

| Aspect | Mechanism | Tier |
|---|---|---|
| Safe boundary clipping | `_hex_is_safe(y)` function tests each boundary-straddling hex's exposed span against 5mm ceiling; omits unsafe hexes. | [D] |
| Regression guard | `worst_span` regression assertion re-measures every drawn hex's true exposed span and asserts it ≤ 5mm, catching bugs in `_hex_is_safe()`. | [D] |

**Justification:** The module's robustness to arbitrary caller-supplied heights
(not row-pitch-aligned) is a design choice. Without the `_hex_is_safe()` check,
a naive `intersection()` with `square([width, height])` would clip boundary hexes
at whatever Y offset their geometric position lands, potentially exposing spans
close to `cell` (e.g., 8mm with default parameters) and violating the 5mm
self-support ceiling. The fix is simple: test each boundary hex and omit those
that would clip unsafely.

## Design Parameters (No Hardware Measurement)

The module does **not** source cell or wall from measured hardware. Both are
design/print-tuning parameters:

- **cell**: Chosen at design time to balance vent area (smaller cell = higher
  density) against printability (larger cell = better self-support margin). With
  the 5mm ceiling and flat-top geometry, cell ≤ 10mm is safe; smaller cells trade
  marginally more density for thinner boundary columns.

- **wall**: Chosen at design time to tune vent density and thermal characteristics.
  With cell=8, wall=1.2 is a sensible print-friendly default (4mm worst-case span);
  thinner wall increases vent area but reduces the boundary safety margin.

No caliper-measurement or vendor-datasheet backing these choices; they are
**design-only** and flagged as `[D]` in all provenance tables.

## Gap / Open Questions

None identified. The module's design is self-contained (geometry + 5mm ceiling).
No external hardware measurement or reference specs are involved.

## Notes for Future Work

- **Print validation:** The 5mm ceiling is a guideline, not an empirical validation
  on this specific geometry. A future refinement could include print-test data
  (e.g., "honeycomb_vent at cell=8, wall=1.2 prints reliably on Bambu P1S + PETG,
  no bridging artifacts down to 4mm span observed"). Mark that test tier as `[B]`
  or higher.

- **Cell/wall trade-off tables:** Future README or Customizer UI could document
  tested (cell, wall) pairs and their resulting worst-case spans, density (vent
  area / total area), and observed print quality. This would move those parameters
  closer to `[B]` tier.
