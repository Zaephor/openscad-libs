# rack10-device-tray

Parametric 1U 10" rack tray cradling a rigid-box network device (GS308 /
GS308T / RLA-PS1): floor + side/rear cradle walls sized from the device
envelope, front open for port access, bottom secure-hole cutouts (screws
pass up through the tray floor into the device's own mounting bosses),
honeycomb floor vents, rear `#40` `rack-support` mate. Consumes `rack10`,
`rack-support`, `honeycomb`. Units: **mm**.

![rack10-device-tray render](renders/rack10-device-tray.png)

## Presets

| Device | `device_size` (w×d×h) | `secure_holes` | Retention |
|---|---|---|---|
| GS308 (default) | `[158,102,26]` `[B]` | `//VERIFY` placeholder | 2 caliper-pending screw-up cutouts |
| GS308T | `[158,101,30]` `[B]` | `[]` — **researched negative** | cradle walls/floor only, zero screws |
| RLA-PS1 | `[189.6,106.6,25.6]` `[B]` | `//VERIFY` placeholder | cradle-pending screw-up cutouts |

All three envelopes are `[B]` (vendor datasheet dimensions; cite source +
tier only, per this repo's provenance rule — no fetch/tooling narrative).

**`secure_holes` provenance is device-specific, not a single caveat:**

- **GS308:** no published bottom mounting-hole geometry exists for the
  plain GS308. The official Installation Guide confirms a keyhole-style
  wall-mount feature exists ("hook it onto the screws") but gives no
  position, spacing, or diameter, and screws are stated as user-supplied.
  Hardware-revision uncertainty is a further open question — current retail
  units are a later chassis revision than the guide's original printing,
  and hole geometry may not have carried over unchanged. The shipped
  default (`[[44.25,51,3.4],[113.75,51,3.4]]`) is a **starting placeholder
  shape only** — neither the spacing nor the diameter is a sourced device
  dimension — pending a caliper pass on the physical unit.
- **GS308T:** `secure_holes = []` is a **researched negative, not a
  placeholder to fill in later.** The device's official Hardware
  Installation Guide covers desktop/flat-surface mounting only — no
  wall-mount or rack-mount section anywhere in the document — corroborated
  by a NETGEAR Community support reply and an independent physical
  inspection report that the underside carries no keyhole slots at all
  (unlike the plain GS308). This preset is retained by the cradle's
  side/rear walls and floor alone, with **zero screws** — if you're editing
  this preset, don't "fix" the empty list thinking it's an oversight.
- **RLA-PS1:** the official datasheet publishes the envelope only, with no
  mounting-hole drawing. Reolink ships a paper mounting template in the
  box, but no dimensions are published for it; one independent community
  rack-mount design confirms underside screw slots exist but publishes no
  numbers. `secure_holes` is a
  `//VERIFY` placeholder pending a caliper pass or the physical template.

**Before printing a secure-hole cutout for any preset, caliper the physical
device's bottom face and override `secure_holes` with real
`[[x,y,dia],...]` coordinates** (device-local origin, front-left bottom
corner; `dia` is the screw-clearance hole diameter, not a countersink
diameter — see `csk_dia`).

The front `port_cutout` default (`[0,0]`) derives a generous full-face
opening (device width minus a 3mm frame each side, full device height);
refine per device from a reference photo or caliper measurement once the
device's actual port layout is known.

Flat print, stackable bottom (countersinks open downward, flush with the
print bed face).

All three presets — default (GS308), `tests/gs308t.scad`, and
`tests/rla_ps1.scad` — are locked by `tests/test_rack10_device_tray.sh`,
which confirms each renders clean and that the GS308T/no-holes preset
stamps 0 countersunk holes.

## Build

```bash
make run P=rack10-device-tray       # interactive
make render P=rack10-device-tray    # regenerate the render above
```

Run `bash tests/test_rack10_device_tray.sh` (from the repo root) for the
project's own test suite.

See [PRINTING.md](PRINTING.md) for print settings.
