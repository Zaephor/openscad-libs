# mitx-2u-chassis

Parametric 2U 10" rack chassis for a mini-ITX board, built "front-IO
appliance" style like its 1U sibling
[mitx-1u-chassis](../mitx-1u-chassis): the board's rear I/O-shield edge
faces the rack **front** (ports + a power button front-accessible), PLUS a
single **low-profile PCIe card aperture + bracket mount** in the front
faceplate (the extra U of height over the 1U sibling is spent on headroom
for a heatsink and a card standing up off the board). Floor + side walls +
rear wall, a rear `#40` `rack-support` tongue mate, a rear exhaust fan
drawing air in through honeycomb intake vents on both side walls, and a
rear DC-in barrel jack. Consumes `motherboards` (board + PCIe-slot data),
`rack10` (rack geometry), `rack-support` (rear tongue mate),
`pcie-bracket` (card bracket size/keep-out + I/O window geometry),
`fans` (fan bore + mount holes), `honeycomb` (self-supporting vent fields).
Units: **mm**.

![mitx-2u-chassis render](renders/mitx-2u-chassis.png)

## Status

**Complete (#43).** A full open-top tray: front faceplate (rack ears, IO
cutout, power button, PCIe slot aperture), off-center board on standoffs,
floor + side walls + rear wall, tongue-flanking corner gussets, the `#40`
rack-support tongue with its own buttress, a rear DC-in barrel jack +
teardropped exhaust fan bore, and honeycomb intake/exhaust vents. All
geometry verified support-free.

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
- **IO cutout direction.** `mobo_io_cutout_stamp()` grows +Y from the
  board's own local Y=0 (its rear/IO edge); the faceplate sits at -Y from
  that same plane (rack10's front-of-panel convention), so the stamp is
  `mirror([0,1,0])`-flipped before being placed in the shared board frame —
  otherwise the cutter grows away from the faceplate and never reaches it.
- **The card aperture comes from the bracket, not the board.** The hole a
  card's ports actually look through is cut from
  `pcie_bracket_window("low-profile")` — the same accessor
  `pcie_bracket()` cuts its own window from. `mobo_pcie_cutout()` is
  **not** used: it models the board-side edge-connector slot footprint (a
  fixed 12mm box at board height), which lands at world Z=[7,19] while the
  card's real I/O window sits at [25.82,69.38] — zero overlap, i.e. a real
  card's ports facing solid faceplate. `tests/test_mitx_2u_chassis.sh`
  probes the same line of sight through both the chassis and the bracket
  to prove they genuinely align, rather than each merely being in-bounds.
- **One Z datum for the bracket.** `_pcie_fold_z()` is the single world Z
  of `pcie_bracket()`'s own local Z=0 fold datum, shared by the aperture,
  the `%`-preview and every bracket fit-assert. It is not a free choice:
  the card seats on the board's PCIe connector body
  (`connector_size("pcie_x16")[2]` = 11.25mm `[A]` above the board), and
  the bracket must both span the card it carries and clear the 2U ceiling
  — two asserts that pin the datum to a ~2.9mm band at defaults.
- **No bracket foot fastener.** This chassis cuts no
  `pcie_bracket_mount_holes()`. The foot rides at card height, 5.2mm clear
  of the floor, so a floor bore cannot fasten it; and the foot's screw
  position (97.13, 8.65) is 2.14mm from structural standoff C's axis
  (98.65, 10.16) — **inside** that post's own 3.0mm radius, with no screw
  diameter or parameter able to separate them. That is not a data bug: the
  same ~1.5mm slot-centreline-to-rear-hole spacing appears on atx and matx
  too, because rear-row mounting holes sit in the 42.6mm bracket gap ahead
  of the connector body by design (see `motherboards.scad`'s own
  `mobo_pcie_ports()` setback note). A real card is retained at the far end
  of its bracket against a chassis rail, not at the board's rear-edge
  strip; retention is left unmodelled here and the conflict is locked in
  `tests/asserts.scad` so it gets revisited if the geometry ever changes.
- **Off-panel + off-board guards.** Because `board_offset` moves the IO
  window, PCIe slot, and button hole together, fit-asserts check: the IO
  cutout's right edge, the PCIe slot's right edge, and both edges of the
  button hole all stay within `+-rack10_panel_width/2`; the board
  footprint itself stays clear of the side walls' interior faces (ported
  from mitx-1u-chassis's #42 final-review finding); the card aperture's
  own X and Z spans stay inside the panel; and the bracket foot's
  footprint stays within the floor slab's interior span (bounded by the
  foot's real half-width, and stricter than the panel-width bound since
  the panel's ears extend past the floor) — see
  `tests/test_mitx_2u_chassis.sh`'s negative controls.
- **2U headroom budget.** Three independent ceiling fit-asserts share the
  same `_int_h()` budget above the standoff+board stack. One of them uses
  the **real** `pcie_bracket_size("low-profile")[0]` (79.2mm) rather than
  the shorter `lp_card_h` envelope, which leaves only 0.91mm of margin at
  defaults — a `standoff_h` bump would otherwise have pushed the actual
  bracket through the ceiling with every other assert still green. Also:
  `heatsink_ceiling` (a heatsink standing off the board, default 55mm —
  more than double the 1U sibling's 25mm, since 2U's extra rack unit is
  spent mostly here) and `lp_card_h`/`lp_card_len` (the inserted
  low-profile card's own keep-out envelope, extending up off the board and
  rearward from the slot). `lp_card_h`/`lp_card_len` (defaults 64.4mm /
  168mm) are explicit **design placeholders, `//VERIFY`** — no board- or
  bracket-sourced figure for either exists (`pcie-bracket.scad`'s own
  header explicitly carries no card-length/card-envelope data), so these
  are this project's own reasoned keep-out numbers, not `[B]`/`[C]`-tiered
  measurements; tune them to your actual card before printing if it
  differs. A further fit-assert keeps the LP card's length clear of the
  rear gusset/tongue zone.
- **Shell + rear tongue.** Floor, two side walls, and a rear wall (outer
  face flush with the tongue root at `_tongue_y()`) form a plain
  rectangular open-top tray — no cantilever, support-free by construction.
  The `#40` `rack_support_tongue()` is placed at `_tongue_y() =
  rack10_rear_post_y(standard) - rack_support_engagement_depth()` —
  `rack_support_tongue()`'s own documented consumer contract, not the more
  conservative `_usable_depth()` (which additionally reserves
  `faceplate_th` as a separate board-depth margin; the two intentionally
  differ). A buttress strip under the tongue's full engagement reach
  (sized to the tongue's own width, built at
  `rack_support_floor_thickness()`) supports what would otherwise be an
  unsupported horizontal overhang.
- **Tongue-flanking gussets.** `_mitx2_gusset()` braces the rear-wall/floor
  corner immediately beside the tongue on both sides, using the same
  hull-of-6-corner-spheres 45° prism `rack-support.scad`'s own gusset uses.
- **Rear DC-in + exhaust fan, generalized flank offset.** Both cut through
  the rear wall via `rotate([-90,0,0])` (native Z-bore frame → +Y through
  the wall). Unlike mitx-1u-chassis's flat `+-clear_width/4` flank offset
  (which happens to clear its own gusset only at that project's 40mm fan
  default), this project derives the flank center **from the gusset's own
  far edge** plus the wider of the fan/DC-in hole radii plus a fixed
  margin (`_rear_flank_cx()`), so fan/DC-in clear the gusset by
  construction for any `fan_size`/`dc_dia` — not just the values that
  happen to work. (The flat-offset idiom was checked first and found to
  put this project's own 60mm-default fan's near edge *inside* the
  gusset's far edge — a real overlap caught by a fit-assert, which is why
  this project generalizes instead of reusing the 1U idiom verbatim.) The
  fan bore is teardropped (`_mitx2_fan_teardrop()`, 45° roof, apex capped
  at the rear wall's own available headroom) since a plain round hole this
  large is well past the safe plain-hole span; the DC-in hole is left
  plain round since the barrel jack's panel-mount nut needs true
  roundness.
- **Honeycomb vents.** Intake fields on both side walls (front half,
  clear of the rear gusset/tongue zone) and an exhaust-flanking field on
  the rear wall (beside the fan's outboard edge, clear of its mounting
  screws and the tongue gusset). Both side walls carry the **same**
  full-height band: an earlier revision pinned the right wall's band above
  the LP card to avoid "collision with the card", which a vent cannot have
  — it is a cut through the wall and occupies no interior volume — and
  there is no airflow objection either, since the card sits 11.5mm inboard
  of that wall and intake drawn past a hot card helps it. All fields
  are self-supporting hex-cell cuts via `honeycomb_vent()`, oriented so
  the bridge-sensitive "height" axis always lands vertical.
- **Support-free.** Every cut and every added solid (faceplate holes, IO
  cutout, PCIe card aperture, button hole, walls, gussets, tongue+buttress,
  fan teardrop, honeycomb vents) is either a
  straight-through cut along a print-vertical axis or a monotonically-
  narrowing 45° prism — no unsupported overhangs anywhere. See
  [PRINTING.md](PRINTING.md).

## Customizer parameters

| Param | Group | Default | Notes |
|---|---|---|---|
| `standard` | Rack | `"labrax"` | Rack vendor key (`rack10_known_standards()`) |
| `ear_type` | Rack | `"slot"` | Ear mount hole style passed to `rack10_holes()` |
| `device_u` | Rack | `2` | Rack unit height |
| `wall` | Print | `2.4` | Side/rear wall thickness, mm — sizes the width fit-assert, the walls themselves, and the gusset/vent clearances |
| `floor_th` | Print | `2.0` | Floor thickness eaten out of the 2U height budget |
| `faceplate_th` | Print | `3.0` | Front rack panel thickness, mm |
| `standoff_h` | Print | `6.0` | Board standoff height, mm |
| `heatsink_ceiling` | Print | `55` | Reserved headroom above the board for a heatsink, mm — checked against `_int_h()` by a fit-assert |
| `button_dia` | Front | `12` | Power button hole diameter, mm |
| `board_offset` | Front | `20` | Board X-offset off panel centerline, mm — opens the low-X gap the button sits in |
| `pcie_screw` | Front | `"6-32"` | Bracket mount-screw thread family (`pcie_known_screws()`) — no foot fastener is cut (see above); read by the standoff-conflict lock in `tests/asserts.scad` |
| `dc_dia` | Cooling/Power | `11` | Rear DC-in barrel jack hole diameter, mm — plain round cut through the rear wall |
| `fan_size` | Cooling/Power | `60` | Rear exhaust fan frame size, mm — must be a size `fan_known_sizes()` recognizes; drives the teardropped bore + `fan_holes()` mount pattern |
| `cell` | Cooling/Power | `8.0` | Honeycomb cell size, mm — shared by all vent fields |
| `hc_wall` | Cooling/Power | `1.2` | Honeycomb wall thickness, mm — shared by all vent fields |
| `lp_card_h`, `lp_card_len` | PCIe keep-out | `64.4`, `168` | Reserved envelope for the inserted low-profile card (height off the board, length rearward from the slot) — design placeholders, `//VERIFY`, no board/bracket-sourced figure exists for either; tune to your actual card |

## Build

```bash
make render-dind P=mitx-2u-chassis   # regenerate the render above (headless, no local GL needed)
```

See [PRINTING.md](PRINTING.md) for print settings.

## Sourcing

Board size/thickness/standoff/IO-cutout/PCIe-slot data come from
`motherboards`; panel width, ear hole centers, and 2U device height come
from `rack10`; the rear tongue's placement and engagement depth come from
`rack-support` (`rack_support_tongue()`, `rack_support_engagement_depth()`,
`rack_support_rail_size()`, `rack_support_floor_thickness()`); the PCIe
bracket's own size/keep-out envelope and floor mount-hole geometry come
from `pcie-bracket`; fan mount spacing/bore sizing comes from `fans`; the
vent cutter geometry comes from `honeycomb`. No dimensions are copied —
this project calls each lib's accessors directly. `lp_card_h`/
`lp_card_len` are the one deliberate exception: this project's own
`//VERIFY` design placeholders, not sourced from any library.
