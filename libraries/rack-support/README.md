# rack-support (library)

Generic **rear-support faceplate + slide-in tongue/slot mating interface**
for `rack10` device trays (#40). The #41-45 tray family (3.5"/5.25"
enclosure, mini-ITX 1U/2U chassis, 2x3.5" + 6x2.5" drive trays) all mount at
the front via rack ears and cantilever rearward up to ~200-260mm; a
structural analysis found the real failure mode is **PETG creep under
sustained load + drive heat** (multi-mm rear droop over months), not
short-term elastic sag. Bolting a `rack_support_plate()` to the rear rack
posts and sliding each tray's rear `rack_support_tongue()` into its channel
converts that front cantilever into a **two-end-supported beam**, cutting
root moment ~4x and deflection ~10x — done once here so no #41-45 consumer
re-invents rear support. Consumes `rack10` for widths/holes/depth. Units:
**mm**.

## Status

**Task 2 of 4 (this pass): accessors + scaffolding only.** The three
mating-interface accessors below are implemented and tested;
`rack_support_plate()` (Task 3) and `rack_support_tongue()` + the reference
fit-check assembly (Task 4) land next. This README's datum/orientation and
Modules sections grow once those exist — don't infer plate/tongue geometry
from this pass.

## Import

```scad
use <rack-support/rack-support.scad>;
```

```scad
rack_support_rail_size();        // [40, 10]  -- tongue [width_X, height_Z] mm
rack_support_slot_clearance();   // 0.4        -- per-side slide fit gap, mm
rack_support_engagement_depth(); // 12         -- tongue insertion depth (Y), mm
```

## Functions

| Function | Returns |
|---|---|
| `rack_support_rail_size()` | `[width_X, height_Z]` mm — cross-section of the mating tongue/rail |
| `rack_support_slot_clearance()` | per-side running gap between tongue and slot, mm |
| `rack_support_engagement_depth()` | Y depth the tongue must insert into the channel to be seated, mm |

See `RESEARCH.md`: these are **DESIGN values** (fit-clearance/engagement
choices for a mechanism this library defines), not measured or spec-sourced
dimensions — cited to `design-for-print` guidance, tagged `//VERIFY`,
bench-tunable on the Bambu P1S / PETG target.

## Consumer contract (#41-45 design rules)

The rules below are binding on every #41-45 tray consumer, from the
structural analysis (creep) pass that motivated this library. (Placement
formula and module-level docs land once `rack_support_plate` /
`rack_support_tongue` exist — Tasks 3-4.)

- Load-bearing walls **>= 2.4mm** (6 perimeters); never below 4 perimeters
  on a structural wall.
- 1U tray web height **>= 20-25mm**; 2U **>= 35-45mm**, or a
  partially-closed box. Height beats thickness (`I` proportional to `h^3`).
- **45deg root gussets** at front-ear-to-floor and tongue-to-body junctions.
- Vertical load rides the **front bolt + the rear bearing floor** —
  **never a snap/latch** (PETG snaps creep and release under sustained
  load; a light retention clip, if ever added, may resist lift but must
  never carry weight).
- Print the tray with its long axis in the build plane (root fibers within
  layers, not stacked across the load path).
- A consumer places its rear tongue so it seats at the rack's rear mounting
  plane: `rack10_rear_post_y(standard)` (Task 1, `rack10.scad`) is that Y
  coordinate; the tongue must reach `rack_support_engagement_depth()` mm
  into the plate's channel from there. The exact placement formula tying
  this to `rack_support_plate()`'s own geometry is finalized in Task 4 once
  that module exists.

## Sources

Per `docs/LIBRARY-AUTHORING.md`'s tier ladder ([A] datasheet/spec, [B]
corroborated peers, [C] STL/SCAD reverse-engineering) — none apply to a
value this library invents for its own mechanism. See `RESEARCH.md` for the
full rationale; summary:

| Source | Backs |
|---|---|
| `.claude/skills/design-for-print/reference/tolerances-fits.md` (free/running fit band, short-engagement-land strategy) | `rack_support_slot_clearance()`, `rack_support_engagement_depth()` rationale |
| This library's own structural role (no external spec) | `rack_support_rail_size()` |
| `libraries/rack10/rack10.scad` `rack10_rear_post_y()` (Task 1) | rear mounting-plane datum consumers place a tongue against |

## Coverage

- **Modeled (this pass):** the three mating-interface accessors only.
- **Deferred:** `rack_support_plate()` (Task 3), `rack_support_tongue()` +
  reference-tray fit-check assembly + full consumer-contract/module docs
  (Task 4).
- **Unify audit:** no current in-repo rear-support consumer — existing
  1U-family libraries (`bpir4-1u-chassis`, `keystone-faceplate`) are
  front-only; #41-45 will be the first consumers of this library.
