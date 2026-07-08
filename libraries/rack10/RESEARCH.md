# rack10 — LabRax 10-inch mini-rack research log (Task 1)

Scope: scaffold + evidence gathering only. No data functions are written into
`rack10.scad` yet (Tasks 2+ consume this file). Every value below is
research-honest: tiered by what was *actually fetched and read* this pass.

## Standard / tier ceiling

There is **no governing standard for 10-inch mini-racks** — LabRax's own
designer states: *"There is no strict standard for 10-inch racks, but Lab
Rax follows the most commonly accepted dimensions."* So tier **[A] is not
reachable for anything in this library**; the ceiling is [B] (corroborated
across independent peers), same conclusion as rack19 (there: paywall; here:
no standard exists to fetch in the first place).

### Sources

1. **`labrax-intro.html`** — `https://the-diy-life.com/introducing-lab-rax-a-3d-printable-modular-10-rack-system/`
   Designer Michael Klements's own write-up, April 7 2025. Primary source for
   LabRax's own stated numbers.
2. **MakerWorld model** — `https://makerworld.com/en/models/1294480-lab-rax-10-server-rack-5u`.
   The page lists the full file manifest (part names, sizes) for the 5U frame.
3. **`labrax-vertpost-thumb.jpg`** — a real, unsigned CDN thumbnail JPEG
   (14501 bytes, matches the manifest's declared `thumbnailSize` exactly) of
   `5U Vertical Post.stl` from a **sibling** MakerWorld design ("Lab Rax 10"
   Server Rack - Bolted Version - 5U", id 1464819). **This is an image, not
   mesh data** — CDN thumbnail confirms rail shape family only, no dimension.
4. **`19-vs-10-rack-dims.svg`** — `https://upload.wikimedia.org/wikipedia/commons/8/84/19_inch_vs_10_inch_rack_dimensions.svg`
   (Commons page: `https://commons.wikimedia.org/wiki/File:19_inch_vs_10_inch_rack_dimensions.svg`).
   Independently authored (Commons user **Cvdr**, "own work based on" the same
   `19 inch rack dimensions.svg` that underlies Wikipedia's own 19-inch-rack
   article — the same base file rack19's RESEARCH.md traces to IBM/Wikipedia).
   A **dimensioned vector drawing comparing 10in and 19in rack hole patterns
   to scale**, with exact numeric labels — the closest thing to a second,
   independent primary source: not a standard, but a to-scale technical
   drawing, not prose. Hole-center world coordinates extracted by parsing the
   raw SVG `<circle>`/`<text>`/`transform` elements (affine matrix
   composition), not eyeballed pixels — see "Per-U hole pattern" below.

### STL provenance

The LabRax STL was not obtainable, so rail dimensions could not be measured
from it (brief Step 3). The MakerWorld manifest exposes no mesh URL, and the
original design was never independently listed on Printables by its designer
(only third-party remixes, which would be reverse-engineering a derivative,
not the original).

In place of a mesh: the Wikimedia SVG diagram (source 4) is a real,
independently-produced **to-scale vector drawing** (not prose, not LabRax's
own claim) that cross-checks the designer's stated numbers via exact
coordinate math, not mesh min/max. It is **not** a LabRax-specific artifact,
so it corroborates the *convention* LabRax says it follows, not LabRax's own
part geometry directly.

## Confirmed / corrected values

### 1U pitch — **44.45 mm** — tier [B]

- LabRax article (verbatim): *"It uses the standard 44.45mm rack unit
  spacing that is used on larger 19-inch racks..."* — explicit, exact.
- Cross-check: the Wikimedia diagram's own hole coordinates (extracted via
  SVG transform math, not stated as a headline label) repeat with a
  **44.50mm** period, not 44.45. This is a **rounding-chain artifact**: the
  diagram's per-gap labels are IBM's 1-decimal-rounded 15.9/15.9/12.7mm
  (15.9+15.9+12.7 = 44.5 exactly) rather than the exact 15.875/15.875/12.7mm
  (= 44.45 exactly) — the same class of error rack19's RESEARCH.md already
  flagged for Wikipedia's 22.25-vs-22.225 case. **Ship 44.45** (LabRax's own
  explicit statement, and the arithmetically-exact EIA-style figure), not the
  diagram's drifted 44.50.

### Hole horizontal center-to-center — **236.525 mm** — tier [B], two independent sources, exact match

- LabRax article: *"...holes 236.525mm apart..."*
- Wikimedia diagram (independent author, different platform): label reads
  **"236.525 mm [9.312\"]"** for the 10in side — identical to the mm
  precision LabRax states. Strongest-confirmed value in this pass.

### Clear/usable width between posts — **222 mm** (LabRax) vs **222.25 mm** (diagram, = 8.75in exact) — tier [B], `//VERIFY` small discrepancy

- LabRax article: *"...a usable width of 222mm between posts."*
- Wikimedia diagram: **"222.25 mm [8.75\"]"**.
- 0.25mm apart — plausibly LabRax rounding a design dimension to a "nicer"
  metric number vs. the diagram's exact imperial→metric conversion, but this
  pass could not resolve which is LabRax's *actual* printed-part dimension
  (would need the mesh). **Ship LabRax's own stated 222mm** as authoritative
  for LabRax specifically (it is the designer's own figure for their own
  product) — tag `//VERIFY 222 vs 222.25mm — 0.25mm gap unresolved without a
  mesh measurement of the actual LabRax part`.

### Panel outer width — **254.00 mm (10in nominal)** — tier [B], **upgraded from an unsourced seed**

- Not stated anywhere in the LabRax article (checked — no "254" or "outer
  width" statement found in the fetched text).
- Wikimedia diagram states it explicitly: **"254.00 mm [10\"]"**.
- **Closure check** (own arithmetic): diagram's usable width (222.25) + 2 ×
  diagram's post width (15.875, same value as 19in's post width) = **254.00
  mm exactly** — internally consistent within the diagram's own numbers.
- If LabRax's own 222mm (not 222.25) is used instead with the same 15.875mm
  post-width assumption, the implied panel width would be 253.75mm, not
  254.00 — a 0.25mm knock-on from the same usable-width discrepancy above.
  **Tag `//VERIFY LabRax's actual outer panel width (254.00 vs 253.75mm) —
  not stated by LabRax itself, only by the independent (non-LabRax-specific)
  Wikimedia diagram; unresolved without a mesh measurement.`**

### Per-U hole pattern (3-hole EIA sub-pattern) — **6.35 / 22.225 / 38.1 mm offsets (gaps 15.875/15.875/12.7)** — tier [B], LabRax-adoption `//VERIFY`

Two pieces of real evidence, neither of them LabRax stating the exact offsets
itself:

1. **LabRax's own Bill of Materials** (verbatim from the article): *"M6
   Brass Inserts (To Mount Equipment) — 6 per rack unit (U)"*. With 2 front
   posts carrying equipment mounting, that is **3 holes per rail per U** —
   confirming the *hole count* matches the EIA 3-hole-per-U convention (this
   is real, LabRax-specific evidence), but not the exact offset numbers.
2. **Wikimedia diagram, exact coordinates** — extracted by parsing the raw
   SVG's `<circle>` elements and composing their `transform="translate(...)"`
   / `matrix(...)` ancestry in Python (not by reading pixel positions off the
   rendered PNG, which was ambiguous on first inspection): the 10in rack's
   hole column (both left and right posts, x≈26.8 and x≈264.3) repeats with
   consecutive y-gaps of **exactly 15.900 / 15.900 / 12.700 mm** (verified by
   subtracting consecutive `cy` world coordinates: 60.078−44.178=15.900,
   75.978−60.078=15.900, 88.678−75.978=12.700, ...). This is the *same*
   3-hole EIA sub-pattern used on 19in racks, applied to the 10in rack in
   this independent diagram — real corroboration that "10in racks conven-
   tionally reuse the 19in 3-hole-per-U sub-pattern" (the premise LabRax's
   article implies but does not spell out numerically), but again **not**
   LabRax's own stated offsets.
3. The shipped seed **6.35 / 22.225 / 38.1** is the arithmetic-exact form
   (6.35 + 15.875 = 22.225, + 15.875 = 38.1, matching rack19's own
   already-verified derivation) rather than either source's rounded figures
   (IBM/diagram's 15.9/15.9/12.7). **Tag `//VERIFY LabRax adopts the exact
   6.35/22.225/38.1 EIA offsets (vs. some LabRax-specific variant) — LabRax
   itself never states discrete offset numbers, only the 3-per-U hole count;
   offsets are inferred from two indirect sources, not read off LabRax's own
   drawing or mesh.`**

### Mounting depth (post face-to-face) — **240 mm** — tier [C] `//VERIFY`, third-party remix corroboration only

The brief's seed (240mm) had zero support in the designer's own article/page
text or the Wikimedia diagram (front-view hole-pattern only, no depth). A
second, targeted research pass found genuine third-party corroboration:
Printables remix model **1499547** ("8-Bay 10 inch 3U Serverrack Mount for
3.5" HDD - Lab Rax") states, twice, in its own description/summary fields:

> "Designed to fit the Lab Rax or any 10" serverrack with 240mm depth:
> https://makerworld.com/en/models/1294480-lab-rax-10-server-rack-5u..."
> "8 Bay HDD mount with cooling for 10 inch racks with a depth of 240mm."

That remix hyperlinks the *exact same* MakerWorld design id (1294480)
already confirmed elsewhere in this file as canonical LabRax, so this is
genuinely LabRax-specific, not a generic-10in-rack guess. However: the
source is an unaffiliated third-party remixer, not the designer, and not a
caliper/mesh measurement — and the number exactly matches the *seed* value,
which is plausibly coincidental corroboration or plausibly the remixer
having copied a commonly-assumed figure rather than measuring. Six other
LabRax-tagged Printables remixes checked in the same pass state no depth
figure at all.

**Ship 240mm, tier [C], `//VERIFY 240mm depth — sourced only from an
unaffiliated third-party remix description, not the designer or a
mesh/caliper measurement; could be circular`.** This is weaker than a
designer-stated [B] value — Task 2 must tag it accordingly and Task 5
(`rack10_flange_*`/placeholder) should not treat it as load-bearing beyond
an illustrative default, same spirit as rack19's honest
`rack19_depth_preset()` treatment.

### M6 screw clearance — **6.6 mm** — tier [B] ISO 273 close-fit, repo precedent

Not refetched this pass (same paywalled-standard situation `rack19`
documented for ISO 273). Carried forward from `libraries/hardware/hardware.scad`
+ `libraries/rack19/RESEARCH.md`'s own M6 derivation. Directly relevant to
LabRax: the article confirms M6 is LabRax's actual chosen fastener — *"I
opted to use M6 screws over 10-32 screws because they are easier to find in
Australia, Asia, and Europe... Lab Rax is designed to use M6x10mm screws."*

### #10-32 screw clearance — **5.0 mm** — tier [C] `//VERIFY` ANSI B18.2, repo precedent

Carried forward from `libraries/rack19/RESEARCH.md` (named-standard,
not fetched this pass; see that file's own fetch-attempt log for why —
ANSI B18.2 is paywalled, same as ISO 273/EIA-310-D). Relevant to LabRax
because the article explicitly frames #10-32 as the alternative fastener
LabRax could have used (*"I opted to use M6 screws over 10-32 screws
because..."*) — i.e. #10-32 compatibility is a real consideration for this
hardware ecosystem even though LabRax itself ships M6. LabRax also has an
official **"Bolt Together Version (M6 and #10-32 Compatible)"** variant per
the article's own download links, confirming #10-32 is a first-class,
designer-supported option, not just a hypothetical.

### Cage-nut square hole side — **9.5 mm** — tier [B] `//VERIFY`, repo precedent, **not used by LabRax**

Carried forward unchanged from `libraries/rack19/RESEARCH.md` (Wikipedia
Cage nut article, single-sourced there too — not re-verified this pass).
**Explicitly not applicable to LabRax** — LabRax uses M6 brass threaded
inserts melted into the printed posts, not cage nuts or a square-hole rail.
Carried only so a *future* non-LabRax 10in vendor (e.g. a commercial rack
using cage nuts) can be added to this library without re-deriving the value.

### Rail flange width/thickness — **not numerically confirmed — no tier, visual-only evidence**

The mesh-measurement this value was supposed to come from (brief Step 3)
could not be obtained (see STL provenance above). One piece of real but
non-numeric evidence: `labrax-vertpost-thumb.jpg`, a genuine (non-fabricated,
byte-size-matches-manifest) CDN thumbnail render of `5U Vertical Post.stl`
from the bolted-version sibling design, shows an **L-profile extruded rail
with round through-holes** along its length — confirms the general rail
*shape family* (consistent with a folded/printed L-bracket rail, conceptually
similar to rack19's flange envelope) but a JPEG render has no scale
reference, so **no mm figure can be extracted from it**. No value is
asserted; Task 2+ should carry this as an explicit unknown/tunable default,
not a sourced constant, same treatment rack19 gave its own flange thickness.

## Device height / stacking gap (Task 1 follow-up)

No LabRax-specific or 10in-mini-rack-specific source states a device max
height or a stacking-gap tolerance — searched the LabRax article, the
Wikimedia comparison diagram (front-hole-pattern only, no panel-height
relief dimension), and a general web search for "10 inch rack panel height
clearance/tolerance" (turned up Jeff Geerling's Mini Rack project and 3D
Rack Mounts' UniFi guide, neither of which states a panel-height relief
figure — both only discuss width/depth clearances). This is the same
"no governing standard" situation the rest of this file already documents
for every other 10in-specific dimension.

### Borrowed value — **43.66 mm max 1U device height / 0.79 mm stacking gap** — tier [C] `//VERIFY`

- Per `libraries/rack19/RESEARCH.md`'s own Device-height/stacking-gap section
  (tier [B] there: Wikipedia `Rack_unit` + Micropolis rack-mounting FAQ,
  exact match): a 1U EIA-310 panel's max height is **43.66 mm (1.719 in)**,
  i.e. **0.79 mm (0.031 in)** less than the 44.45 mm U pitch, applied **once
  per device** (not once per internal U), via `h = 44.45n − 0.79`.
- LabRax explicitly states it reuses the EIA-310 **44.45 mm U pitch** itself
  (already cited above: *"It uses the standard 44.45mm rack unit spacing that
  is used on larger 19-inch racks"*) and its BOM/hole-count evidence already
  confirms LabRax reuses the **same 3-hole-per-U EIA sub-pattern** — i.e.
  LabRax's own stated design philosophy is "borrow 19in EIA-310 conventions,
  narrower width only." Given that pattern, borrowing the *same* panel-height
  relief (rather than inventing a different one) is the most consistent
  assumption, but **this is an inference by analogy, not a LabRax-stated or
  10in-specific fact** — no source (LabRax article, Wikimedia diagram, or
  general search) states a 10in-rack panel-height/gap number directly.
- This lands at tier **[C]**, one step weaker than rack19's [B] for the same
  underlying number, precisely because rack10 has no standard to borrow
  from *by right* — only by the same "most commonly accepted dimensions"
  logic LabRax itself invokes for the U pitch. **Same value as rack19: 43.66
  mm / 0.79 mm** — explicitly noting agreement per the task brief, since both
  libraries' plausible number is identical (rack10 has no independent reason
  to differ, having borrowed the U pitch itself).
- Tag `//VERIFY 43.66mm device height / 0.79mm gap borrowed from EIA-310 by
  analogy — LabRax states no 10in-specific panel-height relief tolerance;
  if `rack10_stack_gap()`/`rack10_device_height()` prove to not match a real
  LabRax part in practice (e.g. a caliper check of a printed post), revise
  independently of rack19 rather than assuming permanent parity.`
- Same non-per-U-multiplication note as rack19 applies here too:
  `rack10_device_height(u)` should be `u * 44.45 - 0.79`, not a per-U-scaled
  variant.
- Consumer note: bpi-r4 chassis to replace its project-local `stack_gap` with `rack10_stack_gap()` (post-wave).

## Summary table for Task 2+

| Value | mm | tier | source |
|---|---|---|---|
| 1U pitch | 44.45 | [B] | LabRax article (explicit); diagram's 44.50 is a rounding-chain artifact, not used |
| hole h center-to-center | 236.525 | [B] | LabRax article + Wikimedia diagram, exact match, 2 independent sources |
| clear/usable width | 222 (ship) / 222.25 (diagram, unresolved) | [B] `//VERIFY` 0.25mm gap unresolved | LabRax article; diagram (8.75in exact) |
| panel outer width | 254.00 | [B] `//VERIFY` LabRax's own value not stated, only the independent diagram's | Wikimedia diagram (10in nominal, closure-checked against its own 222.25 + 2×15.875) |
| per-U hole offsets | 6.35 / 22.225 / 38.1 (gaps 15.875/15.875/12.7) | [B] `//VERIFY` LabRax-specific offsets not stated, only hole-count (BOM) + pattern-reuse (diagram) | LabRax BOM ("6 per U") + Wikimedia diagram exact SVG coordinates |
| mounting depth | 240 (ship) | [C] `//VERIFY`, third-party remix only | Printables remix 1499547 description (2x), links same MakerWorld id 1294480 |
| M6 clearance | 6.6 | [B] | ISO 273 close-fit, repo `hardware`/`rack19` precedent; LabRax confirms M6 is its actual fastener |
| #10-32 clearance | 5.0 | [C] `//VERIFY` | ANSI B18.2, repo `rack19` precedent; LabRax confirms #10-32 as a real alternative + ships a dedicated bolt-together variant |
| cage-nut square | 9.5 | [B] `//VERIFY`, not used by LabRax | repo `rack19` precedent (Wikipedia Cage nut), carried for future non-LabRax vendors |
| rail flange width/thickness | — | not numerically confirmed — no tier, visual-only evidence | LabRax STL unreachable; one qualitative CDN thumbnail confirms rail shape family only, no dimension |
| 1U max device height | 43.66 (exact 43.6626) | [C] `//VERIFY` borrowed by analogy | rack19's [B] value (Wikipedia + Micropolis); no 10in-specific source |
| stacking gap | 0.79 (total, not per-U) | [C] `//VERIFY` borrowed by analogy | rack19's [B] value; no 10in-specific source |

## Coverage / gaps for README (Task 6+)

- **Device height / stacking gap** — no LabRax-specific or 10in-specific
  source exists; the shipped 43.66mm/0.79mm figure is rack19's EIA-310 value
  borrowed by analogy (tier [C]), since LabRax explicitly borrows the
  44.45mm U pitch and 3-hole sub-pattern from EIA-310 already. Flag for a
  caliper check of an actual printed LabRax post if one becomes available.
- **Mounting depth** has zero sourcing this pass — genuinely omitted, not a
  `//VERIFY` guess. Needs either a working STL fetch or a caliper measurement
  of a physical LabRax print before Task 2/5 can assert a real number.
- **Rail flange width/thickness** — same story: STL unreachable, only a
  qualitative shape render obtained, no dimension extractable.
- **Panel outer width (254mm) and per-U offsets (6.35/22.225/38.1)** are
  evidenced by an independent, to-scale Wikimedia diagram, but that diagram
  is **not LabRax-specific** — it documents the general 10in-rack convention
  LabRax's article says it follows, not a direct reading of LabRax's own
  design. Treat as strong circumstantial evidence, not a direct LabRax
  confirmation, until the actual STL/3MF can be fetched and measured.
- **Clear width (222 vs 222.25mm)** — a small, unresolved 0.25mm discrepancy
  between LabRax's own stated figure and the independent diagram's exact
  imperial conversion. Shipped LabRax's own number; flagged for a future
  mesh or caliper cross-check.
- The LabRax STL/3MF (brief Step 3) was not obtainable, so the mesh could not
  be measured — same class of obstacle as `rack19`'s EIA-310-D paywall.
