# keystone — research log

Evidence log for every value in `keystone.scad`. Tiers per
`docs/LIBRARY-AUTHORING.md`: **[A]** vendor datasheet / governing drawing,
**[B]** >=2 independent peers agree, **[C]** reverse-engineered from a public
STL/SCAD mesh (cite the artifact URL) — **not** single-sourced/uncorroborated,
`//VERIFY` = weak/unsourced (never a tier it didn't earn), flagged for a
future pass.

## Face / Opening decomposition (Task #28)

The jack's physical face and the panel window to cut have diverged into two
roles:

- `keystone_face()` — `[14.5, 16.0]` mm — **[B]** invariant jack face /
  plug cross-section (the actual electrical contact footprint). Wikipedia
  "Keystone module" article (secondary source) cites "14.5 mm wide by 16.0
  mm high"; corroborated by cross-retailer sources.
- `keystone_opening(style)` — panel window size per retention style:
  - `"face"` — `[14.70, 16.40]` **[A]** (face-grip retention; preserved from
    pre-#28 default)
  - `"lip"` — `[14.8, 20.3]` (rotate-and-snap retention; width `[B]`
    corroborated by community sources, height 20.3 **[B]//VERIFY** as a
    single community source — caliper-upgradeable, see #16). The taller
    opening allows a rigid fulcrum (bottom) to catch the opening's bottom lip
    while a flex clip (top) snaps over the top lip, achieving retention by
    mechanical pivot rather than plate thickness.

The decomposition lets consumers choose retention style before cutting: tight
face-grip if the assembly uses metal face plates (original design), or snap
if the plate is 3D-printed plastic (new flexibility). Default is `"lip"`
(the taller window).

## `keystone_opening(style)` — per-style panels

See Face/Opening decomposition above. `keystone_opening()` signature changed
from `keystone_opening()` (nullary, returning fixed `[14.70, 16.40]`) to
`keystone_opening(style = "lip")` (unary with string parameter and default).

## `keystone_opening("face")` — `[14.70, 16.40]` mm — **[A]** (pre-#28 nullary default; use `keystone_opening("face")` explicitly)

Preserved for reference. The `"face"` style window size.

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

## Real latch geometry (#31, STL-mesh)

Three public models were mesh-measured to ground the `"lip"` cutout/insert
geometry in a real rotate-and-snap mechanism instead of a plain rectangle:

- **Cutout negative** — "Keystone Jack v2 integration aide" by SimplifiedLife,
  [Printables 1027864](https://www.printables.com/model/1027864). Ships
  `Keystone v2.stl` (the aide frame — what a panel-mounted printed insert
  receiving a real jack looks like internally) + `Keystone v2.step` +
  a plain rectangular `Keystone v2 - Keystone Hole Tool.stl` (a 23.6x27.3x15mm
  featureless block — the boolean-subtract tool for cutting the panel's outer
  pocket that the aide frame presses into; not itself latch geometry).
- **Insert/module A** — "Keystone blank" by pmichaud,
  [Printables 587874](https://www.printables.com/model/587874). Ships only a
  3MF (`keystone-blank-230920.3mf`) — no bare STL.
- **Insert/module B** — "(Parametric) Keystone Connector" by Paul Hatcher,
  [Printables 537480](https://www.printables.com/model/537480). Ships
  `Keystone Connector.stl`.

The cutout negative's `.step` file was not cross-checked against the STL
this pass — the STL alone is the basis for the cutout measurements below,
which is why they're `//VERIFY` (single-mesh reading, not
solid-model-cross-checked, and no second independent cutout-negative model
was in scope this pass).

### Mechanism

Confirmed by the aide frame's internal cavity shape (see below) and
consistent with Wikipedia's "Keystone module" description already cited
under `keystone_tab()`: a **rigid hook** near the top-front rides a ramped
lead-in as the jack is presented at an angle, seats into a shallow pocket:
then the jack body is rotated in, and a **flexible latch** on the bottom
deflects down a second ramp and snaps behind the opening's bottom lip.

Removal (thin blade/spudger deflecting the latch back out of its catch) is
general keystone-jack mechanism knowledge, not something this pass measured
or found a citation for — no front-slot removal-access feature was
identified in the measured geometry (the nearest measured feature, the
latch-clearance plateau, sits 6.97-8.27mm from the front, not at the
front). Treat removal-access geometry as unconfirmed/`//VERIFY` until a
future pass either measures it or finds a source.

### Cutout negative (`Keystone v2.stl`, 1027864) — front-to-back cross-sections

Sectioned in 0.05-0.1mm Z-steps (front face = Z=0, positive = into the part,
overall depth 9.75mm). Width holds constant at **14.90mm** through the
entire depth (the retention mechanism is purely a height/Y-axis effect, no
X-axis taper) — all figures below are the window/cavity **height**, `[C]//VERIFY`
(single mesh, this exact model not corroborated by a second cutout-negative
source):

| Zone | Z from front | Depth | Window H | Note |
|---|---|---|---|---|
| Front lead-in chamfer | 0 – 0.42mm | 0.42mm | 17.41 → 17.43mm | small insertion bevel |
| Front window (stable) | ~0.42mm | – | 17.43mm | matches `keystone_face` 14.5x16.0 `[B]` + ~1.4mm clearance |
| **Top-lip ramp** | 0.42 – 4.32mm | 3.90mm | 17.43 → 21.30mm | ~45° ramp, top edge only; thins the top wall from 5.38mm to 1.51mm |
| **Top-lip engagement pocket** | 4.32 – 5.37mm | 1.05mm | 21.30mm (flat) | top wall holds at **1.51mm** — matches the model's own "thin top side (1.5mm)" note almost exactly, strong confirmation of Z-orientation and measurement accuracy |
| **Bottom-lip ramp** | 5.37 – 6.97mm | 1.60mm | 21.30 → 22.90mm | ~45° ramp, bottom edge only; thins the bottom wall from 6.75mm to 5.16mm |
| Latch-clearance plateau | 6.97 – 8.27mm | 1.30mm | 22.90mm (flat, max) | max window — clearance for the flex latch's deflection travel |
| Rear shoulder (abrupt step) | at 8.27mm | – | 22.90 → 20.06mm | insertion-depth hard stop; both walls thicken (top 1.51→3.10mm, bottom 5.16→6.40mm) |
| Rear window | 8.27 – 9.42mm | 1.15mm | 20.06mm (flat) | |
| Rear chamfer | 9.42 – 9.75mm | 0.33mm | widening | mirrors front lead-in |

Reading: the hook's engagement ramp is staged **before** the latch's ramp
(top ramp starts right at the front window, bottom ramp starts ~5mm in) —
consistent with "hook engages first (near-flush insertion), then the body
rotates in and the latch catches second."

**Undercut: unmeasured.** The table above gives each lip's engagement-slot
*depth* (3.90mm top ramp, 1.60mm bottom ramp) from stacked cross-section
bounds, but a true *undercut* (a re-entrant/overhanging catch profile, as
opposed to a ramped lead-in into a flat pocket) needs a direct profile cut
through the lip rather than stacked cross-section bounds. A direct profile
check was attempted, but the resulting reading was too noisy at this mesh's
resolution to trust a number from it, so no undercut angle/depth is
reported here — treat it as an open `//VERIFY` gap, not a "no undercut
exists" finding. The stacked-cross-section data is at least consistent with
a simple ramp-into-flat-pocket (monotonic per zone, no reversal), but that's
a weaker claim than a directly measured profile would support.

### Insert/module front-face corroboration

Both insert models' front-tip cross-sections corroborate `keystone_face`
14.5x16.0mm `[B]` and are individually in the same range as the cutout
negative's 14.90x17.43mm window (window is naturally larger — it's a
clearance passage, not the jack's own solid footprint):

- pmichaud blank (587874): **14.60 x 16.00mm** at the front tip (Z~0.1mm) — `[C]` (2nd independent model corroborating `keystone_face`, alongside the existing Wikipedia-sourced `[B]` citation as the 1st)
- Hatcher connector (537480): **14.70 x 16.40mm** at the front face (Z~0.05mm) — `[C]` (3rd independent model corroborating `keystone_face`)

### Insert/module retention-flare geometry — `//VERIFY` (parametric, author-chosen, not a standard — per task rule, stays `//VERIFY` regardless of corroboration)

- **pmichaud blank** (22.0mm total Z depth, front = the end whose cross-section
  matches the jack face): a constant compact shaft (14.6x16.0mm, matching the
  front face) runs almost the entire body length; the retention flare —
  where the envelope widens to **17.0 x 19.5mm** (corroborates
  `keystone_body()` bw/bh 17.5/19.5, both currently `//VERIFY` — worth a
  future upgrade pass) to make room for the hook/latch tabs — occupies only
  the **last ~4.8mm nearest the front face**. A long (~17mm), roughly
  constant-cross-section rib runs from just behind the flare almost the full
  remaining body length toward the wire-management end — the structural
  signature of a **flexible cantilever latch arm** (long+thin = compliant),
  as opposed to a short rigid hook stub. This pass could not cleanly isolate
  a separate short "hook" tab from the "latch" arm by automated
  cross-sectioning alone — both features sit inside the same 4.8mm flare
  zone and their loops merge in places — so a hook-specific offset/size is
  not reported here (ambiguous single-mesh reading).
- **Hatcher connector** (9.75mm total Z depth — same order as the cutout
  negative, not the ~22mm insert body): a single **symmetric** step (not two
  staged ramps) at Z~1.5–1.6mm from the front face, where the window jumps
  from the compact front size straight to a max envelope **14.7 x 22.0mm**,
  holding flat for ~6.6mm, then stepping back down near the rear. Both top
  and bottom edges step out *together* here — a materially different
  parametric choice from the aide's staged top-then-bottom ramps, which is
  expected (these are author-chosen bench dimensions, not a de-facto
  standard).
- **Latch travel (upper bound only, from the receiving geometry, not a
  direct deflection measurement)**: the cutout negative's bottom-lip ramp
  opens the window's bottom edge by **1.60mm** (see table above) — this is
  the clearance the frame *provides* for the latch tooth's downward travel,
  not a measurement of the latch's own spring throw (which needs the insert
  flexed under load — not obtainable from a static, unflexed mesh).
- These figures relate to the existing `keystone_tab()` `//VERIFY` seed
  values (`hook_ledge_z` 1.0mm, `tab_thickness` 1.2mm, `hook_edge`/`latch_edge`
  `"+Y"`/`"-Y"`) — orientation (`+Y` fixed hook / `-Y` flexing latch) is
  consistent with what's measured here, but the seed's specific 1.0/1.2mm
  numbers are not directly confirmed or refuted by this pass.

### Caliper-upgradeable

All figures in this section are STL-mesh reverse-engineering of *other
people's* prints, not the user's own hardware. Per backlog #16, every number
here should be re-measured with calipers against the user's own keystone
jacks and printed test fits before Task 2/3 geometry is treated as
final — this research sets the *shape* (ramp-then-pocket, staged
hook-then-latch, ~45° engagement angles) with more confidence than it sets
the exact millimeter values.

## Sources

- [Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical drawing](https://telecom.samm.com/Data/EditorFiles/Datasheets/9-copper-network-products/Unshielded-ISO-IEC-Keystone-Jack-Drawing-Samm-Teknoloji.pdf) — tier A — backs `keystone_opening()`, `keystone_plate_thickness()[0]` (tmin); also the sole (single, non-decomposed) reading behind `keystone_body()[2]` (bd), which stays `//VERIFY` since one non-decomposed reading doesn't earn a tier
- [Wikipedia, "Keystone module"](https://en.wikipedia.org/wiki/Keystone_module) — tier B — corroborates `keystone_opening()`; also the sole secondary source behind the qualitative asymmetric-latch claim behind `keystone_tab()` hook_edge/latch_edge, which stays `//VERIFY` since a single secondary source doesn't clear the `[B]` bar (>=2 independent agreeing sources) on its own
- [Monoprice keystone jack patch-panel product listings](https://www.monoprice.com/category/networking/patch-panels/keystone-jack-panel) — tier B — backs `keystone_pitch()` (3/4in / 19.05mm port spacing), corroborated by independent community discussion of standard keystone-panel spacing
- ["Keystone Jack v2 integration aide" by SimplifiedLife, Printables 1027864](https://www.printables.com/model/1027864) — tier C (single-mesh, `//VERIFY`) — cutout negative window/lip/slot geometry (the cutout window itself is a clearance passage, not the jack's solid footprint, so it is not counted toward the `keystone_face` front-face corroboration)
- ["Keystone blank" by pmichaud, Printables 587874](https://www.printables.com/model/587874) — tier C (front face) / `//VERIFY` (retention-flare, parametric) — front-face corroboration, insert envelope and cantilever-latch-arm evidence
- ["(Parametric) Keystone Connector" by Paul Hatcher, Printables 537480](https://www.printables.com/model/537480) — tier C (front face) / `//VERIFY` (retention-flare, parametric) — front-face corroboration, alternate (symmetric-step) retention-flare reading
