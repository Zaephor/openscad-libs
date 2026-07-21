# din-rail — evidence source log

Evidence/provenance log for the EN 60715 top-hat (TS35) DIN-rail profile,
both standard (7.5mm) and deep (15mm) depth variants. The dimensional data
sourced here is implemented in `din-rail.scad`'s `_din_table()` (width,
depth, material thickness, slot pitch) and `din_rail_lip()` (return-edge lip
geometry).

EN 60715 itself is a paywalled IEC/CENELEC standard and was not fetched
directly. Every dimension below is instead corroborated across independent
published vendor/reference sources that cite EN 60715 (or its EN 50022
predecessor) as the governing spec, per this repo's tiering convention: a
named-but-unfetched standard caps a value at `[B]`, not `[A]`, however many
peers agree.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` the authoritative governing standard/spec itself fetched and read directly.
- `[B]` corroborated across >=2 independent peers.
- `[C]` single-sourced / derived, or a named standard cited but not fetched.
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

## Sources consulted

- WAGO product page/datasheet, part **210-112** — "Steel carrier rail; 35 x
  7.5 mm; 1 mm thick; 2 m long; slotted; according to EN 60715; Hole width 25
  mm" — `wago.com/global/accessories/steel-carrier-rail/p/210-112`
- WAGO product page/datasheet, part **210-197** — "Steel carrier rail; 35 x
  15 mm; 1.5 mm thick; 2 m long; slotted; similar to EN 60715" —
  `wago.com/us/accessories/steel-carrier-rail/p/210-197`
- Phoenix Contact product page, **NS 35/7.5 PERF** (e.g. part 1207653) —
  width 35mm, hole width 15mm, hole height 6.2mm, depth 7.5mm, drill-hole
  spacing 25mm — `phoenixcontact.com/en-us/products/din-rail-ns-35-75-perf-955mm-1207653`
- Phoenix Contact product page, **NS 35/15 PERF** (part 1201730) — 35 x 15mm,
  EN 60715 — `phoenixcontact.com/en-pc/products/din-rail-perforated-ns-35-15-perf-2000mm-1201730`
- Wikipedia, "DIN rail" article — top-hat rail IEC/EN 60715 35x7.5 and
  35x15 variants, EN 50022 predecessor naming — `en.wikipedia.org/wiki/DIN_rail`
- Schneider Electric technical documentation ("Top Hat Section Rail (DIN
  rail)", Machine Expert product help) — IEC 60715-compliant top-hat rail:
  35mm width (+/-0.3mm), 1mm thickness (+/-0.04mm), 7.5 or 15mm height
  (+0/-0.4mm) — `product-help.se.com` (TM3 installation reference)
- Rastro DIN-rail dimensions reference chart — TS35 typical wall thickness
  1.0-1.5mm, slot geometry 15x6.2mm, hole/slot pitch 25mm —
  `rastro.ai/resources/din-rail-dimensions-ts-35-ts-32-ts-15-chart`
- TPS-Eleus "IEC 60715 DIN Rail Layout Guide" — corroborates 25mm drill-hole
  spacing as the commonly-stocked figure — `tps-eleus.com` blog

No third-party STL/3MF mesh was measured for this pass; the return-edge lip
gap below could not be closed even with a mesh-measurement fallback because
no suitable reference model surfaced with a stated dimensioned source (see
that section).

## TS35 x 7.5 (standard-depth top-hat rail)

| Dimension | Value | Tier | Sources |
|---|---|---|---|
| Overall width | 35 mm | [B] | WAGO 210-112, Phoenix Contact NS 35/7.5 PERF, Wikipedia DIN rail |
| Depth | 7.5 mm | [B] | WAGO 210-112, Phoenix Contact NS 35/7.5 PERF, Wikipedia DIN rail |
| Material thickness | 1 mm | [B] | WAGO 210-112 ("1 mm thick"), Schneider Electric ("1mm thickness +/-0.04mm"), Rastro (1.0-1.5mm typical range, low end) |
| Mounting-slot pitch | 25 mm | [B] | WAGO 210-112 ("Hole width 25 mm"), Phoenix Contact NS 35/7.5 PERF ("drill hole spacing of 25 mm"), Rastro, TPS-Eleus |
| Return-edge lip (height / return length / bend radius) | not numerically confirmed by any source found — see below | [C]//VERIFY | none numeric |

Mounting-slot pitch note: the brief's expectation was "~27mm" going in;
every source found instead converges on **25mm** for the perforated/slotted
TS35 rail hole spacing, for both depth variants. Terminology is inconsistent
across vendors — Phoenix Contact separates "hole width" (15mm, the slot
opening's long dimension) from "drill hole spacing" (25mm, the pitch), while
WAGO's terse catalog copy labels the same 25mm figure "Hole width" — read in
context as the pitch figure, consistent with Phoenix Contact's explicit
breakdown, not a literal 25mm-wide single hole.

## TS35 x 15 (deep-depth top-hat rail)

| Dimension | Value | Tier | Sources |
|---|---|---|---|
| Overall width | 35 mm | [B] | WAGO 210-197, Phoenix Contact NS 35/15 PERF, Wikipedia DIN rail |
| Depth | 15 mm | [B] | WAGO 210-197, Phoenix Contact NS 35/15 PERF, Wikipedia DIN rail |
| Material thickness | 1.5 mm | [B]//VERIFY (vendor-variant) | WAGO 210-197 ("1.5 mm thick"), general trade-guide commentary that deep-hat material is "often increased to 1.5mm or 2.3mm" for rigidity |
| Mounting-slot pitch | 25 mm | [B] | WAGO 210-197, Rastro (states pitch is identical across both depth variants), TPS-Eleus |
| Return-edge lip (height / return length / bend radius) | not numerically confirmed by any source found — see below | [C]//VERIFY | none numeric |

Material thickness note: unlike the 7.5mm variant, deep-rail (15mm) material
gauge is genuinely vendor-variant — WAGO's own two catalog SKUs already
differ (1mm for TS35x7.5, 1.5mm for TS35x15), and other vendors' deep-hat
rails are reported anywhere from 1.2mm to 2.3mm depending on load rating.
1.5mm is used as the conservative nominal (WAGO's own direct figure), tagged
`//VERIFY` for the real vendor spread.

## Return-edge lip geometry — both variants

The inward-turned lip at each open edge of the top-hat profile (the
retention-critical feature a snap clip catches on) is described qualitatively
by every source consulted — "hat" cross-section, DIN-rail mounting clips
described as gripping "the top and bottom lips of the rail" — but **no
source found gives a dimensioned lip height, return length, or bend radius**.
General trade/mounting-clip descriptions (clip vendors, DIN-rail-clip
overview pages) confirm the lip exists and is what clips hook onto, but stop
short of a numeric drawing; the authoritative dimensioned cross-section
(including corner/curl radii) is understood to live in IEC 60715's Annex A,
which is paywalled and was not accessed.

Per the brief's guidance for a single-sourced/vendor-variant dimension: this
is modeled as a **conservative nominal**, tagged `[C]//VERIFY`, for Task 2/3
to consume and refine (ideally against a physical caliper-measured rail
per this repo's value-confidence convention, upgrading the tier once
measured):

- Lip height: ~1 mm (approximated from material thickness, since the lip is
  a folded continuation of the same sheet stock — 1mm for TS35x7.5, up to
  1.5mm for TS35x15).
- Return length (horizontal inward reach of the hook): ~1-1.5mm, a
  conservative minimum that a clip's catch geometry should not assume is any
  larger.
- Bend radius: ~0.5-1mm, typical of roll-formed sheet steel of this gauge.

Flag for Task 2/3: **do not treat these three numbers as authoritative** —
they are a placeholder nominal for a dimension this pass could not close with
a real citation, explicitly called out in the task brief as the dimension
"most likely to end up `[C]//VERIFY`". A caliper measurement of a physical
TS35 rail (per this repo's device-data rules) is the fastest path to
upgrading this tier.

## Gaps (values NOT independently corroborated this pass)

- Return-edge lip height / return length / bend radius, both variants: no
  numeric source found; modeled as a conservative placeholder, `[C]//VERIFY`
  (see above).
- TS35x15 material thickness: real vendor spread (1.2-2.3mm reported
  elsewhere); 1.5mm nominal used, `[B]//VERIFY` on the exact figure.

No value in this file was invented without at least a named-standard citation
or a fetched/read vendor page backing it, except the explicitly-flagged
placeholder lip geometry above.
