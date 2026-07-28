# mitx-1u-chassis

Parametric 1U 10" rack chassis for a mini-ITX board, built "front-IO
appliance" style: the board's rear I/O-shield edge faces the rack **front**
(ports + a power button front-accessible), with a rear `#40` `rack-support`
tongue mate on the rack rear and a rear exhaust fan drawing air in through
honeycomb intake vents on both side walls. Consumes `motherboards` (board
data), `rack10` (rack geometry), `rack-support` (rear tongue mate),
`fans` (fan bore + mount holes), `honeycomb` (self-supporting vent fields).
Units: **mm**.

![mitx-1u-chassis render](renders/mitx-1u-chassis.png)

## Status

**Complete (#42).** A full open-top tray: front faceplate (rack ears, IO
cutout, power button), off-center board on standoffs, floor + side walls +
rear wall, tongue-flanking corner gussets, the `#40` rack-support tongue with
its own buttress, a rear DC-in barrel jack + teardropped exhaust fan bore,
and honeycomb intake/exhaust vents. All geometry verified support-free.

## Design

- **Off-center board.** The board is shifted `board_offset` mm off the
  panel's centerline (`_board_x() = board_offset - mobo_size("itx")[0]/2`)
  so the panel's low-X margin opens up wide enough to fit a power button
  beside the mini-ITX IO shield, which itself spans almost the full board
  width (158.75 of 170mm) and leaves no usable gap on the board itself.
- **One shared board-frame offset.** `_board_x()` is the single translate
  applied to the standoffs, the `%`-preview placeholder, *and* the IO
  cutout — all three read the board's own local frame (rear-left-corner
  origin per `motherboards.scad`), so they can't drift apart independently.
- **IO cutout direction.** The library's own `mobo_io_cutout_stamp()` grows
  +Y from the board's local Y=0 (its rear/IO edge); the faceplate sits at -Y
  from that same plane (rack10's front-of-panel convention). This project
  doesn't call that module directly (see below) but its local cutout reuses
  the same `mirror([0,1,0])`-flip before placing the cut in the shared board
  frame — otherwise it grows away from the faceplate and never reaches it.
- **Board-specific IO window height.** The generic ATX-family shield height
  `mobo_io_cutout("itx")[2]` (44.45mm) doesn't fit the available headroom
  above the board (interior height minus `standoff_h` leaves less than
  that), so the cutout is sized to `_io_window_h() = _int_h() - standoff_h`
  instead — this is a BYO-board appliance, not a universal-shield-compatible
  case.
- **Off-center guard.** Because `board_offset` moves both the IO window and
  the button hole, a fit-assert checks the IO cutout's right edge and both
  edges of the button hole stay within `+-rack10_panel_width/2` (see
  `tests/test_mitx_1u_chassis.sh`'s negative control).
- **Shell + rear tongue.** Floor, two side walls, and a rear wall (outer
  face flush with the tongue root) form a plain rectangular open-top tray —
  no cantilever, support-free by construction. The `#40` `rack_support_tongue()`
  is placed at `_tongue_y() = rack10_rear_post_y(standard) -
  rack_support_engagement_depth()` — `rack_support_tongue()`'s own documented
  consumer contract, not the more conservative `_usable_depth()` (which
  additionally reserves `faceplate_th` as a separate board-depth margin; the
  two intentionally differ). A buttress strip under the tongue's full
  engagement reach (sized to the tongue's own width, built at
  `rack_support_floor_thickness()`) supports what would otherwise be an
  unsupported horizontal overhang.
- **Tongue-flanking gussets.** `_mitx_gusset()` braces the rear-wall/floor
  corner immediately beside the tongue on both sides, using the same
  hull-of-6-corner-spheres 45° prism `rack-support.scad`'s own gusset uses.
- **Rear DC-in + exhaust fan.** Both cut through the rear wall via
  `rotate([-90,0,0])` (native Z-bore frame → +Y through the wall), centered
  at `+-clear_width/4` so they scale with `rack10` standard and stay clear of
  the tongue-flanking gussets (asserted). The fan bore is teardropped
  (`_mitx_fan_teardrop()`, 45° roof) since a plain round hole that large
  (36.8mm at the default 40mm fan) rotated onto a horizontal axis is well
  past the safe plain-hole span; the DC-in hole (11mm) is left plain round
  since it's near the "usually fine" band and the barrel jack's panel-mount
  nut needs true roundness.
- **Honeycomb vents.** Intake fields on both side walls (front half, clear
  of the rear gusset/tongue zone) and an exhaust-flanking field on the rear
  wall (beside the fan's outboard edge, clear of its mounting screws and the
  tongue gusset) — all self-supporting hex-cell cuts via `honeycomb_vent()`,
  oriented so the bridge-sensitive "height" axis always lands vertical.
- **Support-free.** Every cut and every added solid (faceplate holes, IO
  cutout, button hole, walls, gussets, tongue+buttress, fan teardrop,
  honeycomb vents) is either a straight-through cut along a print-vertical
  axis or a monotonically-narrowing 45° prism — no unsupported overhangs
  anywhere. See [PRINTING.md](PRINTING.md).

## Customizer parameters

| Param | Group | Default | Notes |
|---|---|---|---|
| `standard` | Rack | `"labrax"` | Rack vendor key (`rack10_known_standards()`) |
| `ear_type` | Rack | `"slot"` | Ear mount hole style passed to `rack10_holes()` |
| `wall` | Print | `2.4` | Side/rear wall thickness, mm — sizes the width fit-assert, the walls themselves, and the gusset/vent clearances |
| `floor_th` | Print | `2.0` | Floor thickness eaten out of the 1U height budget |
| `faceplate_th` | Print | `3.0` | Front rack panel thickness, mm |
| `standoff_h` | Print | `6.0` | Board standoff height, mm |
| `heatsink_ceiling` | Print | `25` | Reserved headroom above the board for a heatsink, mm — checked against `_int_h()` by a fit-assert |
| `button_dia` | Front | `12` | Power button hole diameter, mm |
| `board_offset` | Front | `20` | Board X-offset off panel centerline, mm — opens the low-X gap the button sits in |
| `dc_dia` | Cooling/Power | `11` | Rear DC-in barrel jack hole diameter, mm — plain round cut through the rear wall |
| `fan_size` | Cooling/Power | `40` | Rear exhaust fan frame size, mm — must be a size `fan_known_sizes()` recognizes; drives the teardropped bore + `fan_holes()` mount pattern |
| `cell` | Cooling/Power | `8.0` | Honeycomb cell size, mm — shared by all three vent fields |
| `hc_wall` | Cooling/Power | `1.2` | Honeycomb wall thickness, mm — shared by all three vent fields |

## Build

```bash
make render P=mitx-1u-chassis    # regenerate the render above
```

See [PRINTING.md](PRINTING.md) for print settings.

## Sourcing

Board size/thickness/standoff/IO-cutout data come from `motherboards`; panel
width, ear hole centers, and 1U device height come from `rack10`; the rear
tongue's placement and engagement depth come from `rack-support`
(`rack_support_tongue()`, `rack_support_engagement_depth()`,
`rack_support_rail_size()`, `rack_support_floor_thickness()`); fan mount
spacing/bore sizing comes from `fans`; the vent cutter geometry comes from
`honeycomb`. No dimensions are copied — this project calls each lib's
accessors directly.
