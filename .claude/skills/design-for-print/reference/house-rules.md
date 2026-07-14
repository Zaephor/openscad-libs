# House Rules: Printer Defaults and Clearances

Pin these numbers. When a design decision needs a printer spec or a
clearance value, use the ones on this page instead of re-deriving or
guessing — that keeps every part in this repo consistent instead of
drifting per-agent, per-run.

## Printer and material

- **Printer:** Bambu Lab P1S. Build volume **256 × 256 × 256 mm** — [B],
  well-established public spec
  (<https://us.store.bambulab.com/products/p1s>,
  <https://www.microcenter.com/product/668655/bambu-lab-p1s-3d-printer>).
  Bambu Studio defaults the *usable* print height to 250 mm as a
  bed-collision safety margin; the last 6 mm needs a manual override — don't
  rely on it for a tall part unless the override is confirmed set.
- **Nozzle / layer height:** 0.4 mm nozzle, 0.2 mm layer height. This is a
  repo convention, not an external spec — every `PRINTING.md` template and
  project in this repo states this pair as the default:
  `templates/project-single/PRINTING.md`,
  `templates/project-multipart/PRINTING.md`,
  `projects/cable-clip/PRINTING.md`, `projects/two-piece-box/PRINTING.md`.
  Treat 0.4 mm / 0.2 mm as the baseline for any new part unless a project's
  own `PRINTING.md` states otherwise.
- **Material:** PETG is the repo default for functional/structural parts —
  see `projects/bpir4-1u-chassis/PRINTING.md`. PLA shows up for smaller,
  non-structural fixtures (`projects/cable-clip/PRINTING.md`,
  `projects/two-piece-box/PRINTING.md`). Design-relevant PETG traits:
  - Good layer adhesion relative to PLA — less prone to Z-axis delamination
    (favorable given the layer-anisotropy rule in `strength-physics.md`).
  - Low warp, and the P1S's enclosed chamber helps further — less need to
    over-design draft/brim margins for warp than on an open-frame printer.
  - Stringing/oozing needs retraction tuning: avoid long horizontal nozzle
    travel over open cavities where stringing would be visible or would
    foul a fit.
  - PETG's clean overhang ceiling is rated slightly worse than PLA's:
    roughly 45–50° for PETG vs. 55–60° for PLA — [B]
    (<https://www.snapmaker.com/blog/45-degree-rule-3d-printing/>). This
    repo's 45° rule (`overhangs-supports.md`) is already close to PETG's
    practical limit — don't assume headroom past 45° the way you might
    reason on PLA.

## Hard constraint: no supports

**Every part in this repo is designed to print without support material.**
This is not a style preference; it is load-bearing on the actual print
workflow. `projects/bpir4-1u-chassis/PRINTING.md` states no supports are
needed for the tray or the lid; `projects/cable-clip/PRINTING.md` and
`projects/two-piece-box/PRINTING.md` both list "Supports: None" as the
printing spec, not an aspiration. If a design decision would require
supports, the decision is wrong — redesign the geometry (reorient the part,
chamfer instead of overhang, split into printable sub-parts, teardrop a
horizontal hole) rather than accept supports. See `overhangs-supports.md`
for the concrete techniques.

## Repo clearance precedent (bpir4-1u-chassis)

These are real, working values from a chassis that has actually been
printed and assembled — the single source of truth for this repo's
clearance and insert-bore numbers. Reuse them; don't re-derive a fresh
number for the same kind of fit. Source:
`projects/bpir4-1u-chassis/params.scad`.

| Name | Value | What it's for |
|---|---|---|
| `wall_gap` | 0.25 mm (per side) | Lid-to-wall running/slip clearance |
| `board_insert_bore` | 3.4 mm | M2.5 heat-set insert OD (board standoffs) |
| `lid_insert_bore` | 4.2 mm | M3 heat-set insert OD (lid posts) |
| `boss_wall` | 3.2 mm | Lid-post wall thickness around the insert bore (post OD = `lid_insert_bore + boss_wall`) |
| `post_wall_gap` | 1.2 mm | Printable clearance from lid-post outer edge to side-wall inner face |
| `csk_head_extra` | 2.6 mm | M3 countersink head oversize over the clearance hole (→ ~6 mm 90° CSK head) |

Heat-set inserts in this repo's chassis are installed **post-print, with a
soldering iron, before final assembly**
(`projects/bpir4-1u-chassis/PRINTING.md`). Size bore diameter and boss wall
thickness assuming that install method (a straight-in heated press, not a
tapped thread) — that's what `board_insert_bore` / `lid_insert_bore` /
`boss_wall` above already assume.

These numbers are cited by name elsewhere in this skill rather than
restated — see `tolerances-fits.md` for how they map onto the general fit
bands, and `strength-physics.md` for the reasoning behind `boss_wall`.

## Cross-references

- Term definitions: `glossary.md`
- Overhang / bridging / no-support geometry techniques: `overhangs-supports.md`
- General (non-repo-precedent) fit-band numbers: `tolerances-fits.md`
- Layer strength and boss/insert wall-thickness reasoning: `strength-physics.md`
