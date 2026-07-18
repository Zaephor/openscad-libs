# multibuild — MultiBoard mechanism + grid source log (Task 1)

Scope: Task 1 + Task 1b/1c evidence — comprehensive research log backing the
**checkpoint** (Step 4) and supporting the full implementation in
`multibuild.scad`. This file documents the complete evidence chain (grid pitch,
mount-type data, STL mesh measurement, Large Hole dimension) that validates
`multibuild_grid_pitch()` / `_multibuild_table()` and confirms the Regular Snap
mechanism fits this API shape.

Canonical frame (per `docs/LIBRARY-AUTHORING.md`): mount-feature
axis = Z; board mount surface at Z=0; consumer part body at +Z; grid `[x,y]`
lies in the Z=0 plane, centered in X/Y.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` fetched + read this pass (vendor/official docs or governing standard).
- `[B]` corroborated across >=2 independent peers.
- `[C]` single-sourced / derived, or a named standard cited but not fetched.
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

## Source reachability note

The MultiBuild marketing site (`multiboard.io`), the docs knowledge hub
(`docs.multibuild.io`), and Printables (`printables.com`) served full text
this pass. The parts library (`multiboard.io/parts-library/*`) and the
community forum (`community.multiboard.io`, `community.multibuild.io`), by
contrast, don't carry per-part numeric dimensions in the served page (see
Gaps). The "Common Connections" diagram is a flat web asset
(`docs.multibuild.io/assets/images/multiboard_common-connections-4b433970f396897c7f5d5432da71b3f1.png`,
2080x2500 PNG), carrying its content directly.

**Task 1b addendum:** a follow-up pass obtained a real Printables STL
(community MultiConnect connector, model 716558) and mesh-measured it — see
"STL mesh measurement (Task 1b)" below for the source, dims, and analysis.

## Sources fetched this pass

- `https://multiboard.io` — marketing home page. [A]
- `https://multiboard.io/multiboard` — MultiBoard product/FAQ page (grid
  pitch statement + HSW comparison FAQ). [A]
- `https://docs.multibuild.io/beginner-section/core-parts-documentation` —
  **the authoritative source for this pass**: full taxonomy of MU/CU units,
  Tile hole types, Snap variants, Thread variants, Peg Click, Mid Hole
  accessory attachment. Full text present. [A]
- `https://docs.multibuild.io/beginner-section/tile-mounting-guide` — tile
  assembly (Dual Snaps for temporary joining, Offset Pillars). [A]
- `https://docs.multibuild.io/beginner-section/printing-guidelines` —
  material/tolerance/print-orientation guidance (0.25mm design tolerance,
  ~45° max overhang, no supports, PLA). [A]
- `https://docs.multibuild.io/assets/images/multiboard_common-connections-
  4b433970f396897c7f5d5432da71b3f1.png` — "Multiboard Common Connections"
  diagram (10 assembly-exploded-view panels). [A]
- `https://www.printables.com/model/716558-multiconnect-generic-connector-
  for-multiboard` — community "generic connector" remix (validates the
  single-peg/no-locking-bolt simplification, see Checkpoint findings). [C]
- `https://www.printables.com/model/767851-multibolt-multiboard-bolt-
  connector-system` — community remix; corroborates 25mm hole pitch
  independently of the official docs ("distance between each pin in the
  multiboard is 25mm in both horizontal and vertical direction"), and
  documents its own hardware requirement (M2/M3 bolt + **nut installed in the
  back** — a captive-nut mechanism, but this is a non-official community
  workaround, not the MultiBoard-native mechanism; see Checkpoint findings).
  [C], used only as pitch corroboration ([B] cross-check for the pitch value).
- **(Task 1b)** `https://www.printables.com/model/716558-multiconnect-
  generic-connector-for-multiboard/files` — the model's file-listing
  sub-route; unlike the model-page-only fetch above, this pass found both
  routes carry the per-file STL download paths. [C]
- **(Task 1b)** `https://media.printables.com/media/prints/716558/stls/
  5712854_.../multiconnect-board-connectors_multiboard-snap-connector.stl` —
  the primary measured artifact (101,484 bytes). [C]
- **(Task 1b)** `https://media.printables.com/media/prints/716558/stls/
  5712855_.../multiconnect-board-connectors_multiboard-push-fit-connector.stl`
  — fetched for comparison, set aside as out of v1 scope (Mid-Hole-level
  accessory, not Large-Hole-level board attachment). [C]
- **(Task 1b)** `https://media.printables.com/media/prints/716558/pdfs/
  716558-...pdf` and `https://www.printables.com/model/1074671-multiconnect-
  generic-connector-for-your-multiboard` ("v2" successor model) — both
  chased looking for the description's referenced "dimension PDF"; both
  dead ends this pass (see Task 1b section). [C], not used as a dims source.
- **(Task 1b)** Four render PNGs from the 716558 model gallery
  (`multiconnect-top-down.png`, `-side-view.png`, `-connector-types-a/b.png`)
  — visual corroboration only (octagonal Large Hole, barbed multi-arm
  insertion visible in section view), not a numeric source. [C]
- **(Task 1c)** `https://www.printables.com/search/models?q=multiboard+tile`
  — server-rendered search results, used to locate a Tile model. [A] (page
  fetched and read this pass).
- **(Task 1c)** `https://www.printables.com/model/1277707-multiboard-8x8-
  tiles-corner-core-side` and its `/files` sub-route — "Multiboard 8x8 Tiles
  - Corner, Core, Side" by `blaise1092`, self-described as a repackaging of
  the official multiboard.io Tile meshes. [C].
- **(Task 1c)** `https://files.printables.com/media/prints/b6cd3834-ff54-
  41c4-b0d7-90fc274f5be1/stls/9609503_.../8x8multiboardtiles.3mf` — the
  primary measured artifact (40,137,169 bytes, BambuStudio project 3MF
  containing 3 mesh objects). [C]

## Not reachable this pass (dimensions not in the served page)

- `multiboard.io/parts-library/*` (Snaps/Threads/Tiles product pages —
  product dims not in the served page).
- `community.multiboard.io/*`, `community.multibuild.io/*` (forum, including
  the specifically-relevant "Hi all, new to multiboard... snap connectors too
  small" and "Dimensions for Multiboard" threads — thread bodies not in the
  served page).
- `thangs.com/*` (no STL/model file link in the served page).

The 25mm pitch and hole-type taxonomy are confirmed at [A] by the direct
`docs.multibuild.io` content above — see per-topic findings below.

## Per-topic findings

### Grid pitch — 25mm (MU)

**[A]** `docs.multibuild.io/beginner-section/core-parts-documentation`:
> Unit Types: **MU (Multi Unit)**: Based on **25 mm** sizing (Most MultiBoard
> parts). **CU (Cell Unit)**: Based on **50 mm** sizing (Most MultiBin parts).
> Conversion: 2x2 MU = 1x1 CU.
> MultiBoard Tiles are multi-use boards that are based on a 25 mm grid (MU).

Also **[A]** `multiboard.io/multiboard`: "MultiBoard is a revolutionary,
adaptable board system that is based on the **25 mm** global standard."

**[B] corroboration** (independent community source, `printables.com/model/
767851-multibolt...`): "the distance between each pin in the multiboard is
**25mm** in both horizontal and vertical directions."

**Not tile-pitch-vs-hole-pitch conflated**: both hole families are
independently confirmed at the same 25mm repeat (official-doc phrasing,
corroborating the core-parts-documentation page):
"The Pegboard Holes (small holes) are **25 mm apart**... The Multiholes (big
holes) are **25 mm apart**." Tile *sizing* is also in whole-MU units (e.g. an
"8x8 MU" tile = 200x200mm). One `multibuild_grid_pitch() = 25` (mm) covers
both the hole lattice and the tile-sizing lattice — **no conflation found**.

MultiBin uses a *different* unit (CU = 50mm = 2x2 MU) — out of v1 scope
(board-only, per the plan's non-goals) but noted so a future MultiBin slice
doesn't silently reuse `multibuild_grid_pitch()` for CU-based sizing.

**Open detail (not a pitch-value problem, deferred to Task 2):** the exact
relative offset between the Small-Hole lattice and the Large-Hole lattice
within one 25mm cell (do they coincide, alternate, or run on parallel
sub-positions?) was not resolved this pass — the "Common Connections" diagram
shows both hole sizes on the same Tile icon but at diagram scale, not
dimensioned. Does not change `multibuild_grid_pitch()`'s value, only how
Task 2's `multibuild_grid_points()` would need a per-hole-type offset if a
consumer wants to place mixed small/large mounts precisely.

### Board hole profile — two independent hole families, both threaded

**[A]** `docs.multibuild.io/beginner-section/core-parts-documentation`,
section 1.1 "Hole Types":
> 1.1.1 **Small Holes**: Compatible with Peg Click Hooks, Small Threads, and
> non-3D-printed pegboard accessories.
> 1.1.2 **Large Holes (Multiholes)**: Compatible with Snaps and Large Threads.
>
> All holes on the Tiles are **threaded** and are compatible with a wide
> range of connection types.

"Threaded" here means the printed hole itself carries a printed internal
thread (self-tapping into the plastic bore) that a matching externally-
threaded bolt/insert screws into directly — **not** a captive nut or heat-set
insert. Confirmed by the Thread family below, which screws directly into
Small/Large Holes with no third part.

**Gap — no literal mm diameter/depth found this pass.** Neither
`docs.multibuild.io` nor the marketing site publish a numeric Small-Hole /
Large-Hole diameter or depth in the reachable content. The parts-library
pages (which likely carry per-part STEP/STL downloads with dimensioned
previews) don't carry those dimensions in the served page this pass (see "Not
reachable this pass" above), and the community forum threads that directly
discuss hole/connector fit ("snap connectors are too small for the board
holes") are likewise not in the served page. **Recorded as not-yet-covered
per `docs/LIBRARY-AUTHORING.md` gap handling — no diameter or depth value is
fabricated here.** Task 2 should either (a) mesh-measure an official
Snap/Tile STL (needs a reachable direct download URL — not found this pass)
or a validated community remix explicitly built to the official hole spec, or
(b) recover the dimensions from the parts-library/community-forum pages, whose
content isn't in the served page this pass.

### Mechanism — Snap (primary, board-to-accessory) + Thread (secondary) + Peg Click (2-hole, out of v1 scope)

**[A]** `docs.multibuild.io/beginner-section/core-parts-documentation`,
sections 2-5, and the "Common Connections" diagram (fetched PNG, 10 exploded-
view panels):

1. **Snaps** — "snap into the Large Holes of the MultiBoard Tiles and have a
   Mid Hole for attaching accessories."
   - **Regular**: "Clicks into place and is **completely symmetrical**." —
     straight push-fit, no rotation/angle needed.
   - **Moderate Weight Bearing**: "Holds a lot of weight in ONE direction...
     **most commonly used**... **must be inserted at an angle**."
   - **Heavy Weight Bearing**: more weight, offset-tiles only, also inserted
     at an angle.
   - **Double-Sided (DS) Snaps**: **two parts** (Part A usually at the back
     of the tile, Part B usually at the front) that snap together **on
     opposite sides of the Tile**, sandwiching it — used for temporary
     tile-to-tile joining and freestanding/two-sided tiles, not the general
     single-accessory-to-tile case.
   - Every Snap has a **Mid Hole** for attaching accessories, which itself
     takes 3 further connection types: Bolt-Locked Inserts (needs a separate
     "Locking Bolt" — a third part), Friction-Fit Inserts (2-piece, no
     locking bolt), Mid Threads (screws directly into the Mid Hole).

2. **Threads** — "great for attaching any remix accessory to the MultiBoard
   Tiles by simply adding a hole into the accessory." Three families: **Small
   Thread** (screws into Small Holes), **Mid Thread** (screws into a Snap's
   Mid Hole), **Large Thread** (screws into Large/Multiholes). All are a
   single externally-threaded bolt screwing directly into a printed
   internally-threaded hole — 2-piece, no captive nut.

3. **Peg Click** — "connects to **two** Small Holes on the MultiBoard
   Tiles, just like a pegboard accessory." A single accessory (e.g. the "Peg
   Click Hook" in the Common Connections diagram) engages **two** grid points
   at once, not one.

The Common Connections diagram (`Peg to Tile`, `Small Shelf to Tile`,
`Bracket to Tile` panels) shows the *official, full* accessory-attach chain
as: **Tile → Snap (plugs into a Large Hole) → Locking Bolt → Bolt-Locked
Insert (the actual hook/shelf/bracket)** — i.e. attaching a *shaped*
accessory (not just a Snap by itself) to the board is officially a **3-part**
chain (Tile hole, Snap, Locking-Bolt-secured insert), not 2-part. `Peg to
Tile` and `Bracket to Tile` both label a "Locking Bolt" between the Snap and
the functional part.

MultiBin-side connections (`Rail Click Connector`, `Small Thread
Lite/Multipoint`, `Bar Clip`) shown in the same diagram are a different
part family entirely (CU-based, out of v1 scope).

### Print/material context (not a dimension, but relevant to the "support-free" global constraint)

**[A]** `docs.multibuild.io/beginner-section/printing-guidelines`: "Most
parts are designed with a tolerance of **0.25 mm** and to be as close to
**45 degrees** as possible (sometimes 50 and 60 degrees)... no supports...
Nozzle Size: 0.4 mm. Material: Matte PLA." Confirms MultiBoard's own parts are
designed to the same support-free, ~45°-max-overhang discipline as this
repo's `feedback_no_supports` constraint — corroborating (not contradicting)
the plan's support-free requirement for whatever v1 models.

## Gaps (values NOT found this pass — recorded per gap-handling policy, not fabricated)

Updated after the Task 1b STL mesh-measurement pass (see "STL mesh
measurement (Task 1b)" above) — some Snap-side gaps are now resolved at
`[C]//VERIFY` (mesh-measured, single community source); the Large-Hole
cavity itself remains genuinely unresolved.

- **RESOLVED at `[C]//VERIFY` (STL-measured) — Snap connector envelope and
  mechanism geometry**: overall 24.0 x 24.0 x 12.8mm; 4-arm compliant
  cantilever-snap mechanism (not a single round peg), arm width 3.0mm, tip
  flare radius 11.05mm (~22.1mm tip-to-tip), engagement/flex length ~8.6mm,
  cap/flange ~24x24 x 4.2mm tall, Mid Hole boss ~4mm sq / ~2mm hole. See
  Task 1b section for the full breakdown and the important caveat that this
  is a 4-arm mechanism, not a simple cylinder — a modeling-approximation
  decision Task 2 still needs to make explicitly.
- **RESOLVED at `[C]` (STL-measured, Task 1c) — Large Hole (Multihole)
  diameter/depth**: not found in reachable official content (still true),
  but **now directly measured** from a real Tile STL (see "Large Hole
  dimension (Task 1c)" below) rather than only bounded. Round, ~22.1-22.3mm
  diameter at the narrow waist, 6.4mm tile thickness, waisted/hourglass
  through-hole profile with a flared lead-in chamfer at both faces. **Not
  octagonal** — supersedes Task 1b's visual-only octagonal read (see Task 1c
  section for the correction and why). This was the single remaining hard
  blocker for populating `_multibuild_table()`'s hole-side dims; both the
  Snap/peg side (Task 1b) and the Tile/hole side (Task 1c) now have
  `[C]`-tier measured numbers.
- **STILL OPEN — Small Hole diameter/depth** — not found in reachable
  official content, and out of scope for the Task 1b STL pass (that STL is
  the Large-Hole-side Snap connector only). Not-yet-covered.
- **Dimension PDF / STEP files referenced by the community model's own
  description ("look into the provided dimension PDF... There are also STEP
  files")** — chased this pass and found to be a dead end: no separate PDF
  asset exists in the model's file listing beyond Printables' own auto-
  generated (non-dimensioned) summary PDF, and the STEP files, while
  present, need a CAD kernel this repo's toolchain doesn't have to parse.
  Not-yet-covered; flagged in case a future pass gains STEP-parsing
  capability or finds the dimension PDF hosted elsewhere.
- **Thread pitch/profile** (Small/Mid/Large/Big Thread — these are described
  by the community as a proprietary profile, not a strict ISO M-size,
  though "Big Thread" is reported informally to line up with M3 hardware in
  practice) — no official numeric thread spec found; a community forum post
  ("Thread sizes") explicitly asks Multiboard staff for these and the
  question is open. Not-yet-covered, and not needed for the Checkpoint
  decision below (v1 does not model Threads — see Checkpoint findings).
- **Small-vs-Large hole relative grid offset within a cell** — see the "Open
  detail" note under Grid pitch above.

No value in this file was invented without at least a named-source citation
or a fetched-and-read/measured artifact backing it. Where no source was
reachable, the value is omitted, not guessed.

## STL mesh measurement (Task 1b)

Scope: resolve the Task 1 "missing literal hole/connector mm dimensions" gap
(see Gaps above) by obtaining a real STL of the community "MultiConnect"
connector (Printables 716558, already identified in Task 1 as implementing
the exact Regular-Snap-into-Large-Hole simplification v1 models) and mesh-
measuring it.

### Fetch

- `https://www.printables.com/model/716558-multiconnect-generic-connector-
  for-multiboard` and its `/files` sub-route — the per-file STL metadata
  (folder-hash paths, `filesCount: 42`) is present in the served page. `[A]`
- The STL files are served under
  `https://media.printables.com/media/prints/<print_id>/stls/<numeric-id>_
  <uuid>_<uuid>/<slug-filename>.stl` (also mirrored at `files.printables.com`
  at the same path).
- Of the 21 distinct connector STLs listed on `/files` (`multiboard-snap-
  connector`, `-push-fit-connector`, `-mid-thread-connector[-for-multitool]`,
  `-big-thread-connector[-for-multitool]`, `-small-thread-connector[-for-
  multitool]`, `-*-screw-connector[-for-multitool]` variants, `-small-hole-
  pressure-push-*`), the model's own description text says explicitly: **"The
  snap connector when you just want
  to push in the connector"** vs. **"The push fit connector when you want to
  just push in + have some snap attached already"** — i.e. `-snap-connector`
  is the one that plugs directly into a Tile's Large Hole (the v1-modeled
  primitive); `-push-fit-connector` plugs into an *already-installed Snap's
  Mid Hole* (a second-level, out-of-v1-scope connection per the Checkpoint
  below). **`multiboard-snap-connector.stl` was taken as the primary
  target** (101,484 bytes, binary STL, "Made with Shapr3D" header, at the
  path above). `[C]` (single community source, not official multiboard.io).
- The model description also references **"the provided dimension PDF"** for
  exact numeric dims, and separate **STEP files** ("just the connector head").
  Both are a **dead end this pass**: the only `.pdf` asset in the `/files`
  listing is Printables' own auto-generated model-summary PDF
  (`media/prints/716558/pdfs/*.pdf`, 8 pages) — on inspection **just the model
  page's text/images reflowed to PDF, not a dimensioned drawing**. The
  "dimension PDF" the author refers to in prose has no link in the description
  (checked on both this model and its "v2" successor,
  Printables 1074671) and isn't a separate file in the `/files` listing under
  any of the four folder types actually present (`images/`, `pdfs/`,
  `previews/`, `stls/`) — it appears to be either stale prose (referring to a
  since-removed attachment) or a resource hosted off-Printables that wasn't
  located this pass. STEP files exist (`Connector.step`, `Lock.step`,
  `Plug.step`, etc., named in the STL-sibling `.step` list) but parsing STEP
  geometry needs a CAD kernel this repo's toolchain doesn't have — not
  attempted.
- Four render/marketing PNGs from the model gallery (`multiconnect-top-down.png`,
  `-side-view.png`, `-connector-types-a/b.png`) were also examined for **visual corroboration
  only** (not measurement): the top-down render confirms MultiBoard's Large
  Hole is **octagonal** (not round) in this honeycomb-panel product shot, and
  the side/section render shows multiple connectors seated with a wide flange
  proud above the panel, a body through the panel thickness, and a visible
  barb/flare at the underside tip — consistent with the mesh-derived geometry
  below. `[C]`, visual-only, not a source of numeric dims.

### Method

The STL was mesh-measured directly, per-Z-band rather than by a single
overall bounding box — the overall bbox alone (24.0 x 24.0 x 12.8mm) was
**not sufficient to distinguish a simple round peg from the actual
mechanism** — see findings below.

### Findings — `multiboard-snap-connector.stl`

**[C]//VERIFY — single community STL, not an official multiboard.io source,
but directly mesh-measured (not estimated).**

- **Overall envelope: 24.0 x 24.0 x 12.8mm** (X x Y x Z bounding box).
- **The engagement feature is NOT a single round peg** — this is a
  correction/refinement to the plan's implicit assumption, found by cross-
  sectioning rather than trusting the bbox alone. It is **4 flexible
  cantilever arms** at 90 deg spacing (N/S/E/W), confirmed by coordinate-
  cluster analysis at the tip band (distinct point clusters at
  `(+-11.0, +-1.5)` and `(+-1.5, +-11.0)`, not a ring):
  - Each arm is **3.0mm wide** (tangential dimension, constant along most of
    the arm's length).
  - Each arm's **tip (barb) flares to a max radius of 11.05mm** from part
    center (so opposite-arm tip-to-tip span is approximately **22.1mm**) —
    this flare is localized to the free end (z = 0.2-1.6mm from the tip,
    i.e. the last ~1.4mm of arm length).
  - For most of the arm's length (z ~ 2.4mm to ~8.8mm, i.e. away from the
    flared tip), the arm's outer surface sits within about 3mm of part
    center — i.e. the **undeflected passage profile is much narrower than
    the flared tip**, consistent with a compliant snap-fit: the arms are
    compressed inward to pass through a hole, then spring the tip back out
    to its ~22mm-span rest state to catch the underside once through.
  - **Engagement (flex-arm) length is approximately 8.6mm** (from the tip at
    z=0.2 to where the arms merge into the underside of the cap/flange at
    z~8.8).
- **Cap/flange (the part that stays proud at +Z, matching the plan's
  consumer-body datum): approximately 24 x 24mm outer footprint** (rounded/
  lobed, not a plain square — matches the octagonal-hole product-shot
  corroboration above), **approximately 4.2mm tall** (z 8.8 to 13.0).
  - A **central "Mid Hole" boss sits at the very top** of the cap (z ~
    12.0-13.0): roughly 4mm square outer, with a roughly 2mm through-hole.
    This is a good cross-validation against Task 1's `[A]` official-doc
    finding ("Every Snap has a Mid Hole for attaching accessories") — the
    STL's own top-center feature matches that description structurally, even
    though this specific community remix skips the official Locking-Bolt/
    Insert layer for its *own* board attachment.
- Mesh sanity: 2028 facets, reported (possibly-approximate, mesh may not be
  perfectly watertight) enclosed volume ~4513 mm3 for the whole part —
  plausible for a ~24x24x12.8mm envelope at roughly 61% fill fraction (hollow
  Mid Hole, open arm slots, thin flange).

### Findings — Large Hole (board-side cavity): still NOT directly measurable

This STL contains **only the connector**, not the Tile/board it plugs into —
per the task's own anticipated outcome, the hole dimension **remains a
derived estimate, not a direct measurement**, and is reported honestly as
bounded rather than as a single fabricated number:

- **Floor on hole size (must be at least this big to insert):** the arms'
  undeflected mid-shaft profile stays within ~3mm of center for most of
  their length — so the hole must be at least wide enough to admit that
  folded/compressed bundle during insertion (a few mm across). This is a
  floor derived from the insertion profile, not a spec value.
- **Ceiling on hole size (must be smaller than this or retention fails):**
  the tip's relaxed flare spans ~22.1mm tip-to-tip — if the Large Hole were
  this size or larger, the arms would never catch the underside. So the real
  hole opening is somewhere **between the compressed-insertion floor and the
  ~22mm retention ceiling**, most plausibly much closer to the small end
  (typical pegboard/printed-snap Large Holes are commonly a few mm to ~1cm,
  not centimeters wide) — but **no literal number is recoverable from this
  STL alone**, and none is asserted here. The top-down render (visual-only,
  see Fetch above) additionally shows the Large Hole is **octagonal**, not
  round, which the connector's round/lobed cap covers from above but doesn't
  itself resolve to a dimension.
- **This is a materially different picture than a naive "round peg into
  round hole" read of Task 1's `[A]` doc text** ("Regular Snap... clicks into
  place... completely symmetrical"). The *symmetry* claim still holds (this
  is a 4-fold-symmetric, straight -Z insertion, no angle needed, matching
  Q3 of the Task 1 Checkpoint) — but the actual geometry is a multi-arm
  compliant snap-fit, not a solid round post. **This is new information
  Task 2 needs when deciding how literally to model `multibuild_mount
  ("snap")`/`multibuild_hole("snap")`**: a geometrically faithful model would
  need 4 arms and a flare, not a single cylinder+bore pair; a simplified
  round-peg/round-hole approximation (e.g. using the tip-envelope diameter,
  or the flange OD, as a stand-in) is still a defensible v1 simplification
  given the plan's one-hole-per-type cardinality, but it would be an
  explicit, documented approximation of a shape that is not itself round —
  not a report of a round hole that was directly measured. This document
  does not make that modeling-approximation call; it is Task 2's decision to
  make with these numbers in hand.

### `multiboard-push-fit-connector.stl` (fetched, set aside)

Also fetched (79,884 bytes) for a first look, then **set aside as out of
v1 scope** once the model's own description was read: this variant plugs
into an *already-installed Snap's Mid Hole*, not directly into the Tile's
Large Hole ("The push fit connector when you want to just push in + have
some snap attached already") — a second-level connection, same category as
the official Locking-Bolt/Insert layer Task 1's Checkpoint already scoped
out. Partial measurement (bbox 20.0 x 20.0 x 12.4mm, and a similar-family
flared-foot + central round-post structure at the tip) is consistent with
the same design language as the Snap connector but was **not fully reverse-
engineered** — not needed for the v1 mechanism and would be redundant effort.

## Checkpoint findings (plan Task 1, Step 4)

Re-checked against the Task 2-5 assumed API (`multibuild_grid_pitch()`,
`multibuild_mount(type)` / `multibuild_hole(type)` two-piece positive/
negative, insertion "-Z into the board, body at +Z").

**Q1 — single `multibuild_grid_pitch()`, not tile-pitch-vs-hole-pitch
conflated?** **PASS.** 25mm (MU) is confirmed, at [A] tier, as the repeat
distance for *both* Small-Hole and Large-Hole lattices independently, and as
the tile-sizing unit (tiles are sized in whole MU). MultiBin's separate 50mm
CU unit is out of v1 scope and doesn't leak into the board-only pitch value.

**Q2 — mechanism decomposes into a 2-piece positive (`multibuild_mount`) /
negative (`multibuild_hole`) pair, no third part?** **PASS, with an explicit
v1 scope decision** (see "Which mechanism v1 models" below). The *full
official* accessory-attach chain (Tile → Snap → Locking Bolt → Insert) is
genuinely 3-part for shaped accessories, and Peg Click is a 2-hole-per-
instance mechanism — both would break the plan's 2-role, one-hole-per-type
model if adopted directly. But the **Snap's own board-engagement feature is
itself a clean, official, 2-piece press-fit** (Regular Snap plugs directly
into one Large Hole, no third part) — the same primitive a validated
community project ("MultiConnect — generic connector for multiboard",
Printables 716558) uses directly as a single connector, skipping the
official Locking-Bolt/Insert layer entirely, for exactly this "attach my own
part to the board" use case. **v1 models this primitive** (see below), which
keeps Q2 a clean pass. The 3-part official accessory chain and Peg Click's
2-hole mechanism are explicitly **out of v1 scope** (see non-goals note
below), not force-fit into the 2-role API.

**Q3 — "mount plugs in -Z, part body +Z" matches the real insertion
direction?** **PASS for the chosen mechanism.** The Regular Snap variant
"clicks into place" straight-on (no rotation/angle needed), matching a
static Z-axis plug/retention model: the engagement feature sits behind/within
the board thickness (-Z from the mount face) while the body (where a
consumer's part continues, or where the Mid Hole/accessory face sits) stays
proud at +Z. The Moderate/Heavy Weight-Bearing Snap variants explicitly
**require an angled insertion motion** ("must be inserted at an angle") —
this is real, but it is an *assembly-motion* detail (how you get the part
into the hole), not a mismatch in the *static seated geometry* the plan's
axis datum describes; v1 sidesteps it anyway by choosing the Regular variant
specifically because it doesn't need an angled insertion. Threads are also
Z-axis (screwed straight in) and would equally satisfy Q3 if added later.

### Which mechanism v1 models: Regular Snap → Large Hole (not Threads, not Peg Click)

- **Regular Snap** (positive) plugging into a **Large Hole** (negative) is
  the v1-modeled mechanism: symmetric, straight -Z insertion, genuinely
  2-piece, official, and precedented by a community "generic connector"
  remix that does exactly this simplification. It is the best fit for the
  plan's assumed API shape of all the mechanisms found.
- **Threads** are not modeled in v1 despite also being Z-axis/2-piece,
  because (a) no thread pitch/profile spec was found this pass (Gaps above),
  and (b) this repo has no existing helical-thread-modeling utility
  (`grep`-confirmed: no `BOSL`/`metric_thread`/similar in any `.scad` file),
  so a geometrically honest thread-mating pair is out of reach without a
  separate, larger effort. A future slice could add a `"thread"` mount type
  once (a) and (b) are resolved; `multibuild_known_mounts()` is designed to
  grow.
- **Peg Click** (2-hole-per-instance) is explicitly **out of v1 scope** —
  it doesn't fit the one-hole-per-`type` cardinality `multibuild_hole_dia
  (type)`/`multibuild_hole_depth(type)` assume. A future slice could add it
  as a distinct accessor shape (e.g. returning two hole offsets), not by
  overloading the existing single-hole accessors.
- **DS Snaps** and the **Mid-Hole/Locking-Bolt/Insert accessory-attach
  layer** are also out of v1 scope — the former is a tile-to-tile joining
  mechanism, the latter is a second-level (Snap-to-accessory) connection,
  neither is "how does a project's part attach to the board" (the v1 goal).

**Checkpoint: API confirmed, proceeding as planned** — with the mechanism
choice (Regular Snap / Large Hole) and the scope exclusions above now
explicit for Task 2-5 to transcribe against.

**Update (Task 1b, post-checkpoint):** the STL mesh-measurement pass (see
"STL mesh measurement (Task 1b)" above) resolved the **Snap/connector-side**
half of the "missing literal mm dimensions" blocker at `[C]//VERIFY` tier —
real measured numbers now exist for the connector's envelope, its 4-arm
engagement mechanism, arm width/flare/engagement-length, and the cap/Mid-Hole
boss. It also surfaced a genuinely new finding Task 2 must account for: the
real mechanism is a 4-arm compliant snap, not a single round peg, so
Task 2's `multibuild_mount("snap")` will need to either model that shape
faithfully or make an explicit, documented round-peg approximation — this
file does not make that call. The **Large Hole (board-side cavity) dimension
is still not resolved** — it wasn't in the fetched STL (connector-only) and
remains bounded only loosely (a few mm floor from the insertion profile, a
~22mm ceiling from the tip-flare retention requirement, confirmed octagonal
not round from a corroborating render) rather than given a literal number.
Task 2 can now proceed with the Snap-side numbers in hand, but still cannot
populate the hole-side dims in `_multibuild_table()` without either (a) a
reachable dimensioned Tile source (a parts-library source or a physical
caliper reading), or (b) a spec-faithful Tile STL
(with the Large Hole modeled) to mesh-measure — this remains a real,
narrower-than-before gap to surface to the user before Task 2 starts, per
the "no fabricated dims" constraint.

**Update (Task 1c): Large Hole is now RESOLVED at `[C]` — see "Large Hole
dimension (Task 1c)" below.** A Tile STL (packaged as `.3mf`, containing the
actual Multiboard.io-authored mesh per its own embedded copyright metadata)
was found, fetched, and directly mesh-measured. Headline results: the Large
Hole's main bore is **round** (diameter ~22.1-22.3mm), **not octagonal** —
this corrects Task 1b's visual-only `[C]` "octagonal" read, which is now
understood to have been the connector's own lobed cap/flange shape seen from
above, not the hole boundary. The hole is a **waisted (hourglass) through-hole**,
narrowest at mid-thickness (matching the connector's 11.05mm tip-flare radius
almost exactly — a clean snap-fit cross-validation against the Task 1b
connector numbers) and flared wider at both faces as a lead-in chamfer. Tile
thickness measured at 6.4mm, and the 25mm grid pitch was independently
re-confirmed from the mesh's own hole-center spacing. Task 2 can now populate
`_multibuild_table()`'s hole-side dims.

## Large Hole dimension (Task 1c)

Scope: resolve the one remaining hard blocker flagged at the end of Task 1b
— the Large Hole (board-side cavity) shape and dimensions — by finding and
mesh-measuring a real Tile STL, per the same technique as Task 1b applied to
the board instead of the connector.

### Path taken: 1 (Tile STL found and mesh-measured) — paths 2 and 3 not needed

Path 1 (find + mesh-measure a Tile STL) succeeded, so the fallback paths
(pixel-measuring the "Common Connections" diagram, or a GitHub/Thangs dims
search) were not attempted this pass.

### Fetch

- Searched Printables (`https://www.printables.com/search/models?q=multiboard+tile`)
  for a Tile model. The search results page carries real `/model/<id>-<slug>`
  links — 72 model links found. `[A]` (page fetched and read this pass).
- Selected `https://www.printables.com/model/1277707-multiboard-8x8-tiles-corner-core-side`
  ("Multiboard 8x8 Tiles - Corner, Core, Side" by `blaise1092`) as the
  primary candidate: its `og:description` reads **"8x8 Multiboard Tiles
  because the Multiboard.IO library is a pain to navigate. Credit to
  Multiboard.IO for the model"** — i.e. the uploader's own description claims
  this is a repackaging of the *actual* official multiboard.io Tile meshes,
  not an independent remix. This claim is corroborated by the file's own
  embedded metadata (see Method below): the packaged 3MF's `<metadata
  name="CopyRight">` field is `[{"link":"https://www.multiboard.io/",
  "author":"https://www.multiboard.io/","title":"https://www.multiboard.io/"}]`
  and `Origin` is `"remix"` with `Designer` `blaise1092` — consistent with
  "reuploaded/repackaged official geometry," not scratch-modeled. Treated as
  `[C]` (community reupload, not fetched directly from multiboard.io), but a
  materially stronger `[C]` than an arbitrary remix given this self-reported,
  internally-consistent provenance trail.
- The measured artifact is `8x8multiboardtiles.3mf`
  (`https://files.printables.com/media/prints/b6cd3834-ff54-41c4-b0d7-90fc274f5be1/stls/9609503_0866098a-0c03-4141-9983-47afa29a8283_a35dea36-1d26-4001-833d-1489d1b7d3d4/8x8multiboardtiles.3mf`),
  40,137,169 bytes, a Zip archive (3MF is a zipped XML mesh format, not a
  binary/ASCII STL). `[C]`.
- The model's `/files` page lists exactly 2 file entries, both named
  `8x8+Multiboard+Tiles.3mf` (same `fileSize`, likely a duplicate
  upload/order artifact) — only one was used.

### Method

The 3MF (a zipped XML mesh format) is a **BambuStudio project archive**
containing **3 separate mesh objects** (`object_1/2/3.model` — the "Corner",
"Core", "Side" tile pieces named in the model title; exact correspondence not
determined and not needed), with the root model's `<metadata name="CopyRight">`
carrying the multiboard.io attribution quoted above. Hole geometry was fully
recoverable from vertex positions alone.

Each hole was mesh-measured directly: hole centers located from a
mid-thickness Z-band, each hole's radial profile measured, and the
through-thickness profile established by cross-Z-band scans. A round-vs-faceted
test (fitting radial amplitude per candidate facet count `n`) distinguished a
round bore from a regular polygon — a regular n-gon shows a dominant amplitude
at its own `n`, a round hole shows only small mesh-tessellation noise across
all `n`. The measurement was repeated independently on **two different mesh
objects** (`object_1.model` and `object_3.model`) as a cross-check.

### Findings

**`[C]` — community-repackaged file, self-reporting official multiboard.io
origin via embedded copyright metadata (see Fetch above); directly
mesh-measured, not estimated. Two independent object meshes within the same
file agree to 3 decimal places, which is strong internal consistency but
still a single external source overall (both objects come from the same
upload/author) — recorded as `[C]`, not upgraded to `[B]`, since no second,
independently-authored Tile source was found this pass.**

- **Tile/panel thickness: 6.4mm** (bounding-box Z-extent exactly `±3.20006561`
  / `±3.20005798` in the two objects measured — i.e. **6.40mm total**,
  agreeing to 4 significant figures across both pieces). This is a new data
  point beyond the original scope of this task, useful for Task 2's
  `_multibuild_table()` board-thickness/consumer-datum assumptions.
- **Large Hole cross-section: ROUND, not octagonal or faceted.** Fourier
  facet-fit amplitudes across both measured holes and both object files were
  all small and did not peak at `n=8`: e.g. object_1's hole at (8.97,8.97)
  gave amplitudes `n=3: 0.128mm, n=4: 0.120mm, n=6: 0.060mm, n=8: 0.033mm,
  n=12: 0.019mm` (`n=8` — the octagon hypothesis — has the *smallest*
  amplitude of the set tested, i.e. the *least* octagonal signal, not the
  most). object_3's hole at (-87.5,-87.5) gave a similar pattern (`n=8:
  0.053mm` vs. mean radius 11.08mm — under 0.5%). **This corrects/supersedes
  Task 1b's `[C]` visual-only finding** ("the top-down render confirms
  MultiBoard's Large Hole is octagonal, not round") — that render most
  likely showed the *connector's own lobed/rounded-square cap/flange*
  (Task 1b measured this cap as "approximately 24 x 24mm outer footprint
  (rounded/lobed, not a plain square)") seen from above sitting in the hole,
  not the hole boundary itself. This directly-measured mesh geometry is a
  stronger source than a product-shot visual read and should be treated as
  the current-best answer to the round-vs-octagonal question.
- **Large Hole diameter (narrow waist / main bore): ~22.1-22.3mm**
  (radius mean 11.10-11.13mm across 4 holes measured in object_1 and 2 holes
  in object_3, std ~0.18-0.23mm — consistent across every hole checked,
  in both objects). **This is strikingly close to Task 1b's independently
  mesh-measured connector tip-flare radius of 11.05mm** (relaxed,
  tip-to-tip ~22.1mm) — the hole's main bore and the connector's relaxed tip
  flare are essentially the same size, with only ~0.05-0.1mm per-side margin.
  This is a strong physical cross-validation between the two independently
  fetched/measured artifacts (a community connector STL and a community Tile
  3MF, from different Printables uploads by different authors), and it
  resolves the geometric puzzle Task 1b left open (how does a 4-arm snap with
  an ~11mm-radius relaxed tip pass through and then retain in a hole of
  about the same size?) — answered by the next finding.
- **The hole is a waisted/hourglass through-hole, not a constant-diameter
  cylinder**: cross-sectioning by Z showed the ~11.1mm-radius bore holds
  essentially constant from about `z=-2.4` to `z=+2.4` (a ~4.8mm-tall
  "waist" centered on the panel's mid-thickness), but **both faces flare
  outward beyond that** — at the very top and bottom Z-bands (`|z|` in
  `[2.4, 3.2]`, i.e. the outer ~0.8mm at each face), the *nearest* vertex to
  the hole center jumps to **r >= 12.49mm (object_1) / r >= 12.66mm
  (object_3)**, i.e. **diameter >= ~25.0-25.3mm at the mouth** — a lead-in
  chamfer/flare at both the entry and exit faces. This explains the
  connector mechanism cleanly: the arms' relaxed tip flare (~11.05mm radius)
  is *slightly larger* than the hole's narrow waist (~11.1mm radius is only
  marginally bigger, essentially a snug/interference fit at the neck) but
  *smaller* than both flared mouths (>=12.5mm radius) — so the tips compress
  slightly to pass the neck on insertion, then re-expand into the flared far
  mouth once through, catching against the underside for retention (the
  actual "snap"), matching the "compliant snap-fit" mechanism description
  from Task 1b's connector geometry and the official docs' "clicks into
  place" language.
- **Grid pitch re-confirmed geometrically at 25mm**, independent of the
  official-docs `[A]` citation in the Grid pitch section above: hole centers
  in object_1 were found at x/y positions differing by exactly 25.00mm (e.g.
  `-41.03, -16.03, 8.97, 33.93, 58.84, 83.93`, and `-91.16` — all consecutive
  differences within measurement noise of 25.00mm), and in object_3 at exact
  multiples of 25mm from a `-87.5` origin (`-87.5, -62.5, -37.5, ...,
  +87.5` — 8 hole positions per edge). **Bonus finding**: object_3's holes
  are inset **12.5mm from the tile's outer edge** (edge at ±100mm, first hole
  row/column at ±87.5mm) — i.e. holes sit at half-a-grid-cell inset from the
  panel boundary, a useful detail for Task 2/5 if a consumer wants an
  edge-to-first-hole margin, though not part of the plan's required API
  surface.

### What this resolves vs. what remains open

- **Large Hole diameter, depth/profile, and shape: RESOLVED at `[C]`.**
  Task 2 can populate `_multibuild_table()`'s hole-side dims. The
  recommended values: **diameter ~22.2mm** (round), through the full
  **6.4mm** tile thickness, with the caveat that the true geometry is
  waisted/chamfered (narrower mid-thickness, flared at both mouths) rather
  than a constant-diameter cylinder — a straight-cylinder approximation at
  the ~22.2mm waist diameter is a defensible, documented v1 simplification
  (same category of approximation Task 1b already flagged for the connector's
  4-arm mechanism), not a literal re-report of a simple round hole.
- **Small Hole dimensions**: out of scope for this task (Task 1c was
  Large-Hole-only per the brief) and not measured this pass, even though the
  same Tile mesh almost certainly contains Small Holes too (the "Common
  Connections" taxonomy places both hole families on every Tile) — remains
  **not-yet-covered**, flagged for a future pass if Small Holes enter v1
  scope.
- **Whether this specific 3MF's geometry is bit-for-bit identical to the
  current official multiboard.io Tile files**: not verified against an
  official source directly (still not reachable this pass, per Task 1's
  source-reachability finding) — the `[C]` tier reflects that residual
  uncertainty.
  The internal consistency (two independently-meshed tile pieces agreeing to
  3 decimal places, plus the cross-validation against the independently
  measured connector) makes fabrication or gross remix-drift unlikely, but
  this is corroboration, not an official-source confirmation.

## MultiBin + Fix-Point (#32)

Scope: source log for the MultiBin container family (the 50mm-CU bin grid,
distinct from the 25mm-MU board grid documented above) and the Fix-Point
(formerly "Multipoint") accessory-side receiving negative. Populates the
container + Fix-Point data Tasks 2/3 implement. **All values here are
caliper-upgradeable** — the STL-mesh (`[C]`) numbers are the first-pass
targets for a physical-measurement upgrade (backlog #16).

Sources this section:
- `https://docs.multibuild.io/beginner-section/core-parts-documentation` —
  MU/CU unit definitions, Fix-Point/Multipoint taxonomy + rename note. `[A]`
- `https://docs.multibuild.io/beginner-section/printing-guidelines` — 0.25mm
  design tolerance. `[A]`
- Official **MultiBuild** part models (vendor-authored dimension text +
  mesh-measured geometry), by model ID:
  - `1128566` — 4x4 CU Micro Multibin Shell.
  - `1127745` — 2x2x2.5 CU Multipoint-Rail Multibin Shell.
  - `974135` — 3x2x1.5 CU Simple Walls Multibin Shell.
  - `974493` — 2x2x0.5 CU Simple Walls Multibin Shell.
  - `1142254` — Multipoint Rails (Positive + Negative remixing set): parts
    `Multipoint Rail - Positive`, `Multipoint Rail Slot - Negative`,
    `Lite Multipoint Rail - Positive`, `Lite Multipoint Rail - Negative`.
  - Vendor dimension text for further Simple Walls sizes (`974309` 4x2x1,
    `2x3x2`, `3x1x2.5`, `3x2x4`, `1128559`/`1128561` 1x1 / 2x1 Micro) used to
    confirm the per-CU rules below hold across ≥6 sizes.

### Grid, units, tolerance — `[A]`

- **MU (board grid) = 25mm; CU (bin/container grid) = 50mm**, with
  **2×2 MU = 1×1 CU**. The MU grid (25mm) is the board hole pitch documented
  in "Grid pitch — 25mm (MU)" above; the CU grid (50mm) is the separate
  MultiBin cell size. Do not conflate them. `[A]`
- **Panel / Base Plate pitch = 50mm** — MultiBin Panels and Base Plates sit on
  the confirmed CU grid (CU = 50mm, above); no separate Panel-pitch figure is
  stated in the docs. `[A, derived from CU]`
- **Design tolerance = 0.25mm** (same value the board parts use). `[A]`
- Dimension-order convention: **Width (front) × Depth (side) × Height**. `[A]`

### MultiBin Shell family — footprint / cavity / wall / height

Two shell sub-families share one CU grid: **Simple Walls** (standard depth)
and **Micro** (shallow tray). The per-CU rules below are vendor-stated `[A]`
**and** independently mesh-confirmed `[C]` on the model IDs noted (measured
axis given); where both agree the value is high-confidence, tagged `[A]/[C]`.

**Simple Walls (standard) — external footprint = `50·Nx × 50·Ny` mm.** `[A]/[C]`
- Mesh-confirmed X/Y bounding box: 2×2 → 100.0×100.0, 3×2 → 150.0×100.0,
  2×2(rail) → 100.0×100.0 (models `974493`, `974135`, `1127745`);
  vendor text adds 4×2 → 200×100, 3×1 → 150×50. The footprint is the full
  `50·N` cell — the bin occupies its grid cells edge-to-edge.
- **Wall thickness ≈ 3.0mm** nominal (at the top internal rim), relieving to
  **≈2.6mm** through the body (support-free draft). Mesh: cavity measures
  `50·N − 6` at the rim, `≈50·N − 5.2` mid-body. `[A]/[C]`
- **Internal cavity (W×D) = `(50·Nx − 6) × (50·Ny − 6)` mm** at the rim
  (vendor "internal distance between walls": 2×2 → 94×94, 3×2 → 144×94;
  mesh-confirmed 144.0×94.0 / 94.0×94.0). `[A]/[C]`
- **External height = `50·Hz + 5` mm** (the `+5` is the base floor). Mesh +
  vendor confirmed across Hz = 0.5 → 30, 1 → 55, 1.5 → 80, 2 → 105,
  2.5 → 130, 4 → 205 (mesh Z: 30.0 / 80.0 / 130.0). `[A]/[C]`
- **Floor thickness ≈ 5mm** (mesh: cavity floor of the 0.5-CU shell closes at
  Z ≈ 5–6mm). `[C]`
- **Internal height = `50·Hz − 6` mm usable** (to the internal rim) /
  `50·Hz − 1` total. `[A]`
- **Stacking pitch = `50·Hz` mm** (adds exactly one Hz of CU height per
  stacked bin; the `+5` base is only on the bottom-most shell). `[A]`

**Micro (shallow tray) sub-family** — same 50mm CU cells but a distinct
shallow profile: `[A]/[C]`
- External footprint = `50·N − 2` mm (vendor: 1×1 → 48, 2×1 → 98, 4×4 → 198).
  Mesh note: the 4×4 Micro (`1128566`) walls flare with height — base outer
  ≈193.6mm rising to a 200.0mm top rim — so the "198" is the nominal
  mid-wall figure, not a constant envelope. `[C]`
- Wall ≈ 2.0mm; internal cavity = `50·N − 6` (44 / 94 / 194). `[A]`
- Fixed shallow height 11mm, internal depth 5mm, stack increment +5mm. `[A]`

### Fix-Point (Multipoint) — accessory-side receiving negative

Naming: **"Multipoints" have been renamed to "Fix-Points"; "Multipoint Rails"
are now just "Rails"** (part geometry unchanged). A Fix-Point gives an
accessory a **slide-on** attachment. Two variants: **Regular** (mates a
"Multipoint Hole") and **Lite** (**1mm thinner**, mates a "Multipoint Rail
Negative"). We model the **accessory side only** — the pocket/channel an
accessory cuts into itself to receive a Fix-Point; the Fix-Point part's own
board-side thread/bolt engagement is out of scope. `[A]` (naming/behaviour).

Geometry mesh-measured from the official Positive/Negative parts in model
`1142254` and the Multipoint Holes on the `1128566` bin base (`[C]`, axis
noted; single-sample → caliper-upgrade #16):

- **Dovetail cross-section (the slide-on rail), from the Positives:**
  - Max (buried) width **15.2mm**; throat (exposed-face) width **≈11.7mm**
    Regular / **≈12.8mm** Lite (X axis). `[C]`
  - Depth into the accessory face **3.0mm** Regular / **2.0mm** Lite (Z axis)
    — **Lite is exactly 1mm shallower**, matching the "1mm thinner" spec.
    `[A]` (1mm delta) `/[C]` (absolute depths).
- **Negative cutter (the tool subtracted from an accessory):**
  - Envelope width **17.0mm** (dovetail + clearance, X). `[C]`
  - Cut depth **3.3mm** Regular slot / **2.3mm** Lite (Z) — each ≈0.3mm
    beyond the matching Positive, i.e. the 0.25mm design clearance. `[C]`
- **Multipoint Hole (point receiver) on the bin base:** a **17.0mm-wide**
  dovetail pocket, **one per 50mm CU cell** (mesh: 16 identical 17.0mm
  features across the 4×4 CU base, on the CU grid). Confirms the point hole
  and the rail share the 17mm receiver width. `[C]`
- `//VERIFY`: exact throat width and dovetail flank angle are single-mesh-
  sample derivations; the rail *length* is per-part (variable, not a fixed
  spec). Upgrade all Fix-Point negative dims by caliper (#16).
