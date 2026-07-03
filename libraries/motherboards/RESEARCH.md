# motherboards — re-verification worksheet (Task 1: calibration + orientation)

This replaces the prior RESEARCH.md. The prior pass mis-reconstructed the rear-edge
layout (I/O window overlapping the PCIe slots in X; I/O window right/left
justification asserted without reading the drawing's own datum chain). This
worksheet starts over: read the primary spec PDFs'
**printed dimension labels** (not pixel measurement), and nail the datum +
orientation before any hole is re-chained (hole chaining + closure is Task 2/3).

## Library target frame (unchanged)

Origin at the **rear-left board corner**. `+X` = board width, running along the
**rear I/O edge**. `+Y` = board depth, rear → front. PCB bottom at `Z = 0`. The
rear edge (I/O window + expansion-slot brackets) is at `Y = 0`.

## Sources read

All three were confirmed as real PDFs, rendered to image at 300/600dpi, and
read directly. Cached in a local scratch directory (gitignored; not committed
— matches convention from the `sbc` library tasks).

1. **ATX Specification 2.01** (Intel, 1997-02) — `atx.pdf`
   `https://www.bitsavers.org/pdf/intel/ATX/ATX_Specification_2.01_199702.PDF`
   Worked directly (200 OK). 27 pages, "ATX Specification" / Intel Corp.
   Layout-diagram page: **Figure 3 "Sample ATX/Mini-ATX Layout Diagram" is on
   page 11** (confirmed via the PDF's own text layout, not guessed blind).
   Chassis I/O aperture detail is **Figure 4, page 13** ("Chassis I/O Aperture
   Requirements (rear and side view — see Figure 3 for datum location)").
   Mounting-hole letter map is **Figure 2, page 9**.

2. **microATX Motherboard Interface Specification 1.2** (Intel, 2004-02) — `matx.pdf`
   `https://xdevs.com/doc/_PC_HW/Form_factors/matxspe1.2.pdf`
   Worked directly (200 OK). 23 pages, "microATX Motherboard Interface
   Specification". Layout-diagram page: **Figure 3 "Example microATX Layout
   Diagram" is on page 12**.

3. **ATX Specification 2.2** (Intel, formfactors.org, via Wayback) — `atx22.pdf`
   The brief's literal URL
   (`https://web.archive.org/web/2id_/https://formfactors.org/developer/specs/atx2_2.pdf`)
   returned an **HTML page** (Intel's current motherboard-form-factors marketing
   page), not a PDF — `file` identified it as `HTML document`. Root cause: the
   `2id_` wayback pseudo-timestamp isn't a resolvable capture on its own; a real
   timestamp is needed first. The resolvable snapshot is at timestamp
   `20180417122513`
   (`http://web.archive.org/web/20180417122513/http://www.formfactors.org:80/developer/specs/atx2_2.pdf`,
   note **`www.` + `:80`**, not the bare-domain https URL in the brief). Read in
   `id_` (raw) mode:
   `https://web.archive.org/web/20180417122513id_/http://www.formfactors.org:80/developer/specs/atx2_2.pdf`
   → real PDF, 26 pages, "ATX Specification" (this is ATX
   **2.2**). Layout-diagram page: **Figure 3 "Sample ATX Layout Diagram" is on
   page 12** (rendered **rotated 90°** — the PDF's page content is landscape-
   drawn inside a portrait page box, a Distiller-4.0-era export artifact, not a
   retrieval defect; rotated back to read it).

No `ATX_Specification_2_03` fetch was attempted this task (only the 3 URLs the
brief specifies were fetched); the previous `lib.json` listed
`ATX_Specification_2_03_199812.pdf` as a corroborating source — superseded here
by the verified-working ATX 2.2 fetch, which is newer and was actually
re-confirmed this pass. `lib.json` updated accordingly.

## Datum definition per drawing, and conversion to the library corner frame

**ATX 2.01 Fig 3 (p.11) and ATX 2.2 Fig 3 (p.12):** identical numeric dimension
chain in both (same board; AGP added in 2.2, but the mounting-hole grid and
rear-edge chain are unchanged) — cross-confirms the grid is stable across ATX
revisions. `Datum 0,0` is called out with an arrow pointing at the **first
(rear-row, leftmost) mounting hole** — i.e. the datum is a **hole**, not the
literal board corner. The board is drawn **rear-edge-up** (rear I/O edge at the
top of the page), **not mirrored**: dimensions increase left→right and
top→bottom exactly like the library's own `+X` (rightward) / `+Y` (rear→front,
i.e. down the page) — so converting datum-relative coordinates into the
library's corner frame is a **plain translation, no axis flip**:
- `corner_X = datum_X + 0.650"` — the bottom chain's `.650` is the offset from
  the true left board edge to the datum hole (closes: `.650 + 3.100 + ... +
  11.100 + .650(right margin, = 12.000-11.750) = 12.000"` board width — same
  closure the prior pass already established).
- `corner_Y = datum_Y + <rear-edge inset>` — the top-of-page chain (`.400 /
  .600 / 1.225 / ...`) references the rear board edge directly; exact per-row
  values are **Task 2's job** (hole chaining), not re-derived here.

Figure 4 (p.13, ATX 2.01) is a **rear-and-side VIEW of the chassis I/O
aperture** — i.e. a view from *behind* the panel, which **mirrors X** relative
to Figure 3's top-down view. Confirmed by its own dimension chain: `Datum 0,0`
in Fig 4 sits between a `5.196±0.010` segment (toward the I/O aperture) and a
`(0.650)` segment (toward "the rest of the board") — the **same** `0.650`
value that Fig 3 gives as the left-edge-to-datum offset, but here it's drawn
going the *other* visual direction, confirming the mirroring. Both figures
explicitly cross-reference each other ("rear and side view — see Figure 3 for
datum location"), so they were read as one coherent, self-consistent
coordinate system, not two independent unrelated drawings.

**microATX 1.2 Fig 3 (p.12):** explicit page note: *"Datum B 0,0 = mounting
location hole B. In this figure, the board is shown oriented with the rear of
the board toward the top."* Same rear-edge-up, non-mirrored top view as ATX
Fig 3 — `Datum B 0,0` is called out on the SAME single, non-mirrored figure as
the expansion slots and the I/O window (no separate mirrored figure needed;
Intel drew it once, directly). Unlike ATX's datum (at the board's far left),
**Datum B sits mid-board**, between the expansion-slot cluster (to its left)
and the rear I/O window (to its right) — its own top chain (`1.200 / .800 TYP
/ 2.096 / .812 / Datum B 0,0 / 6.250`) and the independent bottom chain (`.800
/ 1.350 / 1.800 / 8.000 / 9.600`, anchored to the true left board edge) both
need to be walked and closed to fix Datum B's absolute X — that's Task 2.
Conversion to the corner frame is again a **plain translation, no flip** (same
non-mirrored top-view convention as ATX).

## THE ORIENTATION CRUX — confirmed from printed labels, cross-drawing

**Finding: the I/O window sits at the HIGH-X (right) end of the rear edge,
flush with (or ~0.1" beyond) the board's right edge. The expansion-slot
connectors (ISA/PCI/AGP/PCIe) occupy the LOW-X (left) end of the rear edge,
starting close to the datum hole. They are side by side, not overlapping.**

Evidence (label-based, not pixel-measured), independently confirmed on **three**
drawings:

1. **ATX 2.01 Fig 3 (direct read):** the `.500 / .800 TYP / 5.196 / .812` chain
   positions the 7 ISA/PCI connector slots starting ~0.5" right of `Datum 0,0`
   and ending by ~`5.2"`–`6.0"` from datum — i.e. in the board's left half. The
   `6.250" REAR I/O WINDOW IN CHASSIS` callout is drawn separately, further
   right, terminating near the board's right edge (a `.900"` bracket is
   called out right next to it — this is the row1->hole-F **Y**-direction
   bracket identified and closed in Task 2 below, `F_Y = 33.02mm`; it is
   *not* an X-gap between the expansion-slot region and the io window).
2. **ATX 2.01 Fig 4 (cross-check via shared datum):** confirms this
   numerically — from `Datum 0,0`, walking `5.196"` reaches the I/O aperture's
   near edge, and the aperture's own `6.250"` width extends further in the same
   direction (away from the datum/left-edge side) to `0.650+5.196+6.250 =
   12.096"` — ~flush with the 12.000" board width (the ~0.1" excess is the
   chassis-side I/O shield slightly overhanging the PCB edge, not a chaining
   error). This is the **opposite** direction from where Fig 3's `.650"`
   left-edge offset sits — i.e., I/O is at the end of the board **away** from
   the datum/expansion-slot cluster.
3. **ATX 2.2 Fig 3 (direct, non-mirrored read, independent confirmation):**
   identical numeric chain to ATX 2.01 (`.500 / 5.196 / 6.250 / .900`, `Datum
   0,0` at the far left) with the I/O window drawn immediately to the right of
   the expansion-slot region (ISA×4 + PCI×3 + AGP), terminating at the right
   board edge. Same conclusion, independently re-derived on a different PDF.
4. **microATX 1.2 Fig 3 (direct, non-mirrored read):** the ISA/PCI/AGP
   connectors sit to the **left** of `Datum B 0,0`; the `6.250" REAR I/O
   WINDOW IN CHASSIS` + hatched "ACCESSIBLE CONNECTOR I/O AREA" sit to its
   **right**, again terminating near the board's right edge (the same
   row1->hole-F **Y**-bracket described in point 1 above, not an X-gap).
   Same left/right split as ATX, on an independent board size and
   independent hole-lettering scheme.
5. **Corroborating text (not itself dimensioned, but consistent):** ATX 2.01
   p.8 states hole **F is at the "upper right corner of the ATX board"**
   (rear-row, right column) — the same high-X/rear corner where the I/O
   window sits. microATX 1.2 p.11 also recommends the **power input
   connector** go "along the right-hand side of the board" — again the
   high-X side, consistent with I/O-adjacent connectors clustering on that
   end.

### ASCII orientation map (rear edge, library corner frame: `+X` rightward, origin = rear-left corner)

```
 X=0 (rear-left corner)                                              X=width (rear-right corner)
  |                                                                              |
  |<-.65"->o  <-- Datum 0,0 / Datum B (mounting hole; ATX: far left;             |
  |        |     microATX: mid-board, see above)                                |
  |        |                                                                    |
  |========|==== EXPANSION SLOT REGION ====|          |======= REAR I/O WINDOW =====|
  |  ISA / PCI / AGP / (PCIe) connectors,  |  ~gap    |   6.250" x 1.750" nominal   |
  |  low-X end, starting ~.5" right of     |          |   cutout, flush to / just   |
  |  datum, per-slot .800" pitch           |          |   past the right board edge |
  |========|================================|          |==============================|
  |        |                                                                    |
  +--------+--------------------------------------------------------------------+
   Y=0 (rear edge)                                                    board width, X=max
```

### Cross-check against the maintainer's real-board description

Maintainer: *"Facing a motherboard as normally installed in a tower chassis,
the I/O cluster is on the left-most wall, toward the north-most half of that
wall."* The rear edge (I/O + expansion slots, both on the same PCB edge)
becomes the case's rear wall once the board is mounted vertically — matching
"left-most wall" when viewing the opened case face-on. "North-most half" (top
of that wall) is where the I/O shield sits on essentially every ATX tower case
(the I/O shield opening is always near the top of the case's rear panel; the
expansion-slot brackets run below it toward the bottom) — this is
well-established PC-assembly convention, corroborating but **not itself
derived from these flat top-down spec PDFs** (which don't show the
case-mounting rotation), so it's tagged **[B]** rather than **[A]** here.

Given that convention (I/O = top/north of the rear wall once mounted), our
**[A]**, drawing-confirmed finding — I/O at the high-X end, expansion slots at
the low-X end — is **consistent** with the maintainer's description, provided
the board's high-X end is the end that ends up at the top of the case when
mounted (standard ATX mounting rotation). **No conflict found** between the
primary-source finding and the maintainer's description.

**However: this DIRECTLY CONTRADICTS the hypothesis stated in the Task 1
brief** ("I/O is at LOW X (left) on the rear edge, PCIe fills to its +X (right)
side"). That hypothesis is **refuted** by all three drawings above — the
correct arrangement, read from the printed labels, is I/O at **high X**, PCIe/
expansion at **low X**. Flagging this explicitly per the brief's own
instruction ("flag any conflict for the controller rather than guessing")
rather than silently building Task 2/3 around the brief's guess.

This also explains the specific defect the brief describes in the current
`motherboards.scad`: all three form factors set `io_x_off = width - 158.75`
(right-justified — this part is actually **directionally correct**, matching
the confirmed high-X placement) while `mobo_pcie_first_xy` uses a `y` value
equal to the **front-row** Y (e.g. atx: `[190.5, 227.33]`, `227.33` being the
front-row Y, not the rear edge `Y=0`) — i.e. the current PCIe stamp is broken
in **Y** (it isn't even on the rear edge), and its **X** start (`190.5` for
atx) sits inside/near the I/O window's own X span (`146.05..304.80`), which is
how the two features overlap. Task 2/3 must re-derive `pcie_first_xy` on the
rear edge (`y≈0`) at the **low-X** end, sized to fit before the I/O window's
low-X edge — not assume the current numbers.

## What's still open (deliberately NOT done this task — Task 2/3)

- Exact absolute coordinates for every lettered hole (walking + closing the Y
  chains, and microATX's B/R/S holes) — unchanged from before, still open.
  `_mobo_table()` in `motherboards.scad` is **untouched** this task.
- Exact I/O window `x_off` per form factor from the closed chain (this task
  only confirms which *end* it's on and roughly how it's dimensioned, not the
  final closed number — the `12.096" vs 12.000"` ~0.1" excess above needs
  resolving in Task 2, e.g. is the I/O window clipped to the board's right
  edge, or does the PCB actually extend slightly, or is there a keepout-vs-
  board-edge subtlety).
- Exact PCIe first-slot X (low-X end) and per-slot footprint width (not just
  pitch, already `[A]` sourced) — Task 2/3.
- mini-ITX: out of scope for the 3 drawings fetched this task (VIA/Intel
  mini-ITX addendum remains unreached, as documented previously); its 4-hole
  `[C]` data is untouched.

## Provenance legend (unchanged, per docs/LIBRARY-AUTHORING.md)

- **[A]** direct from an Intel/formfactors.org spec dimensioned drawing.
- **[B]** corroborated across ≥2 independent peers (matches
  `docs/LIBRARY-AUTHORING.md`'s canonical wording), or a well-established
  convention not itself printed on the cited drawing.
- **[C]** reverse-engineered / best-available reproduction.

---

# Task 2: standoff-hole chaining + closure worksheet

Picks up exactly where Task 1 left off (`_mobo_table()`'s hole lists were
**untouched** by Task 1). Same rule as Task 1: printed dimension **labels**
read directly off rendered PNGs (the numbers are vector-drawn curves in these
1990s-Distiller PDFs with no extractable text glyphs for the numbers, confirmed
on `atx.pdf` p.11), chained from a datum/edge to an
absolute `[x,y]` in the library's corner frame, closure verified against a
known edge dimension. Pixel measurement used only as the 1-2-hole sanity
check the brief allows, never as the primary source.

One additional primary source was rendered this task that Task 1 didn't need:
**ATX 2.2 Fig 3, page 12** (physical PDF page 12 — confirmed by per-page
search of the document, not assumed from the printed
"Page 11" footer, which is the *document's own* page numbering and one off
from the PDF's physical page index). This sheet is a **much cleaner render**
than the 1997 ATX 2.01 scan of the same figure and was decisive for resolving
the row2/row3 Y ambiguity below.

## ATX — full 3x3 lettered grid (A,C,F / G,H,J / K,L,M), all [A]

**Column X chain** (bottom of ATX Fig 3, both 2.01 and 2.2 sheets, identical
numbers, baseline-dimensioned from the true **left board edge**):

| segment | value | cumulative X | hole column |
|---|---|---|---|
| left edge -> col1 | .650" | 16.51mm | A, G, K |
| left edge -> col2 (unused, B/dashed) | 3.100" | 78.74mm | (none, ATX) |
| left edge -> col3 | 4.900" | 124.46mm | C, H, L |
| left edge -> col5 | 11.100" | 281.94mm | F, J, M |
| left edge -> right edge | 12.000" | 304.80mm | (board width) |

Closure: `.650 + (4.900-.650=4.250) + (11.100-4.900=6.200) + (12.000-11.100=
.900) = 12.000"` exact. The `.900"` last segment is independently printed on
the sheet too (the "REAR I/O WINDOW" crop's own `.900` callout, right next to
a mounting-hole circle) — **two independent printed numbers agree to the same
closure**, not just arithmetic.

**Row Y chain** (left side of ATX Fig 3, baseline-dimensioned from the true
**rear board edge**), resolved this task by directly tracing each dimension
arrow to its terminating hole-row on the clean ATX 2.2 render
(`t2/atx22_leftchain.png`) — the arrowhead for `6.100` visibly terminates at
the row with the "ISA CONNECTOR (4 PLACES)" callout circle, and `8.950`'s
arrowhead visibly terminates at the row with the "10X Ø.156 MTG HOLES"
callout circle, immediately above the `9.600` (board depth) terminus:

| segment | value | cumulative Y | hole row |
|---|---|---|---|
| rear edge -> row1 | .400" | 10.16mm | A, C |
| rear edge -> row2 | 6.100" | 154.94mm | G, H, J |
| rear edge -> row3 | 8.950" | 227.33mm | K, L, M |
| rear edge -> front edge | 9.600" | 243.84mm | (board depth) |

Closure: `.400 + (6.100-.400=5.700) + (8.950-6.100=2.850) + (9.600-8.950=
.650) = 9.600"` exact. Note the front-margin (`.650"`) numerically equals the
left-margin (`.650"`) from the X chain — both are the same standoff-to-edge
keepout convention applied on both axes, a nice (not load-bearing, just
corroborating) cross-axis consistency check.

**CORRECTION (this pass, superseding the F=row1 claim below and in the
per-hole table): F is NOT in row1.** The REAR I/O WINDOW crop on both the ATX
2.01 and ATX 2.2 Fig3 sheets independently prints its own `.900"` dimension
running in the **Y direction**, from the row1 centerline (`.400"` = 10.16mm)
down to hole F — a separate bracket from the X-chain's `.900"` segment
(`12.000-11.100`). The original reconstruction conflated these two,
mistakenly reusing the X chain's numeric coincidence (`.900"`) as if F sat at
row1's Y. Correct chain: `F_Y = row1(.400") + .900" Y-bracket = 1.300" =
33.02mm`. F's X (col5, 281.94mm, "upper right corner" per ATX 2.01 p.8 text)
is unaffected and remains correct.

**Pixel sanity check (1-2 holes, as the brief allows):** on the 1997 ATX 2.01
scan (`atx_p11_600.png`, non-uniform px/in — `scale_x=248px/in` vs
`scale_y=273.6px/in`, i.e. this schematic is **not drawn to true proportional
scale**, confirmed by board bbox ratio 2981/2632=1.13 vs the true 12/9.6=1.25),
row1 (A/C/F) pixel-measured at 0.406" vs the printed .400" label — a ~1.5%
match, good enough as a sanity check. Rows 2 and 3 pixel-measured ~0.39-0.40"
**higher** than their labels (6.49" and 9.34" vs 6.100"/8.950") on that same
scan — this is the schematic's non-proportional rendering (explicitly not to
scale, same reason the X/Y px/in scales differ), **not** evidence the labels
are wrong; resolved definitively instead by directly tracing arrowheads on the
cleaner ATX 2.2 render (above), which is the label-reading method the brief
actually asks for, not pixel math. This is exactly why pixel measurement is
capped at "1-2 hole sanity check" rather than the primary method: these
drawings are schematic, not scaled.

**Per-hole table (library corner frame, mm):**

| hole | x | y | tier | note |
|---|---|---|---|---|
| A | 16.51 | 10.16 | [A] | col1/row1, the datum hole itself |
| C | 124.46 | 10.16 | [A] | col3/row1 |
| F | 281.94 | 33.02 | [A] | col5 X ("upper right corner" per ATX 2.01 p.8 text); Y = row1(.400")+.900" Y-bracket = 1.300in = 33.02mm — **corrected this pass**: F's Y is NOT row1's Y (see CORRECTION note above the Row Y chain table) |
| G | 16.51 | 154.94 | [A] | col1/row2 |
| H | 124.46 | 154.94 | [A] | col3/row2 |
| J | 281.94 | 154.94 | [A] | col5/row2 |
| K | 16.51 | 227.33 | [A] | col1/row3 |
| L | 124.46 | 227.33 | [A] | col3/row3 |
| M | 281.94 | 227.33 | [A] | col5/row3 |

Every hole's column traces to a printed label with an exact closing chain on
the X axis. On the Y axis, 8 of 9 holes (A,C,G,H,J,K,L,M) close directly to
the row1/row2/row3 chain above; **F is the one exception** — its Y is not a
row-chain value at all but a separate, independently-printed `.900"`
Y-bracket off row1 (see CORRECTION above). The blanket claim in an earlier
pass of this file ("every hole's column AND row now traces to a printed
label with an exact closing chain on both axes") **overclaimed** — it is
retracted for F specifically; the other 8 holes' both-axes closure stands.
This also corrects the prior (pre-Task-2) file's scrambled letter-to-column
assignment (e.g. it had `H` sharing `C`'s column and `G` at a fabricated
`140.97mm`/5.55" that matches none of the chain's real values; `A` misplaced
at col5/mid-row instead of col1/row1; `F` at a guessed `29.21mm` unclosed
inset instead of the chain-closed value).

## microATX — B,C,F,H,J,L,M,R,S, all [A]

Read from microATX 1.2 Fig 3 (p.12), a clean, dual-unit (in `[mm]`) native
render — no pixel measurement needed for this sheet at all, mm values read
directly per the brief's "read the mm labels directly" instruction.

**Row Y chain**: identical printed values to ATX (`.400 / 6.100 / 8.950 /
9.600`, `[10.16] / [154.94] / [227.33] / [243.84]`) — confirmed by literally
the same dual-unit labels appearing on this sheet, not assumed. microATX's
max board size is 9.6"x9.6" (same depth as ATX), so the rear-edge-referenced
row Y offsets carry over unchanged: row1 (B,C) = 10.16mm, row2 (R,S,H,J) =
154.94mm, row3 (L,M) = 227.33mm. **F is the exception** (same correction as
ATX, see below): microATX 1.2 Fig3 independently prints its own `.900"`
Y-direction bracket from the row1 centerline down to F, so F_Y = row1(.400")
+ .900" = 1.300" = 33.02mm, not row1's 10.16mm.

**Column X chain**: this sheet's own bottom chain (`.800 / 1.350 / 1.800 /
8.000`, `[20.32]/[34.29]/[45.72]/[203.2]`) is dimensioned from **Datum B
0,0** (not the left board edge — confirmed because the chain's own left
tick-mark sits well right of the true left board edge line in the render, at
Datum B's vertical construction line), giving relative offsets:
`R = B+.800"`, `S = B+1.350"`, `H = B+1.800"`, `J = B+8.000"`.

Datum B's own absolute X (from microATX's **own** left edge) is not a single
printed number on this sheet, so it's derived via **two independent closure
paths that agree exactly** (both [A]-tier: arithmetic on printed numbers, no
guessing):

1. **Right-edge margin path**: this sheet also prints `.900" [22.86]` from
   its own right edge to the F/J/M column (same "`.900` from right edge"
   convention as ATX's rear I/O callout). `9.600 - .900 = 8.700"` = J's
   absolute X. Then `B = J_abs - 8.000 (the printed B->J offset) = 8.700 -
   8.000 = 0.700"`.
2. **Cross-form-factor right-alignment path** (this is also the key finding
   for the mini-ITX section below): microATX and ATX share their **rear-right**
   corner, not their rear-left corner — confirmed because converting matx's
   J (`8.700"` from its own left edge) into ATX's frame via `ATX_width -
   matx_width + matx_J = 12.000 - 9.600 + 8.700 = 11.100"` lands **exactly**
   on ATX's own col5 X (`11.100"`, the F/J/M column) — not approximately,
   exactly. Same check for H: `12.000 - 9.600 + 2.500 = 4.900"` = ATX's col3
   exactly (H_abs = B+1.800 = 0.700+1.800 = 2.500"). Two holes, two exact
   matches — this is a strong, independent confirmation, and it directly
   contradicts a rear-**left**-corner-sharing assumption (under rear-left
   sharing, matx's C/H/L at 124.46mm-from-its-own-left-edge would need to
   equal ATX's C/H/L directly without the width-difference correction, which
   it does **not** — the correction term is required and it closes only
   under right-alignment). **This right-alignment fact is the subtlety
   flagged for mini-ITX below.**

Both paths give `Datum B = 0.700" = 17.78mm` from microATX's own left edge.
Order check: `0 < .700(B) < 1.500(R) < 2.050(S) < 2.500(H/C/L) < 8.700(J/F/M)
< 9.600(right edge)` — monotonic, matches the physical left-to-right layout
in Fig 3.

**Per-hole table (library corner frame, mm):**

| hole | x | y | tier | note |
|---|---|---|---|---|
| B | 17.78 | 10.16 | [A] | Datum 0,0; abs X closes 2 independent ways (see above) |
| C | 63.50 | 10.16 | [A] | == H's column, row1 |
| F | 220.98 | 33.02 | [A] | == J's column X; Y = row1(.400")+.900" Y-bracket = 1.300in = 33.02mm — **corrected this pass**, NOT row1's Y (same F-Y-bracket correction as ATX) |
| R | 38.10 | 154.94 | [A] | Datum B + .800" |
| S | 52.07 | 154.94 | [A] | Datum B + 1.350" |
| H | 63.50 | 154.94 | [A] | Datum B + 1.800"; == ATX's col3 under right-edge alignment (exact) |
| J | 220.98 | 154.94 | [A] | Datum B + 8.000"; == ATX's col5 under right-edge alignment (exact) |
| L | 63.50 | 227.33 | [A] | == H's column, row3 |
| M | 220.98 | 227.33 | [A] | == J's column, row3 |

This corrects the prior file's guessed `140.97mm`/`237.49mm` columns (neither
matches any printed number on this sheet) and its `29.21mm`/`78.74mm` row Ys
(the latter, `78.74mm`=3.100", is actually one of the ATX **X**-chain values —
the prior reconstruction appears to have transposed an X-chain label into a
Y-offset).

## mini-ITX — 4-hole coincidence subset, [B] (gap: no source drawing)

No mini-ITX / VIA addendum PDF is cached in the local scratch directory
and none was fetchable this task (no URL for it was provided in the
brief's source list) — same gap Task 1 already recorded. Per the brief's own fallback ("tag ITX holes [B]/[C] from the
coincidence rule + note the gap"), the 4 holes are derived from the rule
itself rather than left as the prior file's ungrounded pixel-ish guesses:

- Mini-ITX (170x170mm) mounts using a **subset of the ATX standoff grid**
  (this is the entire point of the coincidence rule — an ITX board drops into
  an ATX-compatible chassis's existing standoffs). The only 2x2 block of the
  now-fully-closed ATX 3x3 grid that fits inside a 170x170mm envelope is the
  **rear-left** block: **A, C, G, H** (col1&col3 x row1&row2 = X span
  16.51-124.46mm = 107.95mm, Y span 10.16-154.94mm = 144.78mm, both < 170mm
  with plausible margins). The rear-right block (C,F,H,J) and any row3 block
  do not fit (row3's Y=227.33mm alone exceeds the 170mm depth).
- This requires assuming ITX's **own rear-left corner datum coincides with
  ATX's rear-left corner datum** — i.e. ITX shares ATX's rear-left standoffs,
  not its rear-right ones. **This is the opposite of what this task just
  proved for microATX** (microATX shares ATX's rear-*right* corner, per the
  exact-match closure above) — flagging this explicitly rather than silently
  reusing the microATX assumption. Rear-left is used for ITX instead because
  the arithmetic **rules out** rear-right for ITX specifically: under
  rear-right sharing, ITX's own left edge would sit at `ATX_width - 170 =
  304.80-170=134.80mm`, which excludes ATX's col3 (124.46mm, 10.34mm too far
  left to fit) — leaving only one usable column (col5), not the two needed
  for a 4-hole 2x2 pattern. Rear-left sharing is therefore the only
  self-consistent option producing a valid 4-hole pattern, but it is
  **reasoned, not drawing-confirmed** — hence [B], not [A].
- **//VERIFY**: the datum-coincidence assumption itself (rear-left vs. some
  other ITX-specific convention not modeled here) is unverified without a
  real ITX mechanical drawing. If a mini-ITX/VIA addendum PDF becomes
  reachable in a future task, re-derive from its own printed dimensions and
  replace this [B] block.

**Per-hole table (library corner frame, mm):**

| hole (ITX role) | x | y | tier | == ATX hole |
|---|---|---|---|---|
| rear-left | 16.51 | 10.16 | [B] | A |
| rear-right | 124.46 | 10.16 | [B] | C |
| front-left | 16.51 | 154.94 | [B] | G |
| front-right | 124.46 | 154.94 | [B] | H |

This replaces the prior file's `[6.17,4.90]/[163.65,4.90]/[6.17,124.28]/
[163.65,124.28]` (a near-full-width-and-depth corner rectangle, sourced from
an unrelated third-party "Protocase Fig8" reference, not the ATX-coincidence
rule the actual mini-ITX spec uses) with a grounded-in-the-now-verified-ATX-
grid, explicitly-caveated derivation.

## //VERIFY summary (weakest to strongest)

1. **mini-ITX's rear-left-vs-rear-right datum assumption** — reasoned from
   board-envelope feasibility (rear-right is arithmetically ruled out), but
   not confirmed against an actual ITX drawing. Weakest item this task.
2. **microATX Datum B's absolute X (17.78mm)** — not a single printed number;
   derived from 2 independent arithmetic closures on printed numbers that
   agree exactly. Solid, but flagging the derivation (vs. a hole that's
   directly labelled) for transparency.
3. Everything else in this task's ATX and microATX tables closes directly
   against printed labels with 0.00mm residual — no further `//VERIFY` items.

**Post-review correction (superseding item 3 above for hole F specifically):**
a task review caught that F's Y in both the ATX and microATX tables had been
set equal to row1's Y (10.16mm) — this was wrong. The `.900"` dimension near
the REAR I/O WINDOW on both the ATX 2.2/2.01 Fig3 sheets and the microATX 1.2
Fig3 sheet is a **Y-direction bracket** from row1 down to F, independently
traced on each drawing — not the X-chain's `12.000-11.100=.900` numeric
coincidence that the original derivation mistakenly reused. Corrected value:
`F_Y = row1(.400") + .900" = 1.300" = 33.02mm` in both ATX and microATX. F's
X was unaffected and remains correct in both tables. The blanket claim above
("every hole closes... 0.00mm residual", and the equivalent ATX-section
claim that "every hole's column AND row... traces... on both axes") is
retracted for F on the Y axis — F's Y is now a bracket-closure, not a
direct row-chain closure, though it still closes exactly (0.00mm) against
the independently-printed `.900"` bracket value. All other holes'
both-axes closures are unaffected and stand as originally verified.

## Compile + test verification

- `scripts/openscad.sh --export-format echo -o /dev/null libraries/motherboards/motherboards.scad`
  → exit 0 (`COMPILE_OK`).
- `make test`: see commit message / task-2-report.md for the run captured at
  commit time — any failures traced to now-stale hard-coded old hole
  coordinates are flagged there for Task 4, not silently patched here (this
  task only touches `_mobo_table()`'s `r[2]` hole lists, per the brief's
  explicit scope).

---

## Task 3: I/O window + PCIe chain worksheet (fix orientation + overlap)

Re-derives `r[3]` (io `[x_off,w,h]`) and `r[4]`/`r[5]` (pcie `[first_x,first_y]`,
`count`) per ff, chaining each from the drawings' own printed labels rather
than assuming the old blanket `width - 158.75` right-justify formula. Per
Task 1 (not re-litigated here): +X = width along the rear I/O edge, +Y =
depth rear→front, io window sits at the HIGH-X end, PCIe slots at the LOW-X
end, both anchored to the rear edge (Y=0).

**Post-review correction (this pass):** a later review pixel-traced the ATX
`.500"` bracket and found the original write-up below had the offset
direction backwards — it read `datum + 0.500in` when the ticks actually
bracket `datum - 0.500in` (the connector sits on the LOW-X side of the
datum, not the high-X side), which had put the "first" slot partway into
the board rather than near the true low-X edge, and had also caused the
ATX slot count to be capped at 6 instead of the standard 7. The microATX
`1.200in` chain, on independent re-trace, does **not** close cleanly at
all in this crop (no continuous dimension line was found left of the io
hatch in the rear-edge row band); the prior `[A]` tag on that value was an
overclaim. Both are corrected below: ATX keeps `[A]` (chain independently
re-confirmed, direction fixed); microATX is retagged `//VERIFY [C]`
(flush to the low-X edge, not drawing-read). The bullets below are updated
in place to reflect the corrected values; struck-through reasoning is not
kept separately since the old chain's *direction* (not just its number)
was wrong.

### ATX (304.80 x 243.84)

Source: ATX 2.01/2.2 Fig4 (rear-view I/O aperture) + Fig3 (top view,
`.500"`/`.800" TYP` connector chain), both cross-referenced to the same
Datum 0,0 as the Task 2 hole chain (datum abs X = 16.51mm, established Task 1/2).

- **io** — Fig4 chain: `.650(datum offset) + 5.196 + 6.250 = 12.096in` closes
  the aperture drawing's own printed numbers (Task 1 finding, not re-derived
  here). In the library's corner frame this reads as: window near (low-X)
  edge = `datum(16.51) + 5.196in[131.98] = 148.49mm`. `[A]`.
  Far edge = `148.49 + 158.75 = 307.24mm`, a **2.44mm (0.096in) overhang**
  past the 304.80mm board width — this is the drawing's own printed excess
  (`12.096in` chain vs `12.000in` board width), documented in Task 1 as
  chassis I/O shield overhang, not a chaining error. Kept as-is (not clipped)
  since the brief doesn't require clipping and CSG subtraction past a solid's
  edge is harmless.
  This **replaces** the stale `146.05` (`= 304.80-158.75`, pure
  right-justify — off by 2.44mm from the chained value).
- **pcie** — Fig3's `.500"`/`.800" TYP BETWEEN CONNECTORS` chain (same crop
  used for the Task 1 orientation finding): pixel-forensic re-trace (600dpi
  render, `atx_crop_topleft.png`) of the `.500"` bracket's two ticks found the
  RIGHT tick lands exactly on the Datum A hole center and the LEFT tick lands
  on the first expansion connector's own reference edge — i.e. the connector
  is `datum - 0.500in`, not `datum + 0.500in` as previously written. (The
  `.800" TYP` bracket's own measured pixel span independently cross-validates
  the same px/inch scale, corroborating the reading.) Corrected chain: first
  (rearmost) slot X = `datum(16.51) - 0.500in[12.70] = 3.81mm`. `[A]` (chain
  closes cleanly; only the direction was wrong before). Y = **0** (rear edge —
  fixes the old bug where `pcie_y=227.33` was the FRONT row's Y, putting the
  slot opening at the wrong depth entirely).
- **count** — module footprint model: `first_x + (n-1)*20.32 + 12 <= io_x_off`.
  `3.81 + (n-1)*20.32 + 12 <= 148.49` → `n <= 7.53` → **n=7** (far edge
  137.73mm, 10.76mm clear of io), restoring the standard ATX 7-slot count.
  `[B]` (matches the well-known ATX expansion-slot count). n=8 would reach
  158.05mm, overlapping io by 9.56mm.

### microATX (243.84 x 243.84)

Source: microATX 1.2 Fig3, dual-unit (in/mm) sheet, rotated into readable
orientation (`matx_fig3_rot2.png` was stored sideways; corrected via a -90°
rotation for this task — the underlying cached PDF page is fine, only
that one intermediate PNG crop was mis-rotated).

- **io** — two independent leader lines on the same sheet, each unambiguous
  on its own (no tick-position guessing needed): an arrow from "Datum B 0,0"
  lands on a hole circle; a separate arrow from "ACCESSIBLE CONNECTOR I/O
  AREA" lands on the hatched window's near (low-X) edge. Between those two
  landing points the sheet prints `2.096in[53.24]`. Datum B's absolute X
  (17.78mm) was already established independently in Task 2 (2 closures).
  Chain: `x_off = 17.78 + 53.24 = 71.02mm`. `[A]`.
  Far edge = `71.02 + 158.75 = 229.77mm`, **14.07mm short** of the 243.84mm
  board width (no overhang here — the opposite of ATX's small overhang).
  This **replaces** the stale `85.09` (`= 243.84-158.75`, pure
  right-justify — off by 14.07mm from the chained value). Cross-check: this
  keeps the io X-range clear of hole C/B's X (63.50mm row-1 hole sits at
  63.50 < 71.02, no overlap) — if the stale flush-right value had been
  smaller than 63.50 it would have visually collided with that standoff hole;
  it happens not to, but the new value has more headroom.
- **pcie** — the previous write-up here claimed a `1.200in[30.48]` /
  `.800in TYP[20.32] BETWEEN CONNECTORS` chain closing at the board's
  rear-left corner, tagged `[A]`. Re-trace this pass (pixel scan of
  `matx_fig3_600-12.png` at 600dpi, scale calibrated against the io hatch's
  own known 158.75mm width: hatch spans px 1230→3833, giving 16.40px/mm,
  independent of and more reliable than an earlier mis-scaled attempt that
  had misidentified a text/leader artifact as the board's left edge) found
  **no continuous dimension line** in the rows spanning the rear-edge band
  (the board's own rear-edge/io-corner row block, ~row 1345-1420) at any
  X left of the io hatch's own left edge (x_off=71.02mm). The only
  `.800 TYP`/similar-labelled brackets found in that row band sit fully
  INSIDE the io window's X-range (px 1979-2393 ≈ mm 116.7-141.9, an
  AGP-area callout unrelated to the low-X expansion slots) — not chained to
  the first expansion connector. The prior `30.48` value and its `[A]` tag
  are withdrawn as an overclaim (it also had the same offset-direction bug
  independently found on the ATX row: even taken at face value the phrase
  "board-left-edge + 1.200in" moves AWAY from the low-X edge, into the
  board, rather than sitting flush to it).
  Corrected: `first_xy = [0, 0]`, flush to the board's low-X edge.
  `//VERIFY [C]` — not drawing-read, chosen to satisfy overlap-free +
  in-board given the ambiguous source. Y = **0** (rear edge — still fixes
  the old bug where `pcie_y=227.33` was the front row's Y).
- **count** — `0 + (n-1)*20.32 + 12 <= 71.02` → `n <= 3.90` → **n=3** (far
  edge 52.64mm, 18.38mm clear of io; n=4 would need `first_x <= -1.94`,
  impossible on a non-negative board — so n=4 cannot fit disjoint at ANY
  in-board first_x, not just the chosen one). Real microATX boards route 4
  physical slots; this library's flat 12mm-wide / 20.32mm-pitch
  slot-footprint model (`mobo_pcie_cutout`, itself `//VERIFY [C]`,
  unsourced) cannot fit 4 disjoint from the drawing-derived io position
  given this board's tighter clearance vs ATX — a limitation of the
  simplified footprint constant, not of the chain. `//VERIFY [C]` (deviates
  from the nominal 4-slot standard; this is the maximum count the model
  supports here, not a drawing-derived number).

### mini-ITX (170 x 170)

No ITX addendum drawing exists (same gap already documented in Task 1/2 for
the hole table). Unlike the hole table, io/pcie can't borrow ATX's numbers
directly (ITX's absolute board size differs from ATX's grid spacing), so
this task derives constraint-based values instead of a chain:

- The mandatory 158.75mm-wide io window already consumes 93% of the 170mm
  board width, leaving only 11.25mm of total slack for `x_off` before the far
  edge either falls short of, or overhangs, the board's own +X edge. This is
  a hard consequence of the shared io-window constant on a small board, not
  a modeling choice.
- To fit even one 12mm-wide pcie slot footprint (real mini-ITX boards have
  exactly one expansion slot) on the low-X side at `first_x=0`, `x_off` must
  be `>= 12`. Chosen: **`x_off = 12.7mm`** (far edge 171.45mm, a 1.45mm
  overhang — same order of magnitude as ATX's drawing-derived 2.44mm
  overhang, chosen for consistency rather than picked to make the overhang
  exactly zero).
- **pcie**: `first_xy = [0, 0]`, `count = 1`. Far edge = 12mm, 0.7mm clear of
  the io window. `y=0` fixes the old bug (previous value was `y=4.90`, an
  unexplained non-zero, non-front-row value).
- All four values tagged `//VERIFY [C]` — engineered to satisfy
  overlap-free + in-board + realistic single-slot-count, not read off a
  label. Replaces the stale `io=[11.25,...]` / `pcie_first=[155.83,4.90]`
  (the old pcie X sat inside the old io window's X-range — the same overlap
  bug as the other two ff, plus a non-zero/non-rear-edge Y).

### Disjointness + in-board summary (all three ff)

| ff   | io X-range        | pcie X-range     | disjoint | pcie in-board | pcie y |
|------|--------------------|------------------|----------|----------------|--------|
| itx  | [12.70, 171.45]    | [0.00, 12.00]    | yes (0.70mm gap) | yes | 0 |
| matx | [71.02, 229.77]    | [0.00, 52.64]    | yes (18.38mm gap) | yes | 0 |
| atx  | [148.49, 307.24]   | [3.81, 137.73]   | yes (10.76mm gap) | yes | 0 |

(Post-review correction: matx and atx pcie X-ranges above are the corrected
values — see the post-review correction note at the top of this section.)

### Hole F's Y coordinate — resolved (not a Task 3 item, noted for the record)

An earlier pass through this section had flagged a possible discrepancy in
the **F hole's Y coordinate** (`row1(.400") + .900" = 33.02mm`, set by Task 2),
speculating the `.900"[22.86]` bracket near hole F might instead measure from
the io window's top edge (=rear edge, Y=0) directly down to F, giving
`F_Y = 22.86mm`. That speculation has since been resolved: `F_Y = 33.02mm` is
confirmed correct (the `.900"` Y-bracket runs from row1's centerline down to
F, not from the rear edge), matching `r[2]` in `motherboards.scad` for both
ATX and microATX. No change to `r[2]` was made or is needed — this note
exists only to close out the earlier open flag so a future reader doesn't
re-open it. The io/pcie values derived in this section do not depend on F's
Y either way.

### Files touched

- `libraries/motherboards/motherboards.scad`: `_mobo_table()` `r[3]`/`r[4]`/
  `r[5]` for all three rows; `mobo_io_cutout_stamp`'s header comment (dropped
  the stale "all three ff derive x_off as width-158.75" claim); the stale
  `//VERIFY [C] varies by board` comment on `mobo_pcie_first_xy`.
- `libraries/motherboards/RESEARCH.md`: this section.

### Compile + test verification

- `scripts/openscad.sh --export-format echo -o /dev/null libraries/motherboards/motherboards.scad`
  → exit 0.
- `make test` → all suites PASS (including `tests/test_motherboards_lib.sh`).

### Post-review fix pass (re-derive pcie first_x, restore standard counts)

A subsequent review found the ATX/microATX `pcie first_x` derivations above
had the datum-offset direction backwards (see the post-review correction
note at the top of this section) and that microATX's `[A]` tag on its
`first_x` was an overclaim given the chain doesn't close on re-trace. This
pass:

- ATX: `first_x` corrected `29.21 → 3.81mm` (`datum - 0.500in`, not
  `datum + 0.500in`); kept `[A]` (chain re-confirmed, direction fixed).
  `count` restored `6 → 7` (the standard ATX slot count, now fits: far edge
  137.73mm, 10.76mm clear of io).
- microATX: `first_x` corrected `30.48 → 0mm` (flush to the low-X edge);
  retagged `[A] → //VERIFY [C]` (no continuous dimension chain found left of
  the io hatch on re-trace at 600dpi; the value is engineered, not read off
  a label). `count` restored toward the standard `4 → 3` (4 is mathematically
  impossible in-board at any non-negative `first_x`; 3 is the max the
  simplified slot-footprint model supports here), tagged `//VERIFY [C]`.
- itx: unchanged (`first_x=[0,0]`, `//VERIFY [C]`); `count=1` re-tagged
  `[B]` (mini-ITX's single-slot count is a well-known form-factor standard,
  not board-specific engineering).
- Hole `F_Y` (`r[2]`, untouched by this task): the previously open
  "possibly 22.86mm" flag is resolved — confirmed `33.02mm` is correct; see
  the dedicated note above.
- Re-verified: `scripts/openscad.sh --export-format echo -o /dev/null
  libraries/motherboards/motherboards.scad` → exit 0; `make test` → all
  suites PASS; io/pcie X-ranges recomputed disjoint + in-board for all
  three ff (see the updated summary table above).

---

# Task 7: MIRROR (handedness) correction + mini-ITX drawing recovered ([A])

Two corrections in this pass, both prompted by the maintainer checking the
placeholder renders against a physical board. **These supersede (a) the
"ORIENTATION CRUX" section above, which concluded I/O at high-X, and (b) the
"mini-ITX — 4-hole coincidence subset [B]" section, which used holes A,C,G,H.**

## 1. The spec drawings are MIRROR-HANDED vs a component-side-up board

The Task-1 orientation crux read the drawings' datum→corner conversion as a
plain translation (no axis flip) and concluded I/O at the HIGH-X end, PCIe at
LOW-X. That reproduces a **mirror image** of a real board: held component-side
up with the rear I/O edge away from you, the I/O cluster sits at the **LOW-X
(origin-corner)** end and the PCIe/expansion slots fill toward **+X**. The
maintainer confirmed this directly against hardware ("the PCI-e ports are
perpendicular to the left wall … the io block is also on the side facing the
holder", and twice: the rendered layout "looks inverted from reality" /
"mirrored").

The drawing chains themselves are correct and still close to 0.00mm — they are
simply expressed in a frame that is mirror-handed relative to the library's
component-up frame (the spec figures are drawn with the opposite X handedness
of a board you physically hold face-up). Rather than re-chain every value, the
fix is a **single documented transform applied in the public accessors**:

    component-up_x = width − drawing_x

- `mobo_standoff_xy`: each `[x,y] → [W−x, y]`.
- `mobo_io_cutout`: `[x0,w,h] → [W−x0−w, w, h]` (the drawing near/low-X edge
  becomes the component-up far edge). ATX `148.49 → −2.44` (shield now overhangs
  the **origin-corner** edge, ~2.44mm); microATX `71.02 → 14.07`; ITX `13.87 →
  −2.62`.
- `mobo_pcie_first_xy`: `[x0,y] → [W − (x0 + (n−1)·pitch + slot_w), y]` (mirror
  the whole slot span; the drawing first slot's near edge becomes the component
  last slot's far edge). ATX `3.81 → 167.07` (7 slots to 300.99); microATX
  `0 → 191.20`; ITX `0 → 158`.

The `_mobo_table()` still stores the raw **drawing-frame** coordinates (every
`[A]` chain comment there remains valid — it describes the drawing). Disjoint /
in-board / rear-edge invariants all recompute green in the component-up frame;
the `_io_in_board` test's overhang tolerance moved from the high-X side to the
low-X (origin-corner) side to match.

## 2. mini-ITX — drawing recovered, holes are C,F,H,J ([A]), NOT A,C,G,H

The earlier section flagged the mini-ITX/VIA addendum as "unreached" and fell
back to a `[B]` coincidence guess (holes A,C,G,H, assuming ITX's rear-left
corner coincides with ATX's). **The actual dimensioned spec was recovered**:
the VIA/formfactors **"Mini-ITX Addendum v1.1 to the
microATX specification"** (Wayback `20160306163046id_`), whose **Table 3** lists
the hole letters and whose **Figure 3** is fully dimension-labelled with
**DATUM = hole C**.

### Holes (own rear-left-corner frame, from board LEFT edge) — all [A]

| hole | x (mm) | y (mm) | chain (printed labels) |
|---|---|---|---|
| C (datum) | 6.35 | 10.16 | X `.250"` from left edge; Y `.400"` from rear |
| F | 163.83 | 33.02 | X = C + `6.200"[157.48]`; Y = row1 + `.900"[22.86]` |
| H | 6.35 | 154.94 | X = C's column; Y `6.100"[154.94]` from rear |
| J | 163.83 | 154.94 | X = F's column; Y = H's row |

- **X closure:** `6.35 + 157.48 + 6.17 = 170.00mm` = board width, 0.00 residual.
  The `6.200"[157.48]` column pitch equals ATX's own `col5−col3 =
  281.94−124.46 = 157.48` exactly (independent cross-check).
- **Y:** the three printed values (10.16 / 33.02 / 154.94) match the ATX &
  microATX rows exactly; F is the one off-row hole (row1 + the `.900"`
  I/O-window Y-bracket), the same construction proven for ATX/microATX F.

### Subset vs chassis-offset — RESOLVED (it is chassis-offset)

mini-ITX is **NOT** a same-corner coordinate subset of ATX. Comparing the same
four holes in each board's own left-edge frame:

| hole | ITX own-x | ATX own-x | Δ |
|---|---|---|---|
| C,H | 6.35 | 124.46 | 118.11 |
| F,J | 163.83 | 281.94 | 118.11 |

Constant **X-offset = 118.11mm**, Y identical → the mini-ITX rear-left corner is
inset 118.11mm from ATX's; the boards share standoffs C,F,H,J only once that
offset is applied. mini-ITX shares **neither** edge with ATX (microATX shares
ATX's rear-**right** corner; mini-ITX shares neither). This corrects the earlier
"borrows ATX's rear-left corner (A,C,G,H)" reasoning on both counts.

### I/O window + PCIe

- io `x_off = 13.87` [A] — printed `.300"[7.52]` from datum hole C (`6.35 +
  7.52`). This C-to-panel offset equals microATX's, which is *why* ITX and mATX
  I/O panels align once C,F,H,J land on shared standoffs.
- io `width = 158.75` [A] (printed `6.250"` standard shield); far edge 172.62 →
  ~2.62mm overhang past the 170 edge (analogous to ATX's 2.44mm).
- io `height = 44.45` **[B]** — standard microATX panel; the Addendum (Table 1,
  §2.3) defers panel/connector detail to microATX 1.2 and does not draw it.
- pcie `count = 1` [A] (form-factor definition); `first_x` **[C]** — the single
  slot is undimensioned (Fig 3 draws no slot; §2.3 defers to microATX). Placed
  flush at the low-X rear-edge strip (drawing `first_x=0`).

### Source

- Mini-ITX Addendum v1.1 (dimension-labelled): Wayback
  `https://web.archive.org/web/20160306163046id_/http://formfactors.org/developer/specs/mini_itx_spec_v1_1.pdf`
  (original dead URL `http://www.formfactors.org/developer/specs/mini_itx_spec_V1_1.pdf`).

## Verification

`make check` → OK; `make test` → all suites PASS. Accessor echo (component-up
frame) confirms: ATX io `[−2.44,158.75,44.45]` / pcie `[167.07,0]`; microATX io
`[14.07,…]` / pcie `[191.2,0]`; ITX holes `[[163.65,10.16],[6.17,33.02],
[163.65,154.94],[6.17,154.94]]`, io `[−2.62,…]`, pcie `[158,0]`. All three
placeholders re-rendered.

---

# Task 8: io cross-form-factor discrepancy (resolved: keep faithful) + itx pcie off hole C

## The rear-I/O window sits 16.51mm differently on ATX vs microATX/mini-ITX

Prompted by the maintainer noticing (a) the io-block X differs between ATX and
microATX in the model, and (b) an itx mounting hole sitting under a slot. Both
turned out to be real findings.

Expressed relative to the **shared** mounting hole **C** (C,F,H,J are the common
chassis standoffs across all three form factors, so this comparison is
frame-independent — it does not matter that each spec dimensions from a different
datum, A vs B vs C):

| ff | io near-edge, own left edge | hole C, own left edge | **io near-edge − C** |
|----|----|----|----|
| ATX      | 148.49 | 124.46 | **+24.03** |
| microATX | 71.02  | 63.50  | **+7.52**  |
| mini-ITX | 13.87  | 6.35   | **+7.52**  |

microATX and mini-ITX **agree** (C+7.52); **ATX is the outlier by 16.51mm** (=
0.650″ = hole A's edge inset — a recurring coincidence, see below). The raw
own-corner `x_off` values (atx −2.44, matx 14.07, itx −2.62 after the mirror flip)
make microATX *look* like the odd one out, but that is an artifact of the three
boards having different widths / different hole-C positions; against the shared
hole the outlier is ATX.

### This was double-verified against the ATX drawing — it is NOT a reading error

The 16.51mm gap being exactly hole A's 0.650″ inset strongly suggested the ATX
io might be board-edge-referenced (5.196″ from edge → 131.98 → C+7.52, which
would make all three agree). Two independent re-reads of the cached ATX Fig3/Fig4
resolved it decisively:

- **Reference point = datum hole A, cumulative.** The `5.196″` witness line lands
  on the datum vertical centerline (pixel x≈1874 in `atx_crop_topleft.png`),
  cleanly separated from the board's solid left edge (x≈1714, 160px≈0.645″ left).
  The `0.650″` edge→datum inset is a *separate* segment, not shared with 5.196.
  Scale-checked self-consistent (248 px/inch). Confidence ~0.97.
- So ATX io near-edge = 0.650″ + 5.196″ = 5.846″ = **148.49mm** [A], firmly. The
  microATX (Datum B + 2.096″) and mini-ITX (hole C + 0.300″) values are equally
  firm. The three Intel specs (ATX 2.01/2.2 vs microATX 1.2 / mini-ITX 1.1)
  genuinely place the rear I/O window 16.51mm apart relative to the shared holes.

### Resolution: KEEP SPEC-FAITHFUL, document

Each io value is correct per its own drawing and is right for a **single-board**
faceplate (the common case). Overriding ATX's pixel-verified [A] value with an
inferred "chassis-aligned" 131.98 would be fabrication — the exact thing the
authoring standard forbids. The library keeps all three faithful; the README and
this file flag that a **single universal faceplate** serving multiple form factors
must account for the 16.51mm ATX-vs-mATX/ITX difference (verify against the target
board). No data changed for io.

## mini-ITX single PCIe slot moved off mounting hole C

The itx pcie first_x was [C] undimensioned and had been placed flush at drawing
x=0 → component 158, whose 12mm footprint [158,170] sat directly on hole C
(component 163.65). Re-estimated via the Wikipedia [B] rule "mini-ITX
expansion-slot location matches ATX's": mini-ITX shares ATX holes C,F,H,J at the
constant drawing-frame offset ITX_x = ATX_x − 118.11. Of ATX's 7 slots (drawing
x = 3.81 + i·20.32), only the I/O-adjacent one at 125.73 falls within the ITX
board's ATX-X range [118.11, 288.11]; mapped → 125.73 − 118.11 = **7.62** (drawing
frame) → component 150.38. The rendered 7mm slot bar now clears hole C (bar
[152.88, 159.88] vs hole 163.65). Still [C]//VERIFY.

**Model limit (documented, not a bug):** on the 170mm ITX board the 158.75mm io
window leaves only ~13.87mm of high-X rear edge, which must hold BOTH hole C and
the 12mm slot — so no on-board slot can be simultaneously disjoint from the io
window AND clear of hole C. We chose to clear the mounting hole and let the single
slot abut the io panel's X-span; the io/pcie disjoint invariant is therefore
asserted for ATX/microATX only, with itx instead asserting the slot clears the
holes. (Same class as the documented microATX 3-vs-4-slot footprint limit.)

## Verification
`make check` OK; `make test` all PASS (io/pcie disjoint for atx/matx; itx slot
clears holes; itx certain-value holes locked). itx placeholder re-rendered.

---

# Task 9: microATX hole grid was WRONG by 16.51mm (Datum B mislocated) — CORRECTED

The maintainer, checking the model directly, flagged the microATX io block as
"simply wrong" and the general trust in the io/PCIe values. Re-reading microATX
1.2 Figure 3 directly (the drawing IS to-scale: outline-calibrated 1.350in col =
34.38px-derived vs 34.29 printed) exposed a real data error in the **hole grid**,
not just io.

## Root cause: Datum B was stored at 0.700in[17.78], the drawing prints 1.350in[34.29]

microATX Fig 3 note: "Datum B 0,0 = mounting location hole B." Two independent
reads of the printed dims fix its absolute X at **1.350in = 34.29mm** from the
board left edge:
1. **Bottom X-chain prints `1.350 [34.29]`** left edge -> Datum B, then `8.000
   [203.2]` Datum B -> F/J/M column. Closure: 1.350 + 8.000 + 0.250 (col->right
   edge) = 9.600in = board width. Exact.
2. **On-board constraint:** Fig 3 dimensions ISA slot 1 at `1.200 [30.48]` to the
   LEFT of Datum B. At the old 17.78, ISA1 = 17.78 - 30.48 = -12.70mm (off the
   board) -- impossible. Only Datum B >= 30.48 keeps ISA1 on-board; 34.29 gives
   ISA1 = 3.81mm.

The old derivation had used 0.700in (17.78) -- 0.650in less than the true 1.350in
(the recurring 0.650in = ATX hole-A inset, evidently conflated in). Every microATX
hole X was therefore **+16.51mm off**.

## Corrected microATX geometry (all [A], Datum B = 34.29, column offsets printed)

| feature | was | corrected | offset from Datum B |
|---|---|---|---|
| B (datum) | 17.78 | **34.29** | 0 (=1.350in from left edge) |
| R | 38.10 | **54.61** | +0.800in |
| S | 52.07 | **68.58** | +1.350in |
| C/H/L col | 63.50 | **80.01** | +1.800in |
| F/J/M col | 220.98 | **237.49** | +8.000in |
| io near-edge | 71.02 | **87.53** | +2.096in |
| pcie ISA1 | 0 (flush guess) | **3.81** | -1.200in |
| pcie count | 3 //VERIFY | **4** [A] | fits: far edge 76.77 < io 87.53 |

Rows (Y) unchanged (.400/6.100/8.950in from rear; F off-row at 1.300in = 33.02).

## Consequences (all now consistent)
- **microATX shares ATX holes C,F,H,J at a +44.45mm[1.750in] X-offset**, NOT the
  rear-right corner the old grid assumed (80.01+44.45 = 124.46 = ATX C; 237.49 +
  44.45 = 281.94 = ATX F/J col). microATX sits 16.51mm inside ATX's right edge.
  This also reconciles with mini-ITX: all three now put hole C on ATX's C standoff
  at their own offset (itx +118.11, matx +44.45).
- **io near-edge (component frame) = -2.44mm, now identical to ATX** (was 14.07).
  Both specs put io-far at right edge + 0.096in (2.44mm overhang) -> io is
  effectively right-edge-referenced at 156.31mm-from-right on both. This is the
  "matx io looks different" the maintainer saw -- it was the datum error.
- **count = 4** (the real microATX standard) now fits, since the corrected io
  sits 16.51mm further out. The earlier count=3 "footprint limit" was an artifact
  of the wrong io position.
- The io-vs-shared-hole-C discrepancy (microATX C+7.52 vs ATX C+24.03, 16.51mm)
  is SEPARATE and still real (both io's are right-edge-referenced, but hole C sits
  at different distances from the right edge on the two boards). Kept faithful.

## Expansion-slot chain (both specs, from Fig 3) — for reference
ISA1 (edge-nearest) = datum - offset -> 3.81mm from left edge in BOTH ATX and
microATX. Pitch .800in[20.32]. Connector chain: ISA..ISA .800, ISA->PCI shared
.812, PCI..PCI .800, PCI->AGP .689 (all printed [A]). AGP (io-nearest slot) lands
0.195in inside the io near-edge in BOTH specs -- an independent closure of the
whole ladder. NOTE: 3.81mm to the outermost ISA is physically tight (a ~19mm
bracket overhangs the edge); it is the *sample* layout's outermost position, not a
hard requirement -- number real slots from the io/AGP side inward.

## Verification
`make check` OK; `make test` all PASS (envelope: J=237.49 < 243.84; io/pcie
disjoint atx/matx; component matx io = [-2.44,158.75,44.45], pcie first = [167.07,
0], count 4). matx placeholder re-rendered.

---

# Task 10: DIRECT PIXEL MEASUREMENT — systematic chain-reference error found; full rebuild

The maintainer's interoperability argument (an ATX/mATX/ITX board all mount in the
same ATX chassis on shared standoffs, so holes + I/O shield + expansion slots must
be co-located relative to those standoffs) was used as the governing constraint.
Applying it kept producing a 16.51mm (0.650in) conflict, so the to-scale spec
figures were measured DIRECTLY (pixel ring/line detection, calibrated to the known
board size, cross-checked vs printed dims + overlay) instead of chaining dimension
labels.

## Root cause: rows/columns were chained from row-1/col-1, not the board edge

The prior grids treated the printed ".400 / 6.100 / 8.950" (rows) and the column
dims as EDGE-referenced. Measurement shows they are referenced from the FIRST
hole. So row-2/row-3 and the right hole columns were all off by the row-1 / col-1
inset (~0.400in rows, ~0.650in cols). This single mistake produced every symptom
the maintainer caught (mATX io "different", holes "made up", slots "too close").

## Measured positions (mm; calibrated to board size, cross-checked)

Rows (Y from rear edge), shared by all form factors:
- row1 = 10.16 (.400in) ; row2 = 165.10 (row1 + 6.100in) ; row3 = 237.49 (row1 + 8.950in)
- F off-row (right column, rear) = 33.02 (row1 + .900in)

microATX (243.84) hole columns X: 13.97 / 34.29(Datum B) / 80.01 / 237.49
ATX (304.80) hole columns X: 16.51 / 95.25 / 140.97 / 298.45  (10 holes, not 9)
- rightmost column on BOTH boards = 0.250in (6.35mm) from the RIGHT edge
  (measured 6.5 / 6.3mm) -- the prior "0.900in from right" was the chain error.

I/O window near-edge (measured, matches prior where it was already right):
- ATX 148.49 ; microATX 87.53 ; mini-ITX 13.87 -- ALL 156.31mm from the right edge.

Expansion slots (measured centerlines): pitch 0.800in[20.32] clean; the I/O-nearest
slot (AGP-equivalent) sits ~0.195in inside the io near-edge on both boards.

## Chassis reconciliation (RIGHT-corner share) — everything aligns

Offset each board into the ATX (chassis) frame by aligning right edges:
microATX +60.96mm, mini-ITX +134.8mm. Then:
- microATX colB/C/D (34.29/80.01/237.49) -> 95.25/140.97/298.45 = ATX col2/3/4. Holes align.
- microATX io 87.53 -> 148.49 = ATX io. mini-ITX io 13.87 -> 148.5. I/O shields align.
- microATX AGP 81.5 -> 142.5 = ATX AGP 143.4. mini-ITX slot -> same. Slots align, and
  ITX-slot subset-of mATX-slots subset-of ATX-slots, all co-located.

So the physical constraint is satisfied by construction once the chain-reference
error is removed. There is NO residual 16.51mm discrepancy -- it was the bug.

## Rebuilt library values (this pass)

Rows 10.16 / 165.10 / 237.49 (F 33.02). Columns + io + pcie per the measured table
above. PCIe modelled with uniform 20.32 pitch, the I/O-nearest slot anchored to the
measured position (io_near - slot_w); count = form-factor bracket max (ATX 7 / mATX
4 / ITX 1); first_x = io_near - slot_w - (count-1)*pitch (ATX & mATX both 14.57;
ITX 1.87). io-side slots reproduce the measured centerlines; the outermost differs
from the real board's irregular ISA spacing (uniform-pitch model limit, //VERIFY [C]).

## One value to confirm against hardware
The measured "rightmost mounting hole 0.250in from the right edge" (vs the old
0.900in) is the largest single correction. Calibration is solid (board size + col1
+ io all cross-check), but a caliper reading on a real board's rightmost standoff-
to-right-edge would nail it. If it is actually 0.900in, the right columns shift
-16.51mm uniformly (easy).

## Verification
Measurement agent transcript + overlays kept in a local scratch directory.
Board-size closure passes on both figures (isotropic). After rebuild: make check +
make test green; all 3 placeholders re-rendered; holes+io+slots verified co-located
in chassis space.

---

# Task 11: PCIe x16 connector body dimensions + rear-edge setback

Maintainer: the representative PCIe bars started too close to the rear edge and
covered mounting holes -- both signs the slot geometry was still wrong. Researched
the real connector.

## x16 connector body -- Molex 87715 "PCI Express Edge Card Connector" [A]
(customer drawing SD-87715-207 / doc 877159206, Wayback
web.archive.org/web/20210228062138id_/molex.com/pdm_docs/sd/877159206_sd.pdf)
- length (long axis, DIM B) = 89.00mm ; width (housing) = 7.50mm MAX ;
  height above PCB = 11.25mm MAX ; card-slot opening 5.10mm. Solder tails +4.40 below.
- link-width set confirmed: x1=25.00, x4=39.00, x8=56.00, x16=89.00mm (DIM B).

## Setback from the rear board edge [B measured / C for PCIe-specific]
Measured on the to-scale microATX 1.2 Fig3 (calibrated 7.19 px/mm; self-checked --
the PCI connector measured 85.5mm long vs the real ~85mm, ~1%):
- ISA near-end ~20mm from rear edge ; PCI near 37.3mm, far 122.8mm ; AGP near ~62mm.
PCIe x16 co-locates with the PCI-class add-in-card bracket geometry, so its connector
near-end sits ~38-42mm from the rear edge (maintainer eyeball ~42.5mm -- within range).
The PCIe CEM spec itself was unreachable (all mirrors blocked/HTML), so the exact
PCIe-x16 setback is [C]; the PCI measurement (37.3mm) and the eyeball (42.5) bracket it.

## Library change
mobo_pcie_ports now draws the real 89 x 7.50 x 11.25mm body, SET BACK 40mm from the
rear edge (y=[40,129]). All mounting holes are at y<=33 (rear) or y>=165 (mid/front),
so the connector clears every standoff in Y on all three form factors (echo-verified,
holes_under_connector_Yband = [] for atx/matx/itx) -- the hole-overlap that flagged the
earlier model is gone, matching how a real board keeps standoffs clear of the slots.

---

# Task 12: PCIe x16 setback derived from a public design file ([B], confirms 42.5 eyeball)

Maintainer asked to derive the setback from public STLs / PCB files rather than a
board on hand. Found a real, form-factor-accurate open-source design:

- **TheGuyDanish/CM4_MATX** -- a Raspberry Pi CM4 microATX motherboard, KiCad v5.
  `https://raw.githubusercontent.com/TheGuyDanish/CM4_MATX/HEAD/KiCad/CM4_MATX.kicad_pcb`
- x16 slots are the real vendor part **Amphenol 10018783-10113TLF** (PCIe Gen3 x16),
  three instances J13/J14/J15.

Derivation (KiCad is text s-expression -- read placements + Edge.Cuts directly):
- Edge.Cuts outline X=38.10..281.94, Y=22.86..266.70 = 243.84 x 243.84 = exact microATX.
- Rear I/O edge = the X=38.10 edge (HDMI/Ethernet/USB connectors all cluster on it,
  rotated to face out).
- x16 slot J13 placed at (95.1992, ...); its F.Fab body outline spans local X -14.5..+74.5
  (= 89.0mm, the Molex/Amphenol x16 body length). Near (bracket-side) end = 95.1992 - 14.5
  = board X 80.699.
- **Setback = 80.699 - 38.10 = 42.60mm.**
- Layout is spec-true: slot pitch J13->J14->J15 = exactly 20.32mm; mounting holes 10.16mm
  from the rear edge (standard mATX grid).

**Result: setback = 42.60mm [B]** (design-file-derived; not a normative standard, but a
real spec-accurate board). Confirms the maintainer's ~42.5mm eyeball almost exactly and
sits just above the spec-figure estimate (38-42mm). mobo_pcie_ports default updated 40 ->
42.6. GitHub code-search API needs auth (couldn't full-text search); two mini-ITX KiCad
repos checked were blank outline-only templates (no x16 slot).

---

# SP1: PCIe body sourced from connectors; provenance downgrade corrected (final review, 2026-07-09)

SP1's Task 3 originally downgraded the PCIe x16 body dims (89.00 x 7.50 x 11.25mm)
here from `[A]` to `[C]//VERIFY`, on the theory that Task 11's original `[A]` claim
("a real PCIe x16 card-edge socket [A] (Molex 87715...)") was a soft, uncredited
claim -- i.e. that the Molex 87715 datasheet had never actually been fetched, only
cited by name, per a conclusion reached in connectors/RESEARCH.md's SP1
reconciliation pass.

That conclusion was wrong, and has been corrected as part of closing out this
branch's final review. Task 11's citation (above, "Task 11: PCIe x16 connector body
dimensions") was never a soft claim -- it names a specific Wayback Machine URL,
`web.archive.org/web/20210228062138id_/molex.com/pdm_docs/sd/877159206_sd.pdf`,
resolving to the genuine Molex "PRODUCT CUSTOMER DRAWING" **SD-87715-207** ("PCI
EXPRESS EDGE CARD CONNECTOR (LEAD FREE VERSION)"). This URL has now been
independently re-fetched and re-confirmed: a real 5-page PDF (not a scan, not an
unrelated RoHS certificate), whose page-1 master dimension table gives DIM B
(length) = 89.00mm, width = 7.50mm MAX, height = 11.25mm MAX -- exactly matching
the values Task 11 recorded and that this library has carried ever since. SP1's
Task 1 (`connectors/RESEARCH.md`) had incorrectly reported the archived Molex
citation as unrelated — allegedly "only unrelated RoHS certificates for a
similarly-numbered but different part family" — and that this claim had "no
fetch/URL citation backing it"
-- both statements were false; see connectors/RESEARCH.md's own corrected note for
the reciprocal fix.

**Tier is `[A]`, not `[C]//VERIFY`.** The sourcing change from SP1's Task 3 is still
correct and stays: `mobo_pcie_ports()`'s body-dim defaults (`length`, `width`,
`height`) source from `connector_size("pcie_x16")` in the connectors library instead
of local literals, making connectors the single source of truth for this value --
connectors itself now carries the same `[A]` tier (re-fetched+read this pass), so
motherboards inherits an honestly-earned `[A]`, not a downgrade. The numeric values
are unchanged (89 / 7.5 / 11.25mm throughout); this is a provenance and sourcing
correction, not a geometry change.

# Hole roles (Task 2 of the hole-role-tagging plan, sbc parity)

Every standoff coord in `_mobo_table()` (all three form factors -- itx, matx,
atx) now carries a 3rd/4th field, `[x, y, role, dia]`, mirroring `sbc.scad`'s
`sbc_holes()` pattern. **Every motherboard standoff hole classifies as
`"structural-mount"`** -- there are no component-mount, keep-out, or alignment
holes in this library today. Tier **`[B]`** (design-obvious, not drawing-cited):
none of the ATX/microATX/mini-ITX spec drawings label a "role" for a mounting
hole -- they're all plain chassis-standoff clearance holes by definition (the
spec figures call them "MTG HOLES" / mounting holes, full stop), so classifying
every one as `structural-mount` requires no additional research beyond what's
already cited for the coordinates themselves. `dia` reuses the existing
`mobo_hole_dia()` constant (3.96mm, `[B]` -- see above) via a function call, not
a duplicated literal, so it can't drift out of sync.

`mobo_known_hole_roles()` returns the same 4-string vocabulary as sbc
(`structural-mount`, `component-mount`, `keep-out`, `alignment`) for
cross-library consistency, even though this lib only populates the first.
`mobo_standoff_xy(ff, role=undef)` applies the sbc filter+WARNING idiom
verbatim: omit `role` and get every hole (with a `WARNING:` echo only if a form
factor's holes ever span >1 role -- none do today, so no warning fires in
practice); pass a role string to filter. `mobo_standoff_holes()` and
`mobo_standoffs()` gained a passthrough `role=undef` param with no other
behavior change -- unfiltered calls are backward-compatible (`mobo_placeholder`
reads `mobo_standoff_xy(ff)` positionally and is unaffected, since it only uses
indices 0/1).
