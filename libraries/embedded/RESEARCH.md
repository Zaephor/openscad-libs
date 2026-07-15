# embedded — reconstruction worksheet (Task 1: ESP32/ESP8266 devkit mechanicals)

Board outline, corner radius, PCB thickness, mounting-hole geometry (or its
documented absence), and connector positions/types for five common Espressif /
ESP8266 development boards. This worksheet is the tiered provenance record that
later tasks (data table + geometry) transcribe. Schema mirrors the `sbc`
library exactly.

## Coordinate frame (mirrors `sbc`)

Origin at the **bottom-left PCB corner**, component/top side up. `+X` = board
**long** edge, `+Y` = board **short** edge, PCB bottom at `Z=0`. Connector
`edge` values: `xmin`/`xmax`/`ymin`/`ymax` (opening faces out a lateral edge)
or `top` (opening faces `+Z`, off the PCB top face — used for the pin headers,
same as `sbc`'s GPIO header).

**Board-specific convention adopted here** (Task 2 owns the final datum, but
this worksheet describes every board in these terms so the tables are
unambiguous): every board in this set is a "stick" board — a single USB
connector on **one short edge**, the RF module + PCB-antenna keep-out on the
**opposite short edge**, and two single-row 2.54 mm pin headers running down
the two **long edges**. This worksheet places the **USB end at `xmin` (X=0)**
and the **module/antenna end at `xmax` (X = length)**. The two pin-header rows
sit just inside the long edges (`Y≈0` row and `Y≈W` row) and open `+Z`, so
both are `edge="top"` (never a lateral edge — like `sbc`'s `gpio`).

## Provenance tiers

- `[A]` — a vendor mechanical drawing / datasheet with the exact dimension read
  directly off it this pass.
- `[B]` — corroborated across ≥2 independent peers.
- `[C]` — single community source or derived.
- `//VERIFY` — weak/unconfirmed; re-check against a physical board or a stronger
  source before trusting for a tight-tolerance fit.

## Sources (primary)

Official Espressif dimension drawings (vector PDF — the drawing's dimension
callouts are vector-drawn and read directly off the printed "Unit: mm" figures):

- ESP32-DevKitC V4 dimensions — `esp32_devkitc_v4_dimensions.pdf`
  (`https://dl.espressif.com/dl/schematics/esp32_devkitc_v4_dimensions.pdf`).
  [A] board outline, module outline, RF-antenna keep-out, pin pitch.
- ESP32-S3-DevKitC-1 v1.1 dimensions — `DXF_ESP32-S3-DevKitC-1_V1.1_20220429.pdf`
  (`https://dl.espressif.com/dl/schematics/esp_idf/DXF_ESP32-S3-DevKitC-1_V1.1_20220429.pdf`;
  title block reads "ESP32-S3-DevKitC-1 Rev 1.1, 2022.04.29"). [A].
- ESP32-C3-DevKitM-1 dimensions — `DIMENSION_ESP32-C3-DEVKITM-1_V1_20200915AA.pdf`
  (`https://dl.espressif.com/dl/schematics/DIMENSION_ESP32-C3-DEVKITM-1_V1_20200915AA.pdf`).
  [A].
- LOLIN (WEMOS) D1 mini **V4.0.0** dimension drawing — `dim_d1_mini_v4.0.0.pdf`
  (`https://www.wemos.cc/en/latest/_static/files/dim_d1_mini_v4.0.0.pdf`). [A]
  board outline, mounting-hole diameter ("2.0000 mm") + X-positions, 0.9″ row
  pitch. Corner radius is NOT a printed callout on this drawing (see detail).

Module datasheets (dimension read from the "Physical Dimensions" table):

- ESP-WROOM-32 — `(18.00±0.10) × (25.50±0.10) × (3.10±0.10) mm` [A]
  (`https://www.espressif.com/sites/default/files/documentation/esp32-wroom-32_datasheet_en.pdf`).
- ESP32-S3-WROOM-1 — `18 × 25.5 × 3.1 mm` [A]
  (`https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf`).
- ESP32-C3-MINI-1 — `13.2 × 16.6 × 2.4 mm` [A]
  (`https://www.espressif.com/sites/default/files/documentation/esp32-c3-mini-1_datasheet_en.pdf`).

Espressif user guides (connector-type / USB-count text):

- ESP32-DevKitC V4:
  `https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32/esp32-devkitc/user_guide.html`
- ESP32-S3-DevKitC-1 v1.1:
  `https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32s3/esp32-s3-devkitc-1/user_guide_v1.1.html`
- ESP32-C3-DevKitM-1:
  `https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32c3/esp32-c3-devkitm-1/user_guide.html`
- LOLIN D1 mini: `https://www.wemos.cc/en/latest/d1/d1_mini.html`

ESP8266 NodeMCU v1.0 (a community reference design — no single-vendor mechanical
drawing; dimensions are multi-peer `[B]`):

- `https://www.etechnophiles.com/nodemcu-esp8266-pinout-specs-board-layout/`
  ("Amica 49 × 26 mm, 0.9″ rows; LoLin 58 × 32 mm, 1.1″ rows")
- `https://components101.com/development-boards/nodemcu-esp8266-pinout-features-and-datasheet`
- NodeMCU DevKit v1.0 open-hardware repo: `https://github.com/nodemcu/nodemcu-devkit-v1.0`

## Variant / consolidation decisions

- **`esp32_devkitc`** = ESP32-DevKitC **V4** with the **ESP32-WROOM-32** module
  (38-pin, PCB antenna). The Espressif "getting started" prose quotes 54.4 mm
  length, but that figure is for the longer WROVER/32U module fitted; the **V4
  dimension drawing for the WROOM-32 board reads 48.26 mm** — using the drawing
  value.
- **`esp8266_nodemcu`** = NodeMCU **v1.0 (ESP-12E)**, **Amica ("narrow", 0.9″
  rows)** variant — the dominant/canonical v1.0 form factor. The **LoLin
  ("wide", 1.1″ rows, 58 × 32 mm)** board is a distinct, larger variant and is
  **not** the row modeled here (noted so a future task can add it if wanted).
- **`wemos_d1_mini`** = LOLIN (WEMOS) D1 mini **V4.0.0** (the current revision).
  V4.0.0 switched to **USB-C** and — unlike every earlier D1 mini and unlike the
  older "no mounting holes" community lore — **added two mounting holes** (see
  below). Earlier D1 mini revisions were micro-USB and hole-less; this row is
  explicitly the V4.0.0.
- **C3 / S3 consolidation — NOT consolidated.** The brief allowed collapsing the
  C3 and S3 devkits if one canonical board dominated. It does not: the two have
  **separate official Espressif dimension drawings with materially different
  outlines** — C3-DevKitM-1 is **38.91 × 25.40 mm** (small, ESP32-C3-MINI-1
  module, single micro-USB) and S3-DevKitC-1 is **62.74 × 25.40 mm** (long,
  ESP32-S3-WROOM-1 module, **two** USB ports). They share only the 25.40 mm
  width. Kept as **two independent rows**: `esp32_c3_devkitm` and
  `esp32_s3_devkitc`.

## Per-board summary table

Outline is `[length(X), width(Y)]` mm. "Holes" = mounting holes only (pin-header
holes are not mounting holes). All five boards carry the RF module + PCB-antenna
keep-out on the short edge opposite the USB.

| board | outline L×W (mm) | corner_r | thickness | mounting holes | USB | module |
|---|---|---|---|---|---|---|
| `esp32_devkitc`    | 48.26 × 27.94 [A] | ~0 square [A] | 1.6 [C]//VERIFY | **none** [A] | 1× micro-USB, `xmin` [A] | ESP-WROOM-32 (18×25.5) [A] |
| `esp8266_nodemcu`  | 49 × 26 [B]//VERIFY | ~0.5–1 [C]//VERIFY | 1.6 [C]//VERIFY | **none** [B] | 1× micro-USB, `xmin` [B] | ESP-12E (16×24) [B] |
| `wemos_d1_mini`    | 34.3 × 25.4 [A] | ~4.0 [C]//VERIFY | 1.0 [C]//VERIFY | **2**, Ø2.0 [A] | 1× USB-C, `xmin` [A] | ESP8266EX on-board (PCB antenna) [A] |
| `esp32_c3_devkitm` | 38.91 × 25.40 [A] | ~2 rounded [B]//VERIFY | 1.6 [C]//VERIFY | **none** [A] | 1× micro-USB, `xmin` [A] | ESP32-C3-MINI-1 (13.2×16.6) [A] |
| `esp32_s3_devkitc` | 62.74 × 25.40 [A] | ~0 square [A] | 1.6 [C]//VERIFY | **none** [A] | **2×** micro-USB (UART+USB), `xmin` [A] | ESP32-S3-WROOM-1 (18×25.5) [A] |

**Four of the five boards have NO mounting holes** — they are breadboard/
pin-header boards. This is a confirmed finding (empty hole list + note), not a
gap: it is visible directly on the four drawings that exist, and is the
universal community description of the NodeMCU. **Never invent mounts for
these four.** Only the D1 mini V4.0.0 has mounting holes.

## Per-board detail

### `esp32_devkitc` — ESP32-DevKitC V4 (ESP-WROOM-32, 38-pin)

Read off `esp32_devkitc_v4_dimensions.pdf` ("Unit: mm"):

- **Outline 48.26 (X) × 27.94 (Y) mm** [A] (1.9″ × 1.1″). Board corners drawn
  **square** (no radius callout, sharp right angles) → `corner_r ≈ 0` [A]
  //VERIFY (a real board may have a ~0.5 mm manufacturing break, not drawn).
- **PCB thickness**: not dimensioned (top-view only) → **1.6 mm [C] //VERIFY**
  (standard 2-layer dev-board nominal).
- **Mounting holes: NONE** [A] — the drawing shows only the two pin-header rows;
  no mounting holes anywhere.
- **ESP-WROOM-32 module**: drawn as a **25.40 × 18.00 mm** outline [A] at the
  `xmax` end, with an **"RF Antenna"** keep-out rectangle protruding a further
  **6.04 mm** past the module toward/near the board end [A]. Metal-can shield +
  PCB antenna = a **board-unique** feature (component body + keep-out), modeled
  literally, **not** mapped to a connectors-lib type.
- **Connectors**:
  - `usb` — micro-USB receptacle on the **`xmin`** short edge (bottom of the
    drawing), roughly centered in Y [A] type / [C] exact X-Y offset //VERIFY
    (drawing shows the footprint but does not dimension its offset). Maps to
    connectors-lib **`micro_usb`**.
  - `header_l` / `header_r` — two single rows of **19 pins each** (38 total),
    2.54 mm pitch [A], running down the two long edges, `edge="top"`.
    Board-unique single-row headers (see "Pin headers" note below).
  - `EN` + `Boot` tact buttons present (not modeled as connectors).

### `esp8266_nodemcu` — NodeMCU v1.0, ESP-12E (Amica)

No single-vendor mechanical drawing exists (community reference design);
dimensions are multi-peer `[B]`:

- **Outline 49 × 26 mm** [B] //VERIFY (Amica variant; "49 × 26, 0.9″ rows"
  corroborated across etechnophiles + components101 + others). ~1 mm of
  clone-to-clone variance is expected — re-measure a specific board for a tight
  fit. (LoLin variant = 58 × 32 mm, 1.1″ rows — **not** this row.)
- **corner_r**: not documented → ~0.5–1 mm [C] //VERIFY.
- **PCB thickness**: not documented → **1.6 mm [C] //VERIFY**.
- **Mounting holes: NONE** [B] — every peer describes it as a breadboard board
  with no mounting holes; makers drill their own next to the antenna. Empty hole
  list, do not invent.
- **ESP-12E module**: ~**16 × 24 mm** [B] metal-can shield + PCB trace antenna at
  the `xmax` end (keep-out at the very end). Board-unique, literal.
- **Connectors**:
  - `usb` — micro-USB on the **`xmin`** short edge [B]. Maps to connectors-lib
    **`micro_usb`**.
  - `header_l` / `header_r` — two single rows of **15 pins each** (30 total),
    2.54 mm pitch, **0.9″ (22.86 mm)** row spacing [B], `edge="top"`.
  - `Flash` + `RST` buttons present (not modeled).

### `wemos_d1_mini` — LOLIN (WEMOS) D1 mini V4.0.0

Read off `dim_d1_mini_v4.0.0.pdf` (printed callouts + vector measurement):

- **Outline 34.3 (X) × 25.4 (Y) mm** [A] (drawing prints "34.3000" and
  "25.4000"). The docs spec text quotes "34.2 × 25.6" — using the **drawing's
  34.3 × 25.4**.
- **corner_r ≈ 4.0 mm** [C] //VERIFY. The drawing's **only** small-radius callout
  reads "2.0000 mm", but its two extension lines are **tangent to the mounting
  hole's left/right edges** — it dimensions the **hole diameter**, not the
  corner (see holes below). The rounded corners carry **no** radius leader. The
  two corners at the antenna (`xmax`) end are genuine quarter-circle fillets;
  reconstructing their arc geometry at the drawing's own scale (calibrated three
  ways — the printed 20.4 mm hole spacing and the 25.4 mm / 34.3 mm outline
  witness lines all give 14.48 pt/mm) gives a corner-fillet bounding box of
  ≈ 4.00 mm → **r ≈ 4.0 mm**. A strong estimate but **not a printed callout →
  [C] //VERIFY**. (The two corners at the USB (`xmin`) end are a smaller
  ≈ 1.0 mm break, also reconstructed, not dimensioned.)
- **PCB thickness**: not dimensioned → **1.0 mm [C] //VERIFY** (D1 mini boards
  are commonly the thin ~1.0 mm 2-layer stock; unconfirmed on this sheet).
- **Mounting holes: TWO** [A] — this is the notable V4.0.0 change. The drawing
  dimensions them explicitly: inset **2.5 mm** from each long edge (drawing
  "2.5000 mm"), **20.4 mm** apart (drawing "20.4000 mm" = 25.4 − 2×2.5), i.e.
  at **Y = {2.5, 22.9}** [A]. They sit near the **`xmax` (antenna) end**, at
  **X ≈ 3.2 mm** from that end edge — [C] //VERIFY (X-from-end is
  vector-reconstructed, not a printed callout). **Hole Ø = 2.0 mm** [A] — this is
  a **directly printed callout**: the drawing prints "2.0000 mm" with its two
  extension lines tangent to a hole's left/right edges, and the hole's own vector
  circle reconstructs to Ø ≈ 2.01 mm at the calibrated scale, confirming the
  callout targets the hole diameter (fits an M2 clearance / M1.6–M2 self-tap).
  Role: `structural-mount`.
- **On-board ESP8266EX** (QFN, no metal can) with a **PCB trace antenna** at the
  `xmax` end (same end as the mounting holes). Board-unique keep-out, literal.
- **Connectors**:
  - `usb` — **USB-C** receptacle on the **`xmin`** short edge [A] (docs: "Type-C
    USB Port"; V4.0.0 switched from micro-USB). Maps to connectors-lib
    **`usb_c`**.
  - `header_l` / `header_r` — two single rows of **8 pins each** (16 total),
    2.54 mm pitch, **0.9″ (22.86 mm)** row spacing (drawing "22.8600 mm") [A],
    `edge="top"`.

### `esp32_c3_devkitm` — ESP32-C3-DevKitM-1 (ESP32-C3-MINI-1)

Read off `DIMENSION_ESP32-C3-DEVKITM-1_V1_20200915AA.pdf`:

- **Outline 38.91 (X) × 25.40 (Y) mm** [A] (drawing prints "38.91mm" ×
  "25.40mm").
- **corner_r ≈ 2 mm** [B] //VERIFY — the outline is drawn with **visibly
  rounded** corners (unlike the square DevKitC/S3), but the radius is not
  dimensioned; 2 mm is a visual estimate (this drawing's corners are visibly
  tighter than the D1 mini's ≈ 4 mm antenna-end fillets).
- **PCB thickness**: not dimensioned → **1.6 mm [C] //VERIFY**.
- **Mounting holes: NONE** [A].
- **ESP32-C3-MINI-1 module**: **13.2 × 16.6 mm** [A datasheet], at the `xmax`
  end, **"MINI-ANT-TYPED"** PCB-antenna keep-out drawn protruding past the
  board end [A]. Board-unique, literal.
- **Connectors**:
  - `usb` — micro-USB (J2) on the **`xmin`** short edge [A]. Maps to
    connectors-lib **`micro_usb`**.
  - `header_l` / `header_r` — two single rows of **15 pins each** (30 total),
    2.54 mm pitch, **22.86 mm (0.9″)** row spacing [A], `edge="top"`.
  - `Boot` (SW1) + `RST` (SW2) buttons present (not modeled).

### `esp32_s3_devkitc` — ESP32-S3-DevKitC-1 v1.1 (ESP32-S3-WROOM-1)

Read off `DXF_ESP32-S3-DevKitC-1_V1.1_20220429.pdf` (title block "ESP32-S3-
DevKitC-1, Rev 1.1"):

- **Outline 62.74 (X) × 25.40 (Y) mm** [A] (drawing prints "62.74mm" ×
  "25.40mm").
- **corner_r ≈ 0 square** [A] (red outline drawn with sharp corners) //VERIFY.
- **PCB thickness**: not dimensioned → **1.6 mm [C] //VERIFY**.
- **Mounting holes: NONE** [A].
- **ESP32-S3-WROOM-1 module**: **18 × 25.5 mm** [A datasheet], at the `xmax`
  end, inset **1.27 mm** from each long edge [A], **"MINI-ANT-TYPEB"** antenna
  keep-out protruding past the board end [A]. Board-unique, literal.
- **Connectors** — **two USB ports**, both on the **`xmin`** short edge, side by
  side [A]:
  - `usb_uart` (J2, left / "UART") — **micro-USB** [A].
  - `usb_otg` (J4, right / "USB") — **micro-USB** [A].
  - Both drawn as micro-USB footprints on this v1.1 drawing and described as
    "Micro-USB" in the v1.1 user guide. **//VERIFY**: some later production
    batches / third-party clones of the S3-DevKitC-1 ship with **USB-C** in
    these two positions — the two-ports-on-one-edge topology is stable, the
    receptacle type is revision-dependent. Both map to connectors-lib
    **`micro_usb`** for this v1.1 row.
  - `header_l` / `header_r` — two single rows of **22 pins each** (44 total),
    2.54 mm pitch [A], `edge="top"`.
  - `Boot` (SW1) + `Reset` (SW2) buttons present (not modeled).

## Pin headers — a note on the connectors-lib mapping

Every board here breaks its IO out to **two independent single-row male
headers** (one down each long edge), 2.54 mm pitch, opening `+Z` → `edge="top"`.

The `connectors` library's **`gpio_2x20`** type is a single **2-row × 20-column
block** (50.8 × 5.08 × 8.5 mm) — that is the Raspberry-Pi HAT header, **not** the
same footprint as two separated single rows. So the ESP pin headers do **not**
map cleanly to `gpio_2x20` and are modeled **literally** as per-board single-row
header bodies (length = pins × 2.54 mm, width ≈ 2.54 mm, plastic body height
≈ 2.5 mm [C] //VERIFY). Row spacing where dimensioned is **0.9″ / 22.86 mm**
(NodeMCU, D1 mini, C3-DevKitM-1); DevKitC (27.94 wide) and S3 (25.40 wide) place
their rows just inside the long edges. Exact per-pin X/Y origins are Task 2/4's
to finalize from the drawings; this worksheet fixes the topology, pin counts,
pitch, and edges.

## Connectors-lib mapping summary (for later tasks)

| board connector | connectors-lib type | tier |
|---|---|---|
| every micro-USB (DevKitC, NodeMCU, C3, S3×2) | `micro_usb` | [A] Same Sky UJ2-MBH body |
| D1 mini V4.0.0 USB | `usb_c` | [A] Same Sky UJC-H-G-SMT body |
| pin headers (all boards) | **none** — board-unique single-row, literal | — |
| WROOM/ESP-12E metal can + PCB antenna keep-out | **none** — board-unique, literal | — |

## Weakest-sourced values (for future re-verification)

1. **PCB thickness — all five boards.** No top-view drawing dimensions it;
   1.6 mm (1.0 mm for D1 mini) are nominal `[C] //VERIFY`.
2. **`esp8266_nodemcu` outline (49 × 26).** Community `[B]`, ~1 mm clone
   variance; no single-vendor drawing.
3. **`wemos_d1_mini` corner_r (~4.0) and hole X-from-end (~3.2).**
   Vector-reconstructed off the drawing, not printed callouts → `[C] //VERIFY`.
   (Hole Ø = 2.0 mm — printed "2.0000 mm", extension lines tangent to the hole
   edges — plus hole Y = {2.5, 22.9} and 20.4 mm spacing ARE printed callouts →
   `[A]`. Note: the "2.0000 mm" callout dimensions the **hole diameter**, not the
   corner radius.)
4. **`esp32_c3_devkitm` corner radius (~2).** Visibly rounded but not
   dimensioned → `[B] //VERIFY`.
5. **`esp32_s3_devkitc` USB receptacle type.** micro-USB per the v1.1 drawing;
   some later/clone batches are USB-C → `//VERIFY`.
6. **All USB and pin-header in-plane X/Y offsets.** Topology + edges are firm
   `[A]`/`[B]`; exact positions within the board are Task 2/4 reads.
