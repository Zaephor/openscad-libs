# drive-tray

Parametric 1U `rack10` storage tray: a `cols x rows` grid of bottom-mounted
block drives, honeycomb floor vents, rear `#40` `rack-support` mate. Targets
two presets: 2x3.5" (`#44`) and 6x2.5" (`#45`). Consumes `drives` (device
data), `rack10` (rack geometry). Units: **mm**.

![drive-tray render](renders/drive-tray.png)

## Status

**In progress.** Task 1 (grid layout + drive placement + width/height
fit-assert) done. Faceplate/ears/walls/rear tongue (Task 2), honeycomb floor
vents (Task 3), and the locked `#44`/`#45` presets + this doc (Task 4) are
still pending.

## Build

```bash
make run P=drive-tray       # interactive
make render P=drive-tray    # regenerate the render above
```

See [PRINTING.md](PRINTING.md) for print settings.
