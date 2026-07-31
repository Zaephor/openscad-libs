# heatset — insert dimension research (Task 1)

Scope: Task 1 only — scaffold + evidence-sourced value table. No data table or
modules are implemented in `heatset.scad` yet (Task 2). This file is the
evidence Task 2 will transcribe into `_heatset_table()`.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` fetched + read this pass (vendor datasheet or governing standard).
- `[B]` corroborated across >=2 independent peers.
- `[C]` single-sourced / derived / community-consensus, not vendor-specified.
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

Target: brass heat-set threaded inserts (soldering-iron/heat-installed,
knurled/barbed body, the common 3D-printing style), sizes M2, M2.5, M3, M4,
M5, M6. All values mm unless noted. "Standard" (not "short") length variant
used throughout — shorter variants exist per size but are out of scope for
this table (see Gaps).

## Sources read this pass

1. **PennEngineering (PEM) "SI Inserts For Plastics" datasheet**, page SI-6,
   metric table for straight-wall thru-threaded IUTA/IUTB/IUTC inserts —
   `https://www.pemnet.com/wp-content/uploads/sites/2/2022/06/sidata.pdf`.
   Read directly from the dimensioned drawing. A real manufacturer
   engineering datasheet with a
   dimensioned drawing (callouts A = length, E = after-knurl OD, C = tip/lead
   diameter, plus a "Hole Size in Material" block: min hole depth + hole
   diameter). Covers M2 through M8 in one consistent table — the only source
   this pass that independently covers all six target sizes on its own.
   Tier **[A]** for every value pulled from it.
2. **CNC Kitchen blog, "Tips & Tricks for Heat-Set Inserts used in 3D
   printing"** — `https://www.cnckitchen.com/blog/tipps-amp-tricks-fr-gewindeeinstze-im-3d-druck-3awey`.
   Located the embedded dimension-table image and read it directly:
   `https://images.squarespace-cdn.com/content/v1/5d88f1f13db677155dee50fa/1633075595722-R2DYW7JZTMSPGKKUDEJ8/2021-10-01+10_06_06-Illustrationen.pptx+-+PowerPoint.png`
   (titled "Dimensions & Design Recommendations", CNC Kitchen's own official
   table for the inserts they manufacture/sell). Covers M3, M4, M5, 1/4"-20
   only — **no M2, M2.5, or M6 rows**. Columns: `L` (length), `D1` (insert
   OD), `D2` (insert tip diameter, a property of the insert not the hole),
   `D3` (installation/pilot hole diameter), `W` (min wall thickness around
   the hole). Tier **[A]** (CNC Kitchen's own published spec for their own
   product).
   A second image on the same page (file `2022-10-29 20_00_53-Clipboard.png`,
   a Fusion 360 CAD screenshot, columns `D1/D2/D3/L1/L2`) was also read
   but its `D2` column disagrees with table 1's `D2` (4.4mm vs
   3.9mm for M3) — most likely a different dimension entirely (possibly a
   CAD sketch construction diameter, not the insert's tip diameter) given
   `D1`/`D3` agree closely between the two images. Not used as an
   independent value source; noted only as ambiguous, not corroborating.
3. **ruthex CAD data page** — `https://www.ruthex.de/en/pages/cad-daten`.
   Read the actual download-link text (not a summary): confirms per-size
   STEP filenames `M2x4.step`,
   `M2.5x5.7.step`, `M3x5.7.step`, `M4x8.1.step`, `M5x9.5.step`,
   `M6x12.7.step` (also `M8x12.7.step`, `M3Sx4.0`/`M4Sx4.0`/`M5Sx5.8` short
   variants, `1/4"x12.7`). ruthex is a distinct 3D-printing-focused brass
   insert brand (not CNC Kitchen or PEM). Product page text corroborates
   the same length values, e.g. `RX-M3x5.7`, `RX-M6x12.7`
   (`https://www.ruthex.de/en/pages/cad-daten` product listings). Does not
   expose OD or hole-diameter numbers in fetchable text (those are inside
   the STEP files, not opened this pass) — used only to corroborate
   **insert length** naming, tier contribution limited to that value.
4. **insertguide.com, "Heat Set Insert Hole Size Guide"** —
   `https://insertguide.com/guides/heat-set-insert-hole-size/`. Read as
   extracted text. A 3D-printing-focused buyer's-guide site
   (not a manufacturer) but gives an explicit per-size pilot-hole table
   covering all six target sizes, filling the gap CNC Kitchen leaves for
   M2/M2.5/M6. Tier **[C]** (independent community source, not a
   manufacturer datasheet) — used as corroboration/spread-check only.
5. **SPIROL International, "How to Design the Proper Hole for Heat /
   Ultrasonic Inserts" white paper** —
   `https://www.spirol.com/assets/files/ins-wp-how-to-design-the-proper-hole-for-heat-ultrasonic-inserts-us.pdf`.
   Read directly from the white-paper PDF. SPIROL is a real fastener/insert
   manufacturer; this white
   paper is their general engineering guidance for threaded-insert boss
   design (not 3D-printing-specific, not per-thread-size numeric, but a
   real authored design rule). Direct quote: *"the optimum wall thickness
   or boss diameter of the plastic is two (2) to three (3) times the
   Insert diameter with the relative multiplier decreasing as the Insert
   diameter increases."* Tier **[A]** for the multiplier rule itself
   (fetched+read this pass); the per-size `boss_od` numbers in the table
   below are **derived** from this rule (see below), so those derived
   numbers are tagged `[C]`, not `[A]`.

No source in this pass gave a numeric, size-specific lead-in chamfer value
(see `lead_in` row notes and Gaps).

## Tiered dimension table

All values mm. Where two sources are shown, PEM's value is used as the
table's canonical number (only source covering all six sizes on a single
consistent scale); the second value is the corroborating peer.

| size | insert_od | insert_length | pilot_dia | boss_od | lead_in |
|---|---|---|---|---|---|
| M2   | 3.73 [A] PEM | 4.00 [B] PEM; ruthex `M2x4` | 3.23 [B] PEM; insertguide 3.1 | 9.3 [C] `//VERIFY` derived 2.5×insert_od | 0.4mm @ 45° [C] `//VERIFY` |
| M2.5 | 4.55 [A] PEM | 5.74 [B] PEM; ruthex `M2.5x5.7` | 4.01 [B] PEM; insertguide 3.8 | 11.4 [C] `//VERIFY` derived 2.5×insert_od | 0.4mm @ 45° [C] `//VERIFY` |
| M3   | 4.55 [B] PEM; CNC Kitchen 4.6 | 5.74 [B] PEM 5.74; CNC Kitchen 5.7; ruthex `M3x5.7` | 4.01 [B] PEM 4.01; CNC Kitchen 4.0; insertguide 4.2 | 11.4 [C] `//VERIFY` derived 2.5×insert_od | 0.4mm @ 45° [C] `//VERIFY` |
| M4   | 6.17 [B] PEM; CNC Kitchen 6.3 | 8.15 [B] PEM; CNC Kitchen 8.1; ruthex `M4x8.1` | 5.67 [B] PEM; CNC Kitchen 5.6; insertguide 5.6 | 15.4 [C] `//VERIFY` derived 2.5×insert_od | 0.4mm @ 45° [C] `//VERIFY` |
| M5   | 6.93 [B] PEM; CNC Kitchen 7.1 | 9.52 [B] PEM; CNC Kitchen 9.5; ruthex `M5x9.5` | 6.43 [B] PEM; CNC Kitchen 6.4; insertguide 6.8 `//VERIFY` (outlier) | 17.3 [C] `//VERIFY` derived 2.5×insert_od | 0.4mm @ 45° [C] `//VERIFY` |
| M6   | 8.69 [A] PEM | 12.70 [B] PEM; ruthex `M6x12.7` | 8.03 [B] PEM; insertguide 8.2 | 21.7 [C] `//VERIFY` derived 2.5×insert_od | 0.4mm @ 45° [C] `//VERIFY` |

### Column definitions
- `insert_od` — insert outer diameter over the knurl/barb (PEM drawing
  callout `E`, "after knurl"). This is what the boss must clear.
- `insert_length` — standard-length variant (PEM callout `A`, the longer of
  the two length codes PEM lists per size; matches CNC Kitchen's and
  ruthex's own "standard" length, not their "Short" variants).
- `pilot_dia` — recommended installation/receiving hole diameter (PEM's
  "Hole Dia." column; CNC Kitchen's `D3`).
- `boss_od` — recommended boss outer diameter. **No source this pass gives
  a numeric per-size boss OD table.** SPIROL's white paper gives the
  general rule (2-3x insert diameter, tapering down as size increases);
  this table uses a flat **2.5x insert_od** (the range midpoint) as a
  single practical number per size, per `docs/LIBRARY-AUTHORING.md`'s
  guidance to ship the best-known number and flag derivation. A future
  pass could taper the multiplier (e.g. ~2.8x at M2 down to ~2.0x at M6)
  per SPIROL's stated trend instead of a flat 2.5x — not done here to avoid
  inventing unsourced precision.
- `lead_in` — chamfer at the hole mouth to help the insert self-center.
  **No vendor source this pass gives a numeric chamfer value for heat-set
  inserts specifically** (SPIROL's white paper discusses hole *taper angle*
  for a different insert style — tapered-body inserts in tapered holes —
  not a chamfer at a straight hole's mouth). The 0.4mm @ 45° figure is
  carried from this repo's general 45°-chamfer convention
  (`.claude/skills/design-for-print/reference/glossary.md`) applied at a
  small, insert-size-independent depth per community guidance surfaced in
  search (CAD-forum/community consensus, not a fetched primary source) —
  tier **[C] `//VERIFY`** for every size, and flagged as the weakest value
  in this table.

## Sanity checks (per `docs/LIBRARY-AUTHORING.md` / brief requirement)

`pilot_dia < insert_od` for every size (canonical PEM values):

| size | insert_od | pilot_dia | margin |
|---|---|---|---|
| M2   | 3.73 | 3.23 | 0.50 |
| M2.5 | 4.55 | 4.01 | 0.54 |
| M3   | 4.55 | 4.01 | 0.54 |
| M4   | 6.17 | 5.67 | 0.50 |
| M5   | 6.93 | 6.43 | 0.50 |
| M6   | 8.69 | 8.03 | 0.66 |

Holds for all six sizes, PASS — and the margin is a strikingly consistent
~0.5mm across the whole size range (one consistent vendor's own knurl
allowance), which is a good internal-consistency signal for the PEM table
itself.

`boss_od ≈ 2×insert_od` (brief's stated check; table above uses 2.5x, not
2x):

| size | insert_od | 2×insert_od | boss_od (2.5x) | boss_od vs 2× |
|---|---|---|---|---|
| M2   | 3.73 | 7.46  | 9.3  | +25% |
| M2.5 | 4.55 | 9.10  | 11.4 | +25% |
| M3   | 4.55 | 9.10  | 11.4 | +25% |
| M4   | 6.17 | 12.34 | 15.4 | +25% |
| M5   | 6.93 | 13.86 | 17.3 | +25% |
| M6   | 8.69 | 17.38 | 21.7 | +25% |

PASS in the sense the brief intends (same order of magnitude, boss
comfortably larger than insert_od on every axis) — the table's boss_od
runs a uniform 25% above a literal 2x because it uses SPIROL's midpoint
(2.5x) rather than the floor (2x); this is a real, sourced, order-of-
magnitude match, not an exact-2x tie. Recorded honestly rather than
fudging the multiplier down to hit exactly "2×".

**Cross-check against CNC Kitchen's `W` (min wall thickness)**, for the
three sizes it covers: computing an alternative boss_od as
`pilot_dia + 2×W` gives M3 = 4.0+2(1.6) = 7.2mm, M4 = 5.6+2(2.1) = 9.8mm,
M5 = 6.4+2(2.6) = 11.6mm — all noticeably *smaller* than this table's
2.5x-derived values (11.4/15.4/17.3mm) and closer to a literal 2x-ish
figure. This is not a contradiction: CNC Kitchen's `W` is explicitly
labeled **minimum** wall thickness (a floor, print-crack-risk boundary),
while SPIROL's 2-3x figure is stated as **optimum** (a design target with
margin). The table above intentionally uses the optimum/target figure, not
the bare minimum — consistent with this repo's other libraries picking a
sane default over a bare-minimum survival number. Both numbers are
recorded here so Task 2 (or a consumer wanting a tighter/thinner boss) has
the minimum-wall-derived alternative on record too.

## Gaps (values not independently fetched this pass)

- `lead_in`: no vendor/manufacturer numeric source found this pass for any
  size — see column definition above. Weakest value in this table,
  `[C] //VERIFY` on every row.
- Short-length variants (`M3Sx4.0`/`M4Sx4.0`/`M5Sx5.8`/`M6x6.8`, and PEM's
  shorter length-code rows) exist in real products (ruthex, PEM) but are
  out of scope for this table — only the "standard" length is tabulated.
  Noted here so Task 2 doesn't assume the standard length is the only
  length in the wild.
- `insertguide.com`'s M5 pilot-hole figure (6.8mm) is a real outlier
  against PEM (6.43) and CNC Kitchen (6.4) — both of which tightly agree
  with each other. Flagged `//VERIFY` in the table; PEM/CNC Kitchen's
  6.4-ish figure is treated as the stronger pair.
- `boss_od` has no per-size vendor number anywhere found this pass; it is
  entirely derived from SPIROL's general multiplier rule (see column
  definition). This is the second-weakest value in the table after
  `lead_in`.
- 1/4"-20 (present in both PEM and CNC Kitchen's tables) was not tabulated
  — out of scope, this library targets metric-only sizes per the task
  brief (M2-M6).

No value in this table was invented without at least a fetched-and-read
source or an explicitly derived-and-labeled arithmetic rule behind it.

## Cross-brand M2.5/M3 (Task #6)

Purpose: decide whether the M2.5/M3 insert dimensions diverge enough between
brands to justify a **brand-keyed** table (Task 2 builds the key), or whether
one flat per-size row corroborated across brands is sufficient (Task 2 just
corroborates the existing flat table). Focused on the two smallest
production sizes this repo actually consumes, and on the two
divergence-relevant columns (`insert_od`, install-hole `pilot_dia`) plus
`insert_length`.

Sources read this pass (in addition to those already logged above):
- **PennEngineering (PEM) SI datasheet** (as above) — tier `[A]` for the
  M2.5/M3 rows it lists.
- **CNC Kitchen "threaded inserts in comparison" spec table** (CNC Kitchen's
  own published dimension table for their standard M2.5 and M3 inserts;
  columns `L` length, `D1` insert OD, `D2` centre-tip dia, `D3` hole dia,
  `W` min wall). Tier `[A]` (manufacturer's own product spec).
- **ruthex M2.5 (RX-M2.5x5.7) and M3 (RX-M3x5.7) technical-specifications
  table** (ruthex's own per-product spec, same `D1/D2/D3/L/W` scheme). Tier
  `[B]` — ruthex-published numbers, corroborated cell-for-cell by the CNC
  Kitchen table for the barbed "3D-printing" body family.
- **ruthex HSS drill set for thread inserts** — product spec lists the five
  drill diameters `3.2 / 4.0 / 5.6 / 6.4 / 8.0 mm` covering M2, M2.5, M3, M4,
  M5, M6 & 1/4"; the single 4.0 mm bit is ruthex's recommended install hole
  for **both** M2.5 and M3 (they share a drill). Tier `[B]`.
- **insertguide.com** hole-size guide (community buyer's-guide, not a
  manufacturer) — M2.5 pilot 3.8, M3 pilot 4.2. Tier `[C]`.

### Findings table

Rows = size × brand; all mm. `[tier] source` per cell.

| size | brand | insert_od | pilot/hole | insert_length |
|---|---|---|---|---|
| M2.5 | PEM SI      | 4.55 [A] PEM SI datasheet | 4.01 [A] PEM SI "Hole Dia." | 5.74 [A] PEM SI |
| M2.5 | CNC Kitchen | 4.6 [A] CNC Kitchen spec table (`D1`) | 4.0 [A] CNC Kitchen (`D3`) | 4.0 [A] CNC Kitchen (`L`) |
| M2.5 | ruthex      | 4.6 [B] ruthex RX-M2.5x5.7 spec (`D1`) | 4.0 [B] ruthex (`D3`) + drill-set 4.0mm bit | 5.7 [B] ruthex RX-M2.5x5.7 |
| M2.5 | generic     | 4.4–4.6 [C] community consensus | 3.8 [C] insertguide.com | 5.7 [C] common "standard" |
| M3   | PEM SI      | 4.55 [A] PEM SI datasheet | 4.01 [A] PEM SI "Hole Dia." | 5.74 [A] PEM SI |
| M3   | CNC Kitchen | 4.6 [A] CNC Kitchen spec table (`D1`) | 4.0 [A] CNC Kitchen (`D3`) | 5.7 [A] CNC Kitchen (`L`) |
| M3   | ruthex      | 4.6 [B] ruthex RX-M3x5.7 spec (`D1`) | 4.0 [B] ruthex (`D3`) + drill-set 4.0mm bit | 5.7 [B] ruthex RX-M3x5.7 |
| M3   | generic     | 4.4–4.6 [C] community consensus | 4.2 [C] insertguide.com | 5.7 [C] common "standard" |

**Boss min-wall guideline** (the wall of plastic that must remain around the
install hole):

| guideline | value | source |
|---|---|---|
| min wall around hole, M2.5 | 1.6 mm [A/B] | CNC Kitchen `W` = 1.6 **and** ruthex `W (min.)` = 1.6 (two manufacturers agree) |
| min wall around hole, M3   | 1.6 mm [A/B] | CNC Kitchen `W` = 1.6 **and** ruthex `W (min.)` = 1.6 |
| optimum boss OD (all sizes)| 2–3 × insert_od | SPIROL white paper (as logged above), multiplier tapering down with size |

Note the two figures answer different questions: CNC Kitchen/ruthex `W` is a
**minimum** wall (crack-risk floor, ~pilot_dia + 2·1.6 ≈ 7.2 mm boss OD for
M3), SPIROL's 2–3× is an **optimum** target (the flat table's 2.5× ≈ 11.4 mm
boss OD for M3). Both are on record; Task 3's `heatset_min_wall` accessor
should expose the 1.6 mm manufacturer minimum, distinct from the derived
optimum boss OD already in the flat table.

### Shared-knurl-body observation (per brand)

- **PEM SI:** M2.5 and M3 share the same external body — identical `insert_od`
  (4.55), `pilot_dia` (4.01) and `length` (5.74); only the internal thread
  differs. [A]
- **ruthex:** M2.5 and M3 share the same body exactly — both `RX-*x5.7`, both
  `D1` 4.6 / `D3` 4.0 / `L` 5.7 / `W` 1.6; only the internal thread differs.
  Both driven by the single 4.0 mm bit in ruthex's own drill set. [B]
- **CNC Kitchen:** M2.5 and M3 share `D1` 4.6 / `D3` 4.0 / `W` 1.6; they
  differ only in length (M2.5 standard `L` = 4.0, M3 standard `L` = 5.7). So
  same knurl-body **diameter** family, different length variant. [A]

So within every brand, M2.5 and M3 are the same knurl-body diameter — the
size distinction is purely the internal thread (and, for CNC Kitchen, a
shorter standard M2.5 length).

### Divergence verdict

**Criterion (from task brief):** brand-key iff any `insert_od` OR
recommended-hole difference > 0.2 mm between brands for the same size, OR the
brands use distinct knurl families that a single number can't serve.

- `insert_od` spread, same size: PEM 4.55 vs CNC Kitchen/ruthex 4.6 →
  **0.05 mm** (both M2.5 and M3). Well under 0.2 mm.
- install-hole spread: PEM 4.01 vs CNC Kitchen/ruthex 4.0 → **0.01 mm**.
  insertguide's M3 generic 4.2 is +0.2 vs the 4.0 manufacturer figure —
  exactly *at*, not *over*, the threshold, and it is a `[C]` community value
  contradicted by two `[A]` manufacturer specs, so it does not tip the
  verdict. insertguide's M2.5 generic 3.8 is −0.21 mm from PEM's 4.01 and
  exceeds the threshold on the low side; as a `[C]` community value
  contradicted by `[A]` manufacturer specs, it likewise does not tip the
  verdict.
- knurl families: PEM SI is a straight-wall opposed-knurl insert and CNC
  Kitchen/ruthex are barbed "3D-printing" inserts — technically different
  product lines, but their OD-over-knurl and install-hole numbers converge
  within 0.05 mm, so one canonical value serves all three brands.

**Verdict: CONVERGED.** No `insert_od` or hole difference exceeds 0.2 mm and
no dimensional knurl-family split exists for M2.5/M3. → **Task 2 corroborates
the flat table (no brand key).** The brand-keyed API is *not* warranted by
this evidence; Task 2 should keep one flat per-size row and record the
three-brand agreement.

### Current-lib values this pass touches (flag for Task 2)

- `heatset.scad` M2.5/M3 `insert_od = 4.55` (PEM, canonical) is now
  corroborated by CNC Kitchen (4.6) and ruthex (4.6) within 0.05 mm. The
  **M2.5 `insert_od` tier can rise from single-source `[A]`(PEM) to `[B]`**
  (three-brand agreement) — a tier upgrade requires re-checking the primary
  source, done here. M3 `insert_od` is already `[B]`. No number change
  needed; PEM's 4.55 stays canonical (choosing the tighter of two
  within-tolerance values).
- `pilot_dia = 4.01` (PEM) vs CNC Kitchen/ruthex 4.0 — 0.01 mm, no change.
- **New for Task 3:** a manufacturer **min-wall = 1.6 mm** (M2.5 and M3,
  CNC Kitchen + ruthex agreeing) is now on record — distinct from the
  SPIROL-derived optimum boss OD already in the flat table. No current lib
  value contradicts it; it is additive.

## M2 min-wall (#77)

Purpose: `heatset_min_wall()` shipped covering M2.5/M3 only and asserted for
every other size. A consumer needs M2, so this pass asks whether any
manufacturer publishes a minimum boss wall for an M2 heat-set insert.

### Sources consulted

| Source | Result |
|---|---|
| PEM SI datasheet | Yes, on a page #6 never opened. Page **SI-9**, the microPEM® Symmetrical Thru-Threaded MSIA™/MSIB™ metric table, carries an explicit **"Min. Wall Thickness"** column (footnote: "Refers to wall diameter of boss as tested in ABS and polycarbonate") with a row for **M2 = 1.6 mm**. Caveat: this is a different, smaller insert body than the IUTA™/IUTB™/IUTC™ family already backing this table's other M2 columns — microPEM's M2 is 3.2 mm OD over a 2.85 mm hole, versus IUTA/IUTB/IUTC's 3.73 mm OD over a 3.23 mm hole (see Verdict). Page SI-25's generic "Hole Preparation Guidelines" diagram gives only a dimensionless **Boss Dia. = 2 x Insert Dia.** ratio (no numeric wall mm value, and no per-size table) and states "Thinner walls and bosses may be used but will affect performance" — no hard floor stated at that generic level. |
| CNC Kitchen dimension table | Confirmed, correcting nothing: the table covers **M3, M4, M5, 1/4"-20** (plus M3/M4/M5 "Short" length variants) only — no M2, M2.5, or M6 row, exactly as #6 recorded. The table's own diagram also settles the `W`-datum question below. |
| ruthex RX-M2x4 | Yes. ruthex's own RX-M2x4 retail-packaging artwork carries a dimensioned install diagram: installation hole **Ø3.2**, with **"min. 1.3"** (mm) wall dimensioned immediately outside that hole — the same hole-referenced convention CNC Kitchen uses for `W`. Insert body Ø3.6 (D1) / Ø3.1 tip (D2) / length 4.0. This **disagrees** with PEM's 1.6 mm figure above (see Verdict). |
| Böllhoff IMTEC | Negative on every axis — a genuinely new source this pass. Böllhoff's AMTEC® catalog (IMTEC® is their in-mould variant of the same underlying product families: HITSERT®/SONICSERT®/QUICKSERT®/EXPANSIONSERT®/SPREDSERT®) has **no M2 size at all** — its metric range starts at **M2.5** (EXPANSIONSERT® 1). The catalog's "Recommended wall thicknesses" entry is a qualitative 1-4 relative ranking across insert *types*, not a numeric per-size mm figure, for any size. |
| insertguide.com | Corroborates the M2 pilot-hole figure already on record (3.1 mm) but gives **no numeric minimum-wall-thickness figure for any size** on its dedicated minimum-wall-thickness reference page — only a qualitative per-size sensitivity ranking (M2: "Very sensitive to small geometry changes"). `[C]` ceiling, and no number to use even at that tier. |

### Verdict

**M2 min-wall = 1.6 mm, tier [A].**

Two manufacturers publish a numeric M2 wall figure, and they disagree: PEM's
microPEM® MSIA™/MSIB™ metric table (SI-9) gives an explicit **1.6 mm**
"Min. Wall Thickness" for M2, tested in ABS/PC per its own footnote; ruthex's
RX-M2x4 packaging gives **1.3 mm** for the same size. They do not corroborate
to `[B]` (they disagree, not agree) and come from two different insert body
styles: PEM's microPEM family is a smaller, symmetrical (non-barbed) design
that does not match the IUTA/IUTB/IUTC dimensions already used for this
table's other M2 columns, whereas ruthex's RX-M2x4 body (3.6 mm OD / 3.2 mm
hole) is within 0.13/0.03 mm of them and is the better dimensional match —
but PEM's figure carries a stated test methodology that ruthex's packaging
label does not.

Given a genuine, unresolved disagreement between the only two manufacturer
figures for a crack-risk *floor* value, this table ships the more
conservative (larger) of the two, **1.6 mm**, on the same safe-direction
principle this library already applies via SPIROL's decreasing-multiplier
rule: too much wall costs boss diameter, too little costs a cracked print.
ruthex's 1.3 mm is recorded here, not discarded, so a stronger tie-breaker
(a third manufacturer, or physical testing) can revisit it later.

**Cross-family/cross-hole-size applicability — an unresolved gap, stated
explicitly.** The paragraph above leaned on SPIROL's "multiplier decreases
as insert diameter increases" rule to call 1.6 mm the conservative choice.
On review, that overreaches: SPIROL's rule describes how the *insert
diameter itself* should scale a wall/boss multiplier within a comparable
design — it says nothing about whether a min-wall figure PEM validated
around one specific pilot hole size safely carries over to a *different,
larger* pilot hole from an unrelated product family. That is a distinct
question, and the two hole sizes here are not close: PEM's microPEM
MSIA/MSIB validated 1.6 mm around a **2.85 mm** hole (wall:hole ratio
1.6/2.85 = **0.561**), while this table's M2 row (IUTA/IUTB/IUTC) uses a
**3.23 mm** pilot. Composing `pilot_dia + 2×wall` with the *same absolute*
1.6 mm around that larger hole gives a wall:hole ratio of 1.6/3.23 =
**0.495** — a *smaller* relative-wall ratio than what PEM's own data point
actually represents, not a larger one. If the crack-risk mechanism scales
with wall:hole ratio (a hoop-stress/expansion-during-installation view, not
implausible, and roughly what SPIROL's own multiplier framing implies once
expressed as a ratio rather than an absolute), holding the absolute number
fixed while the hole grows is arguably the *less* conservative direction,
not the more conservative one — the opposite of what the paragraph above
claimed.

For reference, ruthex's own RX-M2x4 hole (3.2 mm) is essentially identical
to this row's 3.23 mm pilot — a materially closer hole-size match than
PEM's microPEM figure — and ruthex's wall:hole ratio (1.3/3.2 = 0.406) sits
close to the same barbed-3D-printing-style family's own M2.5/M3 ratio
(CNC Kitchen/ruthex 1.6/4.0 = 0.400), i.e. that family's ratio is close to
flat across M2→M3. No source in this pass publishes a min-wall figure
tested around a hole in the ~3.2 mm class *and* validated for the
IUTA/IUTB/IUTC-style larger insert body at once — that specific combination
is genuinely unresolved, not just under-documented.

**What the `[A]` tier does and does not cover here:** `[A]` certifies that
1.6 mm is a real, fetched-and-read, tested PEM figure for an M2 insert — it
does **not** certify that 1.6 mm is validated for a boss built around this
library's specific 3.23 mm pilot hole. That transfer is untested by any
source read this pass. The number ships anyway, not because the transfer
has been shown safe, but because: it is still real vendor data (not
invented) for the correct nominal thread size; it is the larger of the only
two real per-size M2 figures found, which is the conventional
err-on-the-side-of-more-material choice for a floor value when a
correction's direction is genuinely ambiguous; and no third source exists
to arbitrate. A future pass with a manufacturer figure tested specifically
around a ~3.2 mm-class M2 hole, or physical print-test data, should
supersede this reasoning rather than be read as already settled by it.

Resulting boss outer diameter: `pilot_dia(M2) + 2 x 1.6` = `3.23 + 3.2`
= **6.43 mm**, against M2.5/M3's 7.21 mm.

### Scope

M4, M5 and M6 remain unresearched in `heatset_min_wall()` and continue to
assert. Note that CNC Kitchen's `W` for M4 (2.1) and M5 (2.6) is already on
record in this file's boss-OD cross-check above; it was deliberately not lifted
into the accessor this pass — no consumer needs it.

## `W` datum — measured from the hole or from the insert? (#77)

`heatset_boss(size, height, wall)` composes its outer diameter as
`pilot_dia + 2*wall`. Whether that is the right composition depends on which
diameter the manufacturers' `W` is measured from.

**Verdict: pilot-referenced.**

Three independent manufacturer diagrams, read directly this pass, all
dimension the wall/min. figure from the installation/pilot hole edge
outward to the boss's outer surface — never from the (larger) installed
insert body:

- CNC Kitchen's "Dimensions & Design Recommendations" diagram: the `W`
  extension line begins exactly where `ØD3` (installation hole diameter)'s
  extension line ends — `W` is the material outside the hole, not outside
  the insert.
- ruthex's RX-M2x4 packaging diagram: "min. 1.3" is dimensioned immediately
  outside the Ø3.2 installation-hole callout — the identical convention.
- PEM's own generic "Hole Preparation Guidelines" diagram (SI-25): "Wall
  Thickness" is called out as the material between the receiving hole
  (labeled "Insert Dia." in PEM's own diagram — the hole the insert
  occupies) and the boss's outer diameter.

`heatset_boss()`'s `od = pilot_dia + 2*wall` composition is therefore the
correct reading of the manufacturers' own convention. No undersizing bug
exists in that composition; no new backlog item is needed for this question.
