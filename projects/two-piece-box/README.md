# two-piece-box

A simple two-part box: base and lid, shown with a tuneable exploded view.

![two-piece-box assembly render](renders/two-piece-box.png)

## Build

```bash
make run P=two-piece-box       # interactive; use the Customizer's `explode` slider
make render P=two-piece-box    # regenerate the render above
```

Exploded view: open `assembly.scad`, drag `explode` (0 = assembled, 1 = exploded),
toggle `show_<part>` bools to isolate parts.

See [PRINTING.md](PRINTING.md) for print settings.
