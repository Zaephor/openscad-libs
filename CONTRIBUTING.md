# Contributing

## Libraries (`libraries/<name>/`)
- Provide reusable real-world data and component helpers — not finished printable items.
- Required: `README.md`, `lib.json` (`name`, `description`, `version`, `sources[]`).
- Imported namespaced: `use <name/file.scad>;`.
- **Multi-role convention** — a component exposes, where applicable:
  1. **Data** — named dim constants + `[x,y]` hole-coordinate lists.
  2. **Placeholder** — `<name>_placeholder()` solid: accurate envelope + keep-outs, for fit checks in an assembly.
  3. **Hole-stamp** — `<name>_holes()`: mounting holes for use inside a consumer `difference()`.
  Conventions: centered origin X/Y, bottom face on `Z=0`; clearances only from named constants; mm; central `$fn`. Pure-data libs (e.g. `hardware`) keep only role 1.
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
