# mitx-2u-chassis

Parametric 2U 10" rack chassis for a mini-ITX board, built "front-IO
appliance" style like its 1U sibling
[mitx-1u-chassis](../mitx-1u-chassis): the board's rear I/O-shield edge
faces the rack **front** (ports + a power button front-accessible), PLUS a
single **low-profile PCIe card aperture + bracket mount** in the front
faceplate (the extra U of height over the 1U sibling is spent on headroom
for a heatsink and a card standing up off the board). Rear `#40`
`rack-support` tongue mate on the rack rear. Consumes `motherboards` (board
+ PCIe-slot data), `rack10` (rack geometry), `rack-support` (rear mate,
engagement-depth budget only so far), `pcie-bracket` (card bracket
size/keep-out; mount-hole geometry not yet consumed — see Status),
`fans`/`honeycomb` (not yet consumed — Tasks 2-3). Units: **mm**.

![mitx-2u-chassis render](renders/mitx-2u-chassis.png)

## Status

**Task 1 of 4 (#43) — scaffold.** This task adds: params + fit-asserts, the
off-center board (standoffs + placeholder), and the front faceplate (rack
ears, IO-shield cutout, power button hole, PCIe slot aperture, PCIe bracket
keep-out preview). **Not yet built:** walls, floor, rear panel, the
`rack-support` tongue mate, the PCIe bracket's floor mount hole, and the
fan/honeycomb vent — Tasks 2-3.

## Design

- **Off-center board.** Same `_board_x()` idiom as mitx-1u-chassis: the
  board sits `board_offset` mm off the panel's centerline
  (`_board_x() = board_offset - mobo_size("itx")[0]/2`), opening a low-X
  margin wide enough for a power button beside the mini-ITX IO shield.
- **One shared board-frame offset.** `_board_x()` is the single translate
  applied to the standoffs, the `%`-preview placeholder, the IO cutout,
  *and* the PCIe slot cutout — all four read the board's own local frame
  (rear-left-corner origin per `motherboards.scad`), so they can't drift
  apart independently. (Verified empirically during implementation: an
  earlier draft translated the IO/PCIe cutter block by `board_offset`
  alone, which put the PCIe slot cutout's world X entirely past the
  panel's own half-width — a silent no-op cut that compiled clean but
  never actually opened. `mobo_pcie_first_xy()` shares the SAME
  component-up local frame as `mobo_io_cutout()`/`mobo_standoff_xy()`, so
  it needs the same `_board_x()` offset, not `board_offset` alone.)
- **IO + PCIe cutout direction.** `mobo_io_cutout_stamp()` and
  `mobo_pcie_cutout()` both grow +Y from the board's own local Y=0 (its
  rear/IO edge); the faceplate sits at -Y from that same plane (rack10's
  front-of-panel convention), so both stamps are `mirror([0,1,0])`-flipped
  before being placed in the shared board frame — otherwise the cutters
  grow away from the faceplate and never reach it (same bug mitx-1u-chassis
  hit on the IO stamp alone).
- **PCIe bracket mount hole is NOT cut here.** `pcie_bracket_mount_holes()`
  bores a Z-axis hole through the bracket's *foot* (flat in the XY plane,
  per `pcie-bracket.scad`'s own header) — a floor/rail fastener, not a
  Y-extruding faceplate through-cut like the two stamps above. Wrapping it
  in the same faceplate mirror is a silent no-op (proven empirically via
  `intersection()` against the faceplate slab: empty result). Task 2 cuts
  the real hole into the floor, where the bracket's foot actually lands.
  The `%pcie_bracket("low-profile")` keep-out preview is still rendered
  here (centered on the slot's own world X via `_pcie_slot_cx()`, since
  `pcie_bracket()`'s local X=0 is its own card-slot centerline, not the
  board's corner-frame origin) so the alignment is visible ahead of Task 2.
- **Off-panel + off-board guards.** Because `board_offset` moves the IO
  window, PCIe slot, and button hole together, fit-asserts check: the IO
  cutout's right edge, the PCIe slot's right edge, and both edges of the
  button hole all stay within `+-rack10_panel_width/2`; and the board
  footprint itself stays clear of the side walls' interior faces (ported
  from mitx-1u-chassis's #42 final-review finding) — see
  `tests/test_mitx_2u_chassis.sh`'s negative controls.
- **2U headroom budget.** Two independent ceiling asserts share the same
  `_int_h()` budget: `heatsink_ceiling` (a heatsink standing off the board)
  and `lp_card_h`/`lp_card_len` (the inserted low-profile card's own
  keep-out envelope, extending from the slot rearward) — either one alone
  must fit under the 2U interior ceiling above the standoff+board stack.
- **Support-free.** The faceplate's ear holes, IO cutout, PCIe slot, and
  button hole are all straight-through cuts along the panel's short
  (thickness) axis — no overhangs. See [PRINTING.md](PRINTING.md).

## Customizer parameters

| Param | Group | Default | Notes |
|---|---|---|---|
| `standard` | Rack | `"labrax"` | Rack vendor key (`rack10_known_standards()`) |
| `ear_type` | Rack | `"slot"` | Ear mount hole style passed to `rack10_holes()` |
| `device_u` | Rack | `2` | Rack unit height |
| `wall` | Print | `2.4` | Side wall thickness, mm (used by the width fit-assert; walls not yet modeled) |
| `floor_th` | Print | `2.0` | Floor thickness eaten out of the 2U height budget |
| `faceplate_th` | Print | `3.0` | Front rack panel thickness, mm |
| `standoff_h` | Print | `6.0` | Board standoff height, mm |
| `heatsink_ceiling` | Print | `55` | Reserved headroom above the board for a heatsink, mm |
| `button_dia` | Front | `12` | Power button hole diameter, mm |
| `board_offset` | Front | `20` | Board X-offset off panel centerline, mm — opens the low-X gap the button sits in |
| `pcie_screw` | Front | `"6-32"` | Bracket mount-screw thread family (`pcie_known_screws()`) — consumed by Task 2's floor mount hole |
| `lp_card_h`, `lp_card_len` | PCIe keep-out | `64.4`, `168` | Reserved envelope for the inserted low-profile card (height off the board, length rearward from the slot) — design placeholders, `//VERIFY`, no board/bracket-sourced figure exists for either |
| `dc_dia`, `fan_size`, `cell`, `hc_wall` | Cooling/Power | `11`, `60`, `8.0`, `1.2` | Reserved for Tasks 2-3 (DC-in jack, fan cutout, honeycomb vent) — not yet consumed |

## Build

```bash
make render-dind P=mitx-2u-chassis   # regenerate the render above (headless, no local GL needed)
```

See [PRINTING.md](PRINTING.md) for print settings.

## Sourcing

Board size/thickness/standoff/IO-cutout/PCIe-slot data come from
`motherboards`; panel width, ear hole centers, and 2U device height come
from `rack10`; the rear mate's engagement depth (consumed by
`_usable_depth()`'s depth fit-assert only, ahead of the tongue itself
landing in Task 2/3) comes from `rack-support`; the PCIe bracket's own
size/keep-out envelope comes from `pcie-bracket`. No dimensions are
copied — this project calls each lib's accessors directly.
