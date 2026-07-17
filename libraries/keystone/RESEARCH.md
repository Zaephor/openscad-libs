# keystone — research log

Evidence log for every value in `keystone.scad`. Tiers per
`docs/LIBRARY-AUTHORING.md`: **[A]** vendor datasheet / governing drawing,
**[B]** >=2 independent peers agree, **[C]** reverse-engineered from a public
STL/SCAD mesh (cite the artifact URL) — **not** single-sourced/uncorroborated,
`//VERIFY` = weak/unsourced (never a tier it didn't earn), flagged for a
future pass.

## `keystone_opening()` — `[14.70, 16.40]` mm — **[A]**

Source: Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical
drawing (DOC rev 01, dated 2021-12-15), "Suggested Panel Cutout" section,
**Plastic** variant: 14.70mm (W) x 16.40mm (H), with a 0.30mm/120° corner
relief for orientation keying. The same drawing's **Metal** variant gives a
slightly larger cutout (14.90 x 17.00) for stamped-metal panels — plastic
figures used here since a 3D-printed panel is closer to the molded-plastic
case than stamped metal.

Corroboration: Wikipedia's "Keystone module" article states the module face
is "14.5 mm wide by 16.0 mm high" — within ~0.3mm of the vendor drawing on
both axes. **[B]** corroborating.

## `keystone_body()` — `[17.5, 19.5, 28.60]` mm — mixed

- `bd` (28.60, Z-depth) — **`//VERIFY`**. Samm Teknoloji drawing carries a
  single labelled overall-depth dimension (28.60mm) next to the isometric
  view of the assembled jack + rear wire cap. Read as the full front-to-back
  keep-out (jack body + dressed wire cap), not decomposed into sub-lengths in
  the source drawing. This is a single, non-decomposed reading from one
  vendor drawing — not STL/mesh-derived (so it doesn't earn `[C]`) and not
  corroborated by a second source (so it doesn't earn `[B]` either). Confirm
  against a second jack's drawing, or an STL/caliper measurement, before
  treating as load-bearing.
- `bw`, `bh` (17.5, 19.5) — **`//VERIFY`**. The same drawing's orthographic
  front/side/top views carry several width/height callouts in the
  17-20mm range (e.g. 17.45, 19.40, 16.05, 16.90), but this pass could not
  confidently map each callout to a specific view/axis from the extracted
  drawing text/geometry. Seeded as a conservative keep-out margin above
  `keystone_opening()` rather than a specific measured envelope. Re-check
  against the same drawing (or a second jack's drawing) before treating as
  load-bearing for a tight-clearance placeholder.

## `keystone_plate_thickness()` — `[1.5, 3.0]` mm — mixed

- `tmin` (1.5) — **[A]**. Samm Teknoloji drawing's "Suggested Panel Cutout"
  lists a target panel thickness of **1.50~1.60mm** for both Metal and
  Plastic variants.
- `tmax` (3.0) — **`//VERIFY`**. No datasheet or drawing found this pass
  giving an explicit upper bound the snap latch tolerates. Seeded from
  common commercial decora/wall-plate stock thickness (anecdotally thicker
  than the vendor's 1.5-1.6mm cutout target and known to work in the field),
  not measured or fetched from a primary source — needs a real upper-bound
  citation (or a caliper measurement of an off-the-shelf plate) before
  relying on it for a snug-fit design.

## `keystone_pitch()` — `19.05` mm — **[B]**

Source: multiple independent retailer/community references describing
keystone patch-panel port spacing as **3/4 inch (19.05mm) center-to-center**
(e.g. Monoprice keystone patch-panel product specs; corroborating community
discussion of standard keystone-panel port spacing). Some brand-to-brand
variance is noted anecdotally (a few panels run slightly wider to clear
bulkier punch-down jack backs), but 19.05mm is the figure that recurs across
independent sources. This is *wider* than the ~18mm figure suggested as a
starting hint in the task brief — the hint was not corroborated and is
superseded by the sourced 19.05mm value.

## `keystone_min_wall()` — `1.6` mm — **`//VERIFY`**

Not a keystone hardware spec, and not sourced at all — this is the repo's
general print-process convention (2x 0.4mm nozzle line width, matching a
2-perimeter default wall), asserted with zero citation (no datasheet, no
mesh, no corroborating peer). Carried forward from the seed value. Needs
either an actual print test confirming this wall survives normal handling
for the target material/nozzle combo, or a pointer to a shared
print-convention library value if/when one exists (see
`docs/LIBRARY-AUTHORING.md` single-source-of-truth rule — no such library
exists yet, so this stays local to `keystone`).

## `keystone_tab()` — `[1.0, 1.2, "+Y", "-Y"]` mm — mixed, all `//VERIFY`

- `hook_edge`/`latch_edge` (`"+Y"`/`"-Y"`) — **`//VERIFY`** qualitative.
  Wikipedia's "Keystone module" article describes two historical retention
  mechanisms: an earlier (1979, AMP Inc. patent) dual diagonal-flange
  design, and the current (1995, International Connectors and Cable Corp.
  patent) "Keystone" design using **one fixed angled mounting flange plus an
  opposing ramp/cantilever latch** — i.e. the modern mechanism is genuinely
  asymmetric front-edge-vs-back-edge, which is what the +Y (fixed hook) /
  -Y (flexing latch) split models. No numeric confirmation of which
  physical edge is "+Y" vs "-Y" in an absolute sense — that's a modeling
  choice, not a sourced fact. This claim is backed by exactly one secondary
  source (Wikipedia), with no second independent source found this pass to
  corroborate it, so it does not clear the `[B]` bar (>=2 independent
  agreeing sources); needs a second independent source (a vendor drawing or
  a keystone-mechanism patent) before it can be upgraded.
- `tab_thickness` (1.2) — **`//VERIFY`**. Carried unchanged from the task
  seed (`[1.0, 1.2, "+Y", "-Y"]`); no datasheet or drawing found this pass
  with a numeric tab-thickness dimension.
- `hook_ledge_z` (1.0) — **`//VERIFY`**. Also carried unchanged from the
  task seed. (An earlier draft of this library silently changed this value
  to 3.0 with no citation or rationale; that was a mistake — there is no
  source for either number, so it has been reverted to the seed's 1.0
  rather than ship an unexplained, uncited deviation.)
  Both `tab_thickness` and `hook_ledge_z` need a real jack drawing's latch
  detail view (or caliper measurement of a physical jack) before Task 3/4
  (cutout/insert) builds print-tuned geometry on top of these numbers.

## `//VERIFY` census (values needing a future pass)

- `keystone_body()[0]`, `keystone_body()[1]` (bw, bh) — axis-mapping from the
  Samm Teknoloji drawing unresolved this pass.
- `keystone_body()[2]` (bd) — single, non-decomposed reading from one vendor
  drawing; not STL/mesh-derived, not corroborated by a second source.
- `keystone_plate_thickness()[1]` (tmax) — no accepted-upper-bound source
  found.
- `keystone_min_wall()` — no source at all; repo print-process convention,
  not a keystone-specific spec.
- `keystone_tab()[0]`, `keystone_tab()[1]` (hook_ledge_z, tab_thickness) — no
  numeric latch/tab source found; both carried unchanged from the task seed.
- `keystone_tab()[2]`, `keystone_tab()[3]` (hook_edge, latch_edge) —
  asymmetric-mechanism claim backed by exactly one secondary source
  (Wikipedia); needs a second independent corroborating source to clear
  `[B]`.

## Sources

- [Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical drawing](https://telecom.samm.com/Data/EditorFiles/Datasheets/9-copper-network-products/Unshielded-ISO-IEC-Keystone-Jack-Drawing-Samm-Teknoloji.pdf) — tier A — backs `keystone_opening()`, `keystone_plate_thickness()[0]` (tmin); also the sole (single, non-decomposed) reading behind `keystone_body()[2]` (bd), which stays `//VERIFY` since one non-decomposed reading doesn't earn a tier
- [Wikipedia, "Keystone module"](https://en.wikipedia.org/wiki/Keystone_module) — tier B — corroborates `keystone_opening()`; also the sole secondary source behind the qualitative asymmetric-latch claim behind `keystone_tab()` hook_edge/latch_edge, which stays `//VERIFY` since a single secondary source doesn't clear the `[B]` bar (>=2 independent agreeing sources) on its own
- [Monoprice keystone jack patch-panel product listings](https://www.monoprice.com/category/networking/patch-panels/keystone-jack-panel) — tier B — backs `keystone_pitch()` (3/4in / 19.05mm port spacing), corroborated by independent community discussion of standard keystone-panel spacing
