# Contributing

## Libraries (`libraries/<name>/`)
- Provide real-world data/measurements only — no printable items.
- Required: `README.md`, `lib.json` (`name`, `description`, `version`, `sources[]`).
- Imported namespaced: `use <name/file.scad>;`.
- Create with `make new-lib NAME=<name>`.

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
