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
rack_support_gusset_rib();       // 10         -- width of each rib flanking the channel, mm
```

## Functions

| Function | Returns |
|---|---|
| `rack_support_rail_size()` | `[width_X, height_Z]` mm — cross-section of the mating tongue/rail |
| `rack_support_slot_clearance()` | per-side running gap between tongue and slot, mm |
| `rack_support_engagement_depth()` | Y depth the tongue must insert into the channel to be seated, mm |
| `rack_support_floor_thickness()` | `rack_support_plate()`'s bearing-floor material thickness, mm — the floor's TOP face (Z = this value) is the actual load-bearing contact datum, not Z=0. `rack_support_tongue()` reads the same accessor to seat on that datum, so plate and tongue can never drift apart independently. |
| `rack_support_gusset_rib()` | Width (mm) of each of the two 45° gusset ribs flanking the channel, one on either side of the slot. The gusset is **not** built full panel-width (#63): its central, slot-width band is cut away by the same `difference()` that carves the channel cavity, leaving only these two ribs — still bonded to both the bearing floor and the mounting wall — free to span the rest of the panel for consumer geometry. |

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
gusset narrowed to two ribs (`rack_support_gusset_rib()` wide each)
flanking the slot — **not** built full panel-width. An earlier,
full-panel-width gusset made the plate's solid envelope span the entire
panel over `Z` in `[0, engagement_depth]`, which collided with any
consumer body reaching the rear post plane (#63); narrowing it to two ribs
still bonds the bearing floor to the mounting wall while leaving the rest
of the panel free for consumer geometry — see
`rack_support_plate_keepout()` below for the accessor that lets a consumer
stay clear of what remains. The mouth is chamfered for slide-in lead-in.

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

### `rack_support_plate_keepout(margin = 0)`

The plate's forward-projecting solid envelope, for a consumer to
`difference()` out of its own body at the **same placement** it uses for
`rack_support_plate()` itself (the rear-post plane,
`rack10_rear_post_y(standard)`). Two rigid printed parts cannot occupy the
same volume — a consumer body reaching the rear post plane (e.g. a
buttress under the tongue, or any wall/shelf that extends that far back)
**will** physically intersect the plate unless this keep-out is subtracted
first. Composed from the same accessors `rack_support_plate()` reads
(single source of truth — no re-literaled numbers) and mirrors the plate's
narrowed gusset wedge (`rack_support_gusset_rib()`) and bearing-floor slab,
covering only the part of the envelope that projects past the mounting
face (local `Y<0`); the panel-internal portion (`Y` in `[0, thickness]`) is
left out since a consumer body that stops at the mounting face never
reaches it.

`margin` (default `0` = exact fit) inflates the envelope for assembly
clearance, but only *outward from the channel cavity's own XY footprint*: it
raises the gusset wedge's apex and widens the prism in `X`. It does **not**
extend the envelope past the plate's mouth plane
(`Y = -engagement_depth()`), and the bearing-floor slab is pinned to the
cavity's exact footprint. Growth into the ring of consumer material
immediately around the cavity would carve a `margin`-wide moat there, and
that ring is the only thing joining a consumer's tongue to the rest of its
body — an earlier revision did exactly that and severed the reference stub
tray's tongue outright at `margin = 0.1`. `tests/test_rack_support_lib.sh`
checks `(d)` assert the containment directly.

`margin` also opens **no clearance at the mounting face** (`+Y`): the
keep-out's rearmost bound is that plane by construction (the panel-internal
portion is deliberately omitted, above) and `margin` has no `+Y` component.
A consumer whose own body also runs to the rear post plane therefore shares
that plane with the plate at any `margin`, and **cannot** raise `margin` to
eliminate the resulting coincident-face touch or CGAL non-manifold warning.
That touch is benign — it measures exactly `0.000000mm³` — and
`tests/test_bay_enclosure.sh` documents the signature.

**Do not let `margin` touch the channel
cavity** — the module subtracts the exact channel-cavity cut (the same
`slot_w`/`floor_thickness`/`slot_h` terms `rack_support_plate()` itself
cuts) back out of the envelope *regardless of `margin`*, because that
cavity is where the consumer's own tongue legitimately lives. This
exclusion is not a simplification to skip: an envelope that omits it would
delete the caller's own tongue on `difference()`, making an interference
check against it pass for entirely the wrong reason (the tongue itself
would vanish, not just clear the plate). `tests/test_rack_support_lib.sh`
carries a dedicated regression assertion against exactly that failure
mode.

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
  to meet that datum flush — but **only forward of the tongue root**
  (`Y < body_reach`). Read the next two bullets together with this one;
  taken alone this instruction used to contradict the keep-out subtraction
  below.

  Forward of the root, running the floor up to the tongue's underside `Z` is
  required for a real reason: a floor that stops short of the tongue's
  Z-start meets it only along a 1D edge, which CGAL reports as non-manifold
  (reproduced while building `assembly.scad`) and which leaves the tongue an
  unsupported shelf. Bring the floor to `floor_thickness()` before the root,
  ramping at 45° if the consumer's own floor is thinner (as `bay-enclosure`
  does, `floor_th` 1.2mm → 2mm).

- **The tongue's engagement span is inherently unsupported — do not try to
  fill it.** Over `Y` in `[body_reach, rack10_rear_post_y(standard)]`, the
  volume beneath the tongue's underside belongs to `rack_support_plate()`'s
  own bearing floor. Two rigid printed parts cannot share it, so whatever a
  consumer builds there is exactly what `rack_support_plate_keepout()`
  deletes; all that survives is a sub-layer `eps` film (measured on the
  reference stub tray: 4.8001mm³ = 40 × 12 × 0.01, ~1/20 of a layer height —
  no slicer emits it). Filling this span is therefore not merely redundant,
  it is self-cancelling, and an earlier revision of this section wrongly
  told consumers to do it. The tongue's 40 × 12mm underside is a genuine
  overhang in **every** consumer of this interface.

- **Anchor the tongue with a 45° root gusset instead** (this is the
  "tongue-to-body junction" case of the root-gusset rule above, and it is
  what makes the overhang printable rather than merely acknowledged). Put
  material **above** `Z = rack_support_floor_thickness()` at
  `Y < body_reach`: a 45° wedge whose vertical leg is the tongue's own front
  face and whose horizontal leg runs forward along the consumer's floor top.
  Sizing it from `rack_support_rail_size()[1]` (the tongue's height) makes
  the apex flush with the tongue's top face and braces the full root
  cross-section without introducing a new dimension. All of `Y < body_reach`
  is free of the plate — its measured `ymin` is `227.999 ≈ body_reach` — so
  this costs nothing in clearance. Both shipped references do it
  (`assembly.scad`, `bay-enclosure`); note `bay-enclosure`'s wedge rises
  from its own thinner floor (`floor_th`), not from `floor_thickness()`, or
  it would float. What this buys is an in-layer anchor for the tongue's
  first printed layer, the same role `drive-tray`'s full-height rear wall
  plays for its tongue. The residual risk is then the same one
  `drive-tray.scad` documents and knowingly accepts: a stocky 40 × 10mm
  cross-section cantilevering `engagement_depth()` (12mm) off an anchored
  root.

- **Subtract the plate's keep-out.** Bringing a body up to the tongue's
  underside means **that same body now reaches the rear post plane, where
  `rack_support_plate()` has its own solid material** (panel, bearing floor,
  gusset ribs). A consumer body that reaches `rack10_rear_post_y(standard)`
  **will** physically intersect the plate unless
  `rack_support_plate_keepout()` is subtracted from it first, at the same
  placement used for the tongue:

  ```
  body_reach = rack10_rear_post_y(standard) - rack_support_engagement_depth()
  difference() {
      // ... consumer body, incl. its floor-to-underside fill FORWARD of
      // body_reach and its 45deg tongue root gusset ...
      translate([0, rack10_rear_post_y(standard), 0]) rack_support_plate_keepout();
  }
  // ... then union the tongue itself, at translate([0, body_reach, 0]) ...
  ```

  An earlier revision of this guidance recommended closing the gap with *"a
  45° buttress ramping from the tray's local floor up to
  `floor_thickness()` before the tongue root"* **and carrying it through the
  engagement span** — that shape reaches the rear post plane and collided
  with the plate's (then full-panel-width) gusset in both this library's own
  `assembly.scad` reference tray (875.89mm³ measured interference) and the
  real shipped `bay-enclosure` project (3554.86mm³ measured interference) —
  see #63. Do not add a freestanding buttress ramp through that span; ramp
  up forward of the root, gusset the root, and subtract
  `rack_support_plate_keepout()`, which is guaranteed by construction to stay
  clear of whatever material `rack_support_plate()` actually contains.

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

- **Modeled:** `rack_support_plate()`, `rack_support_tongue()`,
  `rack_support_plate_keepout()`, the five mating-interface/geometry
  accessors, a reference-tray fit-check `assembly.scad`.
- **Unify audit:** three in-repo rear-support consumers as of #63 — this
  library's own `assembly.scad` reference tray, the real shipped
  `projects/bay-enclosure`, and `projects/drive-tray` (clean without a
  buttress shelf, so it needs no keep-out subtraction) — all three now
  measure zero real interference with `rack_support_plate()`'s envelope.
  Other 1U-family libraries (`bpir4-1u-chassis`, `keystone-faceplate`)
  remain front-only and are not consumers of this library.
