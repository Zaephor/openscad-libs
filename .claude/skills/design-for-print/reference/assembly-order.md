# Design for Assembly: Build Order, Access, and the Exploded Self-Check

How the parts go together is a design input, not an afterthought to check
once modeling is "done." This page covers the default build-order heuristic,
the per-step access rule that follows from it, and the exploded-view
self-check that catches a bad order before it reaches a human or a printer.

## Assembly sequence is a design input

Decide the order parts go together *while* modeling, not after the geometry
is finished. A part designed without regard for what has to slide past or
seat against what else routinely turns out unassemblable even though every
individual part is printable and every individual dimension is correct —
the failure is in the sequence, not any one part.

- Sketch (mentally or in comments) the assembly sequence before finalizing
  hole placement, boss height, or wall geometry for parts that mate.
- Treat "can this actually go together in some order" as a first-class
  design constraint, same tier as overhang angle or fit clearance.

## Default order: interior → exterior

Default to assembling from the inside out: innermost parts (boards,
brackets, inserts) seat first, with outer or intermediate layers (lids,
shells, cover plates) added last.

- An outer or intermediate part added early can physically block a screw
  hole, obstruct the path an inner part needs to slide or drop into, or
  hide a feature (an insert boss, a standoff) that the next step needs
  access to.
- If a design genuinely needs a different order (e.g. an insert must be
  pressed in before an adjacent wall closes over it), that is a deliberate
  exception — call it out explicitly rather than leaving the order implicit
  and undocumented.

## Per-step clearance rule

At every step of the assembly sequence, check two things before moving to
the next step:

- **Fastener access:** can a screwdriver, soldering iron (for a heat-set
  insert), or hand actually reach the fastener/feature being installed at
  *this* step, given everything already in place from earlier steps?
- **Component-insertion clearance:** does the part being added at this step
  have a clear path to its final position, without an already-installed
  part in the way?

No exterior or intermediate part should block an inner screw or component —
if it does, either reorder the sequence or add access (a larger opening, a
removable panel) rather than accepting an unassemblable design.

## The `assembly.scad` self-check gate

This repo's multipart project convention (`assembly.scad` with an `explode`
parameter, `CONTRIBUTING.md`) is not just a viewer for humans — treat it as
a proactive self-check step in the design workflow itself.

- Drive the `explode` parameter (0 = assembled, 1 = fully exploded) and
  render intermediate values to see the build-order story: which part seats
  against which, in what sequence, and whether anything collides or blocks
  access along the way.
- Use the `verify-scad-geometry` skill to render `assembly.scad` headlessly
  (assembled and exploded) and check for collisions or obstructed
  fasteners/components — do this **before printing** and **before human
  review**, not only when a human asks for an exploded view.
- This is a routine workflow step for any multipart design, the same way
  rendering an example to catch a syntax error is routine — not an
  on-request extra.

## Cross-references

- Boss/gusset tie-in and load-path reasoning that assembly order interacts
  with: `strength-physics.md`
- Per-step clearance is the same fit-band reasoning as any other mating
  surface: `tolerances-fits.md`
- Multipart project convention (`assembly.scad`, `explode` parameter):
  `CONTRIBUTING.md`
