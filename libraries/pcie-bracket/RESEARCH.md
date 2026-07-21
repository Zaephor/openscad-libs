# pcie-bracket — research log (Task 1)

Scope: Task 1 only — scaffold + evidence-sourced value log. **No data table
or accessor functions are implemented in `pcie-bracket.scad` yet** (the
shipped `.scad` is the unmodified `make new-lib` stub, placeholder numbers
only) — that is Task 2's job. This file is the evidence Task 2 reads to fill
the real `pcie_bracket_*` accessors.

Canonical frame for Task 2 to adopt: bracket back face (mates the chassis
rear-panel plane) on `Y=0`, centered on `X=0` at the card-slot centerline,
bracket foot (fold, screws to chassis) at low `Z`, growing `+Z` up the
faceplate. Confirm/adjust against `docs/LIBRARY-AUTHORING.md`'s "centered
origin X/Y, bottom face Z=0" convention when Task 2 writes the header.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` fetched + read this pass (vendor datasheet or governing standard).
- `[B]` corroborated across >=2 independent peers (community consensus, or a
  named standard's figures repeated consistently by independent secondary
  sources).
- `[B] (caliper)` direct caliper measurement of a physical part.
- `[C]` single-sourced / derived, or a named standard cited but not fetched.
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

## Correction to the task brief: no such spec as "SFF-8018" for brackets

The plan's Step 2 names **SFF-8018** as the low-profile bracket spec,
described as "SFF committee / SNIA public archive — reachable." This is
incorrect and was checked, not assumed: **SFF-8018 is "ATA Low Power
Modes"** (an expired SFF/SNIA spec, listed in the current SNIA SFF
specifications index) — it has no bracket or mechanical-form-factor content
at all. Not used as a source below.

The actual governing document for low-profile PCI/PCIe bracket and card
geometry is **PCI-SIG's "Low Profile PCI" Engineering Change Notice (ECN) to
the PCI Local Bus Specification** — the same document family that defines the
**MD1**/**MD2** low-profile card-length classes referenced throughout the
distributor/community sources below. This is a PCI-SIG document, not an
SFF/SNIA one.

This PCI-SIG document is member-paywalled, as is the CEM spec that governs
full-height brackets — both bracket classes therefore trace to member-gated
PCI-SIG documents, cited by name and not fetched. Tier `[B]` for values
corroborated by >=2 independent secondary sources below, `[C] //VERIFY` for
single-sourced figures.

## Low-profile bracket (MD1/MD2 card classes)

Corroborating sources (independent, none is the primary PCI-SIG ECN itself):
1. Secondary summary of the PCI-SIG Low-Profile ECN's own figures (multiple
   technical-reference pages agreeing on identical decimal values — see
   note above on fetch access).
2. `flykantech.com` "Standard Profile vs. Low Profile PCIe Card Bracket
   Specifications" blog.
3. PL-Tronic BV / brackets.nl distributor drawing, "Low Profile PCI Card"
   (`brackets.nl/images/producten/pcb3.gif`) — a guideline/reference drawing
   (site's own disclaimer: "THIS DRAWING SHOULD BE USED AS A GUIDLINE
   ONLY!!"), single distributor, not an independent standards body — treated
   as corroboration-weight evidence only, not a primary source on its own.

| Dim | mm | Meaning | Tier |
|---|---|---|---|
| Bracket height (reduced) | 79.2 (3.118in) | low-profile bracket overall height, chassis-foot to top edge | [B] — matches the plan brief's own seed exactly; corroborated by source 2's "typically 79.2mm" |
| Card height incl. edge connector | 64.41 (2.536in) | MD1 **and** MD2 card classes share this max height | [B] — matches the plan brief's ~64.4mm seed; cross-checked against source 3's `63.58mm` (bracket-top-datum to card lower edge; the ~0.8mm delta is plausibly the bracket foot/material thickness, not a disagreement — see thickness row below) |
| MD1 max card length | 119.91 (4.721in) | shortest low-profile 32-bit card class | [B] — cross-checked against source 3's `121.79mm` "MD1 MAXIMUM LENGTH" (distributor's figure includes its own margin/tolerance stack, ~1.9mm over the spec figure — same order, not a genuine disagreement) |
| MD2 max card length | 167.64 (6.600in) | long/common low-profile card class; any card over MD1 length is MD2 | [B] — cross-checked against source 3's `169.52mm` "MD2 MAXIMUM LENGTH" (~1.9mm over, same pattern as MD1 row) |
| Retention-screw position, low-profile vs. full-height | −1.35 (delta only) | low-profile bracket's screw moved 1.35mm closer to the fold vs. the conventional (full-height) bracket; **not an absolute offset** | [B] — stated explicitly in source 1's synthesis; no absolute screw-to-fold distance found this pass, see Gaps |
| Bracket material thickness | 0.8 | sheet-metal gauge, read directly off source 3's drawing | [C] `//VERIFY` — single distributor drawing, guideline-only disclaimer, not independently corroborated |
| Bracket flange/foot width | 18.42 (0.725in) | width of the chassis-mounting foot (the L-flange that screws to the case's expansion-slot rail) — shared with full-height, see below | [B] |

Bottom-line low-profile bracket is **not** simply a full-height bracket cut
short — source 1 states explicitly the top fold/screw region is a "mirror
image of the conventional bracket," a distinct stamping, not a shared
tooling with a shorter cut. Task 2 should model it as its own bracket
profile, not a height-parameterized variant of the full-height one.

## Full-height bracket

Corroborating sources: `accio.com` "PCIe Bracket Dimensions" summary
(attributes figures to PCI-SIG), `flykantech.com` (source 2 above), and the
PL-Tronic full-height drawing (`brackets.nl/images/producten/pcb2.gif`,
labeled "Full Height PCI/AGP/CNR Card" — same guideline-only caveat as the
low-profile drawing above).

| Dim | mm | Meaning | Tier |
|---|---|---|---|
| Bracket height (overall, tab-to-tab) | 120.65 | full-height bracket overall height | [B] — accio.com's figure, attributed to PCI-SIG; corroborated loosely by flykantech's "approximately 120mm (118-120mm, varies by manufacturer)" |
| Bracket flange/foot width | 18.42 (0.725in) | chassis-mounting foot width; same figure both bracket classes (accio.com) | [B] — 0.725in is also the widely-cited generic "PC expansion bracket width" figure independent of this specific pair of sources; flykantech's "~19mm" agrees within rounding |
| Screw-to-screw vertical spacing (2-hole variants) | ~82.6 **or** ~100.33 — disagreement, not resolved | vertical distance between the chassis-foot screw and any second mounting screw | `[C] //VERIFY` — two single-sourced, disagreeing figures (a web-search hedge "approximately 82.6mm" vs. the PL-Tronic drawing's `100.33mm` left-edge dimension, whose own referent — card outline height vs. screw-to-screw span — is itself ambiguous at the drawing's resolution). **Neither adopted with confidence**; see Gaps. |
| Original full-size PCI card height (pre-bracket-height-reduction era) | 107 (4.2in) | historical full-size PCI card height, for context only — not the bracket figure | [C] `//VERIFY` — single secondary mention, informational only, not used for any bracket dimension |

## Screw — do not re-literal, reference the repo's existing value(s)

Community sources agree the bracket retention screw is commonly **6-32
UNC** (most ATX/US-market cases) with some manufacturers (named example:
Lian-Li) using **M3** instead — i.e. exactly the two options the plan brief
names, confirmed by cross-referencing multiple independent
forum/buying-guide sources plus the low-profile ECN summary's own screw
language (source 1, "the retention screw"). No card/case-vendor split more
specific than "6-32 is more common, M3 exists" was found — record both,
don't force a single winner.

This repo already carries clearance-hole values for both thread families —
**Task 2 must call these, not re-literal a new number**:
- `motherboards.scad`'s `mobo_hole_dia()` = **3.96mm** (Ø.156in), tagged
  `[B]` for a #6-32 standoff/screw clearance
  (`libraries/motherboards/motherboards.scad`, `libraries/motherboards/README.md`).
- M3 clearance = **3.4mm**, ISO 273 medium-fit series, established
  precedent in `rack19_screw_clearance("M6")`'s own comment
  (`libraries/rack19/rack19.scad`: "ISO 273's published medium fit series:
  M3->3.4, M4->4.5, M5->5.5, M6->6.6") and inlined the same way in
  `drives.scad` (`libraries/drives/RESEARCH.md`: "3.4 = M3 clearance").
  No single shared `m3_clearance()` accessor exists yet in any lib — every
  consumer to date inlines `3.4` per the `drives`/`rack19` precedent; Task 2
  should do the same (inline `3.4` with the same citation), not invent a
  third value.

## Card-edge-to-bracket offset — cross-reference, not re-researched

The plan's Interfaces line asks for "card-edge-to-bracket offset." A related
board-side figure is **already owned by `motherboards.scad`**, per the
single-source-of-truth rule (`CLAUDE.local.md`) — re-deriving a fresh number
here would duplicate it:

- `mobo_pcie_ports()`'s `setback = 42.6mm [B]` — distance from the
  motherboard's rear I/O edge to the near end of the PCIe slot connector
  body, derived from a real open-source microATX board layout
  (`libraries/motherboards/motherboards.scad`, `libraries/motherboards/RESEARCH.md`
  Task 12).

This is the **motherboard-side** setback (rear-panel-plane to connector),
not a bracket-specific "card PCB edge to bracket front face" figure — the
two are related (the bracket sits at the same rear-panel plane the setback
is measured from) but are not the same measurement, and no independent
card-side figure (distance from a card's own gold-finger edge to where its
bracket mounts) was found this pass. **Recorded as a gap** — Task 2 should
either derive it from `motherboards.scad`'s existing `setback` +
`connector_size("pcie_x16")` (in `connectors.scad`) rather than fabricate a
new literal, or flag it `//VERIFY` if the derivation isn't load-bearing for
the bracket geometry itself (the bracket's own front-face plane is fixed by
the chassis rear panel, not by the card's connector position).

## Slot pitch — cross-reference, not re-researched

`mobo_pcie_pitch() = 20.32mm` `[A]` (ATX 2.01 spec) already lives in
`motherboards.scad` and is the single source of truth for adjacent-bracket
spacing in a multi-slot case. `pcie-bracket` should call it via
`use <motherboards/motherboards.scad>;` if/when Task 2 needs multi-bracket
spacing, not copy the literal.

## Gaps / disagreements summary (honesty checklist)

| Item | Status |
|---|---|
| Low-profile bracket absolute screw-to-fold offset | Only a **delta** (−1.35mm vs. full-height) was found, no absolute figure. Gap. |
| Full-height screw-to-screw vertical spacing | Two disagreeing single-sourced figures (~82.6mm hedge vs. 100.33mm distributor-drawing reading, itself ambiguous whether it's screw span or card-outline height). Neither adopted. `//VERIFY`, flagged for a second independent source before Task 2 uses either. |
| Bracket material thickness (full-height) | Only the low-profile drawing gave a thickness (0.8mm, itself `[C] //VERIFY`); no independent full-height thickness figure found. Assuming shared sheet-metal gauge across both classes is plausible but **not confirmed** this pass — gap. |
| Tab/notch geometry (the shape of the fold where the bracket screws to the chassis, beyond the flat 18.42mm width figure) | Not resolved to numeric detail — the PL-Tronic drawings show the fold visually but the low-resolution guideline GIFs (273x312 / similar) don't support reading tab radius, slot-vs-hole shape, or fold angle with confidence. Gap, not fabricated. |
| Card-edge-to-bracket offset (bracket-specific, not the motherboard-side `setback`) | Not found independently; cross-referenced to `motherboards.scad`'s related-but-different `setback` value instead of inventing a new number. Gap for Task 2 to resolve via derivation or explicit `//VERIFY`. |
| PCI-SIG Low Profile ECN / CEM spec | Both member-paywalled (CEM already known paywalled per the plan and per `connectors/RESEARCH.md`'s existing `pcie_x1`..`pcie_x16` precedent); neither fetched — every bracket-height/length figure above is `[B]`/`[C]` via secondary corroboration, never `[A]`. |
| Original full-size (pre-ATX-era) PCI card height (107mm) | Single secondary mention, informational only — not used for any bracket dimension, not corroborated, `//VERIFY` if ever needed. |

No values in this document were invented without a cited source or flagged
`//VERIFY`/gap where a defensible number could not be found this pass.
