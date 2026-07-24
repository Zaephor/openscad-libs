# honeycomb (library)

Self-supporting hex-hole vent cutter — a reusable module for print-safe ventilation
apertures. Produces flat-top hexagon patterns that bridge reliably without print
supports by design. Suitable for any project's vent/aperture needs (chassis vents,
grille cutouts, fan guards, etc.).

## Import

```scad
use <honeycomb/honeycomb.scad>;

// Cut a 40×20mm vent aperture through a 2mm-thick plate (cell/wall tuned for self-support)
difference() {
    my_part();
    translate([10, 10]) honeycomb_vent(width=40, height=20, depth=2, cell=8, wall=1.2);
}
```

## Orientation and Local Frame

**Local coordinate system** (corner-anchored):
- **X** in [0, width] — left to right
- **Y** in [0, height] — bottom to top
- **Z** in [0, depth] — extrusion/cutter depth

Flat-top hexagons: horizontal edge at top/bottom of each cell (not vertex). Caller
rotates/translates the entire honeycomb_vent call to position it in the model's
global frame.

## Module

| Module | Signature | Does |
|---|---|---|
| `honeycomb_vent(width, height, depth, cell, wall)` | All parameters required, no defaults | Renders hex-hole vent as a linear_extrude in local Z. Tiles flat-top hexagons in columns; asserts self-support constraint (all exposed boundary spans ≤5mm, see Geometry below). |

## Parameters

| Parameter | Units | Role | Notes |
|---|---|---|---|
| `width` | mm | Cutter width (X direction) | Caller supplies; any value ≥0. |
| `height` | mm | Cutter height (Y direction) | Caller supplies; determines vent aperture height and row count. |
| `depth` | mm | Extrusion depth (Z direction) | Thickness of the vent wall / cutter depth. |
| `cell` | mm | Hex point-to-point width (circumradius × 2) | Design/print-tuning parameter. Sizes the hex cells. **With wall=1.2, cell=8 produces 4mm worst-case bridge span (safest); larger cell → larger span (tune down for even safer prints).** [D] design-only. |
| `wall` | mm | Solid gap between adjacent hexes | Design/print-tuning parameter. Thinner wall → denser vent area. [D] design-only. |

## Geometry

**Flat-top hexagon bridging (self-support by design):**

The module uses flat-top hexagons (horizontal edge at cell top/bottom, not vertex).
A flat-top hex's cross-section span varies from `cell/2` at its flat edges (the
intended <=5mm bridge per design-for-print) up to `cell` at the equator. The module
**tests every boundary-straddling hex** via an internal `_hex_is_safe()` function
to ensure clipping never exposes a span larger than 5mm. Hexes that would clip
unsafely are omitted, leaving a visibly-intentional sparse column at the boundary
edge rather than an oversize opening.

**Hex tiling:**
- Hexes tile in **columns** (not rows), spaced horizontally by `0.75×cell + wall`.
- Alternate columns are offset vertically by half the row pitch.
- Row pitch = `hex_flat_to_flat_height + wall` = `cell×sqrt(3)/2 + wall`.

This makes the module safe for ANY caller-supplied height without the caller
needing to pick row-pitch-aligned aperture dimensions.

## Self-Support Assertion

The module includes a **regression guard** assertion:
```
assert(worst_span <= max_safe_span + 1e-6, ...)
```

This fires if any boundary-clipped hex would expose a span > 5mm, catching both
geometry bugs and misconfigured caller parameters (e.g., extremely large cell
with very small height). Under correct design, this should never fire; it is a
safety catch for invalid caller input.

## Sources

| Source | Tier | Backs |
|---|---|---|
| design-for-print skill reference — bridging table | [D] | <=5mm is "reliably self-supporting, minimal-to-no sag" |
| OpenSCAD circle($fn=6) geometry | [D] | Flat-top hexagon orientation (vertices at 0/60/120°, not 30/90/150°) |
| Flat-top hex column-packing geometry | [D] | Hex tiling pitch and offset formulas (derived from standard hex grid math) |

**Tier explanation:** [D] = design-tier only (not measured hardware). Cell and wall are
print-tuning parameters chosen at design time, not sourced from device data or specs.

## Coverage

**Modeled:** Flat-top hex-hole vent cutter, arbitrary width/height/depth, with
print-safe self-support constraint (<=5mm boundary span ceiling).

**Not covered / deferred:**
- Pointed-top hexagons (different aesthetic, different bridging logic).
- Variable-width cells across the aperture.
- Honeycomb fill patterns (solid blocks, gradients).
