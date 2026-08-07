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

## Edge breaking (recommended)

Break exposed external (convex) edges and corners on printed parts — improves
handling comfort, chip resistance, and finished appearance.

*Unlike the no-supports rule above, this is a recommendation, not a hard
constraint — leaving an edge sharp needs no justification.*

### Pinned nominals

The 1.2 mm chamfer nominal traces directly to the precedent in `projects/bpir4-1u-chassis/parts/tray.scad` (lid-post chamfer and fillet both at 1.2 mm) — reuse rather than re-derive. The 2.0 mm corner round is a design value chosen for proportion; the keystone library's `_keystone_chamfer_margin()` (1.15×) is a self-support overhang-slope factor, not a chamfer-size source.

- **Exposed-edge chamfer:** ~**1.2 mm** chamfer leg at 45° (band: 0.5–1.5 mm).
- **Exposed outside-corner round:** ~**2.0 mm** radius on vertical (plan-view) corners; scale down on small parts to keep proportional. Note: a round on a top horizontal edge starts as a near-flat overhang — see `overhangs-supports.md` for the constraint.
- **Print-safe floor:** Keep any break **≥ 2 layer heights (0.4 mm)** so it renders at the repo's 0.2 mm layer height.

### Applies well to

- **Rack ears and mount flanges:** hand-contact surfaces where sharpness causes discomfort and visible chipping.
- **Faceplate perimeters:** edges that face the outside and visible during use.
- **Plate and bracket outside corners:** anywhere gripped or handled during installation or maintenance.
- **Other external convex features:** any edge a hand might contact or that stresses aesthetics.

### Do NOT apply

- **Mating and bearing faces:** surfaces that must stay sharp for a tight fit or flush joint.
- **Fit-critical edges:** anything that affects a tolerance band or insertion clearance.
- **Faces that must stay flush:** stacking datum faces, flat datum planes where a break would disrupt a seal or alignment.
- **Where it would undersize a wall:** do not chamfer or round if it would take a wall thickness below its minimum.
- **Functional sharp edges:** retention shoulders, catch/detent edges (example: the keystone insert's retention face is deliberately sharp).

### Deferred helper

A shared OpenSCAD edge-break primitive is deliberately deferred until a
second part needs the same primitive — that triggers a standing `2nd-consumer`
merge into `libraries/`. Parts implement their own breaks for now, as
`projects/bpir4-1u-chassis/` already does for handling-finish edge-breaking.

## Repo clearance precedent (bpir4-1u-chassis)

These are real, working values from a chassis that has actually been
printed and assembled — the single source of truth for this repo's
clearance and insert-bore numbers. Reuse them; don't re-derive a fresh
number for the same kind of fit. Source:
`projects/bpir4-1u-chassis/params.scad`.

| Name | Value | What it's for |
|---|---|---|
| `wall_gap` | 0.25 mm (per side) | Lid-to-wall running/slip clearance |
| `board_insert_bore` | `heatset_pilot_dia(board_insert_size)` = 3.23 mm (size = M2) | Board-standoff heat-set insert **pilot bore** — derived, not a literal; current size is M2 (was M2.5 / 3.4 mm) |
| `lid_insert_bore` | `heatset_pilot_dia(lid_insert_size)` = 4.01 mm (size = M3) | Lid-post heat-set insert **pilot bore** — derived, not a literal; current size is M3 (was a hardcoded 4.2 mm) |
| `heatset_min_wall(lid_insert_size)` | 1.6 mm (radial, size = M3) | Min wall around a heat-set insert's pilot bore (heatset library, manufacturer crack-risk floor) — lid-post OD = `lid_insert_bore()` + 2× this ≈ 7.21 mm, via `_lid_post_od()` (`projects/bpir4-1u-chassis/params.scad`) |
| `csk_head_extra` | 2.6 mm | M3 countersink head oversize over the clearance hole (→ ~6 mm 90° CSK head) |

Note: an older `post_wall_gap` (printable lid-post-to-side-wall clearance)
no longer exists — the current design places posts **tangent** to the
walls (flush, zero gap) instead of offset by a gap
(`projects/bpir4-1u-chassis/parts/tray.scad`, `_lid_post_xy()`). There is no
replacement number to cite; this table omits it rather than document a
value nothing produces.

Heat-set inserts in this repo's chassis are installed **post-print, with a
soldering iron, before final assembly**
(`projects/bpir4-1u-chassis/PRINTING.md`). Size bore diameter and boss wall
thickness assuming that install method (a straight-in heated press, not a
tapped thread) — that's what `board_insert_bore` / `lid_insert_bore` /
`heatset_min_wall(lid_insert_size)` above already assume.

These numbers are cited by name elsewhere in this skill rather than
restated — see `tolerances-fits.md` for how they map onto the general fit
bands, and `strength-physics.md` for the reasoning behind boss/insert wall
thickness.

## Fastener availability is a design input

**Design to fasteners actually on hand.** Confirm the size is available before
locking it into geometry — a printed part dimensioned for a fastener nobody
stocks is scrap, and heat-set bosses bake the choice into the print.

A chassis was dimensioned around M2.5 heat-set inserts and printed before
anyone checked; the only sizes in the drawer were M2 and M3.

**Standing default: prefer M3, fall back to M2 if there is a size issue or
clearance risk.** M3 is the more common fastener to have on hand — drop to
M2 only when something forces it. This repo's chassis already follows that
order: M3 for the lid posts, M2 for the board standoffs, where the board's
own fixed hole was the size issue that justified the fallback (see below).

**Screw clearance in the MATING part's hole is a constraint too.** When the
hole is fixed by someone else's board, it sets how much misalignment the
assembly can absorb:

- M3 through a 3.0 mm board hole is **zero** clearance — it passes, but with no
  tolerance for standoff misalignment, and it will feel like the standoffs are
  in the wrong place when they are not.
- M2 through the same hole gives **1.0 mm**.

**A smaller screw can be the better engineering choice** when the hole is fixed
and the alignment is not. Do not reflexively size up.

## Test-print the risky interfaces first

Before committing filament and hours to a full part, **print the risky
interface alone** — the faceplate section carrying the port cutouts, the corner
carrying the mounting posts, the feature that mates with a purchased component.

Defects cluster at interfaces with parts you did not design. On one 1U chassis
every discovered defect — a board collision and four port-clearance problems —
sat in two small regions of a large, slow part. A faceplate-only and a
corner-only test print would have caught all of them for a fraction of the
time and material.

This is cheapest exactly when the part is large, slow, or expensive — which is
also when the temptation to "just print it" is strongest.

## Cross-references

- Term definitions: `glossary.md`
- Overhang / bridging / no-support geometry techniques: `overhangs-supports.md` (chamfer-as-overhang-technique)
- General (non-repo-precedent) fit-band numbers: `tolerances-fits.md`
- Layer strength and boss/insert wall-thickness reasoning: `strength-physics.md` (internal-corner fillets for stress)
