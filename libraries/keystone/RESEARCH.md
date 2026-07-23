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

## Standard keystone latch geometry (#38, STL-mesh)

Backlog #38 corrects the #31 latch geometry above, which mesh-measured the
WRONG mechanism. #31's three source models (SimplifiedLife's cutout aide,
pmichaud's blank, Hatcher's connector) all happened to encode a
**rotate-and-snap** mechanism: a rigid hook near the front engages a shallow
pocket first, then the jack rotates in and a flexible latch further back
snaps behind a second, offset lip — the two retention features staged at
*different* depths. That is a real, but different, real-world keystone
mechanism from the one this pass was chartered to measure.

This pass instead targeted the **de-facto standard keystone mechanism**: a
`[`-shaped channel in the panel with wide slits cut through its top AND
bottom walls, mated by a jack whose rear section carries a solid-bottom
**fulcrum** (with a small triangular notch) and a flexing **top arm** (also
carrying a triangular notch) — both notches click into their respective
slits at essentially the *same* depth, not staged.

### Naming clarification

The mechanism measured here is recorded under the key **`"standard"`**
going forward — it is the mechanism the overwhelming majority of
commodity/generic keystone jacks and panels (the models mesh-measured
below) actually use. A future task retargets `keystone_opening("lip")` /
`keystone_tab()`'s current values (the #31 rotate-and-snap read) as a
**deprecated alias**, not a second first-class style — `"lip"` is a real
mechanism (AMP's 1979 dual-diagonal-flange design per the Wikipedia
citation already in this file) but not the one most reference designs
converge on. Proprietary lookalike modules (Mini-Com, HD) use their own
incompatible latch geometry and are explicitly **out of scope** — not
researched, not folded into `"standard"`.

### Mechanism write-up

The jack is presented near-flush to the panel opening and pushed straight
in (no rotation). Two features click into place simultaneously at the same
insertion depth:

- A **fulcrum** on the jack's underside — a short, non-flexing rib — carries
  a small triangular **notch** that rides into a slit cut through the
  channel's **bottom** wall.
- A **flexing arm** on the jack's top — a thin cantilever, free along most
  of its length — carries its own triangular **notch** that rides into a
  slit cut through the channel's **top** wall. The arm deflects down during
  insertion and springs back once its notch reaches the slit, producing the
  click.

Because both notches seat at the same depth (confirmed independently on
both the slot side and the insert side below), insertion is a straight
push-to-click, not a tilt-and-rotate motion — consistent with how generic
keystone jacks are actually handled in the field (straight-in until it
clicks), unlike the #31 mechanism's implied tilt.

Removal: general keystone-jack knowledge (deflect the flexing arm's notch
out of its slit with a thin tool, e.g. through the channel's open front)
was not itself STL-measured this pass — carried forward as the same
`//VERIFY` status #31 left it in.

### Slot (channel) geometry

Two accepted slot models, both mesh-sectioned front-to-back (front face =
depth 0) to find the channel and its top/bottom slits. **No staged
hook-then-latch offset was found in either** (the #31 signature) — in both
models, top and bottom wall relief begins at the same depth from the front
face, which is the acceptance criterion for `"standard"`.

- **Model 1** — "Ethernet RJ45 keystone socket wall plate", [Printables
  1014552](https://www.printables.com/model/1014552). Single-port wall
  plate; channel sectioned at 0.02mm Z-steps through its full depth.
  - Baseline mouth (just past a short front lead-in ramp, ~2mm depth):
    **15.3mm (W) x 18.4mm (H)** — `//VERIFY` (single model)
  - Front lead-in: only the **top edge** ramps (16.6mm -> 18.4mm window
    height over ~2.05mm of depth); the bottom edge holds flat — an
    asymmetric front chamfer, not the symmetric bevel #31 found.
  - Both slits begin **together at ~2.05mm depth from the front face**:
    window jumps to **15.3mm (W) x 22.25mm (H)** (bottom edge opens
    1.5mm, top edge opens 2.35mm, relative to the ramp's end value) —
    `//VERIFY` (single model, but see cross-model corroboration below)
  - Slit width in X does not narrow — each slit runs the **full width** of
    the channel, not a locally narrower cut — `//VERIFY`
  - **Bottom slit ends at ~8.55mm depth** (length ≈ 6.5mm from its 2.05mm
    start) — window drops back to the pre-slit baseline height there.
  - **Top slit continues to ~10.05mm depth**, i.e. essentially to the
    channel's back wall (length ≈ 8.0mm) — **top slit is longer than
    bottom slit** in this model.
  - `back_wall_depth` ≈ **10.05mm** from the front face.
  - `wall_thickness` (residual material bridging each slit, measured
    against the surrounding boss's outer wall) ≈ **1.51mm**, and is the
    **same value on top and bottom** — `//VERIFY` (single model)

- **Model 2** — "Voron 0.2r1 Rear Skirt w/keystone", [Printables
  533549](https://www.printables.com/model/533549) (ships as `.3mf`,
  mesh-parsed directly — no STL export needed). Single keystone cutout in a
  printer-frame skirt panel; sectioned the same way.
  - Baseline mouth (near front): **15.9mm (W) x 21.5mm (H)** — `//VERIFY`
  - Both top and bottom edges move **together at ~1.5mm depth from the
    front face**: X narrows by ~0.6mm/side while Y widens by ~0.9mm/side,
    landing at **14.7mm (W) x 23.3mm (H)** — a different specific motion
    than Model 1 (which held X constant and moved Y only), but the same
    qualitative finding that **both slits start together, at a similarly
    shallow depth** (1.5mm here vs 2.05mm in Model 1).
  - Window holds constant for ~8.2mm, then **all four edges taper inward
    together** (a symmetric rear chamfer, not an asymmetric top/bottom
    close like Model 1) until the channel closes.
  - `back_wall_depth` ≈ **10.0-10.05mm** from the front face.

**Cross-model corroboration — `[C]`:** `back_wall_depth` lands at **~10.0-10.05mm**
independently in both models (1014552: 10.05mm, 533549: ~10.0-10.05mm) —
close enough, from two unrelated designs, to earn `[C]` for *this specific
value* (cite both 1014552 and 533549). The qualitative finding that **top
and bottom slits begin at the same depth from the front face** (not staged)
is also `[C]`, corroborated across both models — this is the key finding
that distinguishes `"standard"` from #31's `"lip"` mechanism. Every other
figure above (exact mouth/window mm, slit lengths, wall thickness, the
specific top>bottom slit-length asymmetry seen only in Model 1) is
single-model and stays `//VERIFY` — Model 2's symmetric-taper close does
**not** corroborate Model 1's asymmetric top-longer-than-bottom close, so
that specific asymmetry claim is weaker than the same-start-depth claim.

A third slot candidate, "Super Slim 11-Port Keystone Panel for 10 inch
Rack" ([Printables 1014587](https://www.printables.com/model/1014587)),
was fetched but not usable this pass: its 11 ports are arranged on a
diagonal, and multiple similarly-sized rectangular loops (screw bosses,
ribs) sit close enough to each port that automated centroid-tracking could
not reliably distinguish the keystone hole from adjacent structural
features. Left as unmeasured/inconclusive, not rejected as wrong-mechanism
— a future pass could resolve it with per-loop visual inspection rather
than automated tracking.

### Insert (module) geometry

- **Model 1** — "SMA-Keystone Modul", [Printables
  366437](https://www.printables.com/model/366437). Single STL, complete
  jack body with both fulcrum and arm modeled — a self-contained
  confirmation of the whole mechanism in one part.
  - Front face (nearest the channel-facing tip): **14.5mm x 16.3mm** —
    `[C]` (corroborates `keystone_face` `[14.5, 16.0]`, joining the two
    `[C]` STL reads already on file from #31's pmichaud/Hatcher models)
  - Body envelope: **~16.5mm x 21.7mm x 27.9mm** — loosely corroborates
    `keystone_body()`'s existing `//VERIFY` `[17.5, 19.5, 28.60]` (same
    order of magnitude on all three axes, not exact) — `//VERIFY`
  - **Bottom fulcrum notch**: base ≈ **2.0mm**, protrusion ≈ **1.5mm**,
    positioned **~6.1-8.1mm behind the front face** — `//VERIFY`
    (single-model mm; shape+position-range corroborated below)
  - **Top arm**: a root block (~5.9mm tall) folds back on itself at
    **`root_z` ≈ 20.0mm behind the front face** (a hairpin turn, likely a
    print-orientation/compactness choice by this author) into a thin
    cantilever, thickness ≈ **1.7mm** — `//VERIFY` (corrected from an
    earlier, less precise centerline-bbox read of this same model; a
    vertex-level re-trace of the ordered section polyline found the true
    arm thickness band, which sits ~1.2mm below where the coarser read had
    placed it). The cantilever's **free length** (root fold to where the
    notch begins) ≈ **14.0mm** — `//VERIFY`. It carries its own triangular
    **notch at the arm's free tip** (the last ~2.6mm of the 14.0mm free
    length, immediately before the front face): base ≈ **2.6mm**,
    protrusion ≈ **1.0mm** above the arm's local shoulder (a further
    ~1.2mm step separates the arm's own thickness band from that
    shoulder — the notch's total rise above the arm's own top surface is
    closer to 2.2mm; **1.0mm** is the triangular ramp itself) —
    `//VERIFY`, positioned **~6.1-8.7mm behind the front face**,
    essentially the **same depth range as the bottom notch**. This
    mirrors the slot side's same-depth finding: the insert's two notches
    seat at the same depth the channel's two slits open at, exactly as
    the push-to-click (not rotate-in) mechanism requires. (Earlier
    reading of this section wrongly placed the notch near the arm's
    root rather than at its tip — corrected via an ordered-vertex
    re-trace, see report.)

- **Model 2** — "SFP+ Cable Keystone Jack", [Printables
  314383](https://www.printables.com/model/314383). Ships as three
  separate parts (`Left.stl` + `Right.stl` body halves, `Hook.stl` a
  standalone flexing-arm insert) — `Hook.stl` sits in its own
  print-bed coordinate frame, not co-registered with Left/Right, so only
  shape/relative dimensions (not cross-part positions) are read from it.
  - Assembled body envelope (Left+Right, no wire-management cap): **~16.9mm
    x 17.3mm x 22mm** — `//VERIFY`, same-order-of-magnitude corroboration
    of `keystone_body()` alongside Model 1.
  - **Bottom fulcrum notch** (visible as an internal pocket wall feature in
    `Left.stl`): base ≈ **2.0mm**, protrusion ≈ **1.25mm**, positioned
    **~6.4-8.4mm behind the front face** — `//VERIFY` (single-model mm)
  - **Top arm** (`Hook.stl`, a separate clip-in part): a root block (~7.1mm
    tall) transitions into a thin cantilever, thickness ≈ **0.90mm**
    — `//VERIFY`. Free length ≈ **8.8mm** measured along the constant-
    thickness run alone (from where the root's fillet ends to where the
    notch begins), or ≈ **10.8mm** if measured from the root block's own
    vertical face through the fillet transition to the notch — `//VERIFY`
    (both readings given since the root-to-arm transition is a rounded
    fillet, not a sharp corner, so "where the arm starts" is a judgment
    call). It runs to a triangular **notch at the arm's tip**: base ≈
    **2.0mm**, protrusion ≈ **1.2mm** — `//VERIFY`. **`root_z`
    (depth-from-front-face of the root) could not be determined for this
    part**: `Hook.stl` ships as a standalone, unassembled STL sitting in
    its own arbitrary print-bed position/orientation, not co-registered
    with `Left.stl`/`Right.stl`'s coordinate frame, so there is no
    reliable way to map its local axes onto the assembled body's
    front-to-back depth without an assumed (not measured) alignment —
    left unmeasured rather than guessed. This notch sits at the arm's
    free end, matching Model 1's (corrected) tip placement — see
    cross-model corroboration below.

**Cross-model corroboration — `[C]`:** both models independently show (a)
a small triangular notch on a solid bottom fulcrum, positioned in the same
~6-8.7mm-behind-front-face range, and (b) a flexing top arm carrying its
own triangular notch **at the arm's free tip** (not partway along it, in
either model — this was miscalled as near-root in an earlier pass over
Model 1's data; a precise ordered-vertex re-trace of that section's
polyline corrected it to tip-positioned, matching Model 2). Both findings
— notch-on-fulcrum and notch-at-arm-tip — are corroborated in **shape and
position order-of-magnitude** across two unrelated designs (SMA 366437,
SFP+ 314383) — `[C]`. The **exact** base/protrusion millimeter values
differ per model (2.0/1.5mm fulcrum and 2.6/1.0mm arm-notch vs 2.0/1.25mm
fulcrum and 2.0/1.2mm arm-notch) and are **not** numerically identical, so
each model's specific mm figures stay `//VERIFY`. Arm length and thickness
also differ substantially per model (14.0mm/1.7mm vs 8.8-10.8mm/0.9mm) —
same qualitative role (a long, thin cantilever), not corroborated
numerically — `//VERIFY`, an author-specific parametric choice akin to the
retention-flare variation #31 already found between its two insert models.

Two further insert candidates were fetched and found inconclusive, not
rejected as wrong-mechanism:

- **"Keystone-Blank"**, [Printables
  557655](https://www.printables.com/model/557655) — a centerline
  (mid-X) depth section shows a constant 21.86mm x 18.95mm envelope
  through nearly the entire body, with no taper toward the 14.5x16 face
  anywhere along that line, and no notch. Two small 1.5mm x 1.85mm
  off-center features exist near one end but could not be confidently
  read as the fulcrum/arm mechanism from a centerline slice alone. This
  model's latch geometry (if any) is evidently off the X centerline;
  resolving it needs an X-offset slice pass, left for a future task.
- **"Keystone Blank Insert Pass-Through"**, [Printables
  1327671](https://www.printables.com/model/1327671) — `plug.stl`'s
  profile is a stepped barrel with a triangular groove that reads as a
  coupler-body retention feature (joining two barrel halves through the
  wall for a pass-through cable), not a panel latch; `insert.stl` (its
  smaller companion STL) is a plain rectangular sleeve with no notch on
  its centerline. Read as a pass-through coupler that rides inside a
  separate, off-the-shelf keystone jack shell rather than modeling its own
  panel-latching geometry — excluded from the notch/arm measurements.

### Datasheet hunt

No vendor datasheet or mechanical drawing was found this pass that
dimensions the slot slits or module notches specifically (the existing
Samm Teknoloji drawing on file dimensions the face-opening and overall
depth only, not this latch's internal features). All latch-geometry values
above are STL-mesh-sourced; none earn `[A]`.

### Caliper-upgradeable

Every millimeter figure in this section is STL-mesh reverse-engineering of
other people's prints, not the user's own hardware — per backlog #16, all
of it should be re-measured with calipers against physical keystone jacks
and printed test fits before Task 2/3 geometry is treated as final. This
research is strongest on *shape and mechanism* (push-to-click, same-depth
top/bottom engagement, triangular notch-in-slit) and weakest on *exact
millimeter values*, where only `back_wall_depth` (~10mm) and the
same-depth-start finding cleared the `[C]` bar this pass.

### Flagship insert — datasheet reconciliation (#54 Task 1)

Two vendor datasheets are on file for this pass: VCELINK "Cat6 Keystone
Coupler" (M226) and VCELINK "Keystone Wall Plate" (A175-1).

- **A175-1 wall plate** dimensions its keystone port window (front view):
  **14.6mm (W) x 16.1mm (H)**, with a larger **19.5mm** opening visible from
  the rear (a front/rear relief taper, consistent with the asymmetric
  front/rear opening already documented elsewhere in this file). This
  dimensions the PANEL OPENING, not an insert — it corroborates
  `keystone_opening("face")` `[A]` (14.70 x 16.40, Samm Teknoloji) as a
  second independent source in the same ~14.6-14.7 x 16.1-16.4mm range, but
  is not itself adopted (no change to that accessor this task).
- **M226 coupler** dimensions its own module cross-section (front view):
  **14.6mm x 16.2mm**, overall length **32.7mm**; a secondary **20.0mm**
  run to an internal step is also dimensioned (plausibly the front,
  keystone-slot-compatible portion of the housing before the coupler's own
  RJ45-facing rear extension — not confirmed from the drawing alone). These
  numbers sit close to, but not identical to, the VCELINK BOUND recorded
  below (face 14.3 x 16.0, depth 32.4mm): deltas of 0.2-0.3mm per dimension,
  consistent with a datasheet nominal vs. an as-received caliper reading of
  the same product line, not a discrepancy. The 20.0mm run is coincidentally
  close to `keystone_insert_depth()`'s 20mm value below, but that value's
  actual source is the Tecmojo latch-root reading (see next section), not
  this datasheet — noted here only as a directionally-corroborating data
  point, not adopted.
- **Tier decision:** the M226 datasheet states a face for *its own* product
  (the VCELINK bound specimen), not for the Tecmojo specimen this task's
  accessors are keyed to (Tecmojo has no vendor datasheet on file). Per
  `docs/LIBRARY-AUTHORING.md`'s tiering, that means `keystone_insert_face()`
  and the other flagship accessors below stay **`[B]` caliper** (Tecmojo
  nominal) — a same-family vendor datasheet for the *other* specimen
  corroborates the VCELINK bound but does not promote the Tecmojo-keyed,
  load-bearing values to `[A]`. Printable face nominal stays 14.3mm
  (caliper, both specimens agree); the datasheets' 14.5-16.2mm range is the
  wider de-facto-standard envelope our eventual slot must clear, not the
  printed insert's own dimension.

### Flagship insert mechanism — [B] caliper (#54 Task 1)

Two physical specimens, both CAT6 keystone inserts: **Specimen A
(Tecmojo)**, bundled with a Tecmojo 0.5U patch panel — smaller, treated as
the PRIMARY/nominal reference below; **Specimen B (VCELINK)**, a bulk-pack
CAT6 insert — larger on several features, does not seat in Specimen A's own
patch panel, and is recorded as the outer BOUND a future slot/opening must
still clear (not modeled as the flagship insert itself). Coordinate frame:
origin at the center of the front face (the face exposed out of the panel,
RJ45 side); X = width, Y = height, Z = depth behind the front face
(positive magnitude increasing away from the panel).

- **Face** — W identical at both specimens (14.3mm); H 15.9mm (A) vs
  16.0mm (B), a 0.1mm delta. `keystone_insert_face()` below takes Specimen
  A's width verbatim and Specimen B's height (both within their mutual
  0.1mm spread): `[14.3, 16.0]`.
- **Depth** — body-only Z is 29.8mm (A) vs 32.4mm (B, +2.6mm — a deeper
  body behind the panel, not relevant to seating). `keystone_insert_depth()`
  below (20mm) is NOT either specimen's raw body length — it is sized to
  clear Specimen A's latch root (anchor z 15.0mm + anchor thickness 3.6mm =
  18.6mm) plus a small margin, i.e. the depth the flagship geometry needs
  behind the face to host the retention mechanism.
- **Guide rib** (L/R side shelf, symmetric) — X protrusion past the cube
  identical at both specimens (0.8mm/side); Y run (long axis) 7.6mm (A) vs
  7.9mm (B); Z thickness 1.4mm (A) vs 1.5mm (B); rib front face starts
  10.0mm (A) / 9.9mm (B) behind the front face. `keystone_insert_guide_rib()`
  below takes Specimen A's reading verbatim: `[0.8, 7.6, 1.4, 10.0]`
  (out, run, thick, z0).
- **Fixed retention lug** (bottom, non-flexing) — X width 7.8mm (A) vs
  8.0mm (B); -Y protrusion past the cube bottom 1.2mm (A) vs 1.1mm (B) (a
  delta that cancels against the width delta — combined bottom envelope is
  17.1mm at BOTH specimens); Z length 7.0mm, identical at both.
  `keystone_insert_lug()` below takes Specimen A's reading verbatim:
  `[7.8, 1.2, 7.0, 6.6]` (w, prot, zlen, z0).
- **Cantilever latch** (top, flexing arm + triangular catch) — the one
  feature where the two specimens diverge meaningfully (identified as the
  reason Specimen B does not seat in Specimen A's own panel): beam width
  9.2mm (A) vs 10.2mm (B, +1.0mm, the single largest delta measured); root
  (anchor) z 15.0mm (A) vs 16.5mm (B); root thickness 3.6mm (A) vs 3.4mm
  (B); tip reach ~5.2mm from the face (A) vs ~5.5mm (B, flagged as an
  internally-inconsistent reading needing re-measurement); beam wall
  thickness 0.9mm (A) vs 1.4mm (B, notably stiffer); deflection clearance
  gap 2.2mm (A) vs 2.0mm (B); catch peak above the cube top 4.3mm (A) vs
  4.9mm (B); catch z-extent 3.0mm (A) vs 2.8mm (B); hat-body top (pre-catch)
  height 3.1mm (A) vs 3.4mm (B). `keystone_insert_latch()` below takes
  Specimen A's reading verbatim: `[9.2, 15.0, 3.6, 5.2, 0.9, 2.2, 4.3, 3.0,
  3.1]` (beam_w, root_z, root_thick, tip_z, beam_wall, defl_clear,
  hook_peak, hook_zext, body_top). Specimen B's larger, stiffer latch is
  the bound a future slot/opening task must clear; the flagship insert
  itself models Specimen A (closer to the universal envelope, PETG-tunable
  flex).

## Sources

- [Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical drawing](https://telecom.samm.com/Data/EditorFiles/Datasheets/9-copper-network-products/Unshielded-ISO-IEC-Keystone-Jack-Drawing-Samm-Teknoloji.pdf) — tier A — backs `keystone_opening()`, `keystone_plate_thickness()[0]` (tmin); also the sole (single, non-decomposed) reading behind `keystone_body()[2]` (bd), which stays `//VERIFY` since one non-decomposed reading doesn't earn a tier
- [Wikipedia, "Keystone module"](https://en.wikipedia.org/wiki/Keystone_module) — tier B — corroborates `keystone_opening()`; also the sole secondary source behind the qualitative asymmetric-latch claim behind `keystone_tab()` hook_edge/latch_edge, which stays `//VERIFY` since a single secondary source doesn't clear the `[B]` bar (>=2 independent agreeing sources) on its own
- [Monoprice keystone jack patch-panel product listings](https://www.monoprice.com/category/networking/patch-panels/keystone-jack-panel) — tier B — backs `keystone_pitch()` (3/4in / 19.05mm port spacing), corroborated by independent community discussion of standard keystone-panel spacing
- ["Keystone Jack v2 integration aide" by SimplifiedLife, Printables 1027864](https://www.printables.com/model/1027864) — tier C (single-mesh, `//VERIFY`) — cutout negative window/lip/slot geometry (the cutout window itself is a clearance passage, not the jack's solid footprint, so it is not counted toward the `keystone_face` front-face corroboration)
- ["Keystone blank" by pmichaud, Printables 587874](https://www.printables.com/model/587874) — tier C (front face) / `//VERIFY` (retention-flare, parametric) — front-face corroboration, insert envelope and cantilever-latch-arm evidence
- ["(Parametric) Keystone Connector" by Paul Hatcher, Printables 537480](https://www.printables.com/model/537480) — tier C (front face) / `//VERIFY` (retention-flare, parametric) — front-face corroboration, alternate (symmetric-step) retention-flare reading
- ["Ethernet RJ45 keystone socket wall plate", Printables 1014552](https://www.printables.com/model/1014552) — tier C (`back_wall_depth`, same-depth top/bottom slit start, jointly with 533549) / `//VERIFY` (mouth/window/slit-length/wall-thickness specifics, single-model) — `"standard"` slot/channel geometry (#38)
- ["Voron 0.2r1 Rear Skirt w/keystone", Printables 533549](https://www.printables.com/model/533549) — tier C (`back_wall_depth`, same-depth top/bottom slit start, jointly with 1014552) / `//VERIFY` (mouth/window specifics, single-model) — `"standard"` slot/channel geometry (#38), 3mf-sourced mesh
- ["SMA-Keystone Modul", Printables 366437](https://www.printables.com/model/366437) — tier C (front face; fulcrum-notch and arm-notch shape+position, jointly with 314383) / `//VERIFY` (exact notch/arm mm, body envelope, single-model) — `"standard"` insert/module geometry (#38), single-STL whole-mechanism read
- ["SFP+ Cable Keystone Jack", Printables 314383](https://www.printables.com/model/314383) — tier C (fulcrum-notch and arm-notch shape+position, jointly with 366437) / `//VERIFY` (exact notch/arm mm, body envelope, single-model) — `"standard"` insert/module geometry (#38), split Left/Right/Hook parts
