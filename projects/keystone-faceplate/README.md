# keystone-faceplate

Parametric 1U 10-inch rack faceplate with N standard keystone jack cutouts.

![keystone-faceplate render](renders/keystone-faceplate.png)

## Customizer parameters

| Param | Default | Notes |
|---|---|---|
| `standard` | `"labrax"` | Rack vendor key (`rack10_known_standards()`) |
| `port_count` | `6` | Number of keystone ports; `0` = blank plate |
| `port_pitch` | `19.05` | Port center-to-center, mm (keystone lib standard pitch) |
| `plate_thickness` | `3.0` | Plate thickness, mm; must stay within the keystone snap range |
| `port_clearance` | `0.25` | Per-side window growth on each keystone cutout |
| `ear_hole_type` | `"slot"` | Ear mount hole style: `round`/`m6`/`10-32`/`square`/`slot` |
| `ear_fastener` | `"m6"` | Fastener sizing the ear clearance hole: `m6` \| `10-32` |
| `slot_travel` | `4` | Obround elongation along X for slot-style ear holes |
| `port_style` | `"lip"` | Port retention style: `lip` (taller lipped window) or `face` (flush face-plate) |
| `show_rack` | `false` | *Preview only* — overlay a 3U rack post frame around the panel (excluded from print) |
| `rack_context_depth` | `0` | *Preview only* — rack context front-to-back depth; `0` uses the vendor's default |

## Build

```bash
make run P=keystone-faceplate       # interactive
make render P=keystone-faceplate    # regenerate the render above
```

See [PRINTING.md](PRINTING.md) for print settings.

## Sourcing

Keystone opening, port pitch, and the plate-thickness snap range come from the
`keystone` lib (tiers in `libraries/keystone/RESEARCH.md`); panel width, ear
hole centers, and 1U device height come from `rack10`. No dimensions are
copied — this project calls each lib's accessors directly.
