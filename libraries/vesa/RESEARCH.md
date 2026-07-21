# vesa — FDMI/MIS pattern source log (Task 1)

Scope: Task 1 only — scaffold + evidence-sourced value log. **No data table or
modules are implemented in `vesa.scad` yet** beyond the `make new-lib`
placeholder boilerplate (that is Task 2). This file is the evidence Task 2
will read to fill in `vesa_pattern()`/`vesa_spacing()`/`vesa_screw()`.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` fetched + read this pass (vendor datasheet or governing standard).
- `[B]` corroborated across >=2 independent peers.
- `[C]` single-sourced / derived, or a named standard cited but not fetched.
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

## Standard access note

The governing document — VESA's own **FDMI (Flat Display Mounting Interface)
/ MIS (Mounting Interface Standard)** spec — is **member-paywalled**, the same
class as PCI-SIG CEM / EIA-310-D / USB-IF already noted in
`libraries/connectors/RESEARCH.md`. No claim below reaches tier `[A]`; the
values are cited to peer-published secondary sources instead and tiered `[B]`
community-consensus. Named-not-fetched.

Three independent pages were read directly this pass and are cited per-value
below:
- Wikipedia, "VESA mount" — `https://en.wikipedia.org/wiki/VESA_mount`
  (tabulates FDMI variants B-F: pattern size, hole count, screw thread,
  position tolerance, bracket clearance-hole diameter, steel-thickness/
  clearance-depth guidance).
- Oeveo, "All about the VESA pattern" —
  `https://www.oeveo.com/content/320-all-about-the-vesa-pattern` (FDMI table:
  MIS-D 75/100, MIS-E, screen-size class, weight rating, screw size).
- vesa-standard.com, "VESA MIS-D Standard 75/100" —
  `https://www.vesa-standard.com/vesa-mis-d.html` (hole spacing + weight/
  screen-size class for the 75/100 square patterns; does not itself state
  screw size).

## MIS-D 75 (75x75 mm square)

- **Spacing**: 75mm x 75mm square, 4 holes (2x2), origin-centered corners at
  (+-37.5, +-37.5). Definitional to the "MIS-D 75mm" name. Tier **[B]** —
  Wikipedia ("Center mount pattern... 075mm x 075mm, 2x2 holes") + Oeveo
  ("Hole pattern: 75 x 50, 75 x 75") + vesa-standard.com ("VESA mounting
  holes / hole pattern: 75x75, 100x100 mm") all agree.
- **Screw**: M4. Tier **[B]** — Wikipedia ("The screw size for part D is
  M4"; also states screws are "standard M4 machine screws" for the B-E
  family) + Oeveo ("Screw size: M4 x 10 mm").
- **Clearance dia**: not re-derived here — see "M4 clearance dia" below
  (references this repo's existing ISO-273 medium-fit convention, not a
  fresh literal).
- **Position tolerance** (context, not consumed by Task 2's API unless
  needed): Wikipedia states "each hole must be within +-0.25mm of its
  nominal position." Tier **[C] //VERIFY** (single-sourced this pass).

## MIS-D 100 (100x100 mm square)

- **Spacing**: 100mm x 100mm square, 4 holes (2x2), origin-centered corners
  at (+-50, +-50). Definitional to the "MIS-D 100mm" name. Tier **[B]** —
  Wikipedia ("Center mount pattern... 100 x 100mm, 2x2 holes") + Oeveo
  ("Hole pattern: 100 x 50, 100 x 100") + vesa-standard.com ("100x100mm")
  all agree.
- **Screw**: M4. Tier **[B]** — same two direct citations as MIS-D 75
  (Wikipedia's M4 callout is stated once for the whole B-E family; Oeveo
  states "M4 x 10 mm" specifically for the 100mm row too).
- **Clearance dia**: see "M4 clearance dia" below.
- **Weight class** (context only): both Oeveo ("up to 30.8 lbs") and
  vesa-standard.com ("max. 14 kg") agree the 100x100 pattern is rated
  heavier than 75x75 — consistent cross-source, not consumed by the planned
  API. Tier **[B]**.

## MIS-E (200x100 mm)

- **Spacing**: 200mm (wide) x 100mm (tall) rectangle. Per Wikipedia this is
  a 2(height) x 3(width) hole count (6 holes total: the 4 square-pattern
  corners of a 100x200 rectangle PLUS 2 extra holes "in the middle of the
  long sides" — i.e. an additional pair at (0, +-50) if centered at origin
  with the long axis on X). Definitional to the "MIS-E" name. Tier **[B]**
  — Wikipedia ("Center mount pattern... 100 x 200mm, 2x3 holes... the two
  extra holes in type E brackets are in the middle of the long sides") +
  Oeveo ("Hole pattern: 200 x 100") both corroborate the 200x100 spacing;
  Oeveo does not independently confirm the 6-hole count, so **the 6-hole
  detail itself is single-sourced this pass — tier [C] //VERIFY** even
  though the 200x100 spacing is [B]. Task 2 should decide whether to model
  MIS-E as 4-hole (matching the plan's `[[x,y,role,dia],...]` for the
  common corner-only mount, sufficient for most consumers) or the full
  6-hole pattern; either way the extra pair's exact position needs the
  4-hole spacing (100 tall / 200 wide) as its basis, which IS solidly [B].
- **Screw**: M4. Tier **[B]** — Wikipedia (states M4 for the whole B-E
  family) + Oeveo ("Screw size: M4 x 10 mm" on the MIS-E row specifically).
- **Clearance dia**: see "M4 clearance dia" below.

## M4 clearance dia — referenced, not re-derived

Per the plan's binding constraint (single source of truth): do not invent a
fresh M4 clearance literal for this library. This repo already establishes
an ISO 273 medium-fit clearance series in
`libraries/rack19/rack19.scad:68` (comment) /
`libraries/rack19/RESEARCH.md` ("Screw clearance 10-32 / 12-24 / M6"
section): **"ISO 273's published medium fit series: M3->3.4, M4->4.5,
M5->5.5, M6->6.6"**. `rack19_screw_clearance()` itself only implements the
`10-32`/`12-24`/`M6` cases (rack19's rail-mount hardware doesn't use M4), but
the M4 point of that same named series is already recorded there:
**M4 -> 4.5mm**.

- **Value**: 4.5mm. Tier **[B]** (same tier rack19 assigned its own M6 point
  from this identical named series — "ISO 273 medium fit, named standard,
  not fetched"). Cited to ISO 273 by name only (paywalled standard), same
  class as the FDMI/MIS standard itself — not independently re-fetched by
  this library.
- **Task 2 guidance**: reference this value with a why-comment pointing at
  `rack19/rack19.scad`'s series comment (single source of truth — the
  number must not be duplicated as an unexplained fresh literal). Since
  `rack19_screw_clearance()` has no `"M4"` case to call as an accessor, the
  established pattern (not a callable function) is what's being reused;
  the why-comment should say so explicitly.
- **Cross-check (informational, not the value we use)**: Wikipedia's own
  VESA-bracket table gives a *different* number — bracket-side clearance
  holes are "5mm in diameter to allow for [+-0.25mm position] tolerance in
  both screen and bracket." That 5mm figure is the VESA-bracket's OWN
  clearance spec (a different design decision made by the standard's
  authors for their own hardware), not this repo's ISO-273 convention — it
  is **not** adopted here, to keep with the single-source-of-truth rule
  (this repo's M4 clearance is always the ISO-273 point, 4.5mm, wherever
  M4 clearance holes are modeled). Recorded for context only, tier
  **[B]** (directly read off the fetched Wikipedia table), //VERIFY-free
  since it is not consumed as a value.

## Screw thread-in / fastening depth

Wikipedia's VESA-bracket table (the same page cited above) gives a "clearance
depth max" of **10mm** and a "steel thickness typical" of **2.6mm** for the
D-75mm/D-100mm/E bracket rows — but these describe the MOUNTING BRACKET's own
sheet-metal thickness and the screw's max protrusion allowance past the
bracket into the display, not a universal thread-engagement depth into any
given display's internal bosses (which is explicitly device-dependent — a
thin monitor and a thick all-in-one PC will differ). No consistent
published figure for "screw thread-in depth into the display" itself was
found (as opposed to the bracket-side protrusion allowance above).

- **Bracket protrusion allowance**: 10mm max (i.e. a screw should not stick
  out more than 10mm past the mount-bracket face). Tier **[C] //VERIFY**
  (single-sourced this pass, and it constrains screw length choice more
  than it dictates a display-side boss depth).
- **Display-side thread-in depth**: **omitted** — no consistent published
  figure exists (device-dependent). README coverage notes this explicitly
  per `docs/LIBRARY-AUTHORING.md`'s gap-handling rule ("no sourcing at all:
  omit the value; record it in the README coverage notes as not-yet-
  covered").

## MIS-F (not modeled — context only)

MIS-F (200x200mm and larger, M6/M8, big-TV class) is out of scope for this
pass (YAGNI, no current consumer). Wikipedia's same FDMI table extends the
B-F letter classes up through 200x200mm+ with M6/M8 screws, consistent with
the general industry understanding that larger displays step up to M6/M8 —
not independently corroborated to `[B]` this pass, and not needed to be:
it backs no value in this library. Not consumed by any value here — no
MIS-F row is added to `vesa_known_patterns()`.

## Summary table

| pattern    | spacing (w x h, mm) | holes | screw | clearance dia | tier |
|------------|----------------------|-------|-------|----------------|------|
| mis-d-75   | 75 x 75              | 4     | M4    | 4.5mm (referenced, ISO 273) | [B] |
| mis-d-100  | 100 x 100            | 4     | M4    | 4.5mm (referenced, ISO 273) | [B] |
| mis-e      | 200 x 100            | 4 (corners; +2 mid-long-side per Wikipedia, [C]//VERIFY if modeled) | M4 | 4.5mm (referenced, ISO 273) | [B] (spacing/screw); [C]//VERIFY (6-hole detail) |

Corner math sanity check (Task 2 will assert this): a WxH rectangle
origin-centered has corners at (+-W/2, +-H/2) — 75x75 -> +-37.5;
100x100 -> +-50; 200x100 -> +-100 (X) / +-50 (Y).

## Gaps (values NOT independently fetched this pass — README should note these)

- MIS-E's extra 2-hole mid-long-side detail: single-sourced (Wikipedia
  only) — `[C] //VERIFY`.
- Display-side screw thread-in/boss depth: no consistent published figure —
  omitted per `docs/LIBRARY-AUTHORING.md` gap-handling (not a `//VERIFY`,
  a documented non-coverage).
- MIS-F (200x200+, M6/M8): out of scope, not modeled, not sourced beyond
  the passing mentions above.

No value in this file was invented without at least a named-standard
citation or a fetched-and-read page backing it.
