# sbc — reconstruction worksheet (Task 2: Model-B family outline + holes)

Board outline, corner radius, and mounting-hole geometry for the Raspberry Pi
"Model B" family (`pi3b`, `pi3bplus`, `pi4b`, `pi5`), sourced from each board's
own official Raspberry Pi Ltd mechanical drawing. Connectors are out of scope
for this task (Task 3).

## Coordinate frame

Origin at the **bottom-left PCB corner**, component/top side up. `+X` = board
**long** edge, `+Y` = board **short** edge, PCB bottom at `Z=0`. This matches
the datum the drawings themselves use (dimension chains run left→right and
top→bottom from the same corner, GPIO-header edge at the top / left in the
drawing views).

## Sources (primary, [A])

Official Raspberry Pi Ltd mechanical drawings, PDF, "Scale 1:1 @A4", each
showing a labelled top view + dimension chain:

- Pi 3 Model B — `RPI-3B-V1_2`, dated 2015-10-06, drawn by James Adams:
  https://datasheets.raspberrypi.com/rpi3/raspberry-pi-3-b-mechanical-drawing.pdf
- Pi 3 Model B+:
  https://datasheets.raspberrypi.com/rpi3/raspberry-pi-3-b-plus-mechanical-drawing.pdf
- Pi 4 Model B (mirror used: PIP asset, same content as the datasheets.raspberrypi.com
  redirect target):
  https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-mechanical-drawing.pdf
  (resolves via 301/302 to
  `https://pip-assets.raspberrypi.com/categories/545-raspberry-pi-4-model-b/documents/RP-008343-DS-1-raspberry-pi-4-mechanical-drawing.pdf`)
- Pi 5:
  https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-mechanical-drawing.pdf
  (resolves via 301/302 to
  `https://pip-assets.raspberrypi.com/categories/892-raspberry-pi-5/documents/RP-008347-DS-1-raspberry-pi-5-mechanical-drawing.pdf`)

The dimension labels were read directly off each drawing. The Pi 5 drawing has
a real text layer (the other three carry outlined/curve text only), so its
labels were additionally cross-checked against extracted text with position
data. All four drawings carry the disclaimer "dimensions are approximate...
should not be used for producing production data... subject to part and
manufacturing tolerances" — normal for reference drawings, not treated as a
downgrade of tier.

## Outline + hole dimension chain — identical across all four drawings

Each of the four drawings prints the **same** dimension chain for the outline
and the 4-hole mounting rectangle (values read directly off the rendered
drawing, confirmed board-by-board):

| label | value (mm) | meaning |
|-------|-----------|---------|
| (X outline) | 85 | overall board width, left edge → right edge |
| 58 | 58 | X span between the two hole columns |
| 29 | 29 | half of 58 (midline dimension, printed both sides) |
| 3.5 | 3.5 | X offset, left edge → left hole column |
| 49 | 49 | Y span between the two hole rows |
| (Y outline) | 56 | overall board height, top edge → bottom edge |

Hole-column X = `{3.5, 3.5+58} = {3.5, 61.5}`. Hole-row Y, by symmetry
`(56-49)/2 = 3.5` on both top and bottom (Pi3B/Pi3B+ print this "3.5" inset
explicitly twice on the left margin; Pi4/Pi5 leave it implicit via the 49/56
pair — both close to the same number) → `{3.5, 3.5+49} = {3.5, 52.5}`.

**Result, all four boards**: outline height `56` [A]; 4 holes at
`(3.5,3.5) (61.5,3.5) (3.5,52.5) (61.5,52.5)` [A] — exactly the brief's stated
"58×49 rectangle inset 3.5mm" pattern. No per-model difference found in the
hole pattern or outline height.

### Outline width: 85 (drawing) vs 85.6 (library value) — flagged

All four official drawings print the X outline as **"85"** (whole mm — the
drawings round X/Y outline labels to integers, unlike the sub-mm precision
used for hole/component offsets such as "3.5", "29.1", "9.623"). The commonly
cited more-precise "classic" Raspberry Pi Model-B figure is **85.6 × 56.5mm**,
repeated consistently across many independent secondary sources (retailer/press
board-dimension callouts, e.g. TechRepublic's Pi 4B review, multiple case-design
write-ups) — multi-peer, tier **[B]**, not read directly off any drawing here.
Per the task brief's directive, the library uses `[85.6, 56]`: **X = 85.6 [B]**
(drawing itself only supports the rounded "85"), **Y = 56 [A]** (drawing's own
value, and coincides with the classic figure's rounding of 56.5). This mixed
precision is called out inline in `sbc.scad`. **//VERIFY**: if X ever needs to
match the *current* drawing exactly rather than the classic figure, it would
be `85` not `85.6` — flagging for a future pass that has a caliper or a STEP
file to settle it.

## Corner radius — [A] on 3 of 4, [B]/VERIFY on Pi 5

- pi3b, pi3bplus, pi4b: each drawing has an explicit callout
  **"CORNER RADIUS = 3.0mm"** with a leader line to the board's rounded corner.
  Tier **[A]**.
- pi5: the Pi 5 drawing has **no equivalent callout** anywhere on the sheet
  (checked — its text layer was extracted and searched; no "corner radius"
  label present, and the region near the outline corner where Pi3B/Pi3B+/Pi4B
  place the callout is blank on the Pi5 sheet). The board is visually the same
  rounded-rectangle shape. Value carried forward as **3.0mm, tier [B],
  //VERIFY** — confirm against a physical Pi 5 board or a case/STEP file if a
  tight-tolerance corner cut is ever needed.

## Mounting hole diameter — [A], minor cross-model wording difference

- pi4b, pi5: drawing labels the mounting hole directly as **"Ø2.7"**. [A]
- pi3b: drawing has a note box: **"4x M2.5 MOUNTING HOLES DRILLED TO 2.75
  +/- 0.05mm"**. [A] — same feature (M2.5 clearance hole), 0.05mm different
  nominal from the Pi4/Pi5 label (2.75 vs 2.7). Not treated as a per-model
  difference worth splitting the function over (the brief's interface is a
  single global `sbc_hole_dia()`, no board argument); library uses **2.7mm**
  (the Pi4/Pi5 value, and within the Pi3B drawing's own ±0.05mm tolerance
  band). pi3bplus drawing shows the hole geometry (58/49/3.5 chain, "2.75"
  callout not independently re-checked in that sheet's crop — carried forward
  from the pi3b value as the two are the same physical connector/mounting
  footprint per Raspberry Pi's own compatibility notes). [A]/[B] blended,
  noted here rather than in-line per-row since the function takes no board
  argument.

## PCB thickness — no drawing source; [C] //VERIFY

**None of the four mechanical drawings dimension PCB thickness anywhere** —
checked both the top-view dimension chain and the side/edge views present on
the Pi 4 and Pi 5 sheets (those side views dimension component heights above
the board and one connector-overhang measurement, not the bare-PCB thickness).

Community measurement threads (Raspberry Pi Forums "Official Dimensions" and
"Raspberry 4B height"; element14 "Thickness of RaspberryPi3 PCB") report
**inconsistent, generation-dependent values**: informally measured Pi boards
range from 1.4mm to 1.6mm depending on model/batch (older boards trending
thinner, ~1.4–1.5mm; newer boards trending toward a more consistent 1.6mm per
some posters). No official Raspberry Pi Ltd figure was found in any of the
searched sources — this is not a governing-standard or vendor-datasheet value,
just user calliper measurements.

Library uses **1.4mm nominal for all four boards, tier [C], //VERIFY** —
matches the brief's own placeholder figure and the lower/older end of the
observed range; a tight Z-stack design should re-measure the specific board
revision or source a vendor STEP file rather than trust this figure.
**//VERIFY**: consider re-checking per-model (older boards vs pi4b/pi5) if a
future task needs an accurate Z stack-up — this task keeps it uniform per the
brief's row shape and does not invent per-model split without a source.

## Per-model differences found

**None**, for outline / hole pattern / hole diameter (within the noted 2.7 vs
2.75 wording) — all four Model-B drawings share byte-for-byte identical
dimension-chain values for these features. The only per-model gap is the
**missing corner-radius callout on the Pi 5 sheet** (documented above).

## Task 3: Connector maps

Box convention throughout: `[x,y,z]` = minimum corner, `[w,d,h]` = extents
along X/Y/Z, `z = sbc_thickness(b)` (1.4mm) for every connector (all sit on
the PCB top face). Datum: bottom-left corner = origin, +X = 85.6mm long edge,
+Y = 56mm short edge. `edge` = which board edge the opening faces; the
edge-axis equation (`x+w≈85.6` for `xmax`, `x≈0` for `xmin`, `y+d≈56` for
`ymax`, `y≈0` for `ymin`) is kept exact for every record since it is
automated-test-enforced (Task 4), even where the true in-plane position is a
softer estimate.

Everything below is read directly off the four drawings (the PDF text layers
are mostly vector paths, not extractable as text, except Pi5's, which has real
embedded text), cross-checked against known Raspberry Pi physical connector
layouts only for **assigning names/order** to dimensioned features, never for
inventing numeric values.

### GPIO header (`gpio`) — all four boards

`x=7.1, y=50.0, w=51.0, d=5.0, h=8.5`, edge `top` (opens +Z, off the PCB's
top face — not a lateral edge).

**Corrected in final review.** An earlier pass had x=1.5 and edge=`ymax`,
both wrong:

- The "1.5" figure is real ink on the pi3b drawing, but it dimensions the
  **AERIAL antenna connector's centerline**, a completely different
  feature, not the GPIO header. Pixel measurement (900dpi re-render,
  35.43px/mm) of the header footprint's own left edge puts it at x≈7.08mm,
  which rounds to **x=7.1** — cross-validated against the drawing's own
  hole-centerline chain (right mounting hole measured at x=61.47mm against
  this same datum, vs. the drawing's dimensioned 61.5mm: <0.1mm residual,
  confirms the pixel-to-mm calibration is sound). x=7.1 also matches the
  well-known Raspberry Pi HAT mechanical-spec header-inset figure, so this
  is now tier **[A]** (direct drawing measurement, corroborated by [B]
  HAT-spec knowledge).
- `edge=ymax` was fabricated so `y+d=56` would satisfy the (lateral-only,
  at the time) edge-touch test in `sbc_test.scad` — the header does not
  actually open out the board's top physical edge; it opens **upward**
  (+Z), off the top face of the PCB, like every 2x20 pin header. This is a
  real category the model needed: a new `edge="top"` (see sbc.scad header
  comment + README) that skips the lateral edge-touch check but still
  enforces the in-plane envelope check.
- y/d are now read directly off the pi3b drawing's own header footprint
  box: top edge at y=55.0, bottom edge at y=50.0 (d=5.0, i.e. the header
  sits inset 1.0mm from the board's `ymax` edge at y=56) — tier **[A]**.
  h=8.5 unchanged, still from the printed "Z-Height=8.5" callout.
  z=1.4 from `sbc_thickness()`.
- pi3bplus, pi4b, pi5: **[B]** — same x/y/w/d/h/edge, carried forward. The
  40-pin header footprint is fixed across the whole Raspberry Pi
  HAT-compliant Model-B family by the HAT mechanical spec, so reuse here is
  a compatibility requirement, not a guess. pi4b's own drawing does show a
  matching "Z-Height=8.5" callout at the header (independently confirms h);
  pi5's drawing does not print a Z-height for the header at all (its sheet
  gives far fewer component-height callouts than pi3b/pi4b) — h=8.5 for pi5
  is carried forward, tier [B].

### pi3b / pi3bplus (identical connector maps — see note below)

Right edge (`xmax`), Y-spans **[A]** off the drawing's own bottom-referenced
Y chain ("10.25 / 29 / 47 / 56"), read as cumulative boundaries between
stacked connector footprints (Ethernet at the bottom-right corner, two
dual-port USB2 shells stacked above it — matches known Pi3B hardware
layout, used only to assign names/order to already-dimensioned boundaries):

- `usb2_1` (lower shell): y=29, d=18 (29→47). h=16.0 **[A]** ("Z-Height=16.0"
  printed at the shell). w=17 (X-depth into board) is the brief's standard
  USB-A body depth, **[B]** — the drawing gives the Y-span+height but no
  top-view X-depth dimension text for this shell; x = 85.6-17 = 68.6.
- `usb2_2` (upper shell): y=47, d=9 (47→56), h=16.0 **[A]**, w=17 **[B]**.
  //VERIFY: this shell's Y-span (9mm) is noticeably shorter than the lower
  shell's (18mm) despite being nominally the same physical part; most
  likely the dimension chain simply terminates at the board's top edge
  (y=56) rather than the shell's true far boundary, i.e. real shell extent
  may run slightly past the drawn board outline near the rounded corner.
  Kept as read rather than corrected without a source.
- `rj45`: y=10.25, d=18.75 (10.25→29), h=13.5 **[A]** ("Z-Height=13.5").
  w=21 **[B]** (brief's standard RJ45 body depth); x=85.6-21=64.6.

Bottom edge (`ymin`), X centrelines **[A]** off the drawing's own
left-referenced chain ("3.5 / 10.6 / 32 / 53.5"), assigned to
connectors by left-to-right visual order + matching Z-height callout at
each position (power connector nearest the left mounting hole, then HDMI,
then AV jack nearest the right mounting hole — matches known Pi3B layout):

- `microusb_pwr`: centreline x=10.6 **[A]**, body w=7.5/d=5.5 **[C]**
  //VERIFY (no Z-height text was captured for this connector in the crops
  examined — its callout may sit just outside the cropped region; h=2.8 is
  a typical microUSB-B receptacle height, not drawing-confirmed).
  x_box = 10.6 - 3.75 = 6.85.
- `hdmi` (full-size Type A): centreline x=32 **[A]**, h=6.5 **[A]**
  ("Z-Height=6.5", matches a standard full-size HDMI shell height well).
  w=15/d=11.5 **[B]** standard full-size HDMI body. x_box=32-7.5=24.5.
- `av_jack` (3.5mm AV/audio jack): centreline x=53.5 **[A]**, h=6.0 **[A]**
  ("Z-Height=6.0"). w=6/d=6 **[C]** //VERIFY (generic jack barrel estimate,
  not separately dimensioned). x_box=53.5-3=50.5.

pi3bplus: **same values, own citation** — the pi3bplus drawing was read
independently and repeats the identical "10.25/29/47/56" and
"3.5/10.6/32/53.5" chains (cross-checked directly on its own sheet, not
merely assumed from pi3b), so its connector map is byte-identical.

**Omitted for pi3b/pi3bplus**: the camera (CSI) and display (DSI) FFC
connectors, both visible on the drawings (Z-Height=5.5 FPC-style
footprints), are not in the brief's required minimum set for these two
boards and were left out rather than guessed. Gap, not a loss of coverage
against the brief.

### pi4b

Right edge (`xmax`), Y-spans **[A]** off the drawing's own chain
("9 / 27 / 45.75 / 56"). Order top-to-bottom on real Pi4B hardware is
swapped from Pi3B (Ethernet moved up near the GPIO corner, USB3 stack in
the middle, USB2 stack at the very bottom-right corner) — used only to
assign names to the already-dimensioned boundaries:

- `rj45`: y=45.75, d=10.25 (45.75→56), h=13.5 **[A]**. w=21 **[B]**;
  x=64.6.
- `usb3`: y=27, d=18.75 (27→45.75), h=16.0 **[A]**. w=17 **[B]**; x=68.6.
- `usb2`: y=9, d=18 (9→27), h=16.0 **[A]**. w=17 **[B]**; x=68.6.

Bottom edge (`ymin`), X centrelines **[A]** off the drawing's own local
chain ("3.5 / 7.7 / 14.8 / 13.5 / 7.5" — read as cumulative-from-left-edge
offsets; the running sums 11.2 / 26.0 / 39.5 / 47.0 were cross-checked
against Pi5's own independently-printed absolute dimensions for the same
three left-most connectors — 11.2 / 25.8 / 39.2 — and agree closely,
confirming the cumulative-chain reading):

- `usbc_pwr`: centreline x=11.2 **[A]**, h=3.2 **[A]** ("Z=3.2"). w=9/d=7.4
  **[B]** standard USB-C receptacle body. x_box=11.2-4.5=6.7.
- `hdmi_1`/`hdmi_2` (micro-HDMI Type D x2): centrelines x=26.0, x=39.5
  **[A]**, h=3.0 **[A]** ("Z=3.0", printed once, applies to both — visually
  identical connectors). w=7.5/d=4.5 **[B]** standard micro-HDMI body.
  x_box = 26.0-3.75=22.25, 39.5-3.75=35.75.
- `av_jack`: h=6.0 **[A]** ("Z=6.0", same value as pi3b's jack). X position
  **[C] //VERIFY by analogy** — the drawing's own last chain value ("7.5")
  most likely belongs to the FPC/display connector positioned between
  HDMI_2 and the jack (not required, omitted — see below), not to the jack
  itself; no unambiguous centreline for the jack was isolated in the crops
  examined. Positioned here by the same ~8mm offset from the right mounting
  hole observed on pi3b (61.5-8=53.5), giving x=53.5, x_box=50.5, w=d=6
  **[C]**.

**Omitted for pi4b**: the display FPC connector (Z-Height=5.5, visible
between micro-HDMI_2 and the audio jack) — not in the brief's required set
for pi4b, left out rather than guessed; its likely position (~x=47,
cumulative-chain value 39.5+7.5) is noted here only as the reasoning for
why it was excluded from the `av_jack` centreline candidate above.

### pi5

Right edge (`xmax`), Y-spans **[A]** off the drawing's own printed chain
("10.2 / 29.1 / 47 / 56"). Real Pi5 hardware combines Ethernet + 2x USB2
into a single molded "combo" shell below a separate USB3 dual-port shell:

- `usb3`: y=29.1, d=17.9 (29.1→47), h=16.0 **[B]** (no Z-height printed on
  the Pi5 sheet for this shell — carried forward from pi3b/pi4b's USB
  shell height, same part family). w=17 **[B]**; x=68.6.
- `rj45` **and** `usb2`: both given the **same box**, y=10.2, d=18.9
  (10.2→29.1), w=21, h=16.0 (all **[B]**, no per-sub-connector split found
  on the drawing — the combo shell is one physical footprint and the
  drawing does not dimension an internal Ethernet/USB2 boundary within it).
  x=64.6 for both. This is a deliberate shared-footprint representation,
  not two independent reads — flagged here rather than per-line //VERIFY
  since both records are equally well/poorly sourced.

Bottom edge (`ymin`), X centrelines **[A]** — Pi5's sheet has real embedded
vector text (unlike the other three) and prints these as absolute
left-edge dimensions directly: "11.2", "25.8", "39.2":

- `usbc_pwr`: x=11.2 **[A]**, h=3.2 **[A]**. w=9/d=7.4 **[B]**.
  x_box=6.7.
- `hdmi_1`/`hdmi_2`: x=25.8, x=39.2 **[A]**, h=3.0 **[B]** (carried forward
  from pi4b's micro-HDMI Z-height; not independently re-printed on the Pi5
  sheet in the crops examined). w=7.5/d=4.5 **[B]**.
  x_box=25.8-3.75=22.05, 39.2-3.75=35.45.
- `pcie_fpc`: **//VERIFY [C], fully estimated** — a PCIe FFC connector is
  visually present on the drawing between micro-HDMI_2 and the 4-pin
  fan-header area (thin vertical-rectangle icon consistent with an FPC
  shell), but no dimension text for it was found in any crop examined.
  Placed at x=44 (box x=44... reads as the min-corner directly, no offset
  applied — treat as a placeholder position), w=8, d=3, h=3, all
  **[C] //VERIFY**. Included per the brief's explicit allowance to ship a
  //VERIFY best estimate rather than omit a required connector; flagged
  here as the weakest-sourced record in the whole table.

Left edge (`xmin`): two required `csi_dsi` (camera/display) FPC
connectors, stacked vertically:

- Near-edge offsets **[A]** off the drawing's own top-referenced dimensions
  "13.3" and "18.4" (distance down from the top/`ymax` edge to each
  connector's near face), with "6" printed as the gap between them
  (56-13.3=42.7 and 56-18.4=37.6, gap 5.1mm — close to the printed "6",
  small rounding accepted).
- `csi_dsi_1` (upper, nearer GPIO): y=42.7 (near/bottom edge), d=6 → spans
  42.7→48.7. `csi_dsi_2` (lower): y=31.6, d=6 → spans 31.6→37.6.
  Both: w=2.5 (FFC insertion depth), h=5.5 (cross-model reuse from
  pi3b/pi3bplus's own CSI connector Z-height, same connector family).
  **[A]** for the near-edge Y offsets, **[C] //VERIFY** for d/w/h — the
  drawing does not dimension each connector's own body length along Y, so
  d=6 is an estimate chosen to avoid the two connectors overlapping; real
  body length may differ.

**Omitted for pi5**: `uart` and `power_button` (both explicitly optional
in the brief). No dedicated UART header footprint or clearly-identifiable
power-button connector body was found on the drawing in the crops
examined — there is an undimensioned small hole near the top-left corner
(distinct from the four M2.7 mounting holes) that might be power-button
related, but it has no connector-body dimensions of its own and doesn't
fit the box-record convention, so it was left out as a documented gap
rather than represented with an invented box.

### Final-review reassessment: pi5 `pcie_fpc` / `csi_dsi_1` / `csi_dsi_2` — lateral or `top`?

The final review asked whether these three records are genuinely lateral
(edge-exiting) connectors or flat FPC connectors that actually face up
(`top`), given the GPIO mistake showed the table had at least one
mis-tagged edge. Re-examined all three against high-res crops:

- `csi_dsi_1`/`csi_dsi_2`: **kept as `xmin` (lateral) — confirmed, not
  reclassified.** Both housings are visibly drawn bulging past the board's
  physical left edge in the high-res crop, which is exactly how a real FPC
  ZIF connector for a camera/display ribbon cable is built and drawn (the
  ribbon exits sideways, clear of the board). This is the same visual
  signature as the other confirmed-lateral connectors (HDMI, USB-C) on this
  sheet, just on the left edge instead of the bottom. No evidence supports
  a `top`-facing interpretation.
- `pcie_fpc`: **kept as `ymin` (lateral) — unchanged, still //VERIFY [C].**
  This is the weakest-sourced record in the table (no dimension text at
  all, §"pcie_fpc" above) and remains a judgment call. The nearby candidate
  icon sits flush with the board's bottom edge, matching the
  "flush-with-edge" drawing convention shared by the other confirmed-lateral
  bottom-edge connectors on this sheet (usbc_pwr, hdmi_1/2) rather than the
  "bulges past the edge" convention seen on the confirmed-lateral csi_dsi
  connectors. No visual evidence was found either way for an upward-facing
  interpretation, so — absent a stronger signal — it stays `ymin` per this
  same-sheet convention. Flagged for future re-verification if a clearer
  source (official pi5 mechanical drawing revision, or vendor CAD) becomes
  available.

### Summary of weakest-sourced records (for future re-verification)

1. pi5 `pcie_fpc` — position and all extents fully estimated, no drawing
   dimension found at all.
2. pi5 `csi_dsi_1`/`csi_dsi_2` — Y near-edge offsets are drawing-read, but
   body length (d) and width (w) are estimated.
3. pi3b/pi3bplus `microusb_pwr` height (h) — not drawing-confirmed.
4. pi4b `av_jack` X position — assigned by analogy to pi3b, not
   independently isolated on the pi4b drawing.
5. pi5 `rj45`/`usb2` — represented as one shared footprint; no internal
   split dimensioned on the drawing.

## BananaPi BPI-R4 (Task 1 of the SBC Plan 2 branch)

Target variant: the **standard BPI-R4** (2x SFP + 4x RJ45, MediaTek MT7988A
Filogic 880; 4G/8G RAM and NAND/eMMC/SD storage options are electrically
irrelevant to the PCB mechanicals) — confirmed as the right variant from its
own component-placement drawing: `SFP1 WAN` + `SFP2 LAN` (2 SFP cages) and
`WAN X1` + `LAN X3` (1+3 = 4 RJ45 ports). This is distinct from `BPI-R4 Pro`
(2x 10G SFP+/RJ45 combo, different board) and `BPI-R4 Lite`/`BPI-R4 Mini`
(different SoC/board), which were explicitly not used.

### Sources

- `https://wiki.banana-pi.org/Banana_Pi_BPI-R4` — returned **HTTP 522** (CDN
  origin unreachable), not accessed; no archived snapshot found.
- `https://www.banana-pi.org/en/bananapi-router/155.html` — product page for
  the standard BPI-R4. States size **"100.5x148mm"** (product-listing text, not
  drawing-sourced, rounds to whole mm) and links to
  `https://docs.banana-pi.org/en/BPI-R4/BananaPi_BPI-R4`.
- `https://docs.banana-pi.org/en/BPI-R4/BananaPi_BPI-R4` — hosts the
  hardware-resource download links (Google Drive + Baidu Cloud mirrors) for:
  PCBA schematic, assembly (Gerber/placement) film, and — critically — a
  **"BPI-R4 DXF file"** entry:
  Google Drive `https://drive.google.com/file/d/1FMqHSZnug-IebvTIhkSwmWhDAPyWxr6A/view`
  (Baidu mirror `https://pan.baidu.com/s/1vLynqxFYmIr0LnWurEIfjA?pwd=8888`, not used).
- **"BPI-R4-Main-V11-assambly"** film,
  `https://drive.google.com/file/d/1FDr47zcd-b2n8qiXFb-DxcuQ-6ye8OCB/view`
  — a 2-page vector PDF (top + bottom placement "ART FILM"). Corroboration/
  context only, not the source of hole coords: confirms the SFP/RJ45 port
  count (see variant note above) and the board's overall silhouette, but its
  "H1..H21" reference labels have **no drawn hole/circle graphic anywhere near
  them** — these are placement/zone reference callouts, not mounting holes, and
  were **not used** as a hole source. This PDF has no dimension text for the
  outline or any hole either.

### The DXF — primary [A] source

`https://drive.google.com/uc?export=download&id=1FMqHSZnug-IebvTIhkSwmWhDAPyWxr6A`
— a zip archive (`BPI-R4-Main-V11-DXF/`) containing
`BPI-R4-Main-V11_TOP.dxf` and `BPI-R4-Main-V11_BOT.dxf` (AutoCAD R12 ASCII
DXF, real CAD export, not a scan) plus component datasheets (SFP cage, RJ45x4
stack, USB-C, etc. — not needed for this task).

`BPI-R4-Main-V11_TOP.dxf` layers of interest:
- `DF_DRAWING_ORIGIN`: a single INSERT at `(0,0)` — the drawing's own origin
  marker, confirms `(0,0)` is the datum the DXF itself uses.
- `BG_DESIGN_OUTLINE`: one closed 8-vertex POLYLINE — the board outline.
- `PG_ASSEMBLY_HOLE_DIAM`: 16 POLYLINE circles — the mounting/standoff holes.

**Outline** — `BG_DESIGN_OUTLINE` bbox: `xmin=0, xmax=148.00072, ymin=0,
ymax=100.50018` → **148.0 x 100.5mm**, tier **[A]** (read from the DXF
bounding-box on the real vector polyline, not pixel-measured). This
**overrides the brief's ~148.5mm hint** — the actual drawing is 148.0mm, not
148.5mm (the product page's own "100.5x148mm" text corroborates 148, not
148.5, as does BPI's own note that this board is "same size as BPI-R64 and
BPI-R2", both classically documented as 148x100.5mm). Cross-checked against
`BPI-R4-Main-V11_BOT.dxf`'s own `BG_DESIGN_OUTLINE` (same layer name):
identical bbox `(0,0)-(148.00072,100.50018)` — TOP/TOP and BOT share one
coordinate system (BOT view is not X-mirrored in this export), so no
axis-flip correction was needed.

**Corners**: the outline polyline is an 8-point polygon —
`(2,0)→(146,0)→(148,2)→(148,98.5)→(146,100.5)→(2,100.5)→(0,98.5)→(0,2)→close`
— i.e. every corner is a **2mm x 2mm 45-degree chamfer**, not a radiused
fillet. `sbc_placeholder()`'s `hull()`-of-corner-cylinders geometry only
supports a fillet radius, so `corner_r=2.0` is used as the closest visual
approximation the shared row schema supports — **//VERIFY**: this is
deliberately not a faithful chamfer reproduction, just the nearest value the
existing module shape can express; a consumer needing the exact chamfer
profile should re-derive it from the DXF polyline directly rather than trust
`sbc_corner_radius("bpir4")`.

**Mounting holes**: `PG_ASSEMBLY_HOLE_DIAM` layer, 16 circles (each exported
as a 3-vertex bulge-arc POLYLINE; centers/diameters extracted from each
polyline's bounding-box extents, which correctly account for the arc bulges rather than
just the raw vertices). All 16 centers, tier **[A]**, DXF-exact (rounded to
2dp here; see the DXF itself for full precision):

| x | y | dia (mm) |
|---|---|----------|
| 129.54 | 15.25 | 3.00 |
| 3.50   | 23.50 | 3.00 |
| 144.50 | 23.50 | 3.00 |
| 75.85  | 27.21 | 3.32 |
| 56.25  | 31.59 | 3.00 |
| 113.54 | 31.59 | 3.00 |
| 129.54 | 35.25 | 3.00 |
| 129.54 | 53.25 | 3.00 |
| 129.54 | 65.25 | 3.00 |
| 117.75 | 69.11 | 3.31 |
| 47.60  | 75.69 | 3.00 |
| 57.60  | 75.69 | 3.00 |
| 56.25  | 88.30 | 3.00 |
| 113.54 | 88.30 | 3.00 |
| 3.50   | 97.00 | 3.00 |
| 144.50 | 97.00 | 3.00 |

14 holes measure almost exactly 3.0mm dia; 2 (at `(75.85,27.21)` and
`(117.75,69.11)`) measure ~3.3mm — real design difference (likely a slightly
larger clearance at those two mount points, e.g. near the fan/heatsink
mounts), not a measurement artifact — kept as read, both tiers **[A]**, no
per-hole diameter distinction is stored in the table (the row schema has one
`[x,y]` list, no per-hole diameter field) — flagged here rather than dropped.
Pattern was sanity-checked by plotting outline+holes against the DXF data:
asymmetric, component-driven layout (holes cluster
where the SFP cages / RJ45 stack / power connectors sit), not a simple
4-corner rectangle like the RPi family — expected for a much larger, denser
router board. `BPI-R4-Main-V11_BOT.dxf` has **0** entities on
`PG_ASSEMBLY_HOLE_DIAM` — the hole layer is only populated in the TOP export;
`TOP.dxf` was used as authoritative (matches our datum: component/top side
up).

**Global `sbc_hole_dia()` mismatch, not fixed here**: the shared
`sbc_hole_dia() = 2.7` constant (used by `sbc_mount_holes()`/
`sbc_standoffs()` for every board, no per-board argument) does not match
BPI-R4's real ~3.0mm holes. This is an existing single-global-constant
design limitation (already noted in the header comment for the 2.7 vs 2.75
Pi3B wording gap) — not something this task's brief asks to change (brief
only adds the `bpir4` row + `sbc_known_boards()` entry), so left as a
**//VERIFY** gap for whichever future task revisits `sbc_hole_dia()` to take
a board argument.

**Thickness**: **no source found anywhere** — not in the DXF (no dimension
text at all beyond a handful of SFP-pin silkscreen labels), not on the
product page, not on the docs page. Library uses **1.6mm, tier [C]
//VERIFY** — a standard multilayer-PCB-thickness assumption, deliberately
*not* reused from the RPi family's 1.4mm (this is a heavier, denser router
board in a different weight/complexity class, so borrowing the SBC-family
figure would be a worse guess than the generic industry-standard 1.6mm).
Re-verify against a physical board or a future STEP file if an accurate Z
stack-up is ever needed.

### Connectors (Task 2: 2xSFP + 4xRJ45 front panel + rest)

**No refdes/component-name TEXT exists anywhere in the DXF** — every layer was
enumerated, and `PG_SILKSCREEN_TOP`'s 11 TEXT
entities are only `'M2'`, four pin-count numbers (`12`/`36`/`45`/`78`), two LED
labels (`Y+`/`G+`), and two SFP pin numbers (`3`/`1`) — no `CN1`, `CN7`, `SFP1`,
`WAN`, `DC12V`, etc. All refdes/label identification therefore comes from the
vendor assembly drawing (`bpir4_main_v11_assembly.pdf`, rendered to
`bpir4_assembly_p1_600.png`, page 1/TOP, and `bpir4_assembly_p2.png`,
page 2/BOT), not the DXF text layer.

**Pixel calibration** (`bpir4_assembly_p1_600.png`, 3657x2617px): the PNG
renders at exactly 600dpi = 23.622px/mm. Board outline detected at px
x=[60,3556] (148mm) and px y=[120,2494] (100.5mm, y-inverted — image top =
board ymax=100.5, image bottom = board ymin=0). Formula used throughout:
`mm_x = (px_x - 60) / 23.622`, `mm_y = 100.5 - (px_y - 120) / 23.622`.
Orientation confirmed to match the DXF datum directly (no mirroring).
Component box edges were then found two ways: (1) a programmatic dark-pixel
row/column-run detector (thresholds pixels <128 as dark, flags a row/col as a
border line when its dark-pixel fraction across a narrowed search window
exceeds 0.4-0.7), cross-checked against (2) direct visual reads off gridded
crops (mm gridlines overlaid every 5/10mm) where the detector was ambiguous or
returned partial hits. Every connector below cites which method(s) produced
its numbers.

**Front panel — all one shared edge, `"ymin"` (y=0)**, confirmed directly off
the assembly drawing (SFP1/SFP2/USB/WAN/LAN x3/DC-in/USB-C-PD all sit flush
against the board's bottom/short edge in the drawing). Left to right by x:

| name | refdes | x0 | w | y0(=0) | d | h | edge | tier |
|---|---|---|---|---|---|---|---|---|
| `usb_1` | CN11 (USB) | 7.41 | 8.89 | 0 | 23.16 | 13.5 | ymin | [B] pos / [C] body h //VERIFY |
| `sfp_1` | CN7+CN8 (SFP cage 1) | 16.3 | 16.51 | 0 | 53.98 | 13.4 | ymin | [B] |
| `sfp_2` | CN9+CN20+CN10 (SFP cage 2) | 34.08 | 16.51 | 0 | 53.98 | 13.4 | ymin | [B] pos / [C] depth //VERIFY |
| `rj45_1` | CN21 port 1/4 "WAN X1" | 62.61 | 13.98 | 0 | 21.45 | 13.60 | ymin | [B] pos / [A] body |
| `rj45_2` | CN21 port 2/4 "LAN X3" | 76.59 | 13.98 | 0 | 21.45 | 13.60 | ymin | [B] pos / [A] body |
| `rj45_3` | CN21 port 3/4 | 90.57 | 13.98 | 0 | 21.45 | 13.60 | ymin | [B] pos / [A] body |
| `rj45_4` | CN21 port 4/4 | 104.55 | 13.98 | 0 | 21.45 | 13.60 | ymin | [B] pos / [A] body |
| `dc_power_1` | CN4 "DC12V" | 124.59 | 10.03 | 0 | 10.71 | 10.0 | ymin | [B] pos / [C] h //VERIFY |
| `usbc_pwr_1` | CN5 "PD20V" | 134.62 | 8.94 | 0 | 9.95 | 3.2 | ymin | [B] pos / [C] width //VERIFY |

Notes per row:
- **`usb_1` (CN11)**: left/right edges (7.41/13.8/16.3) found by
  the dark-pixel detector across two independent search windows — but the 8.89mm
  resulting width is narrow for a typical USB-A shell (~13.6mm) — flag
  **//VERIFY**, possible the true right edge is one of the other nearby
  candidate columns from the same run and this box undershoots the real
  connector.
- **`sfp_1`/`sfp_2`**: widths (16.51mm each) match exactly between the two
  cages — strong mutual corroboration, tier [B]. Depth (53.98mm) was only
  found by the detector for `sfp_1`'s top edge (one hit); `sfp_2`'s own pass
  returned nothing (threshold/contamination), so its depth is carried over
  by the symmetric-cage-layout assumption — **//VERIFY**. 53.98mm is
  plausible against the `DS/SFP0074EP_1X1.pdf` cage datasheet's overall
  length class (cage+connector assemblies commonly run 50-56mm).
- **`rj45_1`..`rj45_4` (CN21, single 4-port ganged block) — re-modeled Task
  2**: hardware-owner ground truth (2026-07-16) confirms the BPI-R4 has
  **one physical 4-port RJ45 block** (WAN + 3x LAN); the "WAN X1" silk text
  marks port 1 of that block, not a separate connector. The prior model (an
  8.0mm lone "WAN" jack attributed to a refdes "CN1", plus a separately
  even-3-split "LAN X3" 3-port block attributed to "CN21") is **discredited
  and superseded** — both were self-flagged weak reads (see the old
  `error`/`different` verdicts in the reconcile table below, now
  reclassified `no-peer`).

  Re-examining the same assembly drawing used for the original pixel
  detection resolved the source of the error: the box previously read as
  "CN1 'WAN X1'" is a **different, unrelated small 2-pin part** (silkscreen
  "+" polarity mark, sits directly under the "FAN" silk label — most likely
  the fan power connector) whose footprint happens to sit flush against the
  real RJ45 block's own left wall. The actual RJ45 refdes is **CN21 alone**
  (confirmed by its own silkscreen text spanning the full block) — a single
  component, matching the ground truth. Restricting the dark-pixel-run
  detector to rows below CN1's own footprint (so its box no longer
  contaminates the scan) finds CN21's true left edge at **x=62.61mm**
  (present in all sampled rows — a solid, continuous border line), not the
  previously-assumed 60.0mm. Right edge (122.77, shared boundary with
  `dc_power_1`'s left edge) is unchanged and remains **[B]** — it was
  already detector-confirmed independent of the CN1 confusion.

  Per-port **pitch**, **width**, **depth**, and **height** are now sourced
  from the exact connector datasheet bundled in the BPI-R4 vendor's own DXF
  export zip (`DS/RJ45x4-HRJC-M03C01C10cNL.pdf` — Haoci Electronics
  ("好磁电子"), "1000BASE 1X4 Tab-Down RJ45", P/N `HRJC-M03C01C10cNL`, Rev
  B): the suggested-PCB-layout view dimensions a **13.98mm** pin-column
  pitch repeated across all 4 ports (used here as both per-port width and
  pitch, i.e. abutting equal-width cells — consistent with a single
  injection-molded 1x4 gang housing and with the front view's 59.00mm
  overall bezel width: 59.00 − 4×13.98 = 3.08mm total end-margin, a
  plausible bezel overhang); the side view gives body depth **21.45mm** and
  height **13.60mm** above the PCB (the latter corroborates, and now
  supersedes as the exact-part tier **[A]** figure, the prior generic
  13.5mm carried on this row). This is the real connector used on this
  board (bundled with its own DXF, not a generic catalog pull), so position
  is **[B]** (re-derived detector read) and body dims are **[A]** (exact
  datasheet for the exact part).

  Resulting block: x=[62.61, 118.53] (55.92mm, 4×13.98mm) — 12.02mm clear
  of `sfp_2`'s right edge (50.59). No board-geometry conflict on that side.

  **Unreconciled gap, //VERIFY:** the computed block end (118.53, from
  block_x0 + 4×pitch) falls 4.24mm short of the drawing's own
  detector-confirmed right edge (122.77, cited two paragraphs above and
  independently re-confirmed on `dc_power_1`'s own boundary read below).
  Plausible explanation: the datasheet's front-view **59.00mm overall
  bezel width** (vs. 55.92mm from pitch alone, a 3.08mm difference — noted
  above) is a bezel/housing overhang not captured by modeling each port's
  body as exactly one pitch-width cell; the true physical bezel likely
  extends closer to (or to) 122.77 on the right. Not resolved here — the
  per-port body dims stay as datasheet-sourced ([A]) rather than stretched
  to fit the drawing's outer edge without a matching datasheet dimension
  for that overhang. **Use the drawing-confirmed 122.77mm as the
  conservative right-edge bound for clearance purposes**: true clearance to
  `dc_power_1`'s left edge (124.59) is **~1.82mm** (not the 6.06mm the
  pitch-only computation would suggest) — still clear, no overlap, but a
  materially tighter margin. Flagging for a future pass rather than
  guessing the bezel-overhang split between the two ends.
- **`dc_power_1` (CN4 "DC12V")**: x/y envelope pixel-detected consistently
  across two separate windowed runs (122.77/124.59/134.62 cols;
  10.71/0 rows) — tier [B] for position. Height (10.0mm) has **no top-view
  Z dimension** anywhere in the DXF (top-view only); this is a generic
  barrel-jack-body estimate, **//VERIFY**.
- **`usbc_pwr_1` (CN5 "PD20V")**: left edge (134.62) and top edge (9.95)
  detector-confirmed (shared boundary with CN4's right edge). The
  right-edge detector pass returned no second hit even with a widened
  search window; width (8.94mm) is a generic USB-C-receptacle datasheet
  figure, not measured from this drawing — **//VERIFY**. Note there is a
  separate component (tentatively "CN6", x=[139.11,147.24], taller
  y-envelope up to ~28mm) just to the right that was NOT mapped — see
  Omissions below; the estimated `usbc_pwr_1` width overlaps its measured
  left edge slightly, a known unresolved conflict flagged here rather than
  silently smoothed over.

**Non-front-panel connectors:**

- **`uart_1`** (CON1, silkscreen labels "G"/"RX"/"TX" — console/UART pin
  header): x=[8,13], y=[10,20], edge=`"top"` (does not touch a lateral
  edge — it's a set-back pin header, per the brief's explicit allowance for
  headers to be `"top"`). Position is a **visual-crop read only**, not
  detector-confirmed (the automated column search for this box kept
  re-finding CN11's own edges instead, since the two components' x-search
  windows overlap) — **//VERIFY** position. Height h=6.0mm is [B], taken
  directly from `DS/Header_PIN 2.54mm.pdf` (generic 2.54mm-pitch pin header
  datasheet, body height 6.0mm) — the same generic header part is plausibly
  reused for multiple headers on this board.
- **`gpio` (Pi-style header): OMITTED — not modeled for bpir4.** An
  exhaustive `PIN_TOP`-layer CIRCLE search for a
  2-row x 20-column, 2.54mm-pitch grid (the signature of a real 40-pin THT
  header) found **no match anywhere** in the DXF — the only tight-pitch
  circle clusters are the MT7988A SoC's BGA/QFN pads (0.65-0.95mm pitch,
  nowhere near 2.54mm). A visual candidate ("CON2", a tall rectangle near
  the xmax edge, ~x=[142,147], y=[57,90]) has a measured ~33mm length that
  doesn't match the ~48-51mm expected for a 40-pin/2.54mm header, so it was
  not used. An earlier pass shipped a fabricated placeholder record only to
  satisfy a (Pi-family) "exactly one gpio" test invariant; that record was
  **removed** in review — inventing a connector position to pass a test
  violates verified-research-over-guesswork. The Task-3 invariant was
  instead scoped to the Pi Model-B boards only. Any GPIO/pin header on
  BPI-R4 is undimensioned in available sources and is a documented gap until
  a physical board / schematic / clearer drawing confirms it.

**Omissions (documented gaps, not guessed at)**:
- **M.2 slot(s)**: BPI-R4 has M.2 sockets referenced in the assembly
  drawing's page 2 (BOT view) as CN12/CN14/CN18/CN16, intended for SIM
  trays and/or an M.2 SSD/modem — but the notes taken while reading page 2
  could not reliably distinguish which of these are true M.2 (NGFF Key-B)
  sockets vs. nano-SIM card trays without further cross-checking against
  labels, and several sit on the PCB **underside** (incompatible with this
  library's shared top-face-only connector z-convention, `z = thickness`,
  which every board in this table uses). Rather than fabricate a
  confident-looking `m2_*` record from an uncertain read, this is left
  **omitted** — a real gap, flagged here per the brief's own guidance.
- **mini-PCIe slot**: a `DS/` datasheet for a mini-PCIe connector exists in
  the component-datasheet folder (implying the board has one), but no
  assembly-drawing position was pinned down in the time available —
  omitted.
- **SIM card trays** (CN13/CN15/CN17, near the ymax edge per assembly-page
  labels): not mapped — out of scope for "connectors" in the sense the
  brief's headline list cares about (USB/power/M.2/GPIO/UART + the
  SFP/RJ45 front panel), and not confidently distinguished from the M.2
  sockets above — omitted.
- **"CN6"**: a squarish component near the right/xmax edge (x=[139.11,
  147.24], y up to ~28mm per one detector pass, with several internal
  lines suggesting a multi-line footprint) with "-"/"+" polarity-style
  silkscreen marks, resembling a battery holder (e.g. CR2032 RTC battery)
  rather than an external cable connector. Tentatively concluded to be an
  **internal** component, not in scope for this connector map — omitted
  rather than guessed at. Flagged because its measured left edge
  (139.11mm) sits close to `usbc_pwr_1`'s estimated right edge (143.56mm),
  a known potential overlap noted above.

**Interaction with tests** (updated after the gpio removal): the one-`gpio`
assert in `libraries/sbc/tests/sbc_test.scad` is scoped to the Pi Model-B
boards (`pi3b`/`pi3bplus`/`pi4b`/`pi5`) — it does NOT apply to `bpir4`, which
has **no** `gpio` record (see the "gpio OMITTED" note above). A universal
`<= 1` guard still forbids a duplicate `gpio` on any board. Sanity check
(`--export-format echo` scratch harness on `sbc_connectors("bpir4")`)
confirms the shipped state: **10** total connectors, exactly 2 `sfp_1`/`sfp_2`,
exactly 4 `rj45_1`..`rj45_4`, **0** `gpio`, and every lateral (`ymin`)
connector pinned to y=0 (edge-touch passes with zero error — note these Y
positions are y=0 by construction, so that assert guards edge-label/
transposition errors, not the Y measurement itself).

### bpi-r4 hole roles (Task 2 of the hole-role-tagging plan)

**Method.** Re-parsed both `BPI-R4-Main-V11_TOP.dxf` and `_BOT.dxf` for their
DXF layer structure. Full layer inventory both files:

- `TOP.dxf`: `BG_DESIGN_OUTLINE` (1 POLYLINE), `DF_DRAWING_ORIGIN` (1 INSERT),
  `PG_ASSEMBLY_HOLE_DIAM` (16 POLYLINE — the holes), `PG_SILKSCREEN_TOP` (560
  POLYLINE + **11 TEXT**), `PG_SILKSCREEN_TOP_OUTLINE` (1085 POLYLINE),
  `PIN_TOP` (1503 POLYLINE + 1363 CIRCLE — component pads, incl. the
  MT7988A's BGA/QFN pad field per the earlier session's header-pad
  sweep).
- `BOT.dxf`: `BG_DESIGN_OUTLINE`, `DF_DRAWING_ORIGIN`, `PG_SILKSCREEN_BOTTOM`
  (165 POLYLINE + **5 TEXT**), `PG_SILKSCREEN_BOTTOM_OUTLINE` (1742
  POLYLINE), `PIN_BOTTOM` (1504 POLYLINE + 256 CIRCLE). **No
  `PG_ASSEMBLY_HOLE_DIAM` on BOT** (confirmed again, same as the earlier
  session's finding — holes are TOP-only).

Neither silkscreen layer carries a component-reference-designator TEXT for
any hole (confirmed again — no `H1`, `MTG1`, etc. anywhere as TEXT). The 11
TOP + 5 BOT TEXT entities are exhaustively enumerated below; nothing was
skipped.

**Exact per-hole diameter** (from the bounding-box extents of each
`PG_ASSEMBLY_HOLE_DIAM` POLYLINE, full float precision, not the 2dp table
above): 14 holes measure `dia_x=dia_y=3.000248mm` (stored as **3.0**). Two
measure elliptically (`dia_x`/`dia_y` differ by ~0.002mm, a bulge-arc export
artifact, not a real ellipse):
- `(75.849480, 27.207559)`: dia_x=3.323590, dia_y=3.321708 → mean
  **3.322649**, stored as **3.32**.
- `(117.749320, 69.109238)`: dia_x=3.311398, dia_y=3.309523 → mean
  **3.310460**, stored as **3.31**.

Both confirm (to the extra precision) the 2dp values already published above
— tier **[A]**, no change from the prior session's read, just confirmed
independently.

**The `M2` TEXT proximity finding — the strongest classification evidence
found.** `PG_SILKSCREEN_TOP` TEXT: `M2` at `(53.086,75.056)`; the other 10
entries are the already-documented pin-count numbers/LED labels/SFP pin
numbers, irrelevant here. `PG_SILKSCREEN_BOTTOM` TEXT: **five** separate `M2`
entries (previously unexamined — the Task-1-era session only enumerated
`PG_SILKSCREEN_TOP` text, not `PG_SILKSCREEN_BOTTOM`), at `(114.046,83.439)`,
`(56.896,35.178)`, `(57.023,83.438)`, `(130.140,18.854)`,
`(114.138,35.187)`. Computing nearest-hole distance for all 16 holes against
this combined 6-entry `M2` text set (both files, real DXF coordinates, no
pixel measurement involved) finds **7 holes each within 3.6-5.5mm of one `M2`
text**, each hole's nearest `M2` text being a *different* text (no
double-assignment) and every other hole being **≥14.80mm** from any `M2`
text (the closest of the 9 non-cluster holes is `(117.75,69.11)` at
14.80mm from `(114.046,83.439)`; see the M2-cluster distance table below, which
covers the 7 clustered holes' nearest-text distances — the 9 non-cluster
holes' distances are not separately tabulated)
— a sharp, unambiguous cluster, not a borderline call:

| hole (x,y) | dia | nearest `M2` TEXT | dist (mm) | layer |
|---|---|---|---|---|
| (129.54, 15.25) | 3.0 | (130.140, 18.854) | 3.65 | BOT |
| (56.25, 31.59)  | 3.0 | (56.896, 35.178)  | 3.65 | BOT |
| (113.54, 31.59) | 3.0 | (114.138, 35.187) | 3.65 | BOT |
| (47.60, 75.69)  | 3.0 | (53.086, 75.056)  | 5.53 | TOP |
| (57.60, 75.69)  | 3.0 | (53.086, 75.056)  | 4.55 | TOP |
| (56.25, 88.30)  | 3.0 | (57.023, 83.438)  | 4.93 | BOT |
| (113.54, 88.30) | 3.0 | (114.046, 83.439) | 4.90 | BOT |

The BOT-layer offsets cluster tightly (3.65mm x4, 4.90-4.93mm x2) — a
consistent label-to-hole placement convention, strong mutual corroboration
that this is a real, deliberate association (an `M2` silkscreen label placed
a fixed small offset from its M.2-socket standoff screw hole), not
coincidence. Tier **[A]**: this is DXF text at its real DXF coordinate,
compared numerically against the DXF's own hole coordinates — no pixel
measurement, no visual read, no estimation. Role: **`component-mount`**
(M.2-standoff, per the brief's explicit "M.2 ... holes → component-mount"
instruction) for all 7. The 2 TOP-text holes (47.60,75.69)/(57.60,75.69)
sit 10mm apart on the same Y row flanking the TOP `M2` label roughly at
their midpoint (52.6) — read as one M.2 socket with two alternate standoff
positions (e.g. for two supported module lengths), not confirmed against a
module-length spec, hence still tier [A] for the *proximity* fact but
**//VERIFY** for that specific interpretation.

**The two larger-diameter holes — visual correlation on the assembly
drawing, tier [C]//VERIFY.** Neither large hole has *any* silkscreen TEXT
within 25mm in the DXF (checked against the full TOP TEXT list). Cropped
`bpir4_assembly_p1_600.png` (TOP view, 600dpi, same calibration as the
existing connector table: `mm_x=(px_x-60)/23.622`,
`mm_y=100.5-(px_y-120)/23.622`) around each:
- `(75.85, 27.21)` dia 3.32: a component footprint labeled **`FAN`** (a
  small bracket/box shape, distinct from the neighbouring `U12` IC) sits at
  approx. `x=[63,71], y=[18,27]`, with a small 2-pin connector (refdes
  `CN1`, silk "+" polarity mark — likely the fan's own power connector, per
  Task 2's RJ45 re-model research; **not** part of the RJ45 block despite
  sitting flush against its left edge) directly below it —
  the hole is ~4.6mm to the right of the FAN footprint's right edge, same Y
  band. Matches the brief's own fan/heatsink hypothesis. Role:
  `component-mount`, **[C]//VERIFY** (visual crop read, box edges not
  detector-confirmed the way the front-panel connector table's edges were).
- `(117.75, 69.11)` dia 3.31: sits in the `VCORE`/`VPROC` voltage-regulator
  cluster (inductors `L4`/`L5`/`L6`, decoupling caps `CP46-48`/`CP63-65`)
  immediately adjacent to `UD2` (a large BGA-outline chip) and the
  `MediaTek Filogic` logo silkscreen — i.e. the SoC's local power-delivery
  area, not open board space. Role: `component-mount`, **[C]//VERIFY** — the
  larger diameter is plausibly a heatsink/shield-can screw needing more
  clearance, consistent with the brief's hypothesis, but no drawing text
  confirms "heatsink" specifically.

Both larger holes measuring ~0.3mm over the 3.0mm baseline, and both sitting
next to power-delivery/thermal-relevant components (fan connector; VCORE
regulation next to the SoC), is circumstantial but coherent — kept as
`component-mount`, not elevated to anything requiring stronger evidence.

**The remaining 7 holes — no `M2` text nearby, not one of the two
larger-dia holes.** All investigated the same way (crop `bpir4_assembly_
p1_600.png` around the DXF coordinate, calibration as above). **Note:** the
`(3.50,23.50)`/`(144.50,23.50)`/`(3.50,97.00)`/`(144.50,97.00)` rows below
were revised after an initial pass — see "Follow-up re-review" further
down for the corrected reasoning and final role; the table here reflects
the corrected, final state, not the initial (superseded) read.

| hole (x,y) | dia | nearby TOP-view context (visual, [C]) | role assigned |
|---|---|---|---|
| (3.50, 23.50)   | 3.0 | comfortably clear of both nearby connectors: ~2.4mm gap to `CN11` (USB) bounding box (x=[7.41,16.3]) and ~2-3mm gap to `CON1`/UART header (x=[8,13],y=[10,20]) — see the "Follow-up re-review" section for the corrected read and why this is now `structural-mount` | `structural-mount` [B]//VERIFY |
| (144.50, 23.50) | 3.0 | **NOT inside `CN6`** (corrected — see "Follow-up re-review"): a dark-row pixel scan of `CN6`'s own top edge puts it at mm_y≈16.6-18.0, i.e. ~5.5-6.9mm *below* this hole, not overlapping it; nothing else (`L13`/`L16`/`CN19`) reaches down within 13mm either | `structural-mount` [B]//VERIFY |
| (129.54, 35.25) | 3.0 | between the `U2`/`SW3` (NAND/eMMC/SD boot-strap switch) cluster and `CN19` | `component-mount` //VERIFY |
| (129.54, 53.25) | 3.0 | in the `VCORE`/`VPROC` regulator row (`CP46-48`, `L4`), same functional block as the (117.75,69.11) large hole | `component-mount` //VERIFY |
| (129.54, 65.25) | 3.0 | between the `VCORE`/`VPROC`/`L4`-`L6`/`U6` power block and the large unlabeled edge connectors `CON2`/`CON3` (right edge, x≈144-148; not confidently identified — possibly the undimensioned mini-PCIe connector RESEARCH.md's Omissions note already flags, but not confirmed) | `component-mount` //VERIFY |
| (3.50, 97.00)   | 3.0 | **at the open, chamfered top-left board corner** — no component footprint, connector, or silkscreen text found nearby in the DXF or the assembly drawing at this position; ALSO 3.5mm inset from the top edge (100.5-97.0=3.5), same as its X-inset — a true 2-axis corner hole | `structural-mount` [B]//VERIFY |
| (144.50, 97.00) | 3.0 | **at the open, chamfered top-right board corner** — same as above, no nearby component found; same true 2-axis 3.5mm corner inset | `structural-mount` [B]//VERIFY |

### Follow-up re-review (human-requested, after initial "0 structural" finding)

The initial pass above concluded 0 holes met the `structural-mount` bar and
tagged the 2 open corner holes `keep-out`. The controller relayed a
human request for one more targeted check before accepting that finding,
pointing out a pattern the initial pass hadn't examined: `(3.50,23.50)`,
`(144.50,23.50)`, `(3.50,97.00)`, and `(144.50,97.00)` all share the **same
two X-columns** (3.5mm and 144.5mm — i.e. exactly the board's own left/right
edges, 148.0mm apart, each inset 3.5mm), forming a rectangle spanning
Y=23.5 to Y=97.0. That's the classic shape of the 4-hole PCB chassis-mount
rectangle this same library already uses for the Pi Model-B family (see the
`pi3b`/`pi3bplus`/`pi4b`/`pi5` rows above: `[3.5,3.5]`/`[61.5,3.5]`/etc, the
identical 3.5mm-inset convention).

**What was re-checked:**

1. **Precisely how clear `(3.50,23.50)` and `(144.50,23.50)` are of their
   nearest components.** `(3.50,23.50)`: hole spans x=[2.0,5.0] (dia
   3.0mm); `CN11`'s left edge is at x=7.41 → **2.41mm clear**. `CON1`'s left
   edge is at x=8, and its top edge (y=20) sits 2mm below the hole's bottom
   (y=22.0, hole center 23.5 - r 1.5) → clear in both axes. This confirms
   "comfortably clear," not "in the general area" — the original table's
   own framing was accurate for this hole, just not surfaced as evidence
   *for* a role beyond `component-mount`.
2. **A tighter re-crop of `(144.50,23.50)`.** The original table's claim —
   that this hole "falls inside" the tentative `CN6` footprint's bounding
   box (`y≈[0,28]`, itself only a rough single-detector-pass estimate from
   the earlier connector-mapping session, never confirmed) — **did not hold
   up**. A 240x240px tight zoom directly on the DXF coordinate shows the
   `H3` assembly-drawing label sitting in clean open whitespace, with `CN6`
   visibly *below* it, separated by a gap. A quantitative dark-row pixel
   scan (thresholding rows <128 gray value across `CN6`'s x-window
   `[139.11,147.24]`) found `CN6`'s real top edge / terminal row at
   mm_y≈16.6-18.0 — **5.5-6.9mm below** the hole at y=23.5, not overlapping
   it. A further scan of the x=[128,148] band between y=23.5 and y=45 found
   the nearest dark feature (part of `L13`/`L16`/`CN19`) at mm_y≈37, a
   13.5mm gap. **This corrects the original table entry**, which was wrong
   — `(144.50,23.50)` is just as isolated as `(3.50,23.50)`, not inside a
   component.
3. **Zoomed re-crops of all four candidate holes plus one `M2`-adjacent
   hole for comparison**, to check for any distinguishing hole-rendering
   style (a washer/keepout symbol, "NPTH" text, different circle styling).
   **No circle is drawn at ANY of the 16 hole positions anywhere on the
   assembly drawing** — not at the 4 candidates, not at the M2-adjacent
   reference hole either. This confirms (again) the earlier session's
   finding that the assembly-drawing PDF simply doesn't render hole
   graphics at all (component placement film only) — so there was no
   washer/NPTH-style differentiator to find one way or the other; this
   check came back inconclusive rather than negative.
4. **BPI-R4 case/enclosure documentation.** No BPI-R4 or same-size-sibling
   (BPI-R64/BPI-R2) case source publishes PCB
   mount/hole/screw/standoff/chassis/heatsink positions. **Real commercial and
   community case products exist for this exact board** — URLs below, split by
   how they were actually checked (a product/search listing is not the same as
   an independently read page; only the two rows marked **read directly** were
   actually opened and read):
   - `https://forum.banana-pi.org/t/case-design-for-the-bpi-r4/19122` —
     **read directly**: an active community case-design
     thread with downloadable STLs, covering fan mount/airflow/antenna
     cable routing; does not discuss PCB hole positions or a screw count.
   - `https://makerworld.com/en/models/1316335-case-for-banana-pi-bpi-r4-wall-mounting-option`
     — **primary source not accessed (HTTP 403)**; everything
     known about it (a wall/shelf-mount case, "232.8mm" bottom plate,
     "22.8mm" SoC heatsink Z-clearance) comes only from a product listing
     summary, not a verified page read.
   - `https://forum.banana-pi.org/t/3d-printable-bpi-r4-case/17324` — found
     in a search listing (title "3D printable BPI-R4 Case"), not independently
     read. The listing's own summary of this thread describes
     configurable mounting feet ("4 different foot sizes... M3 20/15/12/8mm,
     which screws into the bottom without the need of a nut") — i.e. feet
     threaded up into the PCB's own mounting holes from underneath. This
     is the source for that quote; **not independently verified by reading
     the thread myself**, only relayed via the listing summary.
   - `https://openelab.io/products/bpi-r4-lite-aluminum-case`,
     `https://openelab.io/products/bpi-r4-lite-iron-case` — from a product
     listing, not the primary source; both are for the **BPI-R4 Lite** variant, a
     different (smaller, MT7987-based) board than the standard BPI-R4 this
     library rows document — cited only as evidence that Banana Pi's own
     accessory ecosystem sells board-specific metal cases for this product
     family, not as evidence about the standard BPI-R4's own hole positions.
   - `https://youyeetoo.com/products/banana-pi-r4-metal-case` — from a product
     listing, not the primary source; a metal case specifically for the standard
     BPI-R4.
   - `https://www.amazon.com/WayPonDEV-BPI-R4-Router-Board-OpenWRT/dp/B0D2DDVGY3`
     — from a product listing, not the primary source; a bundled metal case/heat-shell
     for the standard BPI-R4.

   None of these — read directly or listing-only — publish coordinate-level
   correlation to specific DXF hole IDs. The evidentiary weight here is
   narrower than the earlier prose implied: it is "commercial/community
   case products verifiably exist for this board (multiple independent
   listings found, one thread's existence and general content
   independently confirmed by reading it)," not "a specific case's screw
   pattern was read and matched to these 4 holes."

**Decision: upgrade all four to `structural-mount`, tier [B]//VERIFY.**
Reasoning: (a) the 4 holes form an internally consistent geometric
rectangle at the exact same 3.5mm edge-inset convention this library
already trusts as the `structural-mount` signature on every other board row
in this table (Pi Model-B and Pi Zero families); (b) all 4 are now confirmed
— not just assumed — clear of every identified component on the board
(2.4-13.5mm gaps, quantified above), correcting the one erroneous
"overlaps `CN6`" claim from the initial pass; (c) 2 of the 4 are literal
chamfered board corners, the strongest possible visual signature for a
case-mount point; (d) real commercial/community case products verifiably
exist specifically for the standard BPI-R4
(`https://youyeetoo.com/products/banana-pi-r4-metal-case`,
`https://www.amazon.com/WayPonDEV-BPI-R4-Router-Board-OpenWRT/dp/B0D2DDVGY3`)
and its family
(`https://openelab.io/products/bpi-r4-lite-aluminum-case`,
`https://openelab.io/products/bpi-r4-lite-iron-case` — BPI-R4 *Lite*
variant), plus an active community case-design thread
(`https://forum.banana-pi.org/t/case-design-for-the-bpi-r4/19122`,
independently fetched and read) — i.e. this board genuinely does get
case-mounted in practice, not merely visually isolated. This is [B]-tier —
a corroborating pattern-match to an established same-library convention
plus confirmed real-world case-mounting practice for this board family —
not [A] (no single doc names these 4 hole coordinates specifically), and
still **//VERIFY**: no source pins down *which* case uses *which* of these
4 holes, or confirms all 4 (vs. e.g. only the 2 true corners) are actually
used by any real case (see point 4 above for the full source-by-source
fetched-vs-search-found breakdown). Treating only 2 of the 4 rectangle
corners as `structural-mount` while leaving the other
2 (which share the *identical* X-inset and the *identical* "confirmed clear
of all components" status) as `component-mount` would have been internally
inconsistent — the same evidence applies to all 4, so all 4 move together.

None of the other 12 holes are affected by this re-review — the `M2`-text
holes, the 2 larger-diameter holes, and the 3 remaining component-cluster
holes (129.54 column at y=35.25/53.25/65.25) all keep their original
`component-mount` classification and evidence unchanged.

**Net result (revised): 4 of 16 holes classified `structural-mount`.**
`(3.50,23.50)`, `(144.50,23.50)`, `(3.50,97.00)`, `(144.50,97.00)`. 12
holes remain `component-mount`. 0 holes remain `keep-out` (both holes that
were tagged `keep-out` in the initial pass are now `structural-mount`).

**Exploratory dead end, documented for the next person: the assembly
drawing's `H1..H21` labels.** Both assembly-drawing pages (TOP p1, BOT p2)
print small `H<n>` labels scattered near components (e.g. `H1` reads almost
exactly at `(3.50,23.50)`'s pixel position, `H4` sits right at the top-left
chamfered corner near `(3.50,97.00)`, `H3` reads almost exactly at
`(144.50,23.50)`) — tempting to read as a hole-numbering scheme. **Rejected
as a reliable source**: a tighter, higher-zoom re-crop around the
`(117.75,69.11)` large hole shows the nearby label actually reads `H21`
(initially misread as `H2` at lower zoom — a real transcription error
caught by re-checking, logged here as a caution for the next reader), with
`H10` also visible a few mm away and *no* label landing convincingly on the
hole itself; multiple `H<n>` labels (`H2`, `H3`, `H8`, `H9`, `H10`, `H11`,
`H18`, `H19`, `H20`, `H21` all appear scattered around the `U1`/`U2`/`CON2`/
`CON3`/`VCORE` region alone, far more than the 16 holes in this dataset
would need) cluster around component groups generally, not 1:1 on hole
centers. This matches the earlier session's own conclusion (see the
"Sources" section above, assembly-film bullet): the `H`-prefixed labels are
placement/zone reference callouts, not a hole ID scheme — **not used** as
evidence for any role assignment above, despite the coincidentally-close
reads on 3 of them.

**Sanity check (post follow-up-review).** `sbc_holes_xy("bpir4",
"structural-mount")` → `[[3.5,23.5],[144.5,23.5],[3.5,97],[144.5,97]]` (4
holes — the edge-inset rectangle described above). `sbc_holes_xy("bpir4",
"keep-out")` → `[]` (0 holes — both holes originally tagged `keep-out` in
the initial pass were upgraded to `structural-mount` in the follow-up
review). `sbc_holes_xy("bpir4","component-mount")` → the remaining 12,
including all 7 `M2`-adjacent holes and both larger-dia holes — confirmed
none of the `M2`-proximate holes or either larger-dia hole ended up
`structural-mount`.

### Task 2 caliper revision — bottom-face convention + bpir4 update

A physical BPI-R4 board (the hardware owner's own unit) was caliper-measured
directly, superseding several DXF/assembly-drawing-derived figures above with
a stronger [B] source (a direct measurement of the real part beats a pixel
read of a vendor drawing). This section documents every value the caliper
pass changed, plus the new "bottom" edge convention it required.

**Thickness**: 1.6mm [C] nominal placeholder -> **1.4mm [B] caliper**. This
changes `z` for every existing top-face/lateral bpir4 connector (all were
`z = sbc_thickness("bpir4")`, now 1.4 not 1.6) and feeds the height
reconciliation below.

**Bottom-face connector convention (new).** `sbc_known_edges()` now includes
`"bottom"` alongside the existing `"xmin"/"xmax"/"ymin"/"ymax"/"top"`. For a
`"bottom"` connector: `[x,y]` is still the board-frame position, but `z=0`
sits at the board's BOTTOM plane (not top), and `h` is a downward protrusion
— the component occupies `z` in `[-h, 0]`, the mirror image of a `"top"`
connector (which occupies `[thickness, thickness+h]`). `sbc_placeholder()`
special-cases `c[3]=="bottom"` to translate the cube down by its own height
before growing +Z, so the geometry actually lands in `[-h,0]` rather than
growing the wrong direction into the board. `sbc_port_cutout()` gained a
symmetric `"bottom"` branch (mirroring the existing `"top"` branch, extruding
further -Z with the same `SBC_OVERLAP` convention) so a future consumer isn't
blocked by the previous `assert(false, ...)` catch-all — no current consumer
calls it with `edge="bottom"` today (`sbc_faceplate_cutouts` filters by
`c[3]==edge` and nothing in this repo passes `"bottom"` to it), but the
generic single-connector cutout module now supports it directly rather than
leaving it as a deliberate footgun-guard, since a bottom-face part is a
completely reasonable thing for a future chassis-floor-cutout consumer to
want (e.g. a later chassis-geometry task needing to expose an M.2/mPCIe slot
from underneath).

**Front-connector height reconciliation.** The caliper gave two figures per
connector: the component's own body height ("alone") and the total height
measured from the board's BOTTOM face to the top of the connector
("bottom->top"). Since this library's connector model places `z=thickness`
(top face) and grows `h` in `+Z`, the modeled top-of-connector is
`thickness+h`; for the faceplate cutout to actually reach the connector's
true physical top, `h` must equal `(bottom->top) - thickness`, not the
"alone" figure (which isn't board-bottom-referenced and disagrees with
`bottom->top` by ~1mm in every case — plausible measurement-datum slop
between "this part's own spec height" and "total stack height as caliper'd
on the assembled board", not treated as an error, just not the number to
store):

| connector | alone | bottom->top | thickness | h = bottom->top − thickness | prior h | action |
|---|---|---|---|---|---|---|
| `usb_1` (USB3) | 13.0 | 15.5 | 1.4 | 14.1 | 13.5 [C] | **replaced**, tier -> [B] caliper |
| `sfp_1`/`sfp_2` | 9.5 | 11.8 | 1.4 | 10.4 | 13.4 [C] | **replaced**, tier -> [B] caliper |
| `rj45_1..4` | 13.2 | 15.1 | 1.4 | 13.7 | 13.60 [A] datasheet | **kept** (see below) |

`rj45`'s caliper-implied h (13.7) is within 0.1mm of the existing exact-part
datasheet figure (13.60, `HRJC-M03C01C10cNL.pdf`) already stored on that row
— read as corroboration, not a correction. Per this repo's value-confidence
rule (never downgrade a tier without cause), the [A] datasheet figure is kept
unchanged; the caliper cross-check is noted here rather than used to
overwrite a higher-tier value that already agrees within noise.

**RJ45 4-port block overall envelope (58.3mm x 20.9mm caliper).** This is the
*outer* physical envelope of the whole ganged block, not a new per-port
literal — per-port pitch/width (13.98mm, exact datasheet) and depth
(21.45mm) are unchanged; the plan's own instruction was explicit that this
figure is corroborating context, not a schema change. It DOES narrow (does
not fully resolve) the "unreconciled gap" flagged earlier in this file
(the pure pitch-math block end at 118.53 vs. the drawing-detector-confirmed
right edge at 122.77): `block_x0 (62.61) + 58.3 = 120.91` sits between the
two prior estimates, a third independent data point landing in the
plausible middle rather than at either extreme. Depth (20.9mm caliper vs.
21.45mm stored) agrees within 0.55mm, consistent with the stored depth. No
row values changed from this figure; it's recorded here as the resolving
context for a previously-open gap.

**New bpir4 components (Task 2).** Bodies sourced from connectors' T1 types
(`sim_2ff`, `microsd`, `m2_key_b`) per SSOT wherever a type fits; literal
board-specific values (with why-comments in sbc.scad) where none does
(reset/WPS buttons, LEDs, DIP switch, the 26-pin GPIO header — connectors.scad
is out of scope/closed for this task per Task 1).

- **`reset_1`/`wps_1`** (rear-actuated buttons, ymax): x/w caliper [B]
  (8.3/18.3, both w=7.5); d/h have no caliper figure (only x+width were
  given) — generic small tactile-switch keep-out estimate, [C]//VERIFY.
- **`sim_1`/`sim_2`/`sim_3`** (mini-SIM 2FF trays, ymax): explicitly flagged
  **reference-only** by the caliper pass itself (weaker confidence than the
  rest of this data) — kept as real connector rows per the brief's explicit
  instruction to add them, but flagged //VERIFY throughout. Caliper w=15
  matches `connector_size("sim_2ff")`'s own w=15 exactly — corroborates the
  T1 type as the right body to source from.
- **`microsd_1`** (ymax): caliper x=81.8 [B]; caliper's own "w=14.6" figure
  matches `connector_size("microsd")`'s **depth** field (14.5, within
  0.1mm) much more closely than its width field (16.44, off by 1.84mm) —
  read as an axis-labeling ambiguity in the caliper note (which axis
  "width" refers to isn't stated in the raw reading), resolved by trusting
  the full 3-axis datasheet-sourced catalog type over a single
  ambiguous-axis figure rather than inventing a rotated literal to
  force-fit one axis. Per SSOT, body comes from `connector_size("microsd")`
  unchanged.
- **`led_1`..`led_7`** (ymax): x0=99.2, pitch=6.4, w=3.2 each, all caliper
  [B]; block spans x=[99.2,140.8] (41.6mm), consistent with the caliper's
  own "~40wide" approximation. No connector type fits a point-indicator LED
  (connectors.scad's catalog is panel/socket bodies, not indicator lights) —
  board-literal with a why-comment. d/h have no caliper figure — generic
  visible-lens-protrusion estimate, [C]//VERIFY.
- **`dip_1`** (DIP switch bank, "top" face — actuated from above, not a
  lateral edge, despite sitting near the right/xmax wall): x reconstructed
  from the caliper's own explicit overhang note ("+2mm overhang off x=148"):
  `x_max = 150`, `x_min = 150-10.4 = 139.6` — this connector is a
  **deliberate, caliper-confirmed exception** to the generic
  within-board-envelope test check (see `sbc_test.scad`'s
  `_overhang_exceptions`), not a data error. y computed from "48.6-rear"
  read as *distance from the rear wall to the box's own rear-facing edge*
  (the same directional convention as the X-axis "distance from left wall
  to the box's own left-facing edge" used everywhere else in this row):
  `y_max = 100.5-48.6 = 51.9`, `y_min = 51.9-6.5 = 45.4`. This
  near-vs-far-edge reading is **not disambiguated by the caliper note
  itself** — flagged //VERIFY for the interpretation, though x/y/w/d
  themselves are [B] caliper. h (2.5mm, generic slide-switch actuator
  height) has no caliper figure, [C]//VERIFY.
- **`gpio26_1`** (26-pin/2.54mm header, "top" face near the right wall):
  distinct from the Pi-family 40-pin `"gpio"` name/type (this is 13 columns,
  not 20 — NOT Pi-HAT-compatible) to avoid a misleading name collision.
  w=13*2.54=33.02 (13-column pin-field span, the same `nCols*pitch`
  convention `gpio_2x20` itself uses), d=2*2.54=5.08 (2-row spacing,
  identical across every 2.54mm header on this board). h=6.0 reused from
  `uart_1`'s own generic 2.54mm-pitch pin-header datasheet
  (`DS/Header_PIN 2.54mm.pdf`) rather than `gpio_2x20`'s h=8.5 (that figure
  is grounded specifically in the Raspberry-Pi-HAT mechanical spec; `uart_1`
  is the more relevant same-board, same-generic-header-family evidence for
  a non-HAT header). y computed from the caliper's "10-rear" the same way
  as `dip_1` above: `y_max=100.5-10=90.5`, `y_min=90.5-5.08=85.42`, [B]
  caliper + //VERIFY interpretation. x has **no caliper figure** at all
  ("right wall" without a number) — placed flush to the right edge
  (`148-33.02=114.98`) as the most literal reading available, [C]//VERIFY,
  not caliper-measured.
- **`m2modem_1`** (M.2 Key-B modem socket, "top" face): x=3.4 (left edge,
  direct per the "x=left-edge" convention), y computed from "14 rear" the
  same directional convention as `dip_1`/`gpio26_1`
  (`y_max=100.5-14=86.5`, `y_min=86.5-8.7=77.8` using the catalog type's own
  depth). Body from `connector_size("m2_key_b")` per SSOT. **Open
  discrepancy, not silently reconciled**: this position (x=3.4, near the
  board's LEFT edge) does not spatially match the DXF-era
  "(47.60,75.69)/(57.60,75.69) M2-silkscreen-text-proximity hole pair"
  documented above in "bpi-r4 hole roles" as a candidate M.2-socket
  standoff pair — that pair sits 44-54mm away at x=47.6-57.6. Both readings
  come from independent evidence (DXF silkscreen proximity vs. direct
  caliper measurement of the real board) and are left unreconciled here
  rather than picking one to silently override the other; a future pass
  with the physical board in hand could resolve which (if either) hole
  pair is this modem's actual standoff.

### Task 2 underside-x reconstruction (mPCIe x2 + M.2 Key-M SSD)

These 3 sockets were caliper-measured on the **flipped (underside) board**,
confirmed source: `.superpowers/sdd/bpir4/component-measurements.md` line
34-35, "Left/right flips between TOP and BOTTOM measurements (board flipped
to see underside)." Every other bpir4 dimension in this file (DXF, assembly
drawing, front-panel caliper figures) is read in the TOP-view frame this
whole row uses; these 3 are the only ones needing an X-mirror before they're
usable board-frame coordinates. Y ("rear" readings) is NOT mirrored — the
flip that swaps left/right does not swap front/rear, corroborated by "rear"
being used consistently for top-face and bottom-face items alike elsewhere
in this caliper pass.

**Transform**: a flipped-frame "X right" reading -> `x_board = X`
(flipped-right = board-frame LEFT); a flipped-frame "X left" reading ->
`x_board = 148 - X` (flipped-left = board-frame RIGHT). This is a pure
X-mirror (`x' = 148 - x`) applied consistently regardless of which edge word
labels the reading — "right"/"left" describe which edge the *caliper user*
was measuring from in their own (flipped) view, not the board frame.

**Worked math, mPCIe #1/#2** ("41.9 rear/4.5 right" and "9.2 rear/4.5
right"): applying the transform, `x_board = 4.5` for both (mirror of a
"right" reading = board-left). **Board-fit sanity check confirms the
direction**: the only two readings of "x_board=4.5" are (a) it's the box's
MIN corner (extends +X to 4.5+29.90=34.4, fits comfortably) or (b) it's the
MAX corner (extends -X to 4.5-29.90=-25.4, off the board entirely —
impossible). This rules out interpretation (b) outright, confirming (a) and,
by extension, confirming the mirror direction itself (the un-mirrored
alternative, `x_board=148-4.5=143.5`, was the FIRST hypothesis considered and
rejected — see the team discussion that resolved this ambiguity). y from each
own "N rear" (unmirrored, same "distance from rear to the box's own
rear-facing edge" convention as `dip_1`/`gpio26_1`/`m2modem_1` above):
`y_max = 100.5-N`, `y_min = y_max - d` (connectors' own `mpcie` depth, 8.20).
mPCIe #1: y=[50.4,58.6]. mPCIe #2: y=[83.1,91.3]. Both fit comfortably within
the board's 100.5mm Y span; both share the same X column (two parallel
underside Mini-PCIe slots near the left edge), consistent with a
Wi-Fi-radio-pair layout.

**Worked math, M.2 Key-M SSD** ("7.6 left/~2 rear/key-right"): applying the
transform to a "left" reading, `x_board = 148-7.6 = 140.4` — the OPPOSITE
mirror direction from mPCIe's "right" readings (flipped-left and
flipped-right mirror to opposite board sides; this is expected, not an
inconsistency). **Cross-check against the plan's own anchor note** ("SSD
opposite `dc_power_1`", x=124.59, a right-side front-panel part): 140.4
lands in that same right-side region of the board (dc_power_1/usbc_pwr_1
span x=124.59-143.56); the un-mirrored alternative (x_board=7.6, near the
LEFT edge) would NOT be "opposite" a right-side part at all — this
independently confirms that "left" readings mirror too, not just "right"
ones, and that the mirror is a true X-reflection applied uniformly. "key
right" is read as: the connector's own key/insertion edge is the box's +X
side, so 140.4 is the MAX corner: `x_min = 140.4 - 21.9 (connector_size
("m2_key_m") width) = 118.5`. **Independent corroboration**: this box's
center, `(118.5+140.4)/2 = 129.45`, matches the x=129.54 multi-length
standoff hole column (see hole-list comment + the section below) to within
0.1mm — strong confirmation the reconstruction landed in the right place,
found without having used that hole's x as an input to this calculation.
y from "~2 rear" (unmirrored, same convention): `y_max=100.5-2=98.5`,
`y_min = 98.5 - 8.7 (connectors' own m2_key_m depth) = 89.8`.

### Task 2: x=129.54 hole column re-interpreted as SSD multi-length standoffs

The user directly confirmed (relayed via the team lead) that the x=129.54
column (y=15.25/35.25/53.25/65.25) is **one socket's multi-length standoff
set** for the M.2 Key-M SSD above — like a standard M.2 socket that supports
2242/2260/2280/22110-length cards by providing a screw-boss at each length,
only one of which is populated depending on which physical card is
installed. This **does not erase** the prior per-hole IC-proximity notes in
"bpi-r4 hole roles" above (kept on record: a standoff can sit near an IC
cluster incidentally AND serve this role — both facts are true simultaneously,
this is a role clarification, not a correction of the proximity observations
themselves). Role stays `component-mount` for all 4 (unchanged).

**Attempted length-to-hole mapping** (best-effort, explicitly NOT asserted
as confirmed — flagged per the team's own guidance that guessing without
evidence is worse than leaving it open): using the SSD connector's own
derived rear-facing edge (y_max=98.5) as the length-measurement reference,
distances to each hole are 98.5-65.25=33.25, 98.5-53.25=45.25,
98.5-35.25=63.25, 98.5-15.25=83.25. Standard M.2 nominal lengths are
42/60/80/110mm (2242/2260/2280/22110). **A clean 4-way mapping does not
work**: a 110mm-long card physically cannot fit this orientation at all (the
board's own Y span is only 100.5mm total, well under 110mm), so at most 3 of
these 4 holes correspond to standard lengths, and the consecutive gaps
(20, 18, 12mm going from the 15.25 hole toward 65.25) only partially match
the standard consecutive-length deltas (18, 20, 30mm) — two of three
approximately match (18, 20) but not in a clean one-to-one order, and the
third (12mm) doesn't match the remaining standard delta (30mm) at all.
**Not resolved cleanly from spacing alone.** Tentative, low-confidence best
guess: the y=35.25 hole (63.25mm from the reference edge) is the closest
plausible candidate for a 2280 (80mm) card, allowing for a plausible
~15-20mm offset between the measurement reference used here and the
standard's own datum point — but this is NOT asserted as fact anywhere in
sbc.scad or the test suite, only recorded here as a documented, flagged
guess for a future pass with the physical board in hand to confirm or
correct.

**Task 2: no new mount holes added.** The brief allows adding mount holes
"where relevant." One new component DOES have an associated existing hole
group after the user's clarification above — the M.2 Key-M SSD's multi-length
standoff options are the already-present x=129.54 column (re-interpreted, not
newly added). For every OTHER new component (modem, mPCIe x2, GPIO26, DIP,
buttons, LEDs, SIM, microSD), the caliper pass gathered zero mounting-hole/
standoff position data — every caliper figure for those is a
connector/component *position*, not a screw-hole coordinate. Inventing a
plausible-looking standoff position for any of them would be exactly the
kind of guess this library's provenance rules exist to prevent (see
`m2modem_1`'s discrepancy above — even an existing, independently-sourced
candidate hole pair doesn't spatially line up with the new caliper position).
No new hole ROWS were added; the existing 16-hole set is unchanged in count,
position, and role by this task — only the x=129.54 column's documented
*purpose* was clarified.

## Shipped modules built on this data

Placeholder envelope (`sbc_placeholder`), mounting-hole/standoff stamps
(`sbc_mount_holes`, `sbc_standoffs`), and connector-opening cutout stamps
(`sbc_port_cutout`, `sbc_faceplate_cutouts`) all ship in sbc.scad and
consume the tables documented above — see sbc.scad's header comment and
README.md for usage.

## Raspberry Pi Zero family (Task 1 of a follow-on plan): outline + holes

`pizero` (Raspberry Pi Zero / Zero W / Zero WH — official Raspberry Pi Ltd
guidance is that all three share one PCB mechanical design) and `pizero2w`
(Raspberry Pi Zero 2 W). Outline/holes were Task 1 of this plan (this
section); connector maps are Task 2, documented in the new section below
("Raspberry Pi Zero family connectors (Task 2)").

### Sources ([A], vendor official mechanical drawings, PDF)

- Raspberry Pi Zero: `RASPBERRY PI ZERO`, ref `RPI-ZERO-V1_2`, dated
  23/09/2015, drawn by Mike Stimson, approved by James Adams:
  https://datasheets.raspberrypi.com/rpizero/raspberry-pi-zero-mechanical-drawing.pdf
  (301/302-resolves to
  `https://pip.raspberrypi.com/documents/RP-008365-DS-raspberry-pi-zero-mechanical-drawing.pdf`,
  which itself 302s to
  `https://pip-assets.raspberrypi.com/categories/579-raspberry-pi-zero/documents/RP-008365-DS-1-raspberry-pi-zero-mechanical-drawing.pdf`).
  Confirmed a real PDF ("PDF document, version 1.4, 1 page(s)"), read directly.
- Raspberry Pi Zero 2 W: title block-free sheet, PDF metadata `Title: "Zero 2
  Mechanical drawing"`, `Author: simon`, created 2021-10-28 (Adobe
  Illustrator 25.4 / Adobe PDF library 16.00). The
  `https://datasheets.raspberrypi.com/rpizero2w/raspberry-pi-zero-2-w-mechanical-drawing.pdf`
  path returns 404; the working URL is the sibling `rpizero2` path,
  `https://datasheets.raspberrypi.com/rpizero2/raspberry-pi-zero-2-w-mechanical-drawing.pdf`
  → 301 → `https://pip.raspberrypi.com/documents/RP-008358-DS-raspberry-pi-zero-2-w-mechanical-drawing.pdf`
  (200 OK, real PDF, 1 page). The full page was checked (reported page size
  311.811 x 283.465 pt) — nothing outside the single view was cropped.

### Outline — [A], confirmed independently on each board's own drawing

Both drawings print the same dimension chain: outline **65 (X) x 30 (Y)**
mm. No rounding ambiguity here (unlike the Model-B family's 85-vs-85.6
issue above) — both figures are printed directly and match the task
brief's stated 65x30mm. **No per-model difference.**

### Corner radius — [A] on pizero, [B]//VERIFY carried-forward on pizero2w

- `pizero`: drawing has an explicit **"CORNER RADIUS = 3.0mm"** callout
  with a leader line to the board's rounded corner — same wording/value as
  pi3b/pi3bplus/pi4b. Tier **[A]**.
- `pizero2w`: **no equivalent callout anywhere on the sheet** — checked the
  full page (confirmed nothing was cropped from the view). The board is visually
  the same rounded-rectangle shape. Value carried forward as **3.0mm,
  tier [B], //VERIFY** — same treatment as this library's existing `pi5`
  row, which has the identical gap (see the Model-B corner-radius section
  above). Confirm against a physical Zero 2 W board or a case/STEP file if
  a tight-tolerance corner cut is ever needed.

### Mounting holes — [A] on both, confirmed independently, NOT blind-copied

Both drawings print the **same** dimension chain for the outline and the
4-hole mounting rectangle:

| label | value (mm) | meaning |
|-------|-----------|---------|
| 65 | 65 | overall board width, left edge → right edge |
| 58 (pizero only — see note) | 58 | X span between the two hole columns |
| 29 | 29 | half of 58 (to the hole-pattern centerline, both sheets) |
| 3.5 | 3.5 | X offset, left edge → left hole column (from the connector-position dimension chain "3.5 / 12.4 / 41.4 / 54", which starts at the same tick as the bottom-left hole on both sheets) |
| 23 | 23 | Y span between the two hole rows |
| 3.5 | 3.5 | Y offset, top edge → top hole row (and, mirrored, bottom edge → bottom hole row) |
| 30 | 30 | overall board height, top edge → bottom edge |

Note on the "58" label: it is printed explicitly on the `pizero` sheet
(three nested horizontal dimensions "65 / 58 / 29") but is **not** printed
as its own figure on the `pizero2w` sheet (only "65" and "29" appear at the
top). This does not weaken the `pizero2w` hole-span value to a guess,
because it is independently derivable and cross-checked from figures that
ARE printed on the `pizero2w` sheet itself: (a) "29" is dimensioned from the
left edge to the hole-pattern centerline; since the board's own centerline
is `65/2 = 32.5`, and `3.5 + 29 = 32.5`, the pattern is confirmed centered,
i.e. symmetric about the board center — combined with (b) the "3.5" left
offset (from the same connector-position chain as `pizero`) and (c) the
board-width symmetry this implies (`65 - 3.5 = 61.5` for the mirror column),
the same `58`-wide, `3.5`-inset span as `pizero` is reconstructed from
`pizero2w`'s own printed numbers, not copied from the other board's sheet.
The Y chain (`30 / 23 / 3.5` top + mirrored `3.5` bottom) IS printed in full
on both sheets.

**Result, both boards**: outline `[65, 30]` [A]; holes at
`(3.5,3.5) (61.5,3.5) (3.5,26.5) (61.5,26.5)` — i.e. the 58x23mm rectangle
inset **3.5mm from all four edges** (not just two — both X and Y insets are
symmetric on both sheets, confirmed by the arithmetic above), tier **[A]**
for `pizero` (fully printed) and **[A]/[B]** blended for `pizero2w` (Y chain
fully printed [A]; X span derived-but-confirmed from printed figures, [A]
for the printed pieces / [B] for the one-step derivation, not a guess).
**No per-model difference found** between `pizero` and `pizero2w`.

### Mounting hole diameter

- `pizero` sheet: **"4x M2.5 MOUNTING HOLES DRILLED TO 2.75 +/- 0.05mm"** —
  same wording as the pi3b row above. [A]
- `pizero2w` sheet: no equivalent callout text found. Not stored per-row in
  this library anyway (`sbc_hole_dia()` is a single global function, 2.7mm,
  shared by every board) — no action needed, noted here for completeness.

### PCB thickness — no drawing source; [C] //VERIFY, same as the Model-B rows

Neither Pi Zero drawing has a side/edge view or any thickness dimension
(checked both full pages). Library uses **1.4mm nominal for both boards,
tier [C], //VERIFY** — same figure and same reasoning as the Model-B family
above (matches the task brief's own suggested "~1.4mm nominal" and the
lower/older end of the community-measured range for Raspberry Pi PCBs); a
tight Z-stack design should re-measure the specific board revision or
source a vendor STEP file rather than trust this figure.

### Per-model differences found

**None**, for outline, hole pattern, or hole diameter wording (both share
byte-for-byte the same dimension-chain values, confirmed independently on
each board's own drawing rather than assumed from the family resemblance).
The only per-model gap is the **missing corner-radius (and hole-diameter,
and title-block) text on the `pizero2w` sheet** (documented above) — this
is a difference in how thoroughly each PDF was authored/exported, not
evidence of an actual mechanical difference between the two boards.

## Raspberry Pi Zero family connectors (Task 2)

### Method: hole-grid-calibrated pixel measurement (extents are not text-dimensioned; the ymin connectors' X-centres partially are)

Both Pi Zero drawings dimension the outline and the 4-hole mounting
rectangle in full (see above), and — checked on both sheets — the bottom-
edge chain **"3.5 / 12.4 / 41.4 / 54"** also lands within ~0.1mm of the
shipped `minihdmi`/`microusb_data`/`microusb_pwr` X-centres, so those three
connectors' X-positions are effectively drawing-dimensioned, not purely
pixel-derived. What neither sheet prints is any connector body width/depth
text or a Z-Height callout, unlike every Model-B drawing (which at minimum
text-dimensions each connector's position, and usually its Z-Height too).
Checked the full page of both sheets (title block strip, margins,
everywhere) for missed text — none found beyond the chain above.

Given that, connector extents (and the `gpio`/`csi` positions, which the
"3.5/12.4/41.4/54" chain does not cover) here come from a different,
non-text method: circle detection located the four mounting-hole
centers on each board's own render (`pizero` at 300dpi; `pizero2w` at
600dpi, for a cleaner pixel read), then
an affine mm<->px transform was built from those hole centers against the
already-[A]-confirmed 58x23mm/3.5mm-inset hole rectangle (see above) — e.g.
for `pizero`: holes detected at px (493.5,993.5)/(1447.5,994.5)/(1449.5,
1373.5)/(493.5,1373.5), giving 16.45-16.52 px/mm on X/Y (self-consistent to
within 0.5%), then contour extraction produced every connector-shaped
silkscreen/outline box, converted to mm via that transform. This is tier
**[B]**: precise and self-consistent (both axes' scale factors agree,
and the same method independently reproduces near-identical mini-HDMI/
micro-USB positions on both boards' own separately-rendered images — see
per-board notes below), but not text-dimensioned, so not [A]. No connector
height (h) is recoverable this way (a top view can't show Z) — every `h`
below is a **[C] //VERIFY** generic connector-body figure (micro-USB-B
reused from this file's own pi3b `microusb_pwr` h=2.8; mini-HDMI and the
`csi` FPC height are generic industry figures, not board-specific).

Filtering: internal SMD/IC footprints (resistors, the SoC, shield cans,
crystals — none touching a board edge) were excluded by requiring each
candidate contour to touch (within measurement noise) one of the four
board edges or the header's own inset-from-`ymax` position; a few dozen
small internal-component contours were found and discarded this way on
each board (documented per-board below only where they were plausible
connector candidates and had to be explicitly ruled out).

### `pizero` (RPI-ZERO-V1_2, 23/09/2015) — 4 connectors: 1 `gpio` + 3 lateral

- **`gpio`** `[7.1, 23.9, 1.4]` / `[51.0, 5.0, 8.5]` / `"top"`. Position/
  extent **[B]**: the elongated unpopulated-header slot sits between the
  two `ymax`-side holes, inset 1.1mm from the top (`ymax`) edge — closely
  matches (not blind-copied from) this file's Model-B-family `_sbc_gpio()`
  figures (`x=7.1`, `w=51.0`, same values; only the board-specific `y`
  differs, since pizero's board is 30mm tall vs. 56mm for Model-B), which
  cross-validates both readings independently. `h=8.5` **[B]** carried
  forward from the Model-B family — same physical Raspberry Pi HAT header
  part across the whole product line, not a per-board guess; no Z-height
  text exists on this sheet to read directly.
- **`minihdmi`** `[6.9, 0, 1.4]` / `[10.9, 7.0, 3.4]` / `"ymin"`. Position/
  extent **[B]** (box measured 6.94..17.88 x, -0.04..6.92 y — bottom edge
  snapped to y=0). This is the left-most of the three bottom-edge boxes,
  a plain (non-stepped) rectangle, distinct in shape from the two
  micro-USB boxes (which show a small stepped foot/flange line at their
  base) — consistent with a different connector family, and its ~11x7mm
  footprint matches a mini-HDMI (Type C) shell reasonably well. `h=3.4`
  **[C] //VERIFY**, generic mini-HDMI receptacle height (no drawing Z
  data).
- **`microusb_data`** `[37.7, 0, 1.4]` / `[7.5, 4.7, 2.8]` / `"ymin"` and
  **`microusb_pwr`** `[50.3, 0, 1.4]` / `[7.6, 4.7, 2.8]` / `"ymin"`.
  Position/extent **[B]** (boxes measured 37.7..45.24 and 50.28..57.88 x,
  both -0.04..4.68 y). Both show the same stepped foot/flange detail,
  confirming they're the same connector type as each other — real Pi Zero
  boards silkscreen the left one "USB" (OTG/data) and the right one
  "PWR IN" (power-only), left-to-right matching this drawing's left-to-
  right box order, so assigned accordingly (silkscreen text itself is not
  visible on this line-art sheet — order/position is the basis for the
  name assignment, not a re-read silkscreen label). `h=2.8` **[C]**
  reused from this file's own pi3b `microusb_pwr` row (same generic
  micro-USB-B receptacle height, already tagged //VERIFY there).

**Omitted, `pizero` — documented gaps, not guesses:**

- **`csi`**: this is the `RPI-ZERO-V1_2` sheet, dated 23/09/2015 — the
  physical CSI camera FPC connector was added in Raspberry Pi Zero
  hardware revision 1.3 (mid-2016), i.e. **after** this drawing. Directly
  checked: the board's right edge, between the two right-side mounting
  holes, reads as a plain straight line on this sheet (see
  `/tmp/z1_rightedge.png`-style crop taken during this task) — no notch,
  no connector-shaped contour, confirmed absent by the same contour-scan
  method used to find the other three connectors (a targeted scan of
  every contour touching the right/left edges found only sub-mm SMD-
  component noise, nothing connector-scale). Verified-absent, not merely
  unsearched.
- **`microsd`**: omitted, but not for lack of drawing evidence — this
  sheet DOES dimension the microSD opening: a box protrudes ~2mm past the
  outline on the **xmin (left) edge**, between the two left-side mounting
  holes, with Y-dimensions **"16.9"** and **"6"** printed on the left
  margin (see the "TOP ASSEMBLY" crop). The reason for the omission is
  that real Raspberry Pi Zero boards mount the microSD card **holder
  body** on the PCB's **underside** (opposite face from the header/SoC/
  other connectors, z<0 in this file's datum) — a well-known distinctive
  design choice for this board family. This top-side connector model
  places every connector at z=`sbc_thickness(b)` (the PCB's top face), so
  an underside-mounted holder is out of scope for it regardless of the
  X/Y opening being dimensioned, and this single top-view sheet gives no
  way to derive the holder's Z extent/depth below the PCB. Omitted as a
  documented scope gap, not a missing-evidence one. A bottom-assembly
  drawing or vendor STEP/DXF would still be needed to source the
  underside geometry (holder depth/shape) properly; out of scope
  for this task (no further fetch attempted, only the two provided PDFs
  available).

### `pizero2w` ("Zero 2 Mechanical drawing", 2021-10-28) — 5 connectors: 1 `gpio` + 3 lateral + 1 `csi`

Own-drawing measurement, independently re-run (not copied from the
`pizero` row) — cross-checked against `pizero`'s figures only after the
fact, per the brief's "confirm on its own drawing" instruction. Hole
centers detected at px (570.5,1303.5)/(1941.5,1302.5)/(568.5,757.5)/
(1943.5,756.5) on the 600dpi `pizero2w_hi.png` render, giving 23.64-23.74
px/mm (self-consistent).

- **`gpio`** `[7.2, 23.9, 1.4]` / `[50.6, 4.9, 8.5]` / `"top"`. Position/
  extent **[B]**, independently measured — agrees with `pizero`'s
  `gpio` reading to within 0.3mm on every figure, a strong cross-check.
  Note: this sheet's header slot actually **renders the 2x20 pin circles**
  (vs. `pizero`'s plain unpopulated-slot outline) — a drawing-style
  difference, not evidence the footprint itself differs. `h=8.5` **[B]**
  carried forward, same reasoning as `pizero`.
- **`minihdmi`** `[7.1, 0, 1.4]` / `[10.8, 6.8, 3.4]` / `"ymin"`
  (box measured 7.07..17.84 x, -0.5..6.83 y). **[B]** position/extent,
  agrees with `pizero`'s minihdmi box (6.94..17.88 / -0.04..6.92) to
  within ~0.3mm. `h=3.4` **[C] //VERIFY**, same as `pizero`.
- **`microusb_data`** `[37.7, 0, 1.4]` / `[7.4, 4.6, 2.8]` / `"ymin"` and
  **`microusb_pwr`** `[50.3, 0, 1.4]` / `[7.4, 4.6, 2.8]` / `"ymin"`
  (boxes measured 37.7..45.13 and 50.28..57.72 x). **[B]** position/
  extent, again agreeing with `pizero`'s equivalent boxes to within
  ~0.3mm — same silkscreen-order-based name assignment as `pizero`
  ("USB" left, "PWR IN" right). `h=2.8` **[C]**, reused as with `pizero`.
- **`csi`** `[61.7, 6.9, 1.4]` / `[3.3, 16.0, 1.5]` / `"xmax"` (notch
  measured 61.65..64.94 x, 6.95..22.92 y). This is the one connector
  present on `pizero2w` but not `pizero`: a clearly deliberate, stepped/
  tabbed **notch cut into the board outline itself**, on the right edge
  (`xmax`), centered between the two right-side mounting holes — absent
  on `pizero`'s v1.2 sheet, consistent with CSI being physically added to
  the Zero family after that drawing was made. Position **[B]**
  pixel-measured directly off this notch. **//VERIFY, flagged as the
  weakest-sourced record in both Pi Zero rows**: this sheet has no refdes,
  label, or dimension text confirming the notch specifically IS the CSI
  FPC connector's clearance channel, as opposed to some other mechanical
  or antenna-related keep-out feature — it is included, per the brief's
  "if the drawing shows it, map it" instruction, because its position
  (centered on the edge opposite the GPIO header, between the corner
  holes) and its distinct, deliberately-shaped-not-just-a-rectangle
  geometry both match the known Pi Zero-family CSI connector location and
  are hard to explain as anything else — but this is the single
  lowest-confidence record shipped for either Pi Zero board. `h=1.5`
  **[C] //VERIFY**, generic low-profile FPC-connector height estimate (no
  Z data of any kind available from a top view).

**Omitted, `pizero2w`:**

- **`microsd`**: same reasoning as `pizero` — the card holder body is
  underside-mounted (z<0) on real Zero-family boards, out of scope for
  this top-side connector model. Unlike `pizero`'s sheet, this drawing's
  own left edge shows no dimensioned protrusion for it: a targeted
  contour scan of the left/bottom edges found nothing SD-slot-shaped
  beyond the already-classified internal component and corner-keepout
  boxes. Documented gap, not a guess.

### Verification performed for this task

- `scripts/openscad.sh --export-format echo -o /dev/null libraries/sbc/sbc.scad`
  → `COMPILE_OK`.
- A scratch `--export-format echo` harness (`sbc_connectors("pizero")` /
  `sbc_connectors("pizero2w")`) confirmed: exactly 1 `gpio` per board;
  every lateral connector's edge-touch invariant holds (`xmax` ⇒
  `x+w≈65`, `ymin` ⇒ `y≈0`) with zero measurement error (all lateral `y`
  values are `0` by construction; the one `xmax` record, `csi` on
  `pizero2w`, has `x+w=65.0` exactly by construction too).
- `make test` passes in full (all existing suites, including
  `tests/test_sbc_lib.sh`) — this task did not touch the Model-B/bpir4
  rows, the outline/hole data, or any data-model function, so no existing
  invariant was put at risk.

## SP2 connector reconcile — Task 1 (verdict table vs the connectors catalog)

Analysis-only pass (no `.scad` file edited by this task). Every connector on
all 7 boards in `_sbc_table()` (plus the shared `_sbc_gpio()` row) is compared
against its best-matching type in `libraries/connectors/connectors.scad`'s
`_connector_table()`, component-by-component on `[w,d,h]`, at a 0.5mm
threshold (per the SP2 design doc's reconcile rule). This supersedes nothing
in `connectors/RESEARCH.md`'s own "SP1 reconciliation" section (which did a
similar pass on 2026-07-09 and is what got `usb_a_stack2_shielded` and
`rj45_shallow` added to the catalog in the first place) — this pass re-runs
the comparison against the **current** catalog, which now includes those two
SP1-added types as first-class peers, and is the version Task 3 should
transcribe from for `sbc.scad` edits.

**Rule**: same nominal part, every `[w,d,h]` axis within 0.5mm → `same`
(record which side's tier wins, never downgrading an existing sbc `[A]` to a
weaker catalog value). A peer exists but a real axis is >0.5mm off →
`different` (candidate for a new type — see below). The sbc value itself
looks wrong against a trusted peer (its own RESEARCH.md already flags the
value as a probable misread, e.g. a chain-truncated span) → `error` (fix
note, not a new type). No catalog type describes the physical part at all →
`no-peer` (stays literal, intentional).

### Verdict table (51 connectors — every row of `_sbc_table()`/`_sbc_gpio()`)

Δ = sbc − catalog, per axis, `w,d,h`. "cat" = the connectors-catalog value's
own provenance tier (from `connectors.scad`'s inline tags); "sbc" = the same
connector's tier as tagged in `sbc.scad`/this file above.

#### pi3b (7)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| gpio | [51.0,5.0,8.5] | gpio_2x20 [50.8,5.08,8.5] | +0.20,−0.08,0.00 | same | sbc h=[A] ("Z-Height=8.5" drawing callout); cat h=[B] (SP1-upgraded, citing this exact sbc evidence) — no downgrade, already the higher-provenance number on both sides |
| usb2_1 | [17,18,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,0,0 | same | exact match — cat type was derived from this very row in SP1 (tier B); sbc pos [A]/w [B] |
| usb2_2 | [17,9,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,−9,0 | different (confirmed by source) | confirmed via the Pi 3B mechanical drawing (`RP-008335`) — the xmax-edge Y chain ("56/47/29/10.25") dimensions the upper USB2 shell as 47→56 = 9mm, drawn flush against the board's own top edge; this is the shell's true drawn extent, not a truncated chain. Genuinely shorter than `usb2_1` (same nominal part, different position on the board, not necessarily identical footprint at the drawn corner). Not the same catalog body as `usb_a_stack2_shielded` — stays literal |
| rj45 | [21,18.75,13.5] | rj45_shallow [21,18.75,13.5] | 0,0,0 | same | exact match — cat type derived from this very row in SP1 (tier B) |
| microusb_pwr | [7.5,5.5,2.8] | micro_usb [7.72,5.48,3.96] | −0.22,+0.02,−1.16 | different (unresolved) | h fails by >2x threshold; w/d agree closely. sbc h=[C]//VERIFY generic guess; cat h=[A] but self-flagged in its own findings as possibly foot-ear-inclusive (ambiguous axis read on the fetched drawing) — two weak/uncertain values, not a confirmed distinct part. Flagged, not adopted |
| hdmi | [15,11.5,6.5] | hdmi [14.50,11.06,6.17] | +0.50,+0.44,+0.33 | same | w exactly at the 0.5mm boundary — counts as same. cat=[A] (Same Sky HD05-19-TH datasheet); sbc=[A] pos+h/[B] w+d — h is an [A]→[A] tie (two independent [A] sources agree within 0.5mm; cat wins as single source of truth), while w/d is a genuine [B]→[A] upgrade from cat's datasheet-grounded value |
| av_jack | [6,6,6.0] | — | n/a | no-peer | 3.5mm AV/audio jack; no generic type in catalog — literal per brief |

#### pi3bplus (7 — identical connector map to pi3b, independently drawing-cross-checked)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| gpio | [51.0,5.0,8.5] | gpio_2x20 [50.8,5.08,8.5] | +0.20,−0.08,0.00 | same | carried-forward [B] h, same as pi3b |
| usb2_1 | [17,18,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,0,0 | same | corroborates pi3b usb2_1 |
| usb2_2 | [17,9,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,−9,0 | different (confirmed by source) | corroborates pi3b usb2_2, independently drawing-cross-checked |
| rj45 | [21,18.75,13.5] | rj45_shallow [21,18.75,13.5] | 0,0,0 | same | corroborates pi3b rj45 |
| microusb_pwr | [7.5,5.5,2.8] | micro_usb [7.72,5.48,3.96] | −0.22,+0.02,−1.16 | different (unresolved) | same as pi3b microusb_pwr |
| hdmi | [15,11.5,6.5] | hdmi [14.50,11.06,6.17] | +0.50,+0.44,+0.33 | same | same as pi3b hdmi |
| av_jack | [6,6,6.0] | — | n/a | no-peer | same as pi3b av_jack |

#### pi4b (8)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| gpio | [51.0,5.0,8.5] | gpio_2x20 [50.8,5.08,8.5] | +0.20,−0.08,0.00 | same | sbc h=[A] own "Z-Height=8.5" callout, independently corroborates pi3b's (cat h=[B]) |
| usb2 | [17,18,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,0,0 | same | matches pi3b usb2_1 exactly |
| usb3 | [17,18.75,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,+0.75,0 | different (marginal) | d over threshold by only 0.25mm past the 0.5mm cutoff — plausibly same-part reading noise (pi3b/pi3bplus's own usb2_1 reads d=18, pi5's usb3 reads d=17.9), not evidence of a genuinely distinct shell. Not proposing a new type for a single marginal axis on one board — flagged for adjudication (see below) rather than either forcing "same" or inventing a type |
| rj45 | [21,10.25,13.5] | rj45_shallow [21,18.75,13.5] | 0,−8.5,0 | different (confirmed by source) | confirmed via the Pi 4B mechanical drawing (`RP-008343`) — the xmax-edge Y chain ("56/45.75/27/9") dimensions the RJ45 box (Z=13.5) as 45.75→56 = 10.25mm, visibly shorter in the drawing than the two USB stacks below it (18.75mm, 18mm). Pi 4B's RJ45 (integrated Gigabit magnetics) is a genuinely different, shorter jack than Pi 3B/3B+'s RJ45 — not the same part despite sharing a name. Stays literal, not `rj45_shallow` |
| usbc_pwr | [9,7.4,3.2] | usb_c [8.94,6.90,3.16] | +0.06,+0.50,+0.04 | same | d exactly at the 0.5mm boundary — counts as same. Both sides [A] — genuine tie, keep cat's fetched value |
| hdmi_1 | [7.5,4.5,3.0] | micro_hdmi [7.5,4.5,3.0] | 0,0,0 | same | exact match. sbc h=[A] ("Z=3.0" drawing callout) is the actual grounding evidence behind cat's own [B] SP1 upgrade for this type — no downgrade, values already identical |
| hdmi_2 | [7.5,4.5,3.0] | micro_hdmi [7.5,4.5,3.0] | 0,0,0 | same | same as hdmi_1 |
| av_jack | [6,6,6.0] | — | n/a | no-peer | same as pi3b av_jack |

#### pi5 (10)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| gpio | [51.0,5.0,8.5] | gpio_2x20 [50.8,5.08,8.5] | +0.20,−0.08,0.00 | same | h=8.5 carried forward [B] (pi5's own sheet has no header Z-height text) |
| usb3 | [17,17.9,16.0] | usb_a_stack2_shielded [17,18,16.0] | 0,−0.1,0 | same | closely corroborates pi3b/pi4b family |
| rj45 (combo w/ usb2) | [21,18.9,16.0] | rj45_shallow [21,18.75,13.5] | 0,+0.15,+2.5 | no-peer | real Pi5 hardware molds Ethernet+2xUSB2 into one combo shell (sbc.scad's own comment); w/d land within 0.15mm of `rj45_shallow` but h=16.0 reflects the combined footprint, not a pure jack — a board-unique combo part, deliberately not force-mapped to `rj45_shallow` or any other single type |
| usb2 (combo w/ rj45, same box) | [21,18.9,16.0] | — | n/a | no-peer | shares the identical undimensioned box with the `rj45` row above — one physical combo shell represented twice in sbc's data model, not two independent connectors to reconcile separately |
| usbc_pwr | [9,7.4,3.2] | usb_c [8.94,6.90,3.16] | +0.06,+0.50,+0.04 | same | same as pi4b usbc_pwr |
| hdmi_1 | [7.5,4.5,3.0] | micro_hdmi [7.5,4.5,3.0] | 0,0,0 | same | independently corroborates pi4b's reading |
| hdmi_2 | [7.5,4.5,3.0] | micro_hdmi [7.5,4.5,3.0] | 0,0,0 | same | same as hdmi_1 |
| pcie_fpc | [8,3,3] | — | n/a | no-peer | PCIe FFC ribbon connector — distinct part class from the catalog's `pcie_x*` card-edge slot connectors; no generic peer |
| csi_dsi_1 | [2.5,6,5.5] | — | n/a | no-peer | camera/display FPC connector; no generic type in catalog |
| csi_dsi_2 | [2.5,6,5.5] | — | n/a | no-peer | same as csi_dsi_1 |

#### bpir4 (10)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| usb_1 | [8.89,23.16,13.5] | usb_a_stack2 [13.66,14.6,13.88] (best h-fit; usb_a_stack2_shielded's h=16.0 fits worse) | −4.77,+8.56,−0.38 | different (unresolved, weak evidence) | h reconciles against `usb_a_stack2` (Δ−0.38, within threshold), but w/d fail by a wide margin against **every** candidate peer (usb_a and usb_a_stack2 share the same w/d, only h differs, so the peer choice doesn't change this). sbc's own w is self-flagged `//VERIFY` "narrow vs typical USB-A body"; d has no independent corroboration either. Not confidently mapped to any type — flagged for adjudication/re-verification, not a basis for a new type from one weak reading |
| sfp_1 | [16.51,53.98,13.4] | sfp [14.5,48.7,9.7] | +2.01,+5.28,+3.70 | no-peer | **#21 adoption reconcile**: now that connectors `sfp` (TE 2007198-1, single-port 1x1 cage) exists, every axis runs far past the SP2 threshold; sbc's figure is a cage-PAIR keep-out (CN7+CN8, SFP0074EP-class) — a multi-component board-unique footprint with no meaningful 1:1 single-port peer (same reasoning as `rj45_1`/combo shells). Literal retained; depth/height stay //VERIFY; no new catalog type from one board |
| sfp_2 | [16.51,53.98,13.4] | sfp [14.5,48.7,9.7] | +2.01,+5.28,+3.70 | no-peer | same as sfp_1 (CN9+CN20+CN10) |
| rj45_1 | [13.98,21.45,13.60] | rj45_shallow [21,18.75,13.5] | −7.02,+2.70,+0.10 | no-peer | **Task 2 reclassify (was `error`)**: re-modeled as port 1 of CN21, the BPI-R4's single 4-port ganged RJ45 block (hardware-owner ground truth), body sourced [A] from the exact bundled connector datasheet (`RJ45x4-HRJC-M03C01C10cNL.pdf`). A ganged multi-port block with its own datasheet has no meaningful 1:1 peer against `rj45_shallow` (a single-port catalog type) — same reasoning as `sfp_1`/`sfp_2`. The prior [8.0,20.0,13.5] reading (an 8mm lone "WAN" jack) is discredited/superseded — see bpir4 RJ45 section above |
| rj45_2 | [13.98,21.45,13.60] | rj45_shallow [21,18.75,13.5] | −7.02,+2.70,+0.10 | no-peer | **Task 2 reclassify (was `different`)**: same reasoning as rj45_1 — one physical ganged block, no single-port peer. The prior [18.2567,19.05,13.5] reading (an assumed even 3-way split of an unrelated 3-port envelope) is discredited/superseded |
| rj45_3 | [13.98,21.45,13.60] | rj45_shallow [21,18.75,13.5] | −7.02,+2.70,+0.10 | no-peer | same reasoning as rj45_2 |
| rj45_4 | [13.98,21.45,13.60] | rj45_shallow [21,18.75,13.5] | −7.02,+2.70,+0.10 | no-peer | same reasoning as rj45_2 |
| dc_power_1 | [10.03,10.71,10.0] | — | n/a | no-peer | DC12V barrel power jack — no barrel-jack type exists anywhere in the catalog; a genuinely distinct connector class, not merely omitted |
| usbc_pwr_1 | [8.94,9.95,3.2] | usb_c [8.94,6.90,3.16] | 0.00,+3.05,+0.04 | different (unresolved, weak evidence) | w/h agree closely (w exact), but d fails by 6x the threshold. sbc's own note flags this exact axis as tangled with an unresolved boundary conflict against the adjacent unmapped "CN6" component — a self-flagged-suspect reading, not confirmed evidence of a deeper USB-C variant. `usb_c` is very likely still the right nominal part; the depth reading itself needs re-verification before adopting either value |
| uart_1 | [5.0,10.0,6.0] | — | n/a | no-peer | console/UART pin header — different pitch/pin-count class from the catalog's only header type (`gpio_2x20`, a 2x20/2.54mm-pitch part); no generic peer |

#### pizero (4)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| gpio | [51.0,5.0,8.5] | gpio_2x20 [50.8,5.08,8.5] | +0.20,−0.08,0.00 | same | h=[B] carried forward from the Model-B family (same physical HAT header part) |
| minihdmi | [10.9,7.0,3.4] | mini_hdmi [10.4,7.5,3.2] | +0.50,−0.50,+0.20 | same | w and d both exactly at the 0.5mm boundary — counts as same. Both sides weak (sbc [B] pos+extent/[C] h; cat [C]//VERIFY cited-not-fetched) — corroboration between two weak sources, not an upgrade to either |
| microusb_data | [7.5,4.7,2.8] | micro_usb [7.72,5.48,3.96] | −0.22,−0.78,−1.16 | different (unresolved) | same foot-ear/generic-guess ambiguity as pi3b's microusb_pwr — `micro_usb` is still the correct nominal peer type (same receptacle family, only wiring differs), the numeric reconcile itself is what's unresolved |
| microusb_pwr | [7.6,4.7,2.8] | micro_usb [7.72,5.48,3.96] | −0.12,−0.78,−1.16 | different (unresolved) | same reasoning as microusb_data |

#### pizero2w (5)

| connector | sbc `[w,d,h]` | catalog type `[w,d,h]` | Δ (w,d,h) | verdict | tier note |
|---|---|---|---|---|---|
| gpio | [50.6,4.9,8.5] | gpio_2x20 [50.8,5.08,8.5] | −0.20,−0.18,0.00 | same | corroborates pizero's gpio reading |
| minihdmi | [10.8,6.8,3.4] | mini_hdmi [10.4,7.5,3.2] | +0.40,−0.70,+0.20 | different (marginal) | w/h agree; d fails by only 0.2mm past the 0.5mm cutoff, and is only 0.2mm off pizero's own minihdmi d=7.0 (which itself passed) — plausibly the same physical mini-HDMI shell read with ordinary cross-board measurement noise, not a distinct part. Flagged for adjudication rather than treated as a confirmed different connector |
| microusb_data | [7.4,4.6,2.8] | micro_usb [7.72,5.48,3.96] | −0.32,−0.88,−1.16 | different (unresolved) | same ambiguity as pizero's microusb_data |
| microusb_pwr | [7.4,4.6,2.8] | micro_usb [7.72,5.48,3.96] | −0.32,−0.88,−1.16 | different (unresolved) | same ambiguity as pizero's microusb_pwr |
| csi | [3.3,16.0,1.5] | — | n/a | no-peer | camera FPC connector notch; no generic type in catalog (same class as pi5's csi_dsi_1/2) |

### No-peer connectors (17 total, literal — intentional, per the brief's global constraint)

`av_jack` (pi3b, pi3bplus, pi4b — 3.5mm AV/audio jack), `csi_dsi_1`/`csi_dsi_2`
(pi5) + `csi` (pizero2w) (camera/display FPC connectors, 3 total), `pcie_fpc`
(pi5, PCIe FFC ribbon — distinct from the catalog's card-edge `pcie_x*`
types), `rj45`+`usb2` combo shell (pi5 — board-unique molded part, 2 records
sharing one box), `sfp_1`/`sfp_2` (bpir4, SFP cages), `rj45_1`/`rj45_2`/
`rj45_3`/`rj45_4` (bpir4, **Task 2**: the single 4-port ganged RJ45 block,
CN21 — a datasheet-sourced ganged multi-port part has no meaningful 1:1
catalog peer, same reasoning as the SFP cages; previously 1 `error` +
3 `different` from the discredited two-connector split), `dc_power_1`
(bpir4, DC barrel jack — no barrel-jack type exists in the catalog at all),
`uart_1` (bpir4, console/UART header — different pin-count/pitch class from
`gpio_2x20`). None of these have — or plausibly should get — a generic
catalog peer; they stay as literal `[w,d,h]` on the sbc side.

### New types needed for Task 2 (SP2)

**None.** Every `different`/`error` verdict above is one of:

1. **A probable sbc-side data problem** (`error`) — **none remain** as of
   Task 2. (pi3b/pi3bplus `usb2_2` and pi4b `rj45` were previously bucketed
   here as a suspected chain-truncated Y-span, but re-checking the source
   drawings confirmed those readings are correct as drawn — reclassified
   `different (confirmed by source)` above, not an sbc data problem. bpir4
   `rj45_1` was the last `error` row — Task 2 re-modeled the whole bpir4
   RJ45 block from a hardware-owner ground truth + the exact connector's
   own datasheet and reclassified all 4 rj45 rows `no-peer`, not a fix
   toward `rj45_shallow`.)
2. **Marginal/noise** — 0.2-0.75mm past the 0.5mm cutoff on a single axis,
   with the same nominal part agreeing closely elsewhere in the family (pi4b
   `usb3`, pizero2w `minihdmi`).
3. **Genuinely unresolved, weak-evidence pairs** — both sides tagged
   `//VERIFY`/self-flagged-ambiguous, with no confident reading on either
   side to derive a new type's dims from (all `micro_usb` mismatches;
   bpir4 `usb_1`, `usbc_pwr_1`).

None of these is a confirmed, well-evidenced *distinct physical part* the way
`usb_a_stack2_shielded`/`rj45_shallow` were in SP1 (both grounded in an exact
or near-exact match repeated across 3+ boards). Manufacturing a new type from
a single ambiguous or self-flagged-suspect reading would violate
verified-research-over-guesswork. All flagged rows above are left for a
future re-fetch/re-measurement pass, not a new catalog entry.

### Ambiguous calls flagged for adjudication

- **bpir4 `usb_1`**: no candidate peer type reconciles on more than 1 of 3
  axes; best-call comparison used here is `usb_a_stack2` (for the h match
  only) — reasonable alternative reading is "no confident peer at all"
  (i.e. reclassify as `no-peer` rather than `different`). Recommend
  re-verifying the board reading before Task 3 touches this row.
- **pi5 `rj45`+`usb2` combo shell**: classified `no-peer` (board-unique
  molded part) here; an alternative would be a dedicated
  `rj45_usb2_combo` generic type if this combo shape recurs on other
  boards in the future. Deferred, not created speculatively for one board.
- **pi4b `usb3`** and **pizero2w `minihdmi`**: both are `different` by a
  narrow margin (0.2-0.25mm past the 0.5mm cutoff) against a peer that
  matches tightly everywhere else in the family — a case could be made
  these are `same` (measurement noise) rather than `different`. Recorded
  as `different` per the letter of the 0.5mm rule; flagging in case a
  looser/rounded threshold is preferred going into Task 3.
- **bpir4 `dc_power_1`/`uart_1`**: classified `no-peer` even though the
  brief's illustrative no-peer list doesn't name "DC barrel jack" or "UART
  header" specifically — both fall under its "board-unique clusters"
  catch-all (no catalog type resembles either). Flagging the extension for
  confirmation, not because either mapping looks wrong.

### Tally

**51 total connectors** (7 pi3b + 7 pi3bplus + 8 pi4b + 10 pi5 + 10 bpir4 + 4
pizero + 5 pizero2w — matches `_sbc_table()`/`_sbc_gpio()` exactly):

- **same**: 21
- **different**: 13 (1 marginal-noise-leaning + 9 unresolved/weak-evidence + 3 confirmed-by-source [pi3b/pi3bplus `usb2_2`, pi4b `rj45`] — see per-row notes; none propose a new type)
- **error**: 0 (bpir4 `rj45_1` was the last one — re-modeled and reclassified `no-peer` in Task 2, not fixed toward `rj45_shallow`)
- **no-peer**: 17 (literal, intentional; +4 in Task 2 — bpir4 `rj45_1`..`rj45_4`, the single 4-port ganged RJ45 block, has no meaningful 1:1 catalog peer)

21 + 13 + 0 + 17 = 51.
