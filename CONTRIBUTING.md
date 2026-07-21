# Contributing

## Libraries (`libraries/<name>/`)
- Provide reusable real-world data and component helpers — not finished printable items.
- Required: `README.md`, `lib.json` (`name`, `description`, `version`, `sources[]`).
- Imported namespaced: `use <name/file.scad>;`.
- **Multi-role convention** — a component exposes, where applicable:
  1. **Data** — functions returning constants + `[x,y]` hole-coordinate lists (expose as functions; `use` does not import variables).
  2. **Placeholder** — `<name>_placeholder()` solid: accurate envelope + keep-outs, for fit checks in an assembly.
  3. **Hole-stamp** — `<name>_holes()`: mounting holes for use inside a consumer `difference()`.
  Conventions: centered origin X/Y, bottom face on `Z=0`; clearances only from named values; mm; central `$fn`. Pure-data libraries (data functions only, no geometry) keep only role 1.
- Create with `make new-lib NAME=<name>`.
- Hardware-reference libraries (dimensions sourced from vendors/standards) MUST follow [docs/LIBRARY-AUTHORING.md](docs/LIBRARY-AUTHORING.md) — per-value provenance tags (`[A]`/`[B]`/`[C]`), `//VERIFY` for weak sourcing, and a Sources table in the README.

## Projects (`projects/<name>/`)
- Required: `README.md` (embeds >=1 image from `renders/`), `PRINTING.md`.
- Single-part: entry `<name>.scad`. Multipart: entry `assembly.scad` + `parts/`.
- Multipart `assembly.scad` MUST expose `explode = 0; // [0:0.01:1]` and one
  `show_<part> = true;` per part; each part offsets along its own vector scaled
  by `explode` (0 = assembled, 1 = exploded).
- Create with `make new-project NAME=<name> [MULTIPART=1]`.

## Before pushing
- `make check` — conventions + compile must pass.
- `make render P=<project>` — refresh renders (CI also regenerates on `main`).
- `make test` — tooling test suite.
- If you add or remove a library or project — or materially change a library's public API or Sources — update the top-level `README.md` Libraries/Projects lists and that library's own `README.md` in the same change. (The top README is the repo's index; keep it in sync so it doesn't drift.)

### Rendering locally without a GPU (dind)

`make render` uses OpenSCAD's GL preview and needs an X/GL stack; it segfaults in
GL-less sandboxes. To render there, use the dind sidecar:

    make render-dind P=<project>     # one project
    make render-dind-all             # every project

This runs the same pipeline inside a Docker container (OpenSCAD 2021.01 + xvfb +
software GL), matching CI output. CI (`render.yml`) renders natively with its own
xvfb and does not use this path.
