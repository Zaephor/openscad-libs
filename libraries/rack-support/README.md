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

**Complete (#40, Tasks 1-4).** `rack10_rear_post_y()` (Task 1, lives in
`rack10.scad`), the four mating-interface accessors, `rack_support_plate()`
(Task 3), and `rack_support_tongue()` + a reference-tray fit-check assembly
(Task 4) are all implemented and tested. The mate itself (tongue seated in
the plate's channel — bearing contact, lateral capture, no clip-through) was
confirmed with `verify-scad-geometry` against `assembly.scad`.

## Import

```scad
use <rack-support/rack-support.scad>;
```

```scad
rack_support_rail_size();        // [40, 10]  -- tongue [width_X, height_Z] mm
rack_support_slot_clearance();   // 0.4        -- per-side slide fit gap, mm
rack_support_engagement_depth(); // 12         -- tongue insertion depth (Y), mm
rack_support_floor_thickness();  // 2          -- plate bearing-floor material thickness, mm
```

## Functions

| Function | Returns |
|---|---|
| `rack_support_rail_size()` | `[width_X, height_Z]` mm — cross-section of the mating tongue/rail |
| `rack_support_slot_clearance()` | per-side running gap between tongue and slot, mm |
| `rack_support_engagement_depth()` | Y depth the tongue must insert into the channel to be seated, mm |
| `rack_support_floor_thickness()` | `rack_support_plate()`'s bearing-floor material thickness, mm — the floor's TOP face (Z = this value) is the actual load-bearing contact datum, not Z=0. `rack_support_tongue()` reads the same accessor to seat on that datum, so plate and tongue can never drift apart independently. |

See `RESEARCH.md`: these are **DESIGN values** (fit-clearance/engagement
choices for a mechanism this library defines), not measured or spec-sourced
dimensions — cited to `design-for-print` guidance, tagged `//VERIFY`,
bench-tunable on the Bambu P1S / PETG target.

## Modules

### `rack_support_plate(standard, u, thickness=3, hole_type="round")`

Rear-support plate: a `rack10`-width panel sized to bolt at the rack's rear
posts. Mounting face at local `Y=0` (where `rack10_holes(standard, u,
hole_type, dia)` stamps the rear pattern — front hole layout reused on this
plane, single source of truth, never re-literaled); the body grows `+Y`
into the rack. A forward-opening (`-Y`) channel accepts a consumer's
`rack_support_tongue()`, bounded by a bearing floor and braced by a 45°
gusset (built full panel-width, surviving as two ribs flanking the slot
after the channel cut — see the module's own header comment for the
geometric reasoning). The mouth is chamfered for slide-in lead-in.

**Z-datum:** per `rack10.scad`'s "Z=0 at the bottom of the U-stack" datum,
ALL of this plate's solid material stays at `Z>=0` — it must never intrude
into the U-slot below (a different device in a real `rack10` stack). The
bearing floor's bottom face sits at `Z=0`; its **top** face
(`Z=rack_support_floor_thickness()`) is the actual bearing-contact surface,
**not** `Z=0`. The channel cavity sits *above* the floor, `Z` in
`[floor_thickness, floor_thickness+slot_h]`.

`assert(engagement_depth <= device_height)` — the tongue's reach can't
exceed the plate's own device-height envelope.

### `rack_support_tongue()`

The mating tongue a consumer tray unions at its rear, centered on the tray
width, projecting `+Y` to slide into `rack_support_plate()`'s channel.
Cross-section from `rack_support_rail_size()`; length (`Y`) from
`rack_support_engagement_depth()`. Z-positioned at
`[rack_support_floor_thickness(), rack_support_floor_thickness() +
rack_support_rail_size()[1]]` — underside on the plate's bearing floor
(tight fit, true bearing contact), top with the plate's `slot_clearance`
headroom. **Not** `Z=[0, rail_size[1]]` — the plate's bearing surface is
above the shared rack10 U-floor datum by `floor_thickness()`, not flush
with it, and the tongue must match. Leading edge is left square: it mates
with the plate's own chamfered mouth lead-in, so no separate tongue-side
bevel is needed. The end face is flat/vertical (no overhang on its own);
see the placement formula and buttressing note below for what the
*consumer* must do to keep the tongue support-free once it's welded onto a
real tray floor.

## Consumer contract (#41-45 design rules)

The rules below are binding on every #41-45 tray consumer, from the
structural analysis (creep) pass that motivated this library.

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
- **Placement formula:** a consumer places its rear tongue so its root (the
  `Y=0` end of `rack_support_tongue()`, before the consumer's own
  `translate()`) sits at:

  ```
  body_reach = rack10_rear_post_y(standard) - rack_support_engagement_depth()
  translate([0, body_reach, 0]) rack_support_tongue();
  ```

  i.e. the tongue's *tip* lands exactly at `rack10_rear_post_y(standard)`
  (the rack's rear mounting plane / `rack_support_plate()`'s own mounting
  face), and its root sits `engagement_depth()` mm forward of that. This is
  the formula `assembly.scad` uses to seat the reference stub tray; it was
  confirmed with `verify-scad-geometry` (bearing contact, lateral capture
  within `slot_clearance`, no clip-through, tongue's Y-span fully inside
  the channel's real Y-band).
- **Buttressing (support-free requirement):** `rack_support_tongue()`'s
  underside sits at `rack_support_floor_thickness()` (2mm), not at the
  consumer's own local `Z=0` floor datum. A consumer's floor must reach up
  to meet the tongue's underside with **no unsupported gap** — e.g. by
  running the tray's own floor at the same `Z` height as the tongue's
  underside for the last `engagement_depth()` mm (as `assembly.scad`'s stub
  tray does), or by adding a 45° buttress ramping from the tray's local
  floor up to `floor_thickness()` before the tongue root. A floor that
  simply stops short of the tongue's Z-start leaves the tongue as an
  unsupported horizontal shelf (a real overhang, not printable without
  support) — verified while building `assembly.scad` (a floor stopping
  exactly at the tongue's own front face reproduced a CGAL non-manifold
  "touching only along an edge" defect; extending the floor to fully
  overlap the tongue's footprint in `Y` fixed both the manifold defect and
  the overhang).

## Sources

Per `docs/LIBRARY-AUTHORING.md`'s tier ladder ([A] datasheet/spec, [B]
corroborated peers, [C] STL/SCAD reverse-engineering) — none apply to a
value this library invents for its own mechanism. See `RESEARCH.md` for the
full rationale; summary:

| Source | Backs |
|---|---|
| `.claude/skills/design-for-print/reference/tolerances-fits.md` (free/running fit band, short-engagement-land strategy) | `rack_support_slot_clearance()`, `rack_support_engagement_depth()` rationale |
| This library's own structural role (no external spec) | `rack_support_rail_size()`, `rack_support_floor_thickness()` |
| `libraries/rack10/rack10.scad` `rack10_rear_post_y()` (Task 1) | rear mounting-plane datum consumers place a tongue against |

## Coverage

- **Modeled:** `rack_support_plate()`, `rack_support_tongue()`, the four
  mating-interface accessors, a reference-tray fit-check `assembly.scad`.
- **Unify audit:** no current in-repo rear-support consumer — existing
  1U-family libraries (`bpir4-1u-chassis`, `keystone-faceplate`) are
  front-only; #41-45 will be the first consumers of this library.
