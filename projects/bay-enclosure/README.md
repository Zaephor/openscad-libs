# bay-enclosure

Parametric 1U/2U `rack10` enclosure for a front-accessible bay device
(5.25" optical drive / 3.5" bay accessory: card readers, fan controllers).
Side-rail mount, open front cutout exposing the device face, rear `#40`
`rack-support` mate. Consumes `drives` (device data), `rack10` (rack
geometry), `rack-support` (rear mate). Units: **mm**.

![bay-enclosure render](renders/bay-enclosure.png)

## Status

**Complete (#41 Part B, Tasks 1-4).** Front rack panel + device-face cutout
+ width/height fit-assert (Task 2); floor + side walls with device side-mount
holes + a 45° rear buttress ramp + the rear `rack_support_tongue()` mate
(Task 3); the three device presets below locked in tests + full gate green
(Task 4).

## Design

- **Side-rail mount.** The device is held by its own side screw holes
  (`drive_holes(device_type, faces="side")`, `drives` lib), cut straight
  through both side walls in one call — there is no bottom-mount tray or
  top lid. `drive_side_holes()` already returns one hole position **per
  wall pair** (tuples are `[x,z,role,dia]` in the drive's own frame; the
  cutter stamps a cylinder at each of the drive's two `Y` faces), so
  `bay_enclosure()` never doubles the count itself — see
  `libraries/drives/README.md`.
- **Open front cutout, no door/bezel.** The rack panel's device-face opening
  is centered on width with `front_clearance` side margin, but flush
  top-and-bottom (no clearance on that axis) — the device is meant to sit
  directly behind the panel with its own face visible/reachable, not behind
  a lid.
- **Rear `#40` mate.** The tray's own floor ramps up (45° self-supporting
  wedge) to meet `rack_support_floor_thickness()` and carries a
  `rack_support_tongue()` at the placement formula from the `rack-support`
  consumer contract (tongue tip lands exactly at
  `rack10_rear_post_y(standard)`), so it slides into a separately-printed
  `rack_support_plate(standard, device_u)` bolted to the rack's rear posts.
  This converts the tray's front-cantilever mount into a two-end-supported
  beam (see `libraries/rack-support/README.md` for the structural
  rationale) — `bay-enclosure` is the first real consumer of that library.
- **No vents/honeycomb (v1).** Out of scope for this backlog item — the
  only rear-support dependency is `#40`, not a future honeycomb/venting lib
  (`#50`). A bay525/bay35 device's own top/face is exposed to the room air
  through the open front, so v1 relies on that instead of a dedicated vent.
- **Flat print orientation, support-free.** Walls vertical (Z = build
  height); the front panel prints flat with no overhangs, the rear buttress
  ramp is a 45° self-supporting wedge, and the tongue mates with the
  channel's own chamfered lead-in — no supports needed anywhere. See
  [PRINTING.md](PRINTING.md).

### Known limitation: unbraced center floor/faceplate joint

The floor's top face meets the faceplate's back face at a sharp interior
corner directly under the device (the X-band between the two side walls).
Every other internal joint in this project (the rear buttress, the
wall-to-floor joints) gets a 45° gusset or is already one contiguous solid
with its neighbor; this one can't be — `_be_device_frame()` parks the
device's underside at exactly `Z=floor_th` (zero clearance, by design), so
there is no headroom above the floor in that X-band for any raised gusset
material without fouling the device fit. This is an accepted, documented
robustness tradeoff for the zero-clearance fit this project targets, not an
oversight; see `bay_enclosure()`'s own "Front floor/faceplate joint" comment
in `bay-enclosure.scad` for the full reasoning.

## Presets

Three device presets are locked (rendered + gated in
`tests/asserts.scad`/`tests/asserts_bay525_fh.scad`/`tests/asserts_bay35.scad`):

| `device_type` | `device_u` | Device (L x W x H, `drives` lib) | Notes |
|---|---|---|---|
| `bay525_hh` (default) | `1` | 200.0 x 146.05 x 42.3 mm | Half-height 5.25". **Tight fit**: only ~0.16mm of height headroom vs. the 1U interior at default `floor_th=1.2mm` (see below). |
| `bay525_fh` | `2` | 200.0 x 146.05 x 82.55 mm | Full-height 5.25", needs the full 2U interior. |
| `bay35` | `1` | 170.0 x 101.6 x 25.4 mm | 3.5" bay device, comfortable margin in 1U. |

**`bay525_hh`@1U is vendor-sensitive.** `rack10_device_height(1)` = 43.66mm;
minus the default `floor_th=1.2mm` leaves a 42.46mm interior against the
device's 42.3mm nominal height — ~0.16mm of margin. The `drives` lib's
depth/height figures for these three bay types are `[C]`/`//VERIFY`
(nominal, mesh/community-sourced, not vendor-datasheet `[A]`; see
`libraries/drives/RESEARCH.md`'s "Bay form factors" section) — a real unit
running a hair tall could exceed this margin. If a fit-assert trips on a
real device, raise `device_u` to `2` or thin `floor_th` (down to the ~3-layer
FDM solid-floor minimum) before reprinting.

## Customizer parameters

| Param | Group | Default | Notes |
|---|---|---|---|
| `standard` | Rack | `"labrax"` | Rack vendor key (`rack10_known_standards()`) |
| `device_u` | Rack | `1` | Rack U height budget (`1` or `2`, per preset table above) |
| `ear_type` | Rack | `"slot"` | Ear mount hole style passed to `rack10_holes()` |
| `device_type` | Device | `"bay525_hh"` | `bay525_hh` \| `bay525_fh` \| `bay35` (`drives` lib, must be a `"block"`-family type) |
| `wall` | Print | `2.4` | Side wall thickness, mm |
| `floor_th` | Print | `1.2` | Floor thickness eaten out of the `device_u` height budget (see `bay-enclosure.scad`'s own comment for why this is thinner than `rack-support`'s 2.0mm convention) |
| `faceplate_th` | Print | `3.0` | Front rack panel thickness, mm |
| `front_clearance` | Print | `1.0` | Side (width-only) gap around the device-face cutout; the cutout's height is flush top+bottom, not clearance-padded |

## Build

```bash
make run P=bay-enclosure       # interactive
make render P=bay-enclosure    # regenerate the render above
```

See [PRINTING.md](PRINTING.md) for print settings.

## Sourcing

Device envelope + side-mount hole data come from `drives` (tiers in
`libraries/drives/RESEARCH.md`); panel width, ear hole centers, `device_u`
height budget, and rear post depth come from `rack10`; the rear tongue
geometry + placement formula come from `rack-support`. No dimensions are
copied — this project calls each lib's accessors directly.
