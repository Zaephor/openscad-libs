# rack19 — EIA-310-D research log (Task 1)

Scope: scaffold + evidence gathering only. No data functions are written into
`rack19.scad` yet (Tasks 2+ consume this file). Every value below is
research-honest: tiered by what was *actually verified* this pass, not
by the seed table's suggested tier.

## Method / environment note

EIA-310-D is a paid standard (paywalled); figures are corroborated across
independent secondary/vendor sources.

Sources used:

1. **Wikipedia — 19-inch rack** — `https://en.wikipedia.org/wiki/19-inch_rack`.
   Tertiary but widely peer-edited; also surfaced the vendor citation below via
   its own reference list.
2. **Wikipedia — Cage nut** — `https://en.wikipedia.org/wiki/Cage_nut`
3. **IBM N series install spec** — `https://www.ibm.com/docs/en/n-series?topic=specifications-requirements`
   ("Rack specifications" — IBM N series storage installation requirements).
   This is a real vendor **installation spec** that explicitly states *"The
   rack or cabinet must meet the EIA Standard EIA-310-D for 19-inch racks"*
   and then gives the numbers that satisfy it.

No additional independent primary source (e.g. a to-scale mechanical drawing)
was found this pass.

## Confirmed values

### 1U pitch — **44.45 mm (1.75 in)** — tier [B]

- Wikipedia: *"The height of the mountable equipment is standardized as
  multiples of 1.75 inches (44.45 mm) or one rack unit or U."*
- IBM: *"...making each 3-hole set of vertical hole spacing 44.45 mm (1.75
  in.) apart on center."*
- Two independent documents, exact match. Seed confirmed as-is.

### Panel width — **482.6 mm (19 in)** — tier [B], single-source this pass

- Wikipedia: *"Each module has a front panel that is 19 inches (482.6 mm)
  wide"* and, separately, *"...giving an overall rack width of 19 inches
  (482.60 mm)."* Neither sentence carries an inline citation in the article.
- IBM's spec does not restate overall panel/rack width (only opening width +
  hole spacing + hole c-c, see below).
- **Closure check** (own arithmetic, not a fetched source): opening width +
  2×post width = 450.85 + 15.875 + 15.875 = **482.6 mm exactly** — internally
  consistent with the opening width (independently corroborated from two sources)
  and the post width (single-sourced from Wikipedia). Seed confirmed; tier is [B] but flagged single-document for
  the *panel width statement itself*.

### Opening width — **450.85 mm (17.75 in)** — tier [B]

- Wikipedia: *"...separated by a gap of 17.75 inches (450.85 mm)..."*
- IBM: *"The front rack opening must be 451 mm + 0.75 mm (17.75 in. + 0.03
  in.) wide."* → tolerance band 450.25–451.75 mm, contains 450.85.
- Two independent documents, consistent within IBM's stated tolerance. Seed
  confirmed as-is.

### Rail post/flange width — **15.875 mm (0.625 in)** — tier [B], informational — `//VERIFY second source for 15.875mm post width`

- Wikipedia: *"The posts are each 0.625 inches (15.88 mm) wide..."*
- Not in the brief's seed table, but needed for the panel-width closure check
  above, and useful context for Task 6 (`rack19_panel()`).

### Hole horizontal center-to-center — **band 464.2–465.8 mm; seed 465.1 mm falls inside it** — tier [B], effectively single-primary-source — `//VERIFY 465.1 nominal vs IBM 464.2–465.8mm band — no discrete point-value source found`

- Wikipedia states: *"...each hole is part of a horizontal pair with a
  center-to-center distance of 18.28–18.34 inches (464.2–465.8 mm)."* — this
  sentence carries Wikipedia's own citation **[24] → the same IBM page**
  fetched above. So this is **not** two independent corroborations; it's one
  primary source (IBM) cited twice.
- IBM (the primary): *"the rail-mounting holes must be 465 mm + 0.8 mm (18.3
  in. + 0.03 in.) apart on center."* → band 464.2–465.8 mm, matches Wikipedia
  exactly (expected, since Wikipedia is quoting it).
- The brief's seed **465.1 mm (18.312 in)** is a commonly-published point
  value that sits centrally inside this confirmed tolerance band, but no
  fetched source states "465.1" or "18.312" as a discrete nominal — the only
  authority actually read gives a **tolerance range**, not a point value.
  Recommend Task 2 use the band's center or the seed value with a comment
  noting it's a tolerance-band midpoint, not a drawing-labelled nominal.

### Per-U hole spacing (the three gaps) — **15.875 / 15.875 / 12.7 mm** — tier [B]

- Wikipedia: *"...center-to-center separations of 0.5, 0.625, 0.625 inches
  (12.70, 15.88, 15.88 mm)."*
- IBM: *"...sets of 3 holes spaced (from bottom to top) 15.9 mm (0.625 in.),
  15.9 mm (0.625 in.), and 12.67 mm (0.5 in.) on center."*
- Two independent documents (rounded to 1 decimal by IBM), consistent. Seed
  gaps confirmed as-is.

### Per-U first-hole offset — **6.35 mm (0.25 in) from the U's lower edge** — tag `//VERIFY`

- Wikipedia (only): *"The holes are centered at 6.35 millimetres (0.25 in),
  22.25 millimetres (0.88 in), and 38.1 millimetres (1.50 in) from the top or
  bottom of the region."*
- IBM's text gives only the **spacings** (previous section), not an anchor
  offset from the U edge — so unlike the gaps, the anchor itself is
  **single-sourced** (Wikipedia prose only, not read off a to-scale drawing —
  no EIA-310-D drawing or vendor mechanical drawing with dimension lines for
  this specific callout could be fetched this pass).
- **Self-review catch:** Wikipedia's own companion figure for the *second*
  hole, 22.25 mm, does **not** close against its own first two numbers:
  6.35 + 15.875 = 22.225 mm exactly (not 22.25). 22.25 mm is what you get if
  you instead sum the *IBM-rounded* 15.9 mm to 6.35 (6.35 + 15.9 = 22.25) —
  i.e. Wikipedia's prose figure looks like a rounding-chain artifact, not an
  independently-read value. This is exactly the chaining trap flagged in the
  project's ATX-spec re-verification precedent: **do not propagate the
  rounded 22.25; use the exact arithmetic 22.225** in Task 2/3 (6.35 +
  15.875 = 22.225, 22.225 + 15.875 = 38.1 — closes cleanly to 44.45 total).
- Ship the seed **6.35 / 22.225 / 38.1** (arithmetic-exact, not Wikipedia's
  22.25) tagged `//VERIFY first-hole offset from U lower edge — only found in
  Wikipedia prose, not read off a to-scale EIA-310-D or vendor drawing`.

### Cage-nut square hole side — **9.5 mm (0.375 in)** — tier [B], single-source this pass

- Wikipedia (Cage nut): *"...a common use for cage nuts is to mount equipment
  in square-holed 19-inch racks..., with 0.375 inches (9.5 mm) square-hole
  size."*
- No second, independent (non-Wikipedia) vendor source was found this pass.
  Ship the seed 9.5 mm tagged `//VERIFY second vendor cage-nut datasheet` per
  the single-source gap-handling rule.

### Round-hole rack mounting-hole diameter — **7.1 mm ± 0.1 mm (0.28 in ± 0.004 in)** — tier [B], bonus/informational

- IBM only: *"Rail-mounting holes must be 7.1 mm + 0.1 mm (0.28 in. + 0.004
  in.) in diameter."* Not in the brief's seed table (that table's screw-
  clearance row is for the *equipment-side* clearance hole into a cage nut,
  not the rack-post's own round-hole diameter) — recorded here as extra
  context for Task 4, single-sourced, not asserted as a confirmed constant.

## Screw clearance 10-32 / 12-24 / M6 (Task 4 — resolves the Task 1 gap below)

Task 1 left this omitted (fetch-blocked). Task 4 re-attempted sourcing, then
fell back to a documented derivation for the two sizes that still had no source.

### M6 → **6.6 mm** — tier [B] ISO 273 medium fit (named standard, not fetched)

No new fetch attempted for M6 specifically (ISO 273 is the same paywalled-
standard situation as M3/M4/M5). Cited directly to ISO 273's published
medium fit clearance-hole series by name (no live URL): M3→3.4, M4→4.5,
M5→5.5. The next point in that same published ISO 273 medium fit series is
**M6→6.6mm** (a widely-republished value, e.g. in Machinery's Handbook–style
clearance-hole tables) — continuing the same named-standard sourcing
convention rather than treating M6 as a fresh unsourced claim. Tiered
[B] (not [A]) for the same reason the M3/M4/M5 values are [B]: cited to the
standard's name/series, not to a live fetch of the standard itself this pass.
This also **updates** the Task 4 brief's seed value (5.0/5.5/6.5 mm were
pre-sourcing placeholder guesses) — M6 changes from the seed's 6.5 to the
correct ISO 273 point value **6.6**.

### 10-32 / 12-24 → **5.0 mm / 5.6 mm** — tier [C] `//VERIFY` (named standard, not fetched this pass)

No source with an imperial-machine-screw clearance-hole table was found this
pass. Engineering Toolbox
(`engineeringtoolbox.com/us-machine-screw-diameters-d_1459.html`) confirms the
**major diameters** #10 = 0.190 in and #12 = 0.216 in, but that page has no
clearance-hole column (only Size/Decimal/Fractional/TPI). (This section
previously claimed a "brief worked example" and a "major diameter rounded up to
next standard metric size" derivation — **both claims were false**: no such
worked example exists in any repo file, and the stated rounding doesn't even
work out arithmetically — 0.190in = 4.826mm does not round to 5.0mm under a
"next metric size" rule, and 5.4864mm does not round to 5.6mm either. That
framing is retracted below.)

The honest basis for **5.0 mm / 5.6 mm** is standard imperial machine-screw
**close-fit clearance-drill** values, as published in **ANSI B18.2**
clearance-hole tables (the same family of standard as ISO 273, just the
imperial/ANSI counterpart): a #10 screw (major dia 0.190in) close-fit
clearance ≈ **0.199 in = 5.05 mm → 5.0 mm**; a #12 screw (major dia 0.216in)
close-fit clearance ≈ **0.221 in = 5.61 mm → 5.6 mm**. Like EIA-310-D itself
and ISO 273, ANSI B18.2 is a paywalled standard — this is a **named-standard
citation, not a live fetch**.

Tier **[C] `//VERIFY — ANSI B18.2 close-fit clearance-drill (#10≈5.05mm,
#12≈5.61mm); named standard, not fetched this pass`**. The confirmed major
diameters (0.190in/0.216in) are consistent with these being close-fit (not
free-fit) clearance values, but the close-fit clearance figures themselves
(0.199in/0.221in) are cited from the standard's published series, not read off
a fetched table — flag for a stronger corroboration pass if one becomes
available.

### Rail flange thickness

Brief explicitly frames this as informational/`//VERIFY`, "typical rail
section, not spec-fixed" — i.e. not expected to be pinnable to EIA-310 at all
(it's a fabricator's sheet-metal gauge choice, not a standard dimension). No
value is asserted here; Task 5/6 should carry it as a tunable default with
`//VERIFY typical 2–3 mm cold-rolled steel, vendor-dependent` when it's
introduced, not as sourced data.

## Depth presets (Task 5/7 honesty fix)

`rack19_known_depths()` / `rack19_depth_preset()` ship three named presets:
`"short-400"` → 400mm, `"std-600"` → 600mm, `"std-800"` → 800mm (post
face-to-face mounting depth). These were introduced in Task 5 tagged `[B]`,
but that tier is **not supported** by this file — no depth section existed
above it, and no source was ever fetched or read for these three numbers.
They are round-number illustrative values, chosen as commonly-seen 19in
enclosure/rack mounting depths (400mm short-depth network racks, 600/800mm
common server-rack depths), not read off any datasheet or standard this pass.

**EIA-310-D does not govern cabinet depth at all** — it fixes the front
panel/hole pattern (width, U pitch, hole spacing) only; front-to-rear depth is
purely a cabinet/enclosure vendor's choice. So unlike the width/hole-pattern
values above, there is no standard to corroborate against in the first place,
and no independent-peer corroboration was attempted or found for the specific
400/600/800mm figures.

Corrected tier: **[C] `//VERIFY illustrative common 19in mounting depths,
vendor-dependent — not EIA-fixed, not independently corroborated`**. Numeric
values and the existing test asserts (which only check `>0` / `len>=1`, not
the specific mm figures) are unchanged — this is a provenance-tag correction
only, not a data change.

## Device height / stacking gap (Task 1 follow-up)

### 1U max device/panel height — **43.66 mm (1.719 in)**, exact **43.6626 mm (1.71875 in)** — tier [B]

- **Wikipedia** (`Rack_unit` article): *"a panel is 1⁄32 inch (0.031 in; 0.79 mm) less in
  height than the full number of rack units would imply"* and, worked for
  n=1: *"a 1U front panel would be 1+23⁄32 inches (1.719 in; 43.66 mm)
  tall."* General formula given: **h = 1.750n − 0.031 in = 44.45n − 0.79 mm**.
- **Micropolis** (`https://www.micropolis.com/support/kb/rack-mounting-faq`,
  "Rack Panels" section, independent, different publisher/vendor):
  *"a standard conforming 1U panel is 1.71875" tall (rounded to 1.719" in EIA
  specs and equalling 43.6626mm)"*, quoting the same formula `h = (1.750×n −
  0.031) in = (44.45×n − 0.79) mm`, and separately: *"height tolerance" is
  "plus zero, but minus 0.031"* — i.e. panel height is a **max**, not a
  nominal-with-symmetric-tolerance.
- Two independent documents (Wikipedia's peer-edited article; Micropolis's
  own vendor rack-mounting FAQ, unrelated publisher), exact numeric match
  (43.66/43.6626 mm, 1.719/1.71875 in, identical formula) — tier **[B]**.
  No third independent source was found, so ship as [B], not [A]
  (EIA-310-D itself remains paywalled, same as every other value in this file).

### Stacking gap — **0.79 mm (0.031 in) total, NOT per-U** — tier [B] `//VERIFY`

- **Important non-obvious finding for Task 2/3**: the formula `h = 44.45n −
  0.79` subtracts the **same fixed 0.79 mm once**, regardless of `n` — it is
  *not* `n × 0.79`. A 1U panel is 44.45 − 0.79 = 43.66 mm; a 2U panel is
  2×44.45 − 0.79 = 88.11 mm (not 88.90 − 2×0.79 = 87.32 mm). Physically this
  makes sense: a device's front panel is one continuous piece of sheet metal,
  so it only needs *one* top-relief cut regardless of how many U's tall it
  is — the relief exists so the panel doesn't bind against the *next*
  device's panel above it, not once per internal U boundary.
  - This means `rack19_device_height(u)` should be `u * 44.45 - 0.79`, **not**
    `u * (44.45 - 0.79/u)` or `u * 43.66`-style per-U scaling — the two
    formulas agree only at u=1 and diverge for u≥2 (e.g. at u=2: 88.11mm vs
    87.32mm, a 0.79mm difference).
  - `rack19_stack_gap()` (a standalone accessor for the 0.79mm constant) is
    still meaningful and matches the task's premise of "tenths of a mm" (it's
    0.79mm — high end of "tenths of a mm", but same order of magnitude), it
    just must not be multiplied by `u` inside `device_height`.
- Tag `//VERIFY 0.79mm gap applies once per device regardless of U count —
  derived from the EIA panel-height formula`s structure (h = 44.45n − 0.79,
  a single subtraction, not n subtractions), not from a source that states
  the "not-per-U" framing explicitly in those words` — the *numbers* are
  solidly [B] (two independent sources, exact match); the *framing* (that
  Task 2 must not naively multiply per U) is this pass's own arithmetic
  reading of the cited formula, not a direct quote, so it gets its own
  `//VERIFY` flag for a second pair of eyes.
- Consumer note: bpi-r4 chassis to replace its project-local `stack_gap` with `rack10_stack_gap()` (post-wave).

## Summary table for Task 2+

| Value | mm | tier | source |
|---|---|---|---|
| 1U pitch | 44.45 | [B] | Wikipedia + IBM |
| panel width | 482.6 | [B] | Wikipedia (closure-checked) |
| opening width | 450.85 | [B] | Wikipedia + IBM |
| rail post/flange width | 15.875 | [B], `//VERIFY second source for 15.875mm post width` | Wikipedia |
| hole h center-to-center | 465.1 (band 464.2–465.8) | [B], `//VERIFY 465.1 nominal vs IBM 464.2–465.8mm band — no discrete point-value source found` | IBM (Wikipedia echoes same ref) |
| per-U gaps | 15.875 / 15.875 / 12.7 | [B] | Wikipedia + IBM |
| per-U first-offset | 6.35 (→22.225/38.1 exact) | `//VERIFY` | Wikipedia prose only |
| cage-nut square side | 9.5 | [B], `//VERIFY` 2nd vendor | Wikipedia (Cage nut) |
| round-hole diameter (bonus) | 7.1 ± 0.1 | [B] | IBM |
| screw clearance M6 | 6.6 | [B] | ISO 273 medium fit (named standard, not fetched) |
| screw clearance 10-32 | 5.0 | [C] `//VERIFY` | ANSI B18.2 close-fit clearance-drill (#10≈0.199in=5.05mm), named standard not fetched this pass |
| screw clearance 12-24 | 5.6 | [C] `//VERIFY` | ANSI B18.2 close-fit clearance-drill (#12≈0.221in=5.61mm), named standard not fetched this pass |
| rail flange thickness | — | `//VERIFY`, informational | not spec-fixed |
| 1U max device height | 43.66 (exact 43.6626) | [B] | Wikipedia + Micropolis, exact match |
| stacking gap | 0.79 (total, not per-U) | [B] `//VERIFY` not-per-U framing | derived from h=44.45n−0.79 formula, Wikipedia + Micropolis |
