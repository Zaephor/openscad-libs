# MultiBuild ecosystem map

A map of the MultiBuild part families this library touches — what the item
types are, how they mate, and how to chain them into a real part. This is a
**map**, not a dimension reference: concrete numbers live in
[`RESEARCH.md`](RESEARCH.md) and behind the accessors in `multibuild.scad`;
only the relationships are documented here.

Every entry is tagged **modeled-in-lib** (there is a shipped accessor/module
for it) or **deferred / not-yet-modeled** (conceptual only, with the backlog
item that would add it). The distinction matters: a deferred item means you
compose that side yourself (measurement or another lib), because this library
emits nothing for it yet.

## Two grids, do not conflate

MultiBuild has two independent grid units, and this library exposes both
separately on purpose:

- **MU (Multi Unit) = 25mm** — the **MultiBoard** pegboard/tile grid.
  Accessor: `multibuild_grid_pitch()` (= 25).
- **CU (Cell Unit) = 50mm** — the **MultiBin** container grid.
  Accessors: `multibin_cu()` / `multibin_panel_pitch()` (both = 50).
  `2×2 MU = 1×1 CU`.

Never size CU-based bin geometry off `multibuild_grid_pitch()`. The two live
in different accessor namespaces (`multibuild_*` board grid vs `multibin_*`
container grid) so the 25-vs-50 distinction can't be lost by accident.

## Item types

### Tiles — the MultiBoard mounting surface (MU grid)

A wall/panel of square Tiles on the 25mm MU grid. Each Tile carries two
independent hole families:

- **Multiholes (Large Holes)** — mate with Snaps and Large Threads.
- **Small / pegboard holes** — mate with Peg Click hooks, Small Threads, and
  non-printed pegboard accessories.

**Deferred / not-yet-modeled** (backlog **#33**): full Tile geometry — the
Tile body, edge profile, and inter-tile joining features (Dual Snaps, Offset
Pillars) are not modeled. Only the board-hole *cutter* exists today
(`multibuild_hole("snap")`), for cutting a Multihole into a consumer's own
panel. Where a chain below starts at a Tile, treat that Tile as the official
part (or a #33-pending model), not something this lib emits.

### MultiBin Panels / bins / shells (CU grid) — **modeled-in-lib**

The 50mm-CU container system. Shipped this branch:

- **Panels / Base Plates** sit on the CU grid (`multibin_panel_pitch()`).
- **Shells / bins** are the containers. Accessors:
  `multibin_footprint(size)` / `multibin_cavity(size)` / `multibin_wall(size)`
  / `multibin_height(size)` for the Simple Walls (standard-depth) family;
  `multibin_placeholder(size)` for the external envelope solid and
  `multibin_cavity_cutout(size)` for the internal cavity negative;
  `multibin_cu()` / `multibin_panel_pitch()` / `multibin_tolerance()` /
  `multibin_floor()` for the shared constants.
- **Bins stack** via the CU-height pitch (`50·Hz`; the `+5` base floor is only
  on the bottom-most shell) — see `multibin_height(size)` and RESEARCH.md.

### Connector / mount families

- **Snap** — **modeled-in-lib** (existing, v1). The Regular Snap plugs
  straight into a Multihole. Positive `multibuild_mount("snap")` +
  negative `multibuild_hole("snap")` + placeholder
  `multibuild_mount_placeholder("snap")`. Type keys via
  `multibuild_known_mounts()`.
- **Fix-Point / Multipoint** — **modeled-in-lib** (this branch), **accessory
  side only**. A Fix-Point gives an accessory a slide-on attachment. The
  library emits the dovetail pocket an accessory cuts into its own face to
  receive a Fix-Point: `multibuild_hole("multipoint")` (Regular, mates a
  Multipoint Hole) and `multibuild_hole("multipoint_rail")` (the Rail / Lite
  variant, 1mm thinner, mates a Rail Negative). The mating positive dovetail
  `multibuild_fixpoint_placeholder(type)` is fit-viz reference geometry only.
  Type keys via `multibuild_known_holes()`. The Fix-Point part's **own
  board-side thread/bolt engagement is out of scope** — that belongs to the
  official part.
- **Rails** — **modeled-in-lib** (this branch) as the Fix-Point *Lite*
  variant: `multibuild_hole("multipoint_rail")`. A Rail is a longer slide
  channel (the real length is per-part/variable; the `length` arg overrides
  the viz-only default).
- **Thread** (Small / Mid / Large / Big) — **deferred / not-yet-modeled**
  (backlog **#35**). No thread pitch/profile spec was recovered and the repo
  has no helical-thread-modeling utility, so no thread-modeling approach is
  decided yet.
- **Peg-Click** — **deferred / not-yet-modeled** (backlog **#36**). Engages
  **two** Small Holes per instance, which doesn't fit the current
  one-hole-per-`type` accessor cardinality; it needs a 2-hole-per-instance API
  generalization first.

### Inserts — project-composed, not lib-modeled

A shaped functional part (a divider, tool holder, component cradle) that fits
inside a Shell or hangs off a Fix-Point. This library does **not** model
inserts; it gives you the negatives to fit one against (a bin cavity, a
Fix-Point pocket). Composing the insert's own shape is a project's job.

## Interconnection matrix

What mates what. **Bold** = an end this library models.

| Board-side feature | Mates with | Modeled here? |
|---|---|---|
| Multihole (Tile, #33-pending body) | **Snap** (`multibuild_mount("snap")`) | Snap side: **yes** |
| Multihole | Large Thread (#35) | deferred |
| Multihole | Fix-Point *board-side* screw | out of scope (official part only) |
| Small / pegboard hole | Peg-Click (#36) | deferred |

| Accessory-side feature | Bridges | Modeled here? |
|---|---|---|
| **Fix-Point pocket** `multibuild_hole("multipoint")` | Tile/board ↔ MultiBin Shell (Regular, via a Multipoint Hole) | **yes** (accessory pocket) |
| **Rail negative** `multibuild_hole("multipoint_rail")` | Tile/board ↔ Shell (Lite, via a Rail Negative) | **yes** (accessory channel) |
| **Bin ↔ bin** | vertical stack via the CU-height pitch (`50·Hz`) | **yes** (`multibin_height`) |

So: a **Fix-Point bridges a Tile/board to a MultiBin Shell** through the
accessory-side (bin-side) pocket or rail this library cuts — Regular via the
Multipoint Hole, Lite via the Rail Negative. The board-side screw engagement
of that same Fix-Point is the official part's job, not modeled here.

## Chains

Concrete X→Y→Z assemblies, using the real accessor names. `#33-pending`
marks a Tile body that isn't modeled yet (use the official part or a #33
model); `project-composed` marks a shape you author yourself.

**1. Hang a custom container off the board via a Fix-Point:**

```
MultiBoard Tile (board Multiholes, #33-pending)
  → Fix-Point            multibuild_hole("multipoint")   (accessory-side pocket)
  → MultiBin Shell       multibin_placeholder(size)      (the hung container envelope)
  → custom Insert        multibin_cavity_cutout(size)    (insert's outer-fit negative)
```

**2. Snap a project part straight onto the board:**

```
MultiBoard Tile (board Multiholes, #33-pending)
  → Snap                 multibuild_mount("snap") / multibuild_hole("snap")
  → our project part     (union the mount onto the part body at Z=0)
```

**3. Slide-mount via a Rail (Lite) instead of a point:**

```
MultiBoard Tile (#33-pending)
  → Rail                 multibuild_hole("multipoint_rail", length=<part-specific>)
  → project accessory    (the accessory carries the rail channel; slides on +X)
```

## Compose recipe — a hang-off-board container

To build a container that hangs off the board and holds a real component:

```
multibin envelope        multibin_placeholder(size)
  + Fix-Point negative    multibuild_hole("multipoint")   (or "multipoint_rail")
  + component keep-outs    from another lib (embedded / sbc) or direct measurement
  → difference()/union() into a single hang-off-board container part
```

The components themselves — an ESP32, a display, a battery, a drive — are
**not modeled by this library**. Pulling their keep-out volumes from a
component lib (e.g. `embedded`, `sbc`) or from a caliper measurement, and
composing them against the bin cavity and the Fix-Point pocket, is the
consuming project's job. This library supplies the MultiBuild-side geometry
(the bin envelope/cavity and the attachment negative); the project supplies
the payload.

## Fit-check honesty

The Fix-Point negatives prove **slide-on clearance only** — that a mating
dovetail has +X room to slide into the pocket — **not retention or
engagement**. Nothing here proves the seated part actually holds; that's a
physical property of the printed dovetail's flank fit and material, same
caveat as the Snap's rigid-static approximation (see the README's "how
honestly" note). Treat the emitted geometry as a starting point to test-fit
and tune.

## Cable routing — not modeled, by design (#34)

MultiBoard mounts on a wall spacer (a 1/8"–1/4" standoff gap), so cables route
behind the board on the wall side; community cord-channel systems (e.g.
Underware) attach via the same mounts this library already provides. There is
no official *core* cord-channel primitive, so this library intentionally
models none — cable routing is a **by-design non-goal**, not a gap.
