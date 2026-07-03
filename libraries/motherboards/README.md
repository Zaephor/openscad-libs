# motherboards (library)

PC motherboard mechanical mounting reference — board sizes, standoff hole
coordinates, rear I/O window, and PCIe slot data for mini-ITX / microATX / ATX.
Mechanical mounting geometry only (no electrical/signal data). Units: **mm**.

Datum: board **REAR-LEFT corner** at the origin, board extends in **+X/+Y**,
PCB bottom on `Z=0`. `+X` = board width (runs along the rear I/O edge), `+Y` =
board depth (rear → front). The rear I/O edge is at `Y=0`.

ATX is 304.80mm (12.0″) wide along the rear edge × 243.84mm (9.6″) deep; the
rear edge carries the I/O panel and PCIe slots.

## Import

```scad
use <motherboards/motherboards.scad>;
```

Role-1 **data** library — `use` only (functions, no variables; see gotcha:
`use` does not import variables).

## Reference

Form-factor key: `"itx"` / `"matx"` / `"atx"` (see `mobo_known_ff()`).

| Function | Returns |
|---|---|
| `mobo_known_ff()` | list of valid form-factor keys |
| `mobo_size(ff)` | `[width_X, depth_Y]` mm board outline |
| `mobo_thickness()` | PCB thickness, mm (0.062″ nominal) |
| `mobo_hole_dia()` | standoff clearance hole diameter, mm |
| `mobo_pcie_pitch()` | PCIe slot-to-slot pitch, mm |
| `mobo_standoff_xy(ff)` | list of `[x,y]` standoff hole coords |
| `mobo_io_cutout(ff)` | `[x_off, width, height]` rear I/O window |
| `mobo_pcie_first_xy(ff)` | `[x,y]` of the first (rearmost) PCIe slot |
| `mobo_pcie_count(ff)` | number of PCIe slots for the form factor |

| Module | Produces |
|---|---|
| `mobo_placeholder(ff)` | PCB envelope solid with standoff holes cut (fit checks) |
| `mobo_standoff_holes(ff, depth, dia)` | standoff clearance holes (subtract from a consumer solid) |
| `mobo_standoffs(ff, height, dia, bore)` | positive standoff posts with pilot bore (print a tray directly) |
| `mobo_io_cutout_stamp(ff, depth)` | rear I/O window as a subtraction solid at `Y=0` |
| `mobo_pcie_cutout(ff, slots, depth)` | PCIe slot openings stepped from the first slot by pitch |

## Sources

| Source | Tier | Backs |
|---|---|---|
| [ATX Specification 2.01](https://www.bitsavers.org/pdf/intel/ATX/ATX_Specification_2.01_199702.PDF) | A | Board size + standoff hole grid (ATX) |
| [microATX 1.2](https://xdevs.com/doc/_PC_HW/Form_factors/matxspe1.2.pdf) | A | Board size + standoff hole grid (microATX), rear I/O window |
| [ATX Specification 2.03](https://www.bitsavers.org/pdf/intel/ATX/ATX_Specification_2_03_199812.pdf) | A | Corroborating ATX text/figures |
| [Protocase enclosure design guide](https://www.protocase.com/resources/how-to-design-for-motherboards/How-to-Design-Enclosures-for-Motherboard.pdf) | C | Corroboration (ATX/mATX) + sole basis for mini-ITX holes |
| [Wikipedia: Mini-ITX](https://en.wikipedia.org/wiki/Mini-ITX) | B | mini-ITX board size |

Provenance tiers (also tagged inline in `motherboards.scad` / `RESEARCH.md`):
**[A]** direct from an Intel/formfactors.org spec dimensioned drawing, **[B]**
multi-peer corroborated (≥2 independent sources agree), **[C]** reverse-engineered
/ best-available reproduction (primary drawing unreachable or chain unclosed).

Full chained-dimension reconstruction and closure proofs: `RESEARCH.md`.

## Coverage & verification notes

**Not covered** (no data — using these keys asserts):
- E-ATX
- DTX / Mini-DTX
- ITX micro-variants (Nano-ITX, Pico-ITX, Mini-ITX "Flex")

**Carried `//VERIFY` items** — confirm before a fit-critical print:

- **mini-ITX standoff coords are tier [C]**. The primary ITX addendum drawing
  was unreachable; coords are derived from Protocase Fig8 + Wikipedia. The
  front-row Y (P3/P4) is the least certain value — confirm against a real board.
- **microATX holes B/R/S and the ATX hole F row-inset** did not fully close
  against the dimensioned drawing (letter↔coordinate mapping unresolved in the
  scan) — tagged [C].
- **`mobo_hole_dia()`** (#6-32 / Ø.156″ = 3.96mm) — confirm against your actual
  standoff hardware (M3 vs #6-32) before drilling to fit.
- **`mobo_io_cutout` x_off** (I/O window horizontal position) — [C] in all three
  form factors.
- **`mobo_pcie_first_xy` / `mobo_pcie_cutout` — IMPORTANT, treat as a stub.**
  Shipped PCIe first-slot positions are placeholder-quality [C] and are **not
  reliable**. Geometry verification showed the ATX default places slots on the
  I/O side and the 7th slot overflows the board's +X edge (x ≈ 312mm > 304.8mm
  width). PCIe slot absolute position varies by board — **you must set
  `mobo_pcie_first_xy` per your target board** before using `mobo_pcie_cutout`.

**ITX-vs-ATX caveat**: mini-ITX standoff holes are **not** a corner-datum
subset of ATX/microATX — ITX's board insets differ from ATX's because it's a
smaller board measured from its own corner. Only **microATX shares the ATX
grid** (holes C, H, L, J, M are identical to 0.00mm). Don't assume ITX ⊆ ATX
in this library's coordinate frame.
