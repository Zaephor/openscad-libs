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

**Modeled-in-lib** (this branch, backlog **#33**): both hole *patterns*, as
an accessory-panel hole-stamp a project differences into its **own** panel —
`multibuild_tile_holes(cols, rows, which)` (`which` = `"large"` for
Multiholes, `"small"` for Small Holes, `"both"` for the combined stamp,
default) — plus a reference envelope, `multibuild_tile_placeholder(cols,
rows)`, a flush `cols*25 x rows*25` slab pre-cut with both patterns for
fit-check/viz. The Multihole dia/tile-thickness values are **aliased** from
the existing `"snap"` row (`multibuild_large_hole_dia()` /
`multibuild_tile_thickness()`, no new numbers); the Small Hole dia/depth/
offset (`multibuild_small_hole_dia()` / `multibuild_small_hole_depth()` /
`multibuild_small_hole_offset()`) are new `[C]//VERIFY` mesh measurements —
see RESEARCH.md "Tile geometry (#33)".

**Still deferred / not-yet-modeled** (remaining **#33** scope): the Tile's
own body — its edge profile, flange/tab geometry, and inter-tile joining
features (Dual Snaps, Offset Pillars) — is not modeled. The hole-stamp and
placeholder above are for stamping a *project's own* panel or for
reference/viz only, not a substitute for the official Tile part. Where a
chain below starts at a Tile, treat that Tile as the official part (or
`multibuild_tile_placeholder()` for viz only), not something this lib emits
as a printable body.

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
| **Multihole** (`multibuild_tile_holes(cols, rows, "large")`) | **Snap** (`multibuild_mount("snap")`) | both sides: **yes** |
| Multihole | Large Thread (#35) | Multihole side: **yes**; Thread: deferred |
| Multihole | Fix-Point *board-side* screw | out of scope (official part only) |
| **Small / pegboard hole** (`multibuild_tile_holes(cols, rows, "small")`) | Peg-Click (#36) | Small-Hole side: **yes**; Peg-Click: deferred |
| Small / pegboard hole | Small Thread (#35) | Small-Hole side: **yes**; Thread: deferred |
| Small / pegboard hole | non-printed pegboard accessories (hooks, bins, etc.) | out of scope (generic hardware, not modeled) |

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

Concrete X→Y→Z assemblies, using the real accessor names. `Tile body:
#33-pending` marks that the Tile's own body/edge profile isn't modeled (use
the official part, or `multibuild_tile_placeholder()` for reference/viz
only) — separate from the Tile's *hole pattern*, which is modeled
(`multibuild_tile_holes()`); `project-composed` marks a shape you author
yourself.

**1. Hang a custom container off the board via a Fix-Point:**

```
MultiBoard Tile (holes modeled, body #33-pending)
  → Fix-Point            multibuild_hole("multipoint")   (accessory-side pocket)
  → MultiBin Shell       multibin_placeholder(size)      (the hung container envelope)
  → custom Insert        multibin_cavity_cutout(size)    (insert's outer-fit negative)
```

**2. Snap a project part straight onto the board:**

```
MultiBoard Tile (holes modeled, body #33-pending)
  → Snap                 multibuild_mount("snap") / multibuild_hole("snap")
  → our project part     (union the mount onto the part body at Z=0)
```

**3. Slide-mount via a Rail (Lite) instead of a point:**

```
MultiBoard Tile (holes modeled, body #33-pending)
  → Rail                 multibuild_hole("multipoint_rail", length=<part-specific>)
  → project accessory    (the accessory carries the rail channel; slides on +X)
```

**4. Make a custom panel MultiBoard-compatible:**

```
custom project panel   (your own shape, sized to multibuild_grid_snap())
  → hole-stamp          multibuild_tile_holes(cols, rows, which)   (cut into the panel)
  → Snap                multibuild_mount("snap") / multibuild_hole("snap")   (via the large holes)
  → our project part    (union the mount onto another part; snaps into the now-Multihole panel)
```

`multibuild_tile_holes(cols, rows, which)` stamps the Multihole and/or Small
Hole pattern into a **project's own panel** — not the official Tile.
`which` = `"large"` (Multiholes only, for Snaps/Large Thread), `"small"`
(Small Holes only, for Peg-Click/Small Thread once #36/#35 exist), or
`"both"` (default). Once stamped, the panel accepts whatever connector this
library already models the board-facing half of — Snap today; Fix-Point
pockets/rails are themselves accessory-side (not board-side) negatives, so
they aren't part of this stamp.

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

## Compose recipe — make a project panel MultiBoard-compatible

To turn a project's own panel into something that accepts MultiBoard
connectors, instead of sourcing an official Tile:

```
project panel            your own shape (cube(), or any custom profile)
  - hole-stamp            multibuild_tile_holes(cols, rows, which)
  → difference() into a MultiBoard-compatible custom board
```

`cols`/`rows` set the stamped Multihole grid extent
(`multibuild_grid_points(cols, rows)`'s own centered-origin convention); the
Small-Hole sublattice (`multibuild_tile_small_points(cols, rows)`) rides
along at the same pitch, offset by `multibuild_small_hole_offset()`. `which`
picks `"large"` (Multiholes, for Snaps/Large Thread), `"small"` (Small
Holes, for Peg-Click/Small Thread — connector side deferred, #36/#35), or
`"both"` (default). The stamped panel is **not** the official Tile: no edge
profile, flange, or inter-tile joining feature is added — only the hole
pattern, so the panel's own footprint must be sized/centered to match
whatever `cols`/`rows` the stamp uses (e.g. via `multibuild_grid_snap()`).

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
