# drives — research log (Task 1)

Scope: scaffold + evidence gathering only. `drives.scad` ships only the
header + `drive_known_types()` stub this pass (empty tables) — the tables
below are what Task 2 transcribes into `_block_table()` / `_card_table()`.
Every value is tiered by what was *actually fetched and read this pass*
(docs/LIBRARY-AUTHORING.md tiers), not by the task brief's seed table.

## Method / environment note

Every spec below was read directly from its primary source document.

**SNIA/SFF specifications were obtained and read this pass** — a better
sourcing outcome than `rack19`'s EIA-310 (fully paywalled). The SFF spec PDFs
(`https://members.snia.org/document/dl/<id>`, indexed from
`https://www.snia.org/technology-communities/sff/specifications`) are public
documents — no login/paywall gate, despite the `members.` subdomain in the URL.

The Mouser-hosted vendor datasheets (Advantech SQFlash 920, Intelligent
Memory) were not accessed this pass; `digikey.com`- and
`vikingtechnology.com`-hosted PDFs were read without issue.

## Sources fetched and read this pass

| # | Spec / doc | URL | Cached as |
|---|---|---|---|
| 1 | **SFF-8301 Rev 1.9** — 3.5" Form Factor Drive Dimensions | `https://members.snia.org/document/dl/25862` (linked from `snia.org/technology-communities/sff/specifications`) | `sff-8301.pdf` |
| 2 | **SFF-8201 Rev 3.4** — 2.5" Form Factor Drive Dimensions | `https://members.snia.org/document/dl/25851` | `sff-8201.pdf` |
| 3 | **SFF-8223 Rev 2.7** — 2.5" Drive Form Factor w/ Serial Attached Connector (SATA/SAS connector location) | `https://members.snia.org/document/dl/25855` | `sff-8223.pdf` |
| 4 | **SFF-TA-8639 Rev 2.2** — Multifunction 6X Unshielded Connector (U.2 mechanical spec) | `https://members.snia.org/document/dl/26489` | `sff-8639a.pdf` |
| 5 | SFF-TA-1001 Rev 1.1 — Universal x4 Link Definition for SFF-8639 (electrical, **not** used — no mechanical content) | `https://members.snia.org/document/dl/26900` | `sff-8639b.pdf` (fetched, not cited for values) |
| 6 | Viking Technology `PSFEM5xxxxBxxx` — M.2 (2280) **SATA** SSD datasheet, Rev A1 2018-07-31 | `https://www.vikingtechnology.com/wp-content/uploads/2021/03/M2_80mm_SMI_SM2258.pdf` | `m2-viking-2280-sata.pdf` |
| 7 | Viking Technology `PSFNP5xxxx5xxx` — M.2 2280 **NVMe/PCIe** SSD manual, Rev C 2019-08-19 | `https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/331/PSFNP5xxxx5xxx_C.pdf` | `m2-viking-nvme-2280.pdf` |

All seven are vendor/standards-body documents fetched and read this pass —
tier **[A]** per docs/LIBRARY-AUTHORING.md ("upstream vendor datasheet or
governing standard... fetched + read this pass"), except where noted `//VERIFY`
below for values that are *inferred* from a figure rather than directly labeled.

**Not accessed** this pass: Advantech SQFlash 920 and Intelligent Memory M.2
datasheets (both `mouser.com`-hosted). Not required in the end since the two
Viking datasheets (SATA + NVMe variants of the same 2280 form factor) gave
full mechanical figures.

**Not fetched at all** (no attempt / out of scope this pass): JEDEC MO-297,
PCI-SIG M.2 Electromechanical Spec (both known-paywalled to non-members —
PCI-SIG specs require paid membership; not tried, so this is a recorded gap,
not a confirmed-paywall like rack19's EIA-310 experience). M.2 2260/2242/2230
vendor drawings (only 2280 fetched).

## Datum convention used below

To make every table entry unambiguous ahead of Task 2, this pass fixes a
concrete datum choice consistent with the `drives.scad` stub's header
(`+X` = length, `+Y` = width, `+Z` = up, bottom face `Z=0`), since the stub
comment doesn't say which end of the length axis is `X=0`:

- **`X=0` at the connector end**, `+X` toward the free/far end. This mirrors
  every fetched SFF drawing's own datum choice (SFF-8301's `-Y-`, SFF-8201's
  "CONNECTOR END" edge) — reusing it avoids a transcription-direction error.
- **`Y=0` at the edge nearest the smaller edge-inset hole column** (SFF-8301's
  `A5`-side, SFF-8201's `A28`-side — called "left" below when the drive is
  viewed from below/underneath with the connector end at top), `+Y` across
  the width to the other side.
- **`Z=0` at the bottom face**, `+Z` up (component/top side).

Every `[x,y]`/`[x,z]` pair below is in this frame. Where a spec's own figure
uses a different named datum (e.g. SFF-8223's "Datum B" = a mounting screw,
not the envelope corner), that is called out explicitly and the translation
into the envelope-corner frame above is marked as this pass's **own
arithmetic** (not a directly-labeled spec value) per the `rack19` closure-check
precedent.

---

## Confirmed values

### 1. `hdd35` — 3.5" — SFF-8301 Rev 1.9, Figure 3-1 + Table 3-1 — tier [A]

Table 3-1 dimension letters, transcribed directly (mm):

| Dim | mm | Meaning (from Fig 3-1 + §3.1 text) |
|---|---|---|
| A1 | 17.80 / **26.10** / 42.00 (all Max) | height (Z) — three drive-height classes; brief's seed height (26.1) is the middle ("1-inch") class, confirmed exact |
| A2 | 147.00 Max | length (X) |
| A3 | 101.60 | width (Y) |
| A4 | 95.25 | bottom hole far column, X-offset from left edge (Y in our frame) |
| A5 | 3.18 | bottom hole near column, Y-offset from left edge |
| A6 | 44.45 | bottom hole 2nd-row spacing *from the A7 row* (incremental) |
| A7 | 41.28 | bottom hole 1st (required) row, X-offset from connector-end datum |
| A8 | 28.50 | side hole 1st (near) row, X-offset from connector-end datum |
| A9 | 101.60 | side hole row-to-row spacing (hole-to-hole, not cumulative from datum) |
| A10 | 6.35 | side hole Z-height above the bottom face (revised — see Task 2 resolutions (c); originally mistranscribed as an X-offset) |
| A11 | 0.25 | tolerance (± on A6/A7/A8/A9/A10/A13 dims) |
| A12 | 0.50 | tolerance (± on A6/A7 dims per fig, see below) |
| A13 | 76.20 (3.000 in) | bottom hole alternate 2nd row, X-offset **directly from connector-end datum** (added Rev 1.5, "new bottom fastener position") |
| Threads | 6-32 UNC-2B, fastener penetration 2.39–3.56mm | both bottom and side holes |

Figure 3-1 reading (own transcription from the rendered drawing,
`sff-8301-fig-600.png` / crops `sff-8301-crop-*.png`): the drawing chains A5
and A4 from the **same** left-edge datum (both terminate on hole-column
lines, not on the right edge — closure check: `A3 − A4 = 101.60 − 95.25 =
6.35mm` = the far column's inset from the right edge, an internally
consistent mirror of A5=3.18 near-edge inset, i.e. **not symmetric** — near
inset 3.18mm, far inset 6.35mm. Hole crosshairs are drawn schematically at
the rectangle's own edge lines in the figure — not to scale; the numeric
callouts govern.). §3.1 text: "the pair of bottom mounting holes located by
dimension A7 is required. One additional pair... either A6 or A13... all
three allowed." So bottom holes are 2–3 *rows* (each row = a Y=3.18/Y=95.25
pair), not a single fixed 4-hole rectangle.

**Bottom holes** (`[x,y]`, mm, connector-end datum):
```
required row (A7):      [41.28,  3.18], [41.28,  95.25]
optional row (A6 from A7): [85.73,  3.18], [85.73,  95.25]   // A7+A6 = 41.28+44.45
optional row (A13 direct): [76.20,  3.18], [76.20,  95.25]
```
`A6` row and `A13` row are two **different, mutually-optional** rear-hole
positions (not the same row expressed two ways) — a drive vendor picks one,
the other, or provides both. Tier **[A]** for all six coordinates (arithmetic
combination of directly-read A-values, flagged per rack19 precedent).

**Side holes** (`[x,z]`, mm; two side faces at `y=0` and `y=101.60`):
```
X: 28.50 (A8, near) and 130.10 (A8+A9 = 28.50+101.60, far)
Z: 6.35 (A10) — see Task 2 resolutions (c) for the revised reading
```
Closure check (X only): `A10` is NOT part of the X chain (see below), so the
real X closure is just `A8 + A9 = 130.10mm < A2 (147.00 max)` — a ~17mm
margin to the connector-end edge, consistent with the connector-end
lip/bezel. Tier **[A]** for X.

**Z-height of the side holes — originally recorded as a gap; revised this
pass (Task 4).** SFF-8301 Figure 3-1 *does* dimension it: `A10 ± A11 =
6.35mm` is drawn as a horizontal dimension in the side-view strip, not a
further X-offset as this section originally transcribed it — it runs between
the strip's own edge and the hole crosshair, perpendicular to the A8/A9 chain,
not in line with it. Full derivation and sourcing in Task 2 resolutions (c)
below.

**Connector** (SATA/power combo at the connector end): **not covered this
pass.** SFF-8301 defines only the bottom/side mechanical envelope, not
connector position — that would be a separate SFF spec (SFF-8482 series) not
fetched this pass. Recorded as a gap, not fabricated.

Thread: **6-32 UNC** (both bottom and side); clearance-hole diameter is not
in SFF-8301 (which specifies the *tapped* thread, not a clearance dia — the
brief's "~3.5mm clearance" seed is a downstream consumer's clearance-fit
choice for a 6-32 screw, not a spec value). Imperial 6-32 clearance is not
yet modeled in this repo (metric ISO-273 clearances are inlined
per-consumer); a `#6` (6-32 UNC) imperial clearance constant is a **gap**,
not fabricated into `drives`.

---

### 2. 2.5" family (`ssd25_7` / `ssd25_9` / `ssd25_15` naming) — SFF-8201 Rev 3.4 — tier [A]

Table 3-1 dimension letters actually used (mm):

| Dim | mm | Meaning |
|---|---|---|
| A1 | 19.05 / 17.00 / 15.00 / 12.70 / 10.50 / **9.50** / 8.47 / **7.00** / 5.00 | height (Z) — 9 standard classes; brief's `{7.0\|9.5\|15.0}` all present verbatim |
| A4 | 69.85 | width (Y); `(A4+A5)` = max width 70.10 per Note 1 |
| A5 | 0.25 | width tolerance/gap component |
| A6 Max | 100.45 (new requirement) / 101.85 (obsolete) | length (X) — **two envelope generations**, see note below |
| A23 | 3.00 | side-hole callout position (own reading: Z-height of the side-hole centerline above the bottom face — see caveat below) |
| A28 | 4.07 | bottom hole near column, Y-offset from left edge |
| A29 | 61.72 | bottom hole column spacing (near→far) |
| A32 | M3 | bottom-hole thread |
| A26 | M3 | side-hole thread |
| A37 | 8.00 | hole counterbore/spotface diameter (both bottom and side) |
| A50/A52 | 14.00 (both identical) | side hole near row, X-offset from connector-end datum (A50=right-side strip, A52=left-side strip — same nominal value, separate GD&T refs) |
| A51/A53 | 90.60 (both identical) | side hole far row, X-offset **directly** from connector-end datum (not incremental — see reading note) |

**Envelope length — two generations**: A6 Max = 101.85mm is explicitly marked
"Obsolete" in the table, replaced by 100.45mm "New requirement". Note 2 also
states dimensions A10/A11/A12 (form-factor-with-connector figure, not
transcribed this pass) "are based on a nominal form factor length of
100.20mm" — i.e. the spec's own internal nominal/reference length is
**100.20mm**, distinct from the A6 envelope max of 100.45mm. Brief's seed of
"100.0" is close to both but matches neither exactly; recording all three
(100.20 nominal, 100.45 new-max, 101.85 legacy-max) tier [A] rather than
picking one silently. Many real-world (older, thicker/rotational) 2.5" HDDs
are built to the legacy 101.85 envelope — worth keeping both for fit-check
conservatism in Task 2.

**Bottom holes** (Figure 3-1 + Figure 3-3 "Required Mounting Holes" —
4 corner holes, all optional when A1 ≤ 7mm per the figure's own note):
Y (width, from left edge) is explicit: near column 4.07, far column
`4.07+61.72=65.79` (closure: `69.85−65.79=4.06≈4.07`, consistent
near/far edge inset). **X (length) is not independently re-dimensioned** for
the bottom holes in Table 3-1 — Figure 3-1 draws the 4 bottom-view corner
holes visually row-aligned with the two side-hole rows, and the side-hole
X-offsets (A50/A52=14.00, A51/A53=90.60) are numerically identical across
their nominally-separate GD&T references, strongly suggesting the bottom
holes reuse the same X positions. This is **this pass's own inference**, not
a value explicitly re-stated for the X1–X4 bottom holes — tag `//VERIFY`.

```
bottom holes [x,y] (X inferred //VERIFY, Y confirmed [A]):
[14.00, 4.07], [14.00, 65.79], [90.60, 4.07], [90.60, 65.79]
```

**Side holes** `[x,z]` (two side faces at `y=0` / `y=69.85`):
```
X: 14.00 (near), 90.60 (far)   — [A], direct off Figure 3-1
Z: 3.00 (A23)                  — [A] value, but see semantic caveat below
```
**Caveat on A23/Z-height**: the spec's Table 3-1 and Figure 3-1 give A23 =
3.00mm and place its dimension bracket at the bottom-left of the figure, in
the position expected for a hole-centerline-above-bottom-face callout — but
no prose in §3 explicitly states "A23 = side-hole Z height" (unlike A28/A29
which are unambiguous from the figure's own extension lines to the hole
columns). The **number** is tier [A] (read off the spec this pass); the
**semantic assignment** ("this is the Z-height of the side-mount hole") is
this pass's interpretation of the figure layout, not an explicit label —
flagged for Task 2 to double check against the raw PDF page (`sff-8201-p9.png`)
before treating it as load-bearing.

**Connector**: see §3 (SFF-8223) below — 2.5" SATA/SAS connector location is
a separate spec from SFF-8201.

---

### 3. `u2` — SFF-TA-8639 Rev 2.2, Figure 5-1 "Device Free (Plug) Connector" — tier [A]

Body envelope: reuses the 2.5" 15mm-height table above (`[100.45|100.20,
69.85, 15.0]`) per the brief — SFF-8639 itself only specifies the
**connector**, not the drive body (U.2 drives are mechanically 2.5"-15mm
drives with the SFF-8639 connector replacing the SATA/SAS one).

Connector mechanical envelope, read directly off Figure 5-1 (`sff-8639a-p15.png`):
```
overall width (Y, pin-row span):   33.43 ± 0.05mm   [A]
envelope length (X, connector body): 42.73 (ref) / 41.13 ± 0.15mm (functional)  [A]
overall height (Z, pin/blade row):  4.90 ± 0.08mm    [A]
```
Cross-check against SFF-8223 (below): SFF-8223's A3 "connector body width" =
33.39mm and A2 "connector envelope length" = 42.73mm — both essentially
identical to the SFF-8639 figures (33.43 vs 33.39, 0.04mm apart; 42.73 exact
match on length). This is expected and stated in SFF-8639's own abstract:
the connector is designed to be a mechanical/pin-compatible superset of the
SATA/SAS connector position defined by SFF-8482/SFF-8223, i.e. **the U.2
connector occupies the same PCB position as the SATA connector it
replaces** — so the position-on-PCB derivation gap noted for §4 below applies
identically here.

**Position on the PCB** (X,Y,Z placement, not just extents): **not resolved
to a firm number this pass** — see §4's derivation gap. SFF-8639 Figure 5-1
only dimensions the *connector part itself* (mating-side/plug geometry), not
its placement on a host PCB; that placement is what SFF-8223 (§4, SATA) and
by the compatibility statement above, SFF-8639/U.2 also inherits.

---

### 4. 2.5" SATA/SAS connector location — SFF-8223 Rev 2.7 — tier [A]

Table 3-1 (mm), Figure 3-1 "Option 1: referenced to bottom mounting screw"
(`sff-8223-p9.png`, `sff-8223-p10.png`):

| Dim | mm | Meaning |
|---|---|---|
| A1 | 69.85 | drive width (cross-check vs SFF-8201 A4 — exact match) |
| A2 | 42.73 | connector envelope length (cross-check vs SFF-8639 — exact match) |
| A3 | 33.39 | connector body width (cross-check vs SFF-8639's 33.43 — 0.04mm apart) |
| A8 | 9.40 | connector Z-height above **Datum B** (a bottom mounting-screw hole, not the envelope) |
| A11 | 4.80 | connector X-offset from Datum B |
| A13 | 13.43 | connector inset from the drive's connector-end edge |
| A14 | 37.20 | connector functional-contact width (dashed, inside A2) |

**Position-on-PCB gap**: SFF-8223 dimensions the connector relative to
**Datum B**, which its own Figure 3-1 defines as "centerline of datum B" = a
specific bottom mounting-screw hole (the near-connector-end hole), *not* the
envelope corner this RESEARCH.md's own datum convention uses. A full
translation would require: `connector_x = (SFF-8201 near-hole X) ±
(SFF-8223 A11-derived offset)`, similarly for Y/Z — i.e. composing two
different specs' figures through an intermediate screw-hole datum. This
pass transcribed both specs' raw values (tier [A] each) but did **not**
carry out that cross-spec composition to a final `[x,y,z]` connector
position — the risk of a sign/axis error compounding across two independently-
read figures is high enough that shipping an unverified composed number
would violate the "don't fabricate/inflate" instruction. **Recorded as an
open item for Task 2**: either (a) do the composition carefully with both
raw figures open side-by-side, or (b) fetch SFF-8223 Option 2 ("referenced to
side mounting screw") for a cross-check, or (c) fetch SFF-8482 directly if a
simpler envelope-corner-referenced figure exists there. Not fetched this
pass (time-boxed after 4 full spec figures already transcribed).

---

### 5. M.2 `m2_2280` — Viking Technology NVMe (`PSFNP5xxxx5xxx` Rev C) + SATA (`PSFEM5xxxxBxxx` Rev A1) datasheets, Figure 3-1 — tier [A]

Both vendor datasheets describe the same 2280 mechanical envelope; NVMe
variant (`m2-nvme-p18.png`) has the fuller dimension set and is the primary
source below, cross-checked against the SATA variant (`m2-viking-p10.png`
et seq.) where both give a value.

```
width (Y):              22.00 ± 0.15mm        [A], both datasheets agree exactly
length (X):              80.00 ± 0.15mm        [A], both datasheets agree exactly
PCB thickness:            0.80 ± 0.08mm        [A], both datasheets agree exactly
top-side component max height: 1.35mm          [A], NVMe datasheet only (SATA
                                                 datasheet's page 11 render did not
                                                 clearly show this callout — not
                                                 independently corroborated, single-source)
mount hole clearance dia:  3.50 ± 0.08mm        [A]
mount hole keepout/pad OD: 5.50 ± 0.10mm        [A]
mount hole Y (centerline):11.00mm  (= width/2, exactly centered)   [A]
mount hole X (from far/free end): 1.45mm inset  [A] — close to and now
                                                 supersedes the brief's seed "~1.5"
card-edge contact width:  19.85 ± 0.15mm, centered on width         [A]
                           (inset (22.00-19.85)/2 = 1.075mm each side)
key:                      "M" — confirmed via NVMe datasheet's pin table
                           (pins 59-66 called out "Module Key M")   [A]
```

In this RESEARCH.md's datum (X=0 at connector end): **mount hole X =
80.00 − 1.45 = 78.55mm**, Y = 11.00mm (own arithmetic from the two directly-
read values, flagged per convention).

**Single-sided module height** (bottom-face-to-top-of-tallest-component, for
a placeholder envelope): `PCB (0.80) + top-side component max (1.35) =
2.15mm`. This **replaces** the brief's seed "~2.3 (//VERIFY)" with a
figure now confirmed [A] this pass — no longer //VERIFY. (Double-sided
modules, with components on the bottom face too, are **not** covered this
pass — both fetched datasheets are single-sided-only variants; a
double-sided-module bottom clearance is a gap.)

**`m2_2260` / `m2_2242` / `m2_2230` — length variants NOT independently
fetched this pass.** Only the 2280 length was in either fetched vendor
datasheet. The `WWLL` M.2 naming convention (width-then-length in mm, e.g.
"2242" = 22mm × 42mm) is treated as definitional/extremely well known but
**no second source was actually fetched and read this pass** to corroborate
60/42/30mm specifically, so per the tiering discipline these three lengths
are tier **[C] `//VERIFY (cited-not-fetched)`** — width (22.00), mount-hole
Y-centerline (11.00, = width/2), key convention, and PCB thickness/height
figures are assumed to carry over unchanged from 2280 (same width, same
spec family) but the **mount-hole X-inset-from-far-end for the shorter
lengths is not assumed to be the same 1.45mm** — shorter modules' hole
position was not checked and could differ; flagged `//VERIFY` rather than
guessed.

**Connector key notch position** (physical mm offset of the M-key notch
along the card edge, for a card-edge cutout stamp): not derived this pass —
only the pin-index range (59-66) was read from the NVMe pinout table, not
translated to a millimeter offset along the 19.85mm contact width. Gap,
flagged for Task 2.

---

## Gaps / disagreements summary (honesty checklist)

| Item | Status |
|---|---|
| 3.5" side-hole Z-height | **Closed in Task 4.** SFF-8301's own A10=6.35mm *is* the Z-height (a horizontal dimension in Fig 3-1, previously mistranscribed as an X-offset); corroborated by Seagate's independently-drawn BarraCuda manual Figure 3 (same value, same geometric role) — number+role tier [B]. Which face it's referenced from (top vs bottom) is inferred, not stated in prose, from WD's side-view rendering showing the PCB (bottom-mounted) hugging the same edge as the Z-datum tag — `//VERIFY` on face-orientation only. See Task 2 resolutions (c), "Task 4 update." |
| 3.5" connector (SATA/power) position/extents | **Not covered by SFF-8301** (needs SFF-8482, not fetched). Gap. |
| 2.5" bottom-hole X (length) position | Inferred from side-hole X by visual row-alignment, not an explicit table value. `//VERIFY`. |
| 2.5" A23 semantic ("side-hole Z-height") | Number is [A]-sourced; its *meaning* is this pass's figure-layout inference, not an explicit spec label. Flagged. |
| 2.5"/U.2 SATA connector X/Y/Z position on PCB | SFF-8223 dimensions it from a screw-hole datum (not the envelope corner); cross-spec composition to envelope-corner coordinates not completed this pass — open item for Task 2. |
| 2.5" envelope length: 100.20 (nominal) vs 100.45 (new max) vs 101.85 (obsolete max) | All three are genuine spec values for different purposes/eras — not a disagreement, but Task 2 must pick deliberately, not silently. |
| M.2 2260/2242/2230 | Not fetched this pass at all — length values are the well-known naming-convention numbers, tier [C] `//VERIFY`, not independently corroborated this pass. |
| M.2 key-notch physical mm offset | Not derived (only pin-index range read). Gap. |
| M.2 double-sided module height | Not covered — both fetched datasheets are single-sided variants. Gap. |
| JEDEC MO-297 / PCI-SIG M.2 spec | Not attempted this pass (known member-paywalled specs) — a vendor datasheet was used instead per the brief's fallback instruction. Not a confirmed-paywall test like rack19's EIA-310; just not tried. |
| Advantech / Intelligent Memory M.2 datasheets (Mouser-hosted) | Not accessed this pass — not used; Viking datasheets (digikey/vikingtechnology-hosted) substituted successfully. |
| 3.5" fastener: imperial 6-32 UNC clearance-hole diameter | Imperial 6-32 clearance is not yet modeled in this repo (metric ISO-273 clearances are inlined per-consumer) — a `drives`-consumer will need this; noted as a gap, not fabricated into `drives`. |

No values in this document were carried over from the task brief's seed
table without being re-derived from a fetched-and-read source this pass, or
explicitly flagged `//VERIFY`/gap where that wasn't possible.

---

## Task 2 resolutions

Five open items from the gaps table above were resolved this pass while
filling `drives.scad`'s data tables. Each is documented here with the
arithmetic/reasoning; the same reasoning is echoed as inline comments next
to the corresponding constant function in `drives.scad`.

### (a) 2.5" envelope length: which of 100.20 / 100.45 / 101.85?

The task-2 brief's own verbatim test (Step 1) hard-codes
`assert(drive_size("ssd25_7") == [100.0, 69.85, 7.0], ...)` — i.e. the test
forces **X = 100.0mm**, which is not identical to any of the three genuine
SFF-8201 values recorded in Task 1 (100.20 nominal, 100.45 new-Max,
101.85 obsolete-Max). Since the interface contract (the test) is
authoritative for Task 2 and 100.0 is closest to the spec's own internal
nominal (100.20mm, off by 0.20mm — Note 2's "nominal form factor length"
used for the A10/A11/A12 connector-area dimensions), **100.0 is used**,
tagged `[C]` (test-mandated round number, not a directly-transcribed
spec value). This deliberately does **not** follow the `motherboards`-library
precedent of using the spec's own stated Max for conservatism — the test
leaves no latitude. Flagged consequence for downstream consumers: legacy
2.5" HDDs built to the obsolete 101.85mm envelope will not clear a fixture
sized to this 100.0mm reference; a consumer needing legacy-HDD clearance
should add margin rather than trust this library's `ssd25_*` envelope length
as a tight fit.

### (b) 2.5"/U.2 SATA connector position on PCB

SFF-8223 Table 3-1 dimensions the connector two ways: relative to **Datum
B** (a bottom mounting-screw centerline — A8=9.40, A11=4.80), and via a set
of dimensions that read directly off the drive's own edges without going
through the screw-hole datum at all (A7, A5, A13, A3). Task 1 flagged the
Datum-B composition path as too risky to attempt blind. This pass re-examined
the actual Figure 3-1 rendering (`crop_top_left.png`, `crop_bottom_left.png`,
freshly viewed this pass) rather than composing through Datum B, and found
the self-contained path sufficient:

- The figure's axis-reference boxes (`Y` at the top-left corner of the
  horizontal `(A1)`=69.85mm width dimension; `X` at the bottom-left corner of
  the vertical `A7 +/- A12` dimension) show this sub-view is drawn with
  **physical Y running horizontally on the page and physical X running
  vertically** (a 90°-rotated plan view) — confirmed by `(A1)=69.85` matching
  the known drive WIDTH exactly (cross-checked against SFF-8201's A4=69.85).
- `A7 +/- A12` (vertical on page ⇒ physical X) runs from the top edge of the
  rectangle (the connector-end datum, X=0) down to the near edge of the
  connector detail ⇒ **A7 = 3.50mm is the connector's X-offset from the
  connector-end edge.** This is corroborated by SFF-8323's abstract text:
  "The connector location is nominally flush to the drive form factor" — a
  3.50mm offset is consistent with "nominally flush."
- `(A13)` and `(A3)` are drawn as a horizontal pair near the bottom of the
  same sub-view (horizontal on page ⇒ physical Y) ⇒ **A13 = 13.43mm is the
  connector's Y-inset from the near side edge, A3 = 33.39mm is the
  connector body's Y-extent** (width across the connector). A3 is
  corroborated against SFF-TA-8639 Figure 5-1's own directly-read
  "overall width (Y, pin-row span) 33.43mm" — 0.04mm apart, same part.
- `(A5)` is drawn as a short vertical dimension (physical X) next to the
  Detail-A keepout callout ⇒ **A5 = 4.00mm is used as the connector's
  X-extent** (depth of the connector body in the insertion direction). This
  is this pass's own inference from the figure's dimension placement, not an
  explicitly-labeled "X-extent" in the spec text — flagged `//VERIFY`.
- Z is **not** given by SFF-8223's own figure in this envelope-corner frame
  (the A8 dimension is relative to Datum B, a screw-hole centerline, not the
  bottom face — composing it would require the same risky cross-datum
  arithmetic Task 1 already declined). **Z_min = 0 is assumed** (connector
  flush to the bottom face), flagged `//VERIFY`. **Z_extent = 4.90mm** is
  reused from SFF-TA-8639 Figure 5-1's direct height read (pin/blade row
  height) — applied to the plain-SATA connector too since SFF-8639's own
  abstract states it is a mechanical/pin-compatible superset of the SATA/SAS
  connector position, but flagged `//VERIFY` since a bare 2-pin-row SATA
  connector's height was not independently confirmed.

Result — `sata` connector record used for `hdd35`/`ssd25_*`:
`["sata", [3.50, 13.43, 0], [4.00, 33.39, 4.90]]`
(position numbers A7/A13 tier **[A]**, extent A3 tier **[A]**, A5/Z tier
`//VERIFY`).

`sff8639` connector record used for `u2` — same PCB position (per SFF-8639's
compatibility statement), SFF-8639's own slightly different width/height
figures:
`["sff8639", [3.50, 13.43, 0], [4.00, 33.43, 4.90]]`
(Y-extent 33.43 tier **[A]**, direct off SFF-8639 Fig 5-1; X-offset/inset
reused from the SATA derivation above, `//VERIFY` for the same reasons).

### (c) 3.5" side-hole Z-height and 3.5" connector position/extents

Re-verified this pass by fetching and reading `sff-8482.pdf` (SFF-8482 Rev
2.5, bare SATA connector part spec) and `sff-8323.pdf` (SFF-8323 Rev 1.6,
"3.5" Form Factor Drive with Serial Attached Connector").

- **SFF-8482**: explicitly defers connector *location* to "the appropriate
  Form Factor Specifications" (§5.2) and contains zero side-hole content —
  confirmed it answers neither gap. Not used for any value.
- **SFF-8301 side-hole Z** — *historical note, superseded by the Task 4
  update immediately below:* at this pass in the research, Figure 3-1 was
  re-confirmed (again) to have no Z-dimension tied to the side holes
  anywhere in the figure, and the X positions (A8=28.50mm near,
  A8+A9=130.10mm far, both tier **[A]**) were recorded in a `drives.scad`
  comment pending a second source for Z. This gap was closed by the Task 4
  work below — see that section for the resolved Z value and current
  `SIDE_35()` behavior.

**Task 4 update — gap closed.** Re-examined the question from scratch before
implementing `drive_holes()`, since the brief's own test asserts
`len(drive_side_holes("hdd35")) >= 2`. Read three new sources:

1. **WD white paper, "3.5-inch Form Factor Mounting Screw Locations and
   Depths" Rev A03** (`support.wdc.com/images/kb/2579-771970-A03.pdf`,
   explicitly cites governing doc as SFF-8300 Rev 2.4). Reproduces the
   identical SFF-8301 Figure 3-1 / Table 3-1 as our own SFF-8301 fetch — not
   an independent numeric source, but its **Figure 4/5 side-mount-hole
   rendering** (`wd-3.5-p5-re.png`) is a labeled 3D-ish side view showing the
   PCB as a visually distinct slab (hidden-line rendering, `wd-fig4-notch-
   crop.png`) protruding from one edge of the casting — used below to
   resolve which face a Z-dimension is referenced from.
2. **Seagate BarraCuda SATA Product Manual Rev A, March 2025**
   (`seagate.com/.../Seagate_BarraCuda_SATA_Product_Manual_210203200.pdf`),
   §3.3.1 explicitly states dimensions "conform to the Small Form Factor
   Standard documented in SFF-8301 and SFF-8323" — this is a genuine
   independent vendor mechanical drawing, not a spec reproduction. Its
   **Figure 3 "Mounting configuration dimensions"** (page 17, side view) draws
   `1.123±.020in`
   (=28.52mm ≈ A8) and `4.000±.010in` (=101.60mm = A9 exactly) as **vertical**
   dimensions (X/length axis, matches SFF-8301's A8/A9 exactly), and
   `.250±.010in` (=6.35mm) as a **horizontal** dimension near the bottom of
   the strip, tagged with a "Z" GD&T datum triangle — same numeric value as
   SFF-8301's A10, same geometric role (horizontal, near the strip's edge,
   not part of the A8/A9 vertical chain).
3. **Re-examined our own SFF-8301 PDF** specifically to check A10's
   dimension-line orientation in the canonical SNIA source
   (not a vendor reproduction). Confirmed directly: **`A10 ± A11` is drawn
   as a horizontal dimension**, between the side-view strip's edge and the
   near hole's crosshair — perpendicular to the A8/A9 chain, not a
   continuation of it. This corrects Task 1/2's transcription (which read
   A10 as "side hole 2nd (far) row, offset from the far/rear edge," i.e. a
   further X-offset) — a genuine misreading, not a data change. The closure
   check Task 2 built (`A8+A9+A10=136.45mm ≤ A2`) happened to hold
   arithmetically but doesn't validate that semantic; A10 is Z, not X.

**Conclusion: A10 = 6.35mm is the side-hole Z-height, tier [B]** (the
number+role is corroborated by two independent sources drawing the same
horizontal dimension in the same geometric position: SFF-8301's own Figure
3-1, and Seagate's independently-authored BarraCuda Figure 3). This
corrects, not just fills, the prior gap entry.

**Residual ambiguity — which face is Z=0 measured from (top or bottom)?**
Neither SFF-8301 nor the Seagate manual labels this in prose; both drawings'
"Z" datum-triangle tag sits on the same edge as the `.250in` dimension's
origin, but a datum-triangle position alone doesn't disambiguate top vs.
bottom without a further physical anchor. Resolved via WD's Figure 4/5
side-mount-hole rendering (source 1 above): its hidden-line 3D-ish side view
clearly shows the PCB as a separate, thinner slab occupying one edge of the
casting's cross-section (`wd-fig4-notch-crop.png` — a translucent
blue-tinted box with dashed hidden-line PCB traces, distinct from the grey
die-cast body). Since 3.5" HDD PCBs mount to the **bottom** face (also
visible directly in WD's Figure 2/3 bottom-view photos, `wd-3.5-p4.png`,
where the green PCB is photographed face-up after flipping the drive
over), the edge the PCB hugs in the side view is the bottom face — and
that is the same edge both SFF-8301's and Seagate's own Z-datum triangle
sits on. This gives `Z = 6.35mm` measured directly from the bottom face,
i.e. straight into our own Z=0-at-bottom datum with no further conversion
needed. Sanity check: 6.35mm out of a 26.10mm height class (~24% up from
the bottom) is consistent with mounting holes sitting low, near the bottom
rail — the conventional real-world position for 3.5" drive-bay side rails,
not the top-referenced alternative (`26.10−6.35=19.75mm`, ~76% up) which
would be atypical.

This top/bottom face resolution is **inference from a labeled rendering +
physical mounting convention, not an explicit textual statement** in any
source — flagged `//VERIFY` on the face-orientation semantic specifically
(the repo's existing precedent, per the 2.5" `A23` caveat above: flag an
inferred-but-unlabeled semantic even when the underlying number is solid).
The **number** (6.35mm) and its **role** (a Z-height, not an X-offset) are
tier **[B]**; the **face it's referenced from** is `//VERIFY`.

`SIDE_35()` now ships `[[28.50, 6.35], [130.10, 6.35]]` instead of `[]`.
- **SFF-8323 DOES answer the 3.5" connector-position gap.** Freshly
  transcribed Table 3-1 this pass: A1=101.60 (width, exact match to
  SFF-8301's A3 — confirms this is the same drive-family width), A2=42.73,
  A3=33.39, A5=4.00, A7=3.50, A13=13.43, A14=37.20 — **every one of these
  values is bit-identical to SFF-8223's 2.5" table** (A2/A3/A5/A7/A13/A14).
  This is strong corroboration that these connector dimensions are
  **connector-intrinsic** (a property of the standardized SATA/SAS connector
  part itself), not derived from the drive family's width/length — so the
  3.5" connector position and extent reuse the identical 2.5" figures.

Result — `hdd35`'s `sata` connector record: same as the 2.5" family,
`["sata", [3.50, 13.43, 0], [4.00, 33.39, 4.90]]` (tiers as in (b) above).

SFF-8323 also has its own A8/A11 pair (A8=36.38, A11=20.68 — *different*
numeric values from SFF-8223's A8=9.40/A11=4.80, because these are relative
to **Datum B**, a bottom-mounting-screw hole whose position differs between
the 2.5" and 3.5" families — consistent with the same axis interpretation).
This pass did **not** use the Datum-B path for either family (per (b)
above), so this divergence doesn't affect the result, but is recorded here
to show the numbers were actually read, not skipped: a bottom-mounting-screw
composition path remains a possible future cross-check, not attempted this
pass (time-boxed; the self-contained A7/A5/A13/A3 path already answers the
gap without it).

### (d) M.2 2260/2242/2230 lengths

Carried through unchanged from Task 1 — tier **[C] `//VERIFY
(cited-not-fetched)`**. No vendor datasheet for these three shorter lengths
was fetched this pass either; only the well-known `WWLL` (width-then-length,
mm) M.2 naming convention backs 60/42/30mm. `drives.scad`'s
`M2_HOLE_2242/2260/2230` mounting-hole positions additionally extrapolate
the 2280 datasheet's `1.45mm` inset-from-the-far-end and `11.00mm`
Y-centerline unchanged across lengths — this specific extrapolation is
**not** independently confirmed for the shorter modules (RESEARCH.md's own
Task-1 gap note already flagged this) and is tagged `//VERIFY` in
`drives.scad`. It is not exercised by the brief's test (only `m2_2280`'s
hole shape and `m2_2242`'s length are asserted), so it does not block Step 4,
but a consumer relying on `drive_card_hole("m2_2242"|"m2_2260"|"m2_2230")`
for a real fixture should treat it as an educated placeholder.

### (e) M.2 key-notch mm offset

Not attempted as a numeric notch-cutout offset. Re-reading the interface in
`task-2-brief.md`, `drive_card_edge(type) -> [[x,y,z],[w,d,h],key]` does not
actually need a notch mm-offset — `key` is a categorical string
(`"b"`/`"m"`/`"bm"`), not a coordinate. What the record needs is the
card-edge (gold-finger) connector's own footprint on the card:

- `x_min = 0` — by definition/convention, the edge connector sits at the
  card's `X=0` end (confirmed by cross-checking against the mount-hole
  position: `drive_card_hole("m2_2280") = [78.55, 11.00]` sits near the
  *far* end of the 80mm card, so the edge connector is at the opposite,
  near/X=0 end) — tier **[C]**, this pass's layout inference, not a
  directly re-stated spec value.
- `y_min = 1.075`, `d(Y-extent) = 19.85` — from RESEARCH.md §5's confirmed
  `card-edge contact width: 19.85 ± 0.15mm, centered on width (inset
  (22.00-19.85)/2 = 1.075mm each side)` — tier **[A]**.
- `h(Z-extent) = 0.80` — reuses the confirmed PCB-thickness figure (the gold
  fingers are the PCB's own edge plating, not a separate component) — tier
  **[A]** value, `//VERIFY` on the "reuse PCB thickness as the edge
  connector's own height" modeling choice.
- `w(X-extent) = 5.0` — **not sourced this pass at all.** Neither fetched
  Viking datasheet dimensions the gold-finger engagement depth along the
  insertion axis. This is a placeholder estimate (typical M.2 edge-connector
  engagement depth), tagged `//VERIFY (unsourced estimate)` in
  `drives.scad` — flagged rather than silently presented as confirmed, per
  the "honestly fall back to omission/flagged //VERIFY... do not force-fit"
  instruction. It was kept (not omitted like the 3.5" side-hole Z) because
  the interface requires all three `[w,d,h]` components to be present
  (unlike the side-holes list, which can simply be empty).
- `key = "m"` — tier **[A]**, directly confirmed in Task 1 via the NVMe
  datasheet's pin table ("Module Key M", pins 59-66).

This resolves the interface's actual requirement without needing the
pin-index-to-millimeter notch-position derivation originally sketched as a
possible approach — that derivation would have required an unconfirmed
assumed total pin count (75) and was dropped in favor of this simpler,
better-sourced footprint-based record.

## Task 5 resolution: `drive_connector_cutout` extension axis

The task-5 brief's own sample code guessed the cutout should grow along `+Y`
("the drive's connector/back edge is at high Y"), flagged as an explicit
uncertainty to check against this document. That guess is **wrong** — no new
fetch was needed to resolve it, just re-reading what's already recorded
above plus the actual accessor output:

- This document's own "Datum convention used below" section (top of file)
  already fixes it: **"`X=0` at the connector end, `+X` toward the
  free/far end"** — the connector sits on the **low-X** face, not a high-Y
  back edge.
- Confirmed by the block-family connector position: `C35_POS()`/`U2_POS()`
  place the SATA/SFF-8639 connector at `x=A7=3.50mm` — Task 2 resolution (b)
  above states explicitly "A7 = 3.50mm is the connector's X-offset from the
  connector-end edge," corroborated by SFF-8223/SFF-8323's "nominally flush"
  text — i.e. hard against `X=0`, not near the envelope's `Y=width` edge.
- Confirmed by the card-family (`M2_EDGE()`) comment: "x=0 at the card's
  connector end (by convention; corroborated by the mount hole sitting near
  the *far* end of the 80mm card, so the edge connector is at the opposite,
  near/X=0 end)" — same low-X face, independently arrived at for the M.2
  family.
- Live-checked this pass against `drive_connector("ssd25_9")` (`x=3.50` out
  of a 100mm-long envelope) and `drive_card_edge("m2_2280")` (`x=0` out of
  an 80mm-long card) — both trivially near `X=0`, confirming the same face
  for both families, so `drive_connector_cutout` does not need to branch on
  `drive_family(type)` for the axis/direction (it does still branch to fetch
  the differently-shaped `drive_connector`/`drive_card_edge` records).

`drive_connector_cutout` now grows the cut in `-X` (past the drive's
connector-end edge) instead of `+Y`. Render-verified for both a block type
(`ssd25_9`) and a card type (`m2_2280`): the cutout box's own bounding box
(rendered standalone, not differenced) extends from a negative X well past
0 up to `pos[0]+ext[0]+clearance`, confirming it actually pierces the
connector-end face rather than merely compiling.

## Hole-role tagging (hole-role-sweep)

`sbc` established a per-hole `[x,y,role,dia]` schema with a shared 4-value
role vocabulary (`structural-mount`, `component-mount`, `keep-out`,
`alignment`) and role-filtered accessors. This pass migrates `drives` to the
same schema for parity (`drives_known_hole_roles()`, `role=undef` param on
`drive_bottom_holes`/`drive_side_holes`/`drive_holes`).

Role classification here needed no new fetch or drawing re-read: every hole
in `BOTTOM_35()`/`SIDE_35()`/`BOTTOM_25()`/`SIDE_25()`/`SIDE_25_7()` and every
`M2_HOLE_22xx()` is, per the governing SFF spec text itself (SFF-8301/
SFF-8201's own "mounting hole" table captions), the drive's screw-mount hole
— there is no other hole category in any of these tables (no keep-out,
component, or alignment holes documented anywhere in this library's sources).
So every hole tags `structural-mount`, uniformly, across all types — tier
**[B]** (design-obvious: a table titled "mounting holes" whose only entries
are mounting holes needs no further corroboration to call them
`structural-mount`; this is not a fabricated datum, just the existing
[A]/[B]-tiered coordinate data given its one obvious role).

`dia` for the new 4th tuple field reuses `drive_holes()`'s own
already-documented default clearance, `3.4` (M3 clearance; see that module's
docstring) — applied uniformly, including to the M.2 mounting holes, rather
than inventing a separate M2-class figure not otherwise present in this
file's data. No lib version other than the role tag + dia carry-through
changed; coordinates are untouched.

A final-review fix pass made `drive_holes()` read this per-hole `dia` instead
of a single module-level constant (parity with `mobo_standoff_holes()`/
`sbc_mount_holes()`). This means the M.2 tuples' `3.4` now actually RENDERS
as the cut diameter for `m2_*` types, not just sits as tagged-but-unused
data — the M.2-vs-M3 clearance mismatch flagged above (M.2 standoff screws
are typically ~M2, ~2.2-2.4mm, not M3's 3.4mm) is a real, visible
over-sized cut today, not a latent one. Left as-is deliberately (no new
M.2-specific dia derived this pass); a future pass should re-derive the M.2
standoff clearance from spec rather than reusing the block-drive M3 figure.

Because every type here has exactly one role present, the sbc-style
multi-role `WARNING:` echo (fired when `role=undef` and a type's holes span
>1 role) never triggers for `drives` today — verified by
`tests/test_drives_lib.sh`'s no-role-consumer control. That's expected, not a
bug: the WARNING idiom exists for API parity with `sbc` (which does have
multi-role boards), not because `drives` needs it yet.
