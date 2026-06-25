# __NAME__

TODO: describe the multipart item.

![__NAME__ assembly render](renders/__NAME__.png)

## Build

```bash
make run P=__NAME__       # interactive; use the Customizer's `explode` slider
make render P=__NAME__    # regenerate the render above
```

Exploded view: open `assembly.scad`, drag `explode` (0 = assembled, 1 = exploded),
toggle `show_<part>` bools to isolate parts.

See [PRINTING.md](PRINTING.md) for print settings.
