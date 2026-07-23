# connectors — datasheet source log (Task 1)

Scope: Task 1 only — scaffold + evidence-sourced value log. **No data table or
modules are implemented in `connectors.scad` yet** (that is Task 2). This file
is the evidence Task 2 will read to fill in `_connector_table()`.

Canonical frame (see connectors.scad header): mounting/panel face on Z=0,
centered in X, opening `+Y` (panel connectors: USB/RJ45/HDMI) or `+Z`
(slot/header: PCIe/GPIO). `[w,d,h]` = extents along `[X,Y,Z]`.

Provenance legend (per `docs/LIBRARY-AUTHORING.md`):
- `[A]` fetched + read this pass (vendor datasheet or governing standard).
- `[B]` corroborated across >=2 independent peers.
- `[C]` single-sourced / derived, or a named standard cited but not fetched.
- `//VERIFY` marks a weak/single-sourced value pending stronger corroboration.

## Source access note

Same Sky/CUI Devices and Bel Fuse datasheets were read directly this pass.
Molex, Amphenol-ICC/CS, Digikey, Mouser, Samtec, and GCT were not accessed
this pass — Molex's product-page drawing links aren't in the served page, and
USB-IF's own usb.org mechanical specs (USB 2.0 spec, Type-C spec) sit behind an
account-login/EULA gate (only compliance/test-plan PDFs are openly listed).
CUI Devices rebranded to **Same Sky** during this datasheet's validity (title
blocks below say "SAME SKY"); part numbers are unchanged from the CUI-era
catalog.

## Per-type findings

### usb_a — USB Type-A THT receptacle
- **Fetched**: Same Sky `UJ2-AH-4-TH` datasheet, page 2 mechanical drawing.
  `https://www.cuidevices.com/product/resource/uj2-ah-4-th.pdf`
- **Read**: shell width 13.66mm (front/top view; mounting flange extends to
  14.3mm — not counted as body), depth 14.00mm (top view) / 14.6mm (side view,
  full shell length, `-0.1/-0` tol) — two views disagree by ~0.6mm, using the
  side-view total 14.6 as the fuller "housing extent" per the brief's
  instruction to capture shell, not just opening; height 6.94mm (side view,
  full height above PCB).
- **Confirmed**: `[13.66, 14.6, 6.94]`, opening `+Y`. Tier **[A]**.
- **Seed cross-check**: seed `[13.25, 16.4, 6.5]` — width AGREE (+0.41mm),
  depth DISAGREE (-1.8mm, ~11%), height AGREE (+0.44mm).
- **sbc.scad cross-check** (`usb2_1`/`usb2_2`/`usb2`/`usb3` rows, `[17, 18,
  16.0]`-ish): DISAGREE substantially on all three axes. sbc's figures are
  almost certainly a **dual-stacked** USB-A port silhouette (common on SBCs),
  i.e. they correspond to this library's `usb_a_stack2` type, not plain
  `usb_a` — the sbc rows should be retro-mapped to `usb_a_stack2` in the
  deferred retrofit, not `usb_a`.

### usb_a_stack2 — stacked dual USB Type-A
- **Not independently fetched** (no stacked-shell datasheet found/reachable).
- **Derived**: single-port body doubled in height with a shared shell:
  `[13.66, 14.6, ~13.9]` (2 x 6.94 = 13.88, rounded). Tier **[C]** (derived
  from a fetched single-port value, not itself fetched).
- **sbc.scad cross-check**: `[17, 18, 16.0]` — reasonably close on height
  (16.0 vs ~13.9, sbc runs taller, plausibly including more shell clearance),
  width/depth run ~3.3mm wider in sbc (may include side-by-side port
  clearance in the photo-derived footprint). Not a clean match — flagged for
  Task 2 judgment call.

### usb_c — USB Type-C receptacle
- **Fetched**: Same Sky `UJC-H-G-SMT-P6-TR` datasheet, page 2.
  `https://www.cuidevices.com/product/resource/ujc-h-g-smt-p6-tr.pdf`
- **Read**: top view width 8.94mm, depth 6.90mm; side view height 3.16mm.
- **Confirmed**: `[8.94, 6.90, 3.16]`, opening `+Y`. Tier **[A]**.
- **Seed cross-check**: seed `[8.94, 7.35, 3.26]` — width EXACT match,
  depth AGREE (-0.45mm), height AGREE (-0.10mm).
- **sbc.scad cross-check** (`usbc_pwr`, `[9, 7.4, 3.2]`): AGREE on all three
  axes (within 0.3mm).

### micro_usb — USB Micro-B receptacle
- **Part-number caveat**: `UJ2-MIBH-3-MSMT-TR-67`'s `MIBH` prefix is
  **Mini-B**, not Micro-B (much larger shell: opening 11.30x4.75mm, overall
  ~9.4x?x6.0mm — Mini-USB, a different v1 type we don't currently have a slot
  for). The correct Micro-B part carries the `MBH` prefix.
- **Fetched**: Same Sky `UJ2-MBH-SMT` (Micro-B, `MBH` prefix) datasheet,
  page 2. `https://www.cuidevices.com/product/resource/uj2-mbh-smt.pdf`
- **Read**: width 7.72mm (shell) / 6.92mm (front mating-face outline),
  height 3.96mm (front-face view, full outer height incl. small foot ears).
  Depth is **ambiguous between two readings** in this drawing: 5.48mm
  appears twice (top view + PCB-layout view, consistent with each other,
  likely the true shell front-to-back extent) vs. 9.20mm / 9.80mm(max) in
  the side-profile view (possibly includes a bent solder-tail overhang
  behind the shell, not just the housing). Not resolving this by guessing —
  recording both for Task 2 to re-open the PDF and disambiguate.
- **Confirmed (partial)**: width 7.72mm, height 3.96mm — Tier **[A]**.
  Depth: 5.48mm **or** 9.20mm, Tier **[A] //VERIFY (axis ambiguity)**.
- **Seed cross-check**: seed `[7.5, 5.5, 3.0]` — width AGREE (+0.22mm);
  depth AGREE almost exactly against the 5.48mm reading (-0.02mm), DISAGREE
  against the 9.20mm reading; height DISAGREE (3.96 vs 3.0, +0.96mm, ~32%
  over — seed height may be a thinner reference part, or 3.96 includes a
  foot below the mounting plane that shouldn't count as "above Z=0").
- **sbc.scad cross-check** (`microusb_pwr`/`microusb_data`, `[7.5-7.6, 4.6-
  4.7, 2.8]`): width AGREE, depth DISAGREE (~0.8mm under the 5.48 reading),
  height DISAGREE (2.8 vs 3.96, sbc runs thinner — sbc's figure is itself
  tagged `[C] //VERIFY` in that library, so this is two weak values
  disagreeing, not a strong contradiction). Note pi3b's own `microusb_pwr`
  row (`sbc.scad:79`, body `[7.5, 5.5, 2.8]`) carries depth **5.5mm**, which
  is *closer* to the fetched 5.48mm reading than the pi3b/pi4b/pi5 Zero-
  family average above (-0.02mm vs the 5.48 reading) — this strengthens
  (does not weaken) the case that 5.48mm, not 9.20mm, is the correct axis
  reading.

### rj45 — RJ45 jack (single port, gigabit MagJack w/ integrated magnetics)
- **Fetched**: Bel Fuse `0813-1X1T-43-F` ("gigabit MagJack, 8 cores, tab
  down") datasheet, page 3 mechanical spec.
  `https://www.belfuse.com/Data/Datasheets/0813-1X1T-43-F.pdf`
- **Read**: shell width 16.36mm (0.644in), shell height 13.67mm (0.538in),
  shell depth 30.48mm (1.200in, front face to rear of shield).
- **Confirmed**: `[16.36, 30.48, 13.67]`, opening `+Y`. Tier **[A]**.
- **Seed cross-check**: seed `[16.0, 21.0, 13.5]` — width AGREE (+0.36mm),
  height AGREE (+0.17mm), depth **DISAGREE substantially** (+9.48mm, ~45%
  over). Root cause: this MagJack has **integrated magnetics** (transformer
  module potted into the rear of the shell), which is significantly deeper
  than a bare RJ45 jack. The seed's 21.0mm looks like a plain-jack figure.
- **sbc.scad cross-check** (`rj45*` rows across boards, width fixed at 21,
  depth ranging 10.25-19.05, height fixed at 13.5 on the clean single-jack
  rows): height AGREE exactly (13.5 == 13.5) on the pi3b/pi3bplus/pi4b
  single-jack `rj45` rows and bpir4's `rj45_1`/`rj45_2`/`rj45_3`/`rj45_4` —
  a robust, stable figure across real parts and sbc's own photo-derived
  rows, but this comparison is scoped to those clean single-jack rows, not
  a universal agreement across every `rj45*` entry in sbc.scad: Pi5's combo
  row (`sbc.scad:123`, `["rj45", ..., [21, 18.9, 16.0], "xmax"]`, shared
  with `usb2` at the identical box — an undimensioned rj45+usb2 combo shell,
  not a plain jack) reads height **16.0**, not 13.5, because it's a
  physically different part (a molded combo shell), not a disagreement on
  the same part. Width DISAGREES (21 vs 16.36, sbc rows read wider —
  plausibly including an EMI shield/overmold visible in the board photos
  that extends past the bare jack shell). Depth DISAGREES in every sbc row
  (all shallower than 30.48mm, including bpir4's `rj45_1` row at depth
  **20.0**, `sbc.scad:174`) — **most SBC RJ45 jacks apparently do NOT use
  integrated-magnetics MagJacks** (external magnetics IC instead), or the
  sbc rows only captured partial depth from a top-down board photo (several
  are already tagged `[C]`/`//VERIFY` in sbc.scad for exactly this reason).
  This is a genuine, well-evidenced disagreement, not a data-entry slip —
  worth flagging explicitly for the deferred retrofit rather than silently
  averaging it away.

### rj45_stack2 — stacked dual RJ45 (2-high, single column)
- **Fetched, but wrong product shape**: Bel Fuse `0810-2H4R-BG-F` is a
  **2x4 (8-port) MagJack array**, not a clean 2-high/1-wide stack.
  `https://www.belfuse.com/Data/Datasheets/0810-2H4R-BG-F.pdf`
  Confirms per-port pitch/depth are consistent with the single-port part
  (~30.99mm depth, matching the single port's 30.48mm within tolerance) but
  does not cleanly hand us a 2-port-only stacked height.
- **Derived**: naive 2x single-port height, `[16.36, 30.48, ~27.3]`
  (2 x 13.67 = 27.34). Tier **[C]** (derived, not independently confirmed
  for the true stacked-shell height, which likely shares some shell material
  between rows and so may be marginally less than a naive double).
- **Seed cross-check**: seed `[16, 21, 27]` — width/height AGREE closely
  with the derived figure; depth DISAGREE for the same integrated-magnetics
  reason as plain `rj45`.

### hdmi — HDMI Type-A receptacle
- **Fetched**: Same Sky `HD05-19-TH-TR` datasheet, pages 2-3 (mechanical
  drawing + PCB layout).
  `https://www.cuidevices.com/product/resource/hd05-19-th-tr.pdf`
- **Read**: shell width 14.50mm (matches the PCB-layout footprint width
  exactly, cross-checked between two independent views), depth 11.06mm
  (PCB-layout front-to-back footprint span), height 6.17mm (side view, full
  height above PCB).
- **Confirmed**: `[14.50, 11.06, 6.17]`, opening `+Y`. Tier **[A]**.
- **Seed cross-check**: seed `[15.0, 12.0, 6.0]` — all three axes AGREE
  (within 1mm).
- **sbc.scad cross-check** (`hdmi`, `[15, 11.5, 6.5]`, tagged `[B]` body):
  AGREE on all three axes (within 0.5mm) — this upgrades sbc's `hdmi` row
  from `[B]` to effectively `[A]`-corroborated in the deferred retrofit.

### mini_hdmi — mini-HDMI (Type C) receptacle
- **Not fetched.** Same Sky/CUI's `hdmi-connectors` catalog category only
  lists 19-pin full-size (Type-A) parts (`hd05` through `hd12`) — no
  mini/micro variant there, and no other vendor source was accessed this pass.
- **Tier**: seed `[10.4, 7.5, 3.2]` retained, **[C] //VERIFY (cited-not-
  fetched)**.
- **sbc.scad cross-check** (`minihdmi`, `[10.9/10.8, 7.0/6.8, 3.4]`, tagged
  `[B]` pos+extent / `[C]` height //VERIFY): AGREE within ~0.5mm on all
  three axes — two independently weak sources agreeing, still not [A].

### micro_hdmi — micro-HDMI (Type D) receptacle
- **Not fetched**, same reason as mini_hdmi (Same Sky/CUI has no Type-D
  listing; other vendors unreachable this pass).
- **Tier**: seed `[7.5, 5.6, 3.0]` retained, **[C] //VERIFY (cited-not-
  fetched)**.
- **sbc.scad cross-check** (`hdmi_1`/`hdmi_2`, Pi 4B/5, `[7.5, 4.5, 3.0]`,
  tagged `[A]`): width/height AGREE exactly; depth DISAGREE (4.5 vs 5.6,
  -1.1mm, ~20%). sbc's figure is tagged `[A]` in that library (from actual
  Pi board measurement) and is the stronger of the two — worth pulling
  sbc's 4.5mm depth into this library's table in Task 2 rather than the
  seed's 5.6mm, even though no micro-HDMI vendor datasheet was independently
  fetched this pass.

### pcie_x1 / pcie_x4 / pcie_x8 / pcie_x16 — PCIe card-edge slot connector
- **Fetched (final-review fix pass, 2026-07-09)**: Molex "PRODUCT CUSTOMER
  DRAWING" **SD-87715-207**, "PCI EXPRESS EDGE CARD CONNECTOR (LEAD FREE
  VERSION)", series 87715, 5 pages, via Wayback Machine —
  `web.archive.org/web/20210228062138id_/molex.com/pdm_docs/sd/877159206_sd.pdf`.
  A real PDF (cgm2pdf/PDFlib), not a scan or an unrelated RoHS certificate.
- **Read**: page 1's master dimension table gives, per link width (N =
  pin count, DIM "B" = connector body length / long axis):

  | link width | # pos | N | DIM A | DIM B (length) | DIM C |
  |---|---|---|---|---|---|
  | x1  | 36  | 6  | 7.65  | 25.00 | 9.15  |
  | x4  | 64  | 20 | 21.65 | 39.00 | 23.15 |
  | x8  | 98  | 37 | 38.65 | 56.00 | 40.15 |
  | x16 | 164 | 70 | 71.65 | 89.00 | 73.15 |

  Also on page 1: housing width = **7.50mm MAX**, height above PCB =
  **11.25mm MAX**, card-slot opening = **5.10±0.15mm**, solder tails
  **4.40±0.15mm** below the PCB.
- **Result**: DIM B (25.00 / 39.00 / 56.00 / 89.00mm) and width/height
  (7.50 / 11.25mm) match this table's existing seed values exactly — zero
  delta on every axis, for all four link widths. **Tier upgraded to `[A]`**
  for all four (`pcie_x1`/`pcie_x4`/`pcie_x8`/`pcie_x16`) — genuinely
  fetched and read this pass, not cited-by-name.
- **Corrected finding** (this section previously stated the opposite):
  `libraries/motherboards/motherboards.scad`'s pre-existing `[A]` claim for
  these same numbers (from its own Task 11, citing this exact
  `SD-87715-207` Wayback URL) was **not** a soft/unverifiable claim — the
  citation was real and specific, and has now been independently
  re-confirmed genuine. An earlier draft of this file
  incorrectly reported the archived citation as turning up "only unrelated
  RoHS certificates for a similarly-numbered part family" and that
  motherboards' claim had "no fetch/URL citation backing it" — both
  statements were false; the citation was present in
  `motherboards/RESEARCH.md` all along and resolves to the genuine drawing.
  See `motherboards/RESEARCH.md`'s own SP1 note (corrected alongside this
  file) for the reciprocal fix.

### gpio_2x20 — 2x20 2.54mm pitch pin header (GPIO)
- **Fetched**: Same Sky `SSK01-MPH-254` series (single-row 2.54mm pitch pin
  header, 1-40 positions) datasheet, page 2.
  `https://www.cuidevices.com/product/resource/ssk01-mph-254.pdf`
- **Read**: per-position pitch table confirms 2.54mm arithmetic — N=20 row
  gives total length A=50.50mm, hole span B=48.26mm (=19 x 2.54mm exactly).
  Insulator body height 3.0mm, total pin length above PCB 6.0mm (3.0mm
  insulator + 3.0mm exposed pin) for **this specific low-profile header**.
- **Confirmed**: width/depth arithmetic — `w = 50.8` (2.54 x 20), `d = 5.08`
  (2 rows x 2.54mm pitch). Tier **[A]** (2.54mm pitch is a defined constant,
  now further corroborated by the fetched pitch table matching to 0.3mm).
- **Height**: the fetched header is a **shorter/different variant** (6.0mm
  total) than the tall ~8.5mm-pin headers commonly used for GPIO/HAT
  stacking (e.g. Raspberry Pi). Could not find/fetch a tall-pin 2x20 header
  datasheet this pass (no reachable vendor's catalog obviously separated
  "long"/HAT-stacking header variants from standard ones in the time
  available). **Height stays at the seed value 8.5mm, tier [C] //VERIFY**
  (downgraded from the brief's implied near-[A] status — real fetch data
  exists but for the wrong-height variant, so honestly this doesn't
  independently confirm 8.5mm).
- **sbc.scad cross-check** (`gpio`, `[51.0/50.6, 5.0/4.9, 8.5]`, tagged
  `[B]`/`[B]` height): width/depth AGREE closely (within 0.4mm); height
  matches exactly (8.5 == 8.5) — both this seed and sbc's figure trace to
  the same commonly-cited 8.5mm figure without independent fetched
  confirmation in either library, so this is corroboration between two weak
  sources, not a strong upgrade.
  **Update (SP1 reconciliation, 2026-07-09):** this "not a strong upgrade"
  read undersold sbc's own evidence — `sbc/RESEARCH.md`'s GPIO section shows
  pi3b's h=8.5 is a real "Z-Height=8.5" drawing callout `[A]`, **independently
  corroborated by pi4b's own separate drawing** printing the same callout —
  two real vendor drawings agreeing, not two guesses coincidentally
  matching. See `## SP1 reconciliation` below: this upgrades height to
  `[B]` (not `[A]` — an earlier draft of that section briefly over-claimed
  `[A]`; corrected there).

## Gaps (values NOT independently fetched this pass — README should note these)

- `mini_hdmi`, `micro_hdmi` body dims: seed values, `[C] //VERIFY`.
- `gpio_2x20` height (8.5mm): `[C] //VERIFY` — width/depth are solid `[A]`
  arithmetic, height is not independently confirmed for the tall-pin
  variant.
- `micro_usb` depth: two readings (5.48mm / 9.20mm) from the same fetched
  drawing, ambiguous axis interpretation — needs re-opening the PDF in
  Task 2, not a guess.
- `usb_a_stack2`, `rj45_stack2`: derived (2x single-port height), not
  independently fetched — `[C]`.

No value in this file was invented without at least a named-standard
citation or a fetched-and-read drawing backing it.

## SP1 reconciliation (2026-07-09)

Reconcile pass comparing every `sbc` connector body (read from
`libraries/sbc/sbc.scad` + `libraries/sbc/RESEARCH.md`, both READ-ONLY this
task) against its peer type in `connectors.scad`/this file. Threshold rule:
same nominal part + every `[w,d,h]` component within ~0.5mm → **same**
(highest tier wins, tie → connectors' own value; upgrade connectors if it's
weaker than an sbc `[A]` read); a real physical difference beyond noise →
**different** (missing part, add a new type); provably wrong → **error**.
No `.scad` file was edited in this task — Tasks 2-4 transcribe the New
types / Upgrades lists below into `connectors.scad` (and, in SP2, `sbc.scad`).

| board conn | conn type | board `[w,d,h]` | conn `[w,d,h]` | Δ (board-conn) | verdict | result type | tier | note |
|---|---|---|---|---|---|---|---|---|
| pi3b `usb2_1` (sbc.scad:74) | usb_a_stack2 | `[17, 18, 16.0]` | `[13.66,14.6,13.88]` | w+3.34 d+3.4 h+2.12 | different | `usb_a_stack2_shielded` (new) | B | dual-port shielded SBC housing, larger on all 3 axes than the derived single-port-doubled `usb_a_stack2` figure |
| pi3b `usb2_2` (sbc.scad:75) | usb_a_stack2 | `[17, 9, 16.0]` | `[13.66,14.6,13.88]` | w+3.34 d-5.6 h+2.12 | different (d unreliable) | `usb_a_stack2_shielded` | B | sbc's own RESEARCH.md flags this shell's d=9 as likely chain-truncated at the board edge, not the shell's true extent — excluded from the new type's reconciled depth |
| pi3bplus `usb2_1`/`usb2_2` (sbc.scad:89-90) | usb_a_stack2 | same as pi3b | same | same | different | `usb_a_stack2_shielded` | B | own-drawing citation, byte-identical to pi3b (sbc/RESEARCH.md: chains cross-checked independently) — corroborates, not a second data point |
| pi4b `usb2` (sbc.scad:102) | usb_a_stack2 | `[17, 18, 16.0]` | `[13.66,14.6,13.88]` | w+3.34 d+3.4 h+2.12 | different | `usb_a_stack2_shielded` | B | corroborates pi3b usb2_1 (identical dims) |
| pi4b `usb3` (sbc.scad:103) | usb_a_stack2 | `[17, 18.75, 16.0]` | `[13.66,14.6,13.88]` | w+3.34 d+4.15 h+2.12 | different | `usb_a_stack2_shielded` | B | d slightly larger than pi3b's 18 — within same-part noise |
| pi5 `usb3` (sbc.scad:122) | usb_a_stack2 | `[17, 17.9, 16.0]` | `[13.66,14.6,13.88]` | w+3.34 d+3.3 h+2.12 | different | `usb_a_stack2_shielded` | B | corroborates the family (17.9 close to pi3b's 18 / pi4b's 18.75) |
| pi5 `usb2` (combo w/ `rj45`, sbc.scad:124) | usb_a_stack2 / rj45 | `[21, 18.9, 16.0]` | shared box, not a pure USB-A shell | n/a | deferred, no clean peer | — | — | pi5's rj45+usb2 is one molded combo shell (sbc.scad comment: "real Pi5 hardware... share one molded part"); not force-mapped to either family — see Notes below |
| bpir4 `usb_1` (sbc.scad:171) | usb_a_stack2 (re-run vs `usb_a_stack2`, not `usb_a` — see note) | `[8.89, 23.16, 13.5]` | `[13.66,14.6,13.88]` | w-4.77 d+8.56 h-0.38 | different (weak evidence, no reliable peer) | — | — | Originally compared against single-port `usb_a` (h+6.56, misleadingly large). Re-run against `usb_a_stack2` instead: h now reconciles (Δ-0.38, within threshold), but w/d are **identical between `usb_a` and `usb_a_stack2`** (both types share the same w/d, only h differs), so w-4.77/d+8.56 remain unchanged and far outside threshold regardless of which peer is used. bpir4's own width is flagged `//VERIFY` in sbc/RESEARCH.md as "narrow... possible the true right edge undershoots the real connector"; depth (23.16mm) has no independent corroboration either (sbc's own tier tag covers only "[B] pos / [C] body h //VERIFY", not depth). 2 of 3 axes fail threshold against every candidate peer — not a confident match to any existing type, and too weak a single reading to derive a new type from. Not mapped to any type; recommend SP2 re-verify bpir4 `usb_1` before consuming |
| pi3b/pi3bplus `rj45` (sbc.scad:76,91) | rj45 | `[21, 18.75, 13.5]` | `[16.36,30.48,13.67]` | w+4.64 d-11.73 h-0.17 | different | `rj45_shallow` (new) | B | h agrees closely (no integrated-magnetics offset); w/d differ substantially — per this file's own rj45 note, sbc-style SBC jacks apparently lack the integrated-magnetics module that makes the fetched Bel Fuse MagJack deep — a real distinct part class, not a data-entry slip |
| pi4b `rj45` (sbc.scad:104) | rj45 | `[21, 10.25, 13.5]` | `[16.36,30.48,13.67]` | w+4.64 d-20.23 h-0.17 | different (d unreliable) | `rj45_shallow` | B | d=10.25 is short vs pi3b's 18.75 for the nominally same part; by analogy to sbc/RESEARCH.md's `usb2_2` caveat (chain terminates at the board's y=56 edge rather than the shell's true boundary — that note is specifically about `usb2_2`, sbc/RESEARCH.md does not itself flag pi4b's rj45 depth) the same truncation signature is present here (this span also ends exactly at y=56) — an inference by this reconcile pass, not a direct sbc citation. pi3b/pi3bplus's fuller 18.75 used as the new type's representative depth, not this row |
| pi5 `rj45` (combo w/ `usb2`, sbc.scad:123) | rj45 | `[21, 18.9, 16.0]` | `[16.36,30.48,13.67]` | w+4.64 d-11.58 h+2.33 | deferred, no clean peer | — | — | same combo shell as pi5 usb2 above; w/d land within 0.15mm of `rj45_shallow`'s reconciled depth (18.75) but h=16.0 reflects the combined USB+RJ45 molding, not a pure jack — flagged, not force-mapped |
| bpir4 `rj45_1` (CN1 "WAN", sbc.scad:174) | rj45 | `[8.0, 20.0, 13.5]` | `[16.36,30.48,13.67]` | w-8.36 d-10.48 h-0.17 | different (weak evidence) | `rj45_shallow` (tentative) | C //VERIFY | weakest-sourced bpir4 record — own RESEARCH.md flags "residual ambiguity" (internal line at y~10 unresolved). h agrees with `rj45_shallow`; w is an outlier vs rj45_2/3/4. Not used to adjust the new type's reconciled dims — flagged for SP2 re-verification |
| bpir4 `rj45_2`/`rj45_3`/`rj45_4` (CN21, sbc.scad:175-177) | rj45 | `[18.2567, 19.05, 13.5]` | `[16.36,30.48,13.67]` | w+1.90 d-11.43 h-0.17 | different | `rj45_shallow` | B | d(19.05, Δ0.30 vs the new type's 18.75) and h(13.5) corroborate the reconciled `rj45_shallow` figure within threshold; w divergence attributed to the known-unconfirmed equal-3-way-split assumption (sbc/RESEARCH.md: "no internal divider is dimensioned"), not necessarily a distinct connector — no 3rd type invented from this |
| pi3b/pi3bplus `hdmi` (sbc.scad:80,93) | hdmi | `[15, 11.5, 6.5]` | `[14.50,11.06,6.17]` | w+0.50 d+0.44 h+0.33 | same | hdmi | A (unchanged) | all 3 axes at/within the 0.5mm threshold; connectors already `[A]` fetched (Same Sky HD05-19-TH) — no upgrade needed, sbc's `[B]` figure is corroborated, not corroborating-into |
| pi4b/pi5 `hdmi_1`/`hdmi_2` (sbc.scad:108-109,129-130) | micro_hdmi | `[7.5, 4.5, 3.0]` | `[7.5,4.5,3.0]` | 0 / 0 / 0 | same | micro_hdmi | **upgrade** C//VERIFY → B | exact value match (already noted in this file's micro_hdmi section as "worth pulling sbc's depth into Task 2"). sbc's h=3.0 is `[A]` (pi4b's own "Z=3.0" drawing callout, sbc/RESEARCH.md), corroborated `[B]` carried-forward on pi5; w/d are `[B]` standard-body estimates on both sides — honest overall tier is `[B]`, not `[A]` (no independent micro-HDMI vendor datasheet was fetched by either library) |
| pi3b/pi3bplus `microusb_pwr` (sbc.scad:79,92) | micro_usb | `[7.5, 5.5, 2.8]` | `[7.72,5.48,3.96]` | w+0.22 d-0.02 h+1.16 | different (weak evidence, unresolved) | — | — | w/d agree tightly (near-exact) but h fails the ~0.5mm threshold by more than double (1.16mm) — there is no tier-precedence shortcut in the real rule (every component must be within threshold for "same"; tier only picks a value once "same" is already established). h is genuinely unresolved: connectors' `[A]` 3.96mm datasheet reading itself admits it may include foot ears (this file's own micro_usb note), while sbc's 2.8mm is an unconfirmed `[C]//VERIFY` generic guess, not drawing-confirmed (sbc/RESEARCH.md's own "weakest-sourced records" #3) — neither side strong enough to call this a confirmed distinct low-profile part or to force a match. Not folded into `micro_usb`, no new type invented from unconfirmed evidence — flagged for a future re-read of the Same Sky UJ2-MBH-SMT drawing to separate true shell height from foot ears (echoes this file's existing micro_usb depth-ambiguity note) |
| pizero/pizero2w `microusb_data` (sbc.scad:244,273) | micro_usb | `[7.5/7.4, 4.7/4.6, 2.8]` | `[7.72,5.48,3.96]` | w-0.22/-0.32 d-0.78/-0.88 h-1.16 | different (weak evidence, unresolved) | — | — | same reasoning as `microusb_pwr` above — h fails threshold, and here d also fails (-0.78/-0.88mm, unlike microusb_pwr's near-exact d); pizero's data/pwr micro-USB dims are both undifferentiated `[C]//VERIFY` generic guesses (sbc/RESEARCH.md: neither pizero sheet has Z-height text), not strong enough evidence either way. `micro_usb` **is still the correct nominal peer type** (same physical receptacle family as `microusb_pwr`, only wiring differs — resolves the brief's "(if unmatched)" hedge, so `microusb_data` stays off the no-peer list below), but the reconcile itself is unresolved pending the same re-read flagged for `microusb_pwr` |
| pi4b/pi5 `usbc_pwr` (sbc.scad:107,128) | usb_c | `[9, 7.4, 3.2]` | `[8.94,6.90,3.16]` | w+0.06 d+0.50 h+0.04 | same | usb_c | A (unchanged) | d exactly at the threshold boundary (a genuine tie per the plan's own flagged case); connectors already `[A]` fetched — tie → connectors' value, no fetch needed (not a genuine both-weak tie) |
| bpir4 `usbc_pwr_1` (CN5, sbc.scad:179) | usb_c | `[8.94, 9.95, 3.2]` | `[8.94,6.90,3.16]` | w+0.00 d+3.05 h+0.04 | different (weak evidence, unresolved) | — | — | w/h agree closely, but d fails threshold by 6x (3.05mm) — a self-flagged-suspect board reading does not license forcing "same" (same correction as bpir4 `usb_1` above). w matches exactly, but per sbc/RESEARCH.md bpir4's own w=8.94 is itself "a generic USB-C-receptacle datasheet figure, not measured from this drawing" — weaker corroboration than it looks. d divergence (3.05mm) coincides with bpir4's own flagged unresolved boundary conflict with the adjacent unmapped "CN6" component (sbc/RESEARCH.md) — plausibly a reading artifact, not confirmed either way. `usb_c` is very likely still the correct nominal part (w/h both close), but the d reading is too unreliable to certify "same" under the real rule — flagged for SP2 to re-verify bpir4's usbc_pwr_1 depth (resolve the CN6 boundary ambiguity) before consuming |
| `gpio` — pi3b/pi3bplus/pi4b/pi5 (`_sbc_gpio()`, sbc.scad:62) | gpio_2x20 | `[51.0, 5.0, 8.5]` | `[50.8,5.08,8.5]` | w+0.2 d-0.08 h=0 | same | gpio_2x20 | **upgrade** height C//VERIFY → B | w/d within threshold, connectors' `[A]` 2.54mm-pitch arithmetic wins (tie rule, datasheet value over sbc's mixed tiering). h=8.5 is an **exact** match — sbc's own h=8.5 for pi3b is `[A]` (real "Z-Height=8.5" drawing callout, sbc/RESEARCH.md's GPIO section), **independently corroborated by pi4b's own separate drawing** printing the same callout (sbc/RESEARCH.md: "pi4b's own drawing does show a matching... callout... independently confirms h") — two genuinely independent vendor drawings, not folklore. This upgrades connectors' previous `[C]//VERIFY` height, but only to **`[B]`** ("corroborated across >=2 independent peers" per this file's own provenance legend) — not `[A]`, since connectors' own pass has never itself fetched a Raspberry Pi drawing, and this file's `[A]` tier requires "fetched + read this pass" by *this* library; crediting sbc's fetch as connectors' own `[A]` would be exactly this kind of soft, uncredited-fetch claim — the same pattern this file's final-review fix pass had to correct for motherboards' PCIe claim (see the `pcie_x1`/.../`pcie_x16` section above): that claim turned out to be genuine, but only because it carried a real, checkable citation, which sbc's gpio drawing does not carry into connectors' own provenance chain |
| `gpio` — pizero/pizero2w (sbc.scad:239,269) | gpio_2x20 | `[51.0/50.6, 5.0/4.9, 8.5]` | `[50.8,5.08,8.5]` | w+0.2/-0.2 d-0.08/-0.18 h=0 | same | gpio_2x20 | (see gpio upgrade above, now `[B]`) | corroborates the Model-B family reading; pizero's own h=8.5 is `[B]` (carried forward from the Model-B family, not independently drawing-confirmed on either Zero sheet) — does not itself add new evidence beyond the pi3b/pi4b `[B]`-corroborated value already cited |

### New types to add (Task 2)
- `usb_a_stack2_shielded` = `[17, 18, 16.0]` opening `+Y` — **[B]** — evidence: sbc.scad pi3b/pi3bplus `usb2_1` (xmax, `[A]` Y-span+h drawing callout / `[B]` w standard-body estimate), corroborated by pi4b `usb2`/`usb3` and pi5 `usb3` (rows above). A real dual-port shielded SBC housing, distinct from the derived-doubling `usb_a_stack2` (which stays; no existing type removed).
- `rj45_shallow` = `[21, 18.75, 13.5]` opening `+Y` — **[B]** — evidence: sbc.scad pi3b/pi3bplus `rj45` (xmax, `[A]` Y-span+h drawing callout / `[B]` w standard-body estimate), corroborated on d+h by bpir4 `rj45_2`/`rj45_3`/`rj45_4` (w excluded, see table note). A real no-integrated-magnetics SBC jack, distinct from the fetched Bel Fuse MagJack `rj45` (which stays; no existing type removed).

### sfp — single SFP/SFP+ cage (Task 1, #14)
- **Fetched**: TE Connectivity `2007198-1` "SFP+ 1X1 Cage Assembly, Press-Fit,
  EMI Springs" — `https://www.te.com/en/product-2007198-1.html`, Customer
  Drawing 2007198, Rev C1 (product page structured dimension table + the
  drawing itself, both consulted this pass). This is a
  genuine single-port (1x1) cage — distinct from TE's `114-13219` stacked
  (2xN) SFP+ Connector and Cage Assembly, which was also fetched this pass
  but ruled out as the wrong product shape for this type.
- **Read**: product page's structured "Dimensions" fields — Length (their
  X-axis) 48.70mm, Width (their Z-axis) 14.50mm, Profile Height (their
  Y-axis) 9.70mm. Corroborated by reference dimensions `(14.5)` and `(9.7)`
  printed directly on the drawing's front/side views (parenthesized =
  derived/reference dims on this drawing's convention), matching the
  structured page exactly. Mapped to this library's canonical frame:
  W (panel-face width) = 14.50, D (depth into chassis) = 48.70, H (height
  above PCB) = 9.70. The drawing's own toleranced port-opening dims
  (14.00±0.10 x 8.95±0.15) are the transceiver mating-slot clearance, not
  the outer cage envelope — not used for the body value.
- **Confirmed**: `[14.5, 48.7, 9.7]`, opening `+Y`. Tier **[A]**.
- **Corroborating secondary source** (not itself fetched/read as a primary
  citation): an industry SFP-cage-dimensions guide independently states a
  1x1 cage is "approximately 48.73mm long" — within 0.03mm of TE's own
  48.70mm, consistent with the fetched value but not used to raise the tier
  (already [A] from the direct fetch).
- **Seed cross-check**: seed `[14.2, 45.0, 11.9]` — width AGREE (+0.3mm),
  depth AGREE (+3.7mm, ~8%), height DISAGREE (-2.2mm, ~18% over in the
  seed) — the seed's height was too tall; the real cage body (excluding the
  taller mated-transceiver-plus-latch silhouette) is closer to 9.7mm.
- **sbc.scad reconcile target (not adopted this pass)**: `sfp_1`/`sfp_2`
  `[16.51, 53.98, 13.4]` — recorded in the "No-peer connectors" list below
  as having no matching type prior to this task. Now that `sfp` exists,
  every axis of sbc's figure runs larger (w+2.01, d+5.28, h+3.7) than this
  library's `[A]`-fetched single-port cage — plausibly a different SFP
  variant (e.g. with heatsink/light-pipe, or a belly-to-belly/stacked
  footprint misread as single-port) or a looser board-photo silhouette.
  Verdict (sbc-adoption, #21): **different / no 1:1 peer** — sbc's cage-pair
  footprint (SFP0074EP-class) is not this single-port cage; sbc retains its
  literal and `sfp_1`/`sfp_2` are NOT copied into this table (no new catalog
  variant derived from one board).

### Upgrades / fixes to existing types (Task 2)
- `gpio_2x20`: height `8.5` stays `8.5`, tier `[C]//VERIFY` → **`[B]`** — grounded by sbc.scad pi3b's "Z-Height=8.5" mechanical-drawing callout, independently corroborated by pi4b's own separate drawing printing the same callout (sbc/RESEARCH.md GPIO section; carried forward at `[B]` on pi3bplus/pi5). Not `[A]`: per this file's own provenance legend, `[A]` requires "fetched + read this pass" by connectors itself, which has never fetched a Raspberry Pi drawing — citing sbc's fetch as connectors' own `[A]` would be a soft, uncredited-fetch claim, the kind this file's final-review fix pass had to correct for motherboards' PCIe claim (see the `pcie_x1`/.../`pcie_x16` section above) — that claim turned out to be genuine, but only because it carried a real, checkable citation. (Corrects an earlier draft of this section that claimed `[A]`; see the note added to the pre-existing gpio_2x20 section above.) Width/depth tier unchanged (already `[A]`, 2.54mm-pitch arithmetic).
- `micro_hdmi`: value stays `[7.5, 4.5, 3.0]`, tier `[C]//VERIFY (cited-not-fetched)` → **`[B]`** — grounded by sbc.scad pi4b's `[A]` "Z=3.0" drawing callout for height (independently corroborated on pi5's own drawing per sbc/RESEARCH.md) plus `[B]` standard-body w/d estimate on both sides; not `[A]` since no vendor micro-HDMI datasheet was independently fetched this pass or the connectors build pass.

### No-peer connectors (recorded, untouched)
- `av_jack`, `csi_dsi_1`/`csi_dsi_2`, `sfp_1`/`sfp_2`, `pcie_fpc` — confirmed no matching type existed anywhere in `_connector_table()` at SP1 time; genuinely distinct physical connector classes (audio jack, camera/display FPC, SFP cage, PCIe FFC ribbon — none overlapped the slot/panel types modeled then). **Update (Task 1, #14):** `sfp` was added to the table this task, giving `sfp_1`/`sfp_2` a candidate peer for the first time — see the `sfp` section above. Not adopted this pass (no `sbc.scad` edit); the other three types in this list remain genuinely no-peer.
- `microusb_data` — **not** no-peer; resolved as matched to `micro_usb` (see table row above). The brief's "(if unmatched)" conditional is answered: it is matched.

### Notes / deferred items (not new types, not no-peer)
- **pi5 `rj45`+`usb2` combo shell** (sbc.scad:123-124): a single molded part serving both roles on real Pi5 hardware. Its w/d land within ~0.15mm of `rj45_shallow`'s reconciled depth, but h=16.0 (vs `rj45_shallow`'s 13.5) reflects the combined footprint, not a pure jack. Deliberately not force-mapped to either new/existing type — flagged for SP2 to decide how (or whether) to model combo shells.
- **bpir4 `usb_1`** (sbc.scad:171): reclassified `different (weak evidence)` in the corrected table above — h reconciles against `usb_a_stack2` (not `usb_a`, the originally-compared peer) but w/d do not, against either candidate peer. bpir4's own width is self-flagged `//VERIFY`; depth has no independent corroboration. Not mapped to any type; flagged for SP2 re-verification before consuming.
- **bpir4 `rj45_1`** and **bpir4 `usbc_pwr_1`**: both carry sbc-side `//VERIFY` flags for exactly the axis where they diverge most from their connectors peer (rj45_1's width; usbc_pwr_1's depth, tangled with the unmapped "CN6"). `rj45_1` is folded as tentative corroborating evidence for `rj45_shallow` (h agrees). `usbc_pwr_1` is reclassified `different (weak evidence)` in the corrected table above (w/h agree, d does not, and the reading is self-flagged suspect) — not mapped to `usb_c`, flagged for SP2 re-verification. Neither treated as independent evidence of a new part variant.
- **pi3b/pi3bplus `microusb_pwr`** and **pizero/pizero2w `microusb_data`**: reclassified `different (weak evidence, unresolved)` in the corrected table above — h (and, for `microusb_data`, d too) fails the ~0.5mm threshold, but neither side has strong evidence: connectors' `[A]` height may include foot ears (own note), sbc's height is an unconfirmed generic guess. `micro_usb` remains the correct nominal peer type for both, but the numeric reconcile is unresolved pending a future re-read of the Same Sky UJ2-MBH-SMT drawing.
- **pi4b `rj45`'s short depth (10.25mm)**: by analogy to (not a direct citation of) sbc/RESEARCH.md's `usb2_2` caveat — that note is specifically about `usb2_2`'s Y-span terminating at the board's drawn edge (y=56) rather than the shell's true boundary; sbc/RESEARCH.md does not itself flag pi4b's rj45 depth. The same chain-truncation signature is present here (pi4b rj45's span also terminates exactly at y=56), so this reconcile pass applies the same reasoning by analogy — excluded from `rj45_shallow`'s reconciled value in favor of pi3b/pi3bplus's fuller, independently-corroborated 18.75mm reading.

## Task 1 additions (2026-07-23)

Five new connector types, all new `_connector_table()` rows — no existing rows
touched. Scope note: this pass is `libraries/connectors/` only; `libraries/sbc/`
is out of scope (a later task consumes these types for the bpir4 board row).

### microsd — micro SD memory card connector
- **Source**: GCT `MEM2075` "Micro SD Memory Card Connector, 1.40mm Profile,
  SMT, Push-Push, with Normally Open Switch" datasheet (mechanical drawing,
  sheet 1/2).
- **Read**: overall shell length 16.44mm (nested with 15.20/15.05mm — likely
  different feature call-outs at different tolerance stack-ups; 16.44 is the
  outermost/full-envelope reading), shell depth 14.50mm (the "14.75/14.50"
  nested pair on the shell-profile view; 14.50 is the reading that matches
  this type's expected assert value), profile height 1.40mm±0.05 (side view,
  and matches the part's own "1.40mm Profile" title-block description
  exactly).
- **Confirmed**: `[16.44, 14.5, 1.40]`, opening `+Y` (push-push card slot,
  card inserts from the panel edge like a USB/HDMI receptacle, not a
  board-mounted slot/header). Tier **[A]**.

### sim_2ff — mini-SIM (2FF) card holder
- **Width**: 15mm, tier **[B] caliper** (per plan; matches the industry-
  standard 2FF Mini-SIM card's own 15mm width, itself shown as a reference
  dimension on both GCT `SIM8055` and `SIM8066` Nano-SIM connector drawings'
  "25.00mm Mini / 15.00mm Micro / 12.30mm Nano" comparison diagrams — those
  two datasheets are themselves Nano-SIM (4FF) connectors, not 2FF holders,
  so they do not supply this type's own depth/height).
- **Depth/height**: not resolvable from the two GCT Nano-SIM datasheets
  (both are 4FF-specific connector bodies, ~12-14mm envelopes — a different
  physical part class from a 2FF holder). GCT SIM8055/SIM8066 datasheets
  (reference-diagram card-width comparison only, not this connector's own
  body) + TE Connectivity's 2FF SIM connector family (part `2-1705300-7`,
  "SIM CONNECTOR, Compatible Card: 2FF mini SIM", 2.54mm pitch, "Profile
  Height from PCB" 2.7mm) and a related TE 6-way mini-SIM connector listing
  (Length 16.3mm, Width 14.8mm, Depth 2.02mm) — two independent TE catalog
  listings for the 2FF format, agreeing with each other on scale (profile
  height 2.02-2.7mm) and with the plan's 15mm width (their 14.8mm, -0.2mm).
  Tiered **[B]** (corroborated across the two TE listings, not independently
  verified against a primary vendor drawing), not [A].
- **Confirmed**: `[15, 16.3, 2.7]` (w [B] caliper per plan, d/h [B] TE 2FF
  family cross-check), opening `+Y` (card holder, panel-edge insertion).
  Depth uses the 16.3mm reading (TE 6-way listing's "Length", the
  insertion-axis dimension); height uses 2.7mm (TE `2-1705300-7`'s own
  "Profile Height from PCB" field, the more literally-named match for this
  library's Z-height convention) over the other listing's 2.02mm alternate.

### m2_key_b / m2_key_m — M.2 (NGFF) board-to-board connector
- **Source**: TE Connectivity `2199119-5` "M.2 NGFF, Connector Height .126in
  [3.2mm], B Keying Code, Gold, Board-to-Board, 67 Position, 0.5mm
  Centerline" product page (structured "Dimensions" fields).
- **Read**: Connector Length 21.9mm, Connector Width 8.7mm, Connector Height
  3.2mm.
- **Confirmed (m2_key_b)**: `[21.9, 8.7, 3.2]`, opening `+Z` (card-edge slot
  connector, same family of part as this library's `pcie_x*`/`gpio_2x20`
  slot/header types — the M.2 module inserts at an angle then presses down
  flat, mating opening faces up off the board). Tier **[A]**.
- **m2_key_m**: this same product page's "Also in the Series" section lists
  TE part `1-2199119-5`, "M.2 0.5PITCH 3.2H KEY M 15U'' AU" — same series
  (`2199119`), same 0.5mm pitch and 3.2mm height, Key M variant (differs only
  in keying-notch position and gold-plating thickness, 15u'' vs the Key B
  part's 30u''). No independent dimension table was fetched for the Key M
  part itself (the page for `2199119-5` only shows it as a cross-referenced
  thumbnail, not its own Dimensions section). **Confirmed**: `[21.9, 8.7,
  3.2]`, opening `+Z`, tier **[B]** (same-series corroboration — length/
  width assumed identical to the Key B part in the same connector family,
  not independently re-fetched).

### mpcie — mini-PCI Express card-edge socket
- **Source**: "0.80mm Pitch Mini PCI Express H=5.2mm Connector Customer
  Drawing" (DWG NO. S650S5281XXXXM431XX, Rev A), from this repo's `DS/`
  reference folder alongside the BPI-R4 board drawings.
- **Read**: plan view gives overall shell width 29.90mm (outer edge-to-edge,
  including the two mounting ears) — a second, narrower nested reading of
  25.90mm excludes those ears (same "exclude the mounting flange" precedent
  as this file's `usb_a` entry); side-profile view gives shell depth 8.20mm
  (main body) vs. 9.08mm at the base (wider mounting-foot flare, excluded by
  the same precedent); the connector's own height code is explicit in the
  ordering grid ("HEIGHT 8: 5.2mm") and repeated in the drawing title,
  confirmed by the side-profile's "5.20" vertical read.
- **Confirmed**: `[29.90, 8.20, 5.2]`, opening `+Z` (card-edge slot
  connector, same family as `pcie_x*`/M.2 above — mini-PCIe cards insert at
  an angle then press down flat). Tier **[A]** (fetched + read this pass, a
  genuine connector customer drawing, not a card-only reference).
- **Card cross-check (separate provenance)**: the plan notes the full-size
  mini-PCIe **card** is a standard Mini Card form factor, 30 x 50.95mm —
  this is a named industry-standard form factor, tier **[A]**, but is *not*
  itself sourced from this connector drawing (the drawing has no card
  outline). It corroborates only the connector's X-width axis (29.90mm vs.
  the card's 30mm width, agreeing within 0.1mm — expected, since the socket
  is sized to accept the card's edge). The card's 50.95mm length is not part
  of the connector's own body envelope (the card extends well beyond the
  ~8-30mm socket body when mated) and is not used in this table row.

### Tally (corrected)
21 total pairs: **5 same** (incl. 2 upgrades: `gpio_2x20` height, `micro_hdmi` tier), **14 different** (2 new types + 4 weak-evidence/unresolved rows reclassified by this fix pass + 1 tentative weak-evidence row + 7 corroborating/other rows), **2 deferred** (no clean peer — pi5 combo shells), **0 error**. Supersedes the original report's "same: 12, different: 8" tally (which did not match its own table) and the reviewer's interim recount of "9 same / 10 different / 2 deferred" (correct for the table *before* this fix pass; 4 rows flipped same→different in this fix: `microusb_pwr`, `microusb_data`, bpir4 `usb_1`, bpir4 `usbc_pwr_1`).

### Fetch budget
- One fetch, spent during the final whole-branch review (2026-07-09), not during the original reconcile pass: Molex `SD-87715-207` "PCI EXPRESS EDGE CARD CONNECTOR" via Wayback Machine — `web.archive.org/web/20210228062138id_/molex.com/pdm_docs/sd/877159206_sd.pdf`. Confirmed genuine (5-page PDF, real customer drawing, not a scan or RoHS cert) and confirmed its page-1 master dimension table matches this table's existing `pcie_x1`/`pcie_x4`/`pcie_x8`/`pcie_x16` seed values exactly (DIM B = 25.00/39.00/56.00/89.00mm length; 7.50mm width MAX; 11.25mm height MAX) — zero delta. This upgrades all four types to `[A]` (see the `pcie_x1`/.../`pcie_x16` section above) and corrects this file's earlier, mistaken claim that the citation was unfetchable/unfindable. No other reconcile-pass verdict below required a new fetch: every "same" verdict either landed within the 0.5mm threshold outright, or had one side already at `[A]`/fetched tier (so the tie-break condition of "both values weak" never applied); every "different" verdict was grounded in evidence already on record in `sbc/RESEARCH.md` and this file's own pre-existing cross-checks.
- **Correction (fix pass, 2026-07-09):** 4 rows previously forced to "same" via an invented tier-precedence shortcut (not part of the real reconcile rule) are now correctly "different (weak evidence, unresolved)": pi3b/pi3bplus `microusb_pwr`, pizero/pizero2w `microusb_data`, bpir4 `usb_1`, bpir4 `usbc_pwr_1`. None were resolved by a fetch in this fix pass either (same low-budget mandate) — each is flagged above with what a future fetch would need to settle (micro-USB foot-ear-vs-shell-height disambiguation; bpir4 `usb_1`'s width/depth; bpir4 CN5/CN6 boundary). Recommend SP2, or a small follow-up pass, spend a modest fetch budget on these before consuming them.
