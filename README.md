# openscad-libs

An OpenSCAD monorepo of reusable **libraries** (real-world measurements/data) and printable **projects**.

## Quick start

```bash
make help                 # list all targets
make run P=cable-clip      # open a project in OpenSCAD (OPENSCADPATH preset)
make render P=cable-clip   # regenerate a project's render
make new-lib NAME=foo      # scaffold a library
make new-project NAME=bar [MULTIPART=1]
make check                 # lint conventions + compile-check all .scad
make list                  # list libraries and projects
```

Libraries are imported namespaced by folder once `OPENSCADPATH` points at `libraries/`
(the `make`/`scripts/openscad.sh` launcher sets this for you):

```scad
use <hardware/hardware.scad>;
```

## Libraries

- [hardware](libraries/hardware) — fastener and standard hardware dimensions.

## Projects

- [cable-clip](projects/cable-clip) — single-part M3-mounted cable clip.
- [two-piece-box](projects/two-piece-box) — multipart box with exploded view.

See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.
