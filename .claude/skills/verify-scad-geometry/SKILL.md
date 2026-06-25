---
name: verify-scad-geometry
description: Render OpenSCAD parts/assemblies headlessly (no OpenGL) and produce a colored side-profile overlap view to catch overlaps, gaps, and misalignment before trusting geometry or printing. Use when verifying OpenSCAD fit/alignment, generating a headless render, or checking multipart fit.
---

# Verify OpenSCAD Geometry

OpenSCAD compiles cleanly even when surfaces overlap, leave gaps, or
misalign — the renderer never complains. A render is the check. This skill
renders geometry without OpenGL (exports binary STL, draws with matplotlib),
so it works in sandboxes and CI.

## When to use

- Verifying fit/alignment of a part or assembly before trusting the geometry.
- Producing a headless preview render (no display / no GL available).
- Eyeballing multipart fit before greenlighting a print.

## How to use

The bundled `render_stl.py` self-installs its Python deps on first run.

**Single render** (iso/top/side):

```bash
python3 .claude/skills/verify-scad-geometry/render_stl.py projects/<p>/assembly.scad --out /tmp/p.png
```

**Colored overlap** — the high-value fit check. Pass two or more parts; each
gets a distinct color projected onto a side plane, so overlaps interpenetrate
and gaps/misalignment are obvious:

```bash
python3 .claude/skills/verify-scad-geometry/render_stl.py --overlay \
  projects/<p>/parts/body.scad projects/<p>/parts/lid.scad --axis yz --out /tmp/overlap.png
```

Then read the PNG. `OPENSCADPATH` is auto-set to the repo's `libraries/` (found
by walking up), so `use <lib/...>` imports resolve. Exits non-zero (no PNG) on
an OpenSCAD export error or bad arguments.
