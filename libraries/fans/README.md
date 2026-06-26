# fans (library)

PC fan mechanical mounting reference — frame sizes, mounting-hole spacing, and
parametric thickness. Mechanical mounting geometry only (no airflow/electrical).

Orientation: airflow along **+Z**; square frame centered in X/Y; bottom on `Z=0`.

## Import

```scad
use <fans/fans.scad>;

difference() {
    my_bracket();
    fan_holes(120);   // four M5 clearance holes at 105mm spacing
    fan_bore(120);    // airflow opening
}
```

## Data (functions)

`fan_hole_spacing(size)`, `fan_default_thickness(size)`, `fan_holes_xy(size)`,
`fan_mount_hole_dia(size)`, `fan_screw_case()`, `fan_hole_clearance()`,
`fan_known_sizes()`, `fan_table()`.

| size (mm) | hole spacing c-c (mm) | default thickness (mm) |
|---|---|---|
| 40 | 32 | 10 |
| 50 | 40 | 10 |
| 60 | 50 | 25 |
| 70 | 60 | 25 |
| 80 | 71.5 | 25 |
| 92 | 82.5 | 25 |
| 120 | 105 | 25 |
| 140 | 124.5 | 25 |
| 200 | 154 | 30 |
| 220 | 170 | 30 |

Thickness is a parameter on every module (default from the table), so
non-standard-depth fans are a parameter change.

## Sources

| Source | Tier | Backs |
|---|---|---|
| [Wikipedia: Computer fan](https://en.wikipedia.org/wiki/Computer_fan) | B | Frame sizes + hole-spacing table |
| [graphicscardhub: PC fan screw size](https://graphicscardhub.com/pc-fan-screw-size/) | B | Case-screw (M5) + 4.3mm hole diameter |

## Coverage notes / `//VERIFY`

- Case-screw nominal (M5 self-tapping) — `//VERIFY` against a vendor datasheet
  before a fit-critical print.
- 40–60mm mounting-hole diameter varies (~3.2–4.3mm by model) — `//VERIFY` per
  target fan; the library defaults to 4.3mm.
- Airflow bore diameter is design-dependent; `fan_bore` defaults to ~0.92×size.
- Sizes 25/30/35/38/45/160/170/180/230/250mm: not covered — no standardized
  hole spacing found.
