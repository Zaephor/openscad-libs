---
name: design-for-print
description: Use when designing or modeling a 3D-printable part (esp. OpenSCAD in this repo) and making a printability or design-language decision — chamfer vs fillet vs bevel, avoiding supports/overhangs, sizing a press/slip/free fit or hole clearance, orienting a part for strength, or adding a boss/rib/gusset. Also the reference for what a print or CAD term means.
---

# Design for 3D Print

## Core Rules

- **The 45° self-support rule:** Overhangs steeper than 45° need support material. Read `reference/overhangs-supports.md`.
- **Orient load across layers:** Part strength varies by direction; align stress toward layer planes. Read `reference/strength-physics.md`.
- **Fillet internal corners:** Sharp corners create stress concentrations and are hard to print cleanly. Read `reference/glossary.md`.
- **Pick a fit band on purpose:** Clearances compound; measure before you design. Read `reference/tolerances-fits.md`.

## House Rules

This repo defaults to **Bambu P1S (PETG, 0.4 mm nozzle, no supports)**. Every design must work support-free — orient parts, add draft angles, and slope overhangs to stay under 45°. See `reference/house-rules.md` for printer specs, material defaults, and pre-computed clearances.

## Reference Index

| Deciding about… | Read |
|---|---|
| What a term means (chamfer/fillet/bevel/boss/rib/gusset/draft/counterbore/countersink) | `reference/glossary.md` |
| Overhangs, supports, bridging, orientation | `reference/overhangs-supports.md` |
| Clearances, fits, hole sizing, elephant's foot | `reference/tolerances-fits.md` |
| Part strength, layer direction, ribs vs walls | `reference/strength-physics.md` |
| This repo's printer/material defaults + clearances | `reference/house-rules.md` |
