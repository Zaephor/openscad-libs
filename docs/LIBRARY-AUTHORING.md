# Library Authoring Standard

How hardware-reference libraries in `libraries/` are researched, sourced, and
structured. Every value must be auditable back to an authority.

## Provenance and confidence tiers

Every spec-able value carries an inline tag and source:

```scad
function fan_hole_spacing(size) = ...; // [B] https://en.wikipedia.org/wiki/Computer_fan
```

- **[A]** — upstream vendor datasheet or governing standard (Intel/formfactors
  ATX spec, raspberrypi.com mechanical drawing, SNIA SFF-8201, EIA-310-D, ...).
- **[B]** — corroborated across multiple independent peers (e.g. Wikipedia plus
  two retailer/datasheet sources that agree).
- **[C]** — reverse-engineered from a public STL or SCAD library (cite the
  artifact URL).

A group of values that share one source (e.g. a whole dimension table from one
drawing) may carry a single citation above the block.

`lib.json` `sources[]` lists the authority URLs. The library `README.md`
includes a **Sources** table linking each authority and noting what it backs.

## Gap handling

- Weak or single-sourced value: ship the best-known number, tagged
  `//VERIFY <what to confirm and why>`. Surface these before any print depends
  on them — an unverified value on an active path wastes prints.
- No sourcing at all: omit the value; record it in the README coverage notes as
  not-yet-covered. (You cannot flag a number you do not have.)

## Structure (three roles)

Each library is `libraries/<name>/<name>.scad`, imported namespaced
(`use <name/name.scad>;`), exposing where applicable:

1. **Data** — named constants and `[x, y]` coordinate lists, or lookup
   functions over a data table. Expose anything a consumer reads as a
   **function** (OpenSCAD `use` does not import top-level variables).
2. **Placeholder** — `<name>_placeholder(...)` envelope solid (accurate
   envelope + marked keep-outs) for fit checks.
3. **Hole-stamp / cutout** — `<name>_holes(...)` and other stamps for use
   inside a consumer `difference()`.

Conventions: centered origin in X/Y, bottom face on `Z=0`; millimeters;
clearances only from named values; a central `$fn`. A header comment states the
library's **default orientation**. Pure-data libraries (e.g. `hardware`) keep
only role 1.

## Verification

Each library passes `make check` (compiles headless, conventions pass) and is
rendered with the `verify-scad-geometry` skill. Value assertions live in a
`*_test.scad` checked by a bash test that greps OpenSCAD **stderr** for
`ERROR: Assertion` — OpenSCAD's exit code on assert files is unreliable, so the
stderr signal is what's trusted.
