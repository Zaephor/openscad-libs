# rack10 ecosystem map

A map of the 10-inch mini-rack pieces this library models — what the item
types are, how they mate to a rack post and to a consumer's own geometry, and
how to chain them into a real 1U panel. This is a **map**, not a dimension
reference: concrete numbers live behind the accessors in `rack10.scad` and in
[`RESEARCH.md`](RESEARCH.md) / the [`README.md`](README.md) Sources table;
only the relationships are documented here. A reader who wants a number
follows the named accessor, not this file.

Every entry is tagged one of:

- **modeled** — there is a shipped accessor/module for it.
- **illustrative-only** — an accessor exists but carries no sourced value; a
  placeholder you must not build against (see the flange note below).
- **planned / not-yet-modeled** — conceptual only, named with the backlog
  item that would add it. This library emits nothing for it yet, so you
  compose that side yourself.

## No governing standard — vendor-keyed

This is rack10's central caveat, and the reason every geometry accessor takes
a `standard` key (see `rack10_known_standards()` — currently `"labrax"`,
`"deskpi"`, `"tecmojo"`):

**There is no EIA-style governing standard for 10-inch mini-racks at all** —
LabRax's own designer says so explicitly. So tier `[A]` is not reachable for
anything in this library; the ceiling is `[B]`, and every geometry row is
vendor-keyed rather than standard-derived. The three vendors nonetheless
**share their hole geometry** — the same horizontal hole center-to-center
span (`rack10_hole_h_span`) and U pitch (`rack10_u`) — because all three
converge on the same de facto convention. What differs per vendor is the
panel/opening widths (`rack10_panel_width` / `rack10_clear_width`) and the
mounting depth (`rack10_depth_preset`), plus the per-call hole type.

This is rack10's analog of a "do not conflate" caveat: do not treat any rack10
value as standard-blessed. It is the strongest corroboration available for a
domain that has no authority to appeal to.

## Item types

### Data accessors — **modeled**

The geometry / fastener / U functions a consumer reads to size and place its
own solids:

- U geometry: `rack10_u`, `rack10_stack_gap`, `rack10_device_height`.
- Vendor row + widths: `rack10_known_standards`, `rack10_panel_width`,
  `rack10_clear_width`, `rack10_depth_preset`.
- Hole placement: `rack10_hole_h_span`, `rack10_hole_h_centers`,
  `rack10_u_hole_offsets` (the three per-U hole positions), `rack10_hole_z`.
- Fastener / hole-type vocabulary: `rack10_known_hole_types`,
  `rack10_screw_clearance`, `rack10_square_size`.

### Panel & hole-stamp modules — **modeled**

The panel-plus-holes idiom (there is no combined `_panel_holes` helper — you
`difference()` the two yourself, same as rack19):

- `rack10_panel` — a plain vendor-width faceplate blank.
- `rack10_holes` — the mounting-hole cutter for both rail columns, subtracted
  from a consumer solid. Hole type is per-call (`round` / `m6` / `10-32` /
  `square` / `slot`).
- `rack10_slot_profile` — the obround cross-section `rack10_holes`' `slot`
  branch extrudes; extrude it directly for a standalone profile.

### Fit-check placeholders — **modeled** (`%` keep-out, non-print)

- `rack10_placeholder` — the four vertical rail flanges + front hole strip +
  a `%` usable-equipment keep-out volume.
- `rack10_rackpost_context` — `rack10_placeholder` padded above and below a
  device band, so you can preview a device framed in rack context.

Both are reference envelopes for a GUI fit-check, **not printable rack posts**
(see "Fit-check honesty" below).

### Illustrative-only — do **not** build against

- `rack10_flange_width`, `rack10_flange_thickness` — the rail-flange envelope
  dimensions used by `rack10_placeholder`. These carry **no source and no
  tier at all**: LabRax posts are printed plastic (no rolled-flange spec to
  cite) and the STL was never obtained. They exist only to give the
  placeholder a shape. This is the key contrast with rack19, whose flange
  width *is* sourced — see the rack19-parallel table.

### Planned / not-yet-modeled — forward-looking

Named here so the map is honest about what is coming, but **this library
emits nothing for these yet**:

- **`#40`** — the rear-support faceplate cluster.
- **`#41`–`#45`** — the follow-on trays / chassis parts built on top of it.
- **`#3`, `#20`** — device-specific 1U trays (each its own backlog item).

Treat every name in this subsection as a future addition, not existing
geometry. When one ships, it moves up into the modeled sections above.

## Interconnection matrix

What each rack10 end mates with, and which side this library actually models.
**Bold** = an end rack10 models.

| rack10 end | Consumed by | Mates with | Modeled here? |
|---|---|---|---|
| **`rack10_panel`** (vendor-width 1U blank) | keystone-faceplate project | the U opening; abuts stacked units via `rack10_device_height` | **yes** (the blank) |
| **`rack10_holes`** (ear cutter) | keystone-faceplate + bpir4 tray | rack-post screws, sized by `rack10_screw_clearance` | **yes** (the holes); fastener itself is generic hardware, not modeled |
| **`rack10_panel_width`** / **`rack10_clear_width`** | bpir4 params (its own `cube` blank) | the vendor panel / equipment opening | **yes** (the widths); the blank is project-built |
| **`rack10_hole_h_span`** / **`rack10_hole_h_centers`** | keystone-faceplate (ear column X) | the rack post hole columns | **yes** (the positions) |
| **`rack10_depth_preset`** | both consumers | feeds `rack10_rackpost_context` depth | **yes** |
| **`rack10_rackpost_context`** | both consumers (as `%`) | the four rack posts around a device band | **yes** (reference envelope, fit-check only) |
| keystone jack window (`keystone_cutout` / `keystone_boss`, **keystone lib**) | keystone-faceplate project | a `rack10_panel` port position | keystone side: separate lib; rack10 side: **yes** |

**The keystone library does not depend on rack10.** `keystone` is a standalone
port-geometry library (it references nothing rack-related). rack10 and keystone
meet **only in the keystone-faceplate *project***, which `use`s both and places
keystone ports into a `rack10_panel`. Do not read the last row above as a
library-level dependency — it is a project-layer composition.

## Chains

Concrete X→Y→Z assemblies using the real accessor names. Markers:
`[modeled]` = a shipped rack10 accessor; `[keystone lib]` = geometry from the
separate keystone library; `[project]` = a shape the consuming project authors
itself; `[%]` = a non-print fit-check preview.

**1. The faceplate chain (keystone-faceplate project — the canonical compose):**

```
rack10_panel(standard, 1)               [modeled]      1U vendor-width blank
  + keystone_boss(...)                  [keystone lib] per-port boss material (union)
  - rack10_holes(standard, 1, ear)      [modeled]      ear mounting slots/holes (difference)
  - keystone_cutout(...)                [keystone lib] per-port jack window (difference)
  → 1U keystone faceplate
  % rack10_rackpost_context(standard, 1, 1, depth)     [modeled][%] rack preview
```

Ear column X comes from `rack10_hole_h_span`; ports are centered vertically at
`rack10_device_height(1)`.

**2. The bpir4 chain (chassis tray — reuses rack10 for widths + holes only):**

```
own cube() panel blank                  [project]      sized by rack10_panel_width / rack10_clear_width
  - rack10_holes(standard, 1, slot)     [modeled]      ear slots, dia = rack10_screw_clearance("10-32")
  → 1U chassis tray / faceplate
  % rack10_rackpost_context(standard, 1, 1, rack10_depth_preset(standard))  [modeled][%] rack preview
```

The bpir4 chassis builds its **own** panel body (a raw `cube`) and uses rack10
only for the vendor widths and the hole-stamp — it does **not** call
`rack10_panel`. Contrast the faceplate chain, which does.

## Compose recipe — a 1U rack panel

The canonical panel-plus-ear-slots-plus-ports difference, in pseudo-recipe form
(the faceplate chain above, spelled out):

```
difference() {
    union() {
        rack10_panel(standard, 1, thickness)          # vendor-width 1U blank
        for each port:
            keystone_boss(...)                        # [keystone lib] local boss material
    }
    rack10_holes(standard, 1, ear_type,               # ear mounting slots/holes
                 dia = rack10_screw_clearance(fastener))
    for each port:
        keystone_cutout(...)                          # [keystone lib] jack windows
}
% rack10_rackpost_context(standard, 1, 1,             # rack context preview (non-print)
                          rack10_depth_preset(standard))
```

**Components not modeled here.** The device payload behind the panel and the
keystone jack internals come from elsewhere — the keystone library for the
port geometry, and the project (or a component library / measurement) for
whatever the panel fronts. This library supplies the rack-side geometry: the
panel blank, the ear holes, and the fit-check envelope. The consuming project
supplies the payload and the ports.

## rack19 parallel

rack10 was modeled on `rack19` (the 19-inch EIA-310-D sibling — see the
"rack10 parity" note in `rack19.scad`). The two share a near-identical accessor
shape, so a consumer who knows one can read the other. Correspondence and the
differences that matter:

| Concept | rack10 | rack19 |
|---|---|---|
| Governing spec | vendor-keyed, `rack10_known_standards()` param, `[B]` ceiling | single EIA-310-D, **no `standard` param**, `[A]` reachable in principle |
| Default hole type | `"round"` | `"square"` (cage-nut) |
| Usable opening | `rack10_clear_width(standard)` | `rack19_opening_width()` |
| Rail flange | `rack10_flange_width` / `rack10_flange_thickness` — **illustrative-only** | `rack19_flange_width` — **sourced** |
| Mounting depth | `rack10_depth_preset(standard)` — folded into the vendor row | `rack19_known_depths()` / `rack19_depth_preset(name)` — separate named presets |
| Panel / holes | `rack10_panel`, `rack10_holes` | `rack19_panel`, `rack19_holes` |
| Fit-check | `rack10_placeholder`, `rack10_rackpost_context` | `rack19_placeholder`, `rack19_rackpost_context` |

The headline difference is provenance: rack19 has a real (if paywalled)
standard behind it, so its opening width and flange are sourced; rack10 has no
standard, so its widths are per-vendor `[B]` and its flange is illustrative.

## Fit-check honesty

`rack10_placeholder` and `rack10_rackpost_context` are `%` keep-out envelopes.
They prove **clearance and envelope only** — that a device of a given size fits
within the usable opening and the padded rack context — **not load, retention,
or post accuracy**. The flanges are centered on the hole column (a
reference-envelope simplification, not the true post centerline), the flange
dimensions are illustrative (see Item types), and nothing here proves a real
printed post would hold the weight. Treat the emitted envelope as a fit-check
starting point, not a structural or printable part.
