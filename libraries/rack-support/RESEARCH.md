# rack-support — evidence source log

Evidence/provenance log for `rack-support.scad`'s mating-interface accessors
(`rack_support_rail_size()`, `rack_support_slot_clearance()`,
`rack_support_engagement_depth()`, `rack_support_floor_thickness()`). Unlike
most libraries in this repo, these four values are **not** measured or spec-sourced dimensions of a real-world
part — there is no vendor part, standard, or physical artifact to measure.
They are **DESIGN values**: fit-clearance and engagement choices for a
slide-in tongue/slot mechanism this library itself defines (rear-support
plate presenting a channel; a consumer tray's `rack_support_tongue()` slides
into it). Per `docs/LIBRARY-AUTHORING.md`'s tier ladder ([A] datasheet/spec,
[B] corroborated peers, [C] STL/SCAD reverse-engineering), none of those
tiers apply to a value with no external authority to cite — inventing a
tier for a made-up-here number would misrepresent its confidence. Every
value below is tagged `//VERIFY design` instead: sourced to this repo's own
`design-for-print` skill guidance as the rationale, not a tier, and flagged
bench-tunable on the user's Bambu P1S / PETG per this repo's standard
disclaimer for unvalidated fit clearances.

Provenance legend used in this file:
- **DESIGN** — a value chosen by this library's own design, not measured or
  spec-sourced; rationale cited to `design-for-print` guidance.
- `//VERIFY` — flagged for bench confirmation before a print depends on it
  (per `docs/LIBRARY-AUTHORING.md` "Gap handling": ship the best-known
  number, flag it).

## `rack_support_slot_clearance() = 0.4` mm (per-side)

This is the per-side running gap between the tongue and the slot it slides
into. `.claude/skills/design-for-print/reference/tolerances-fits.md`'s FDM
clearance-band table puts a **free/running fit** (something meant to slide,
not press or snap) at **≈0.3–0.4mm per side**; 0.4mm sits at that band's
looser end, favoring an easy hand-insertion slide over a snug one — a
sensible default for a tray a user will slide in/out repeatedly, not a
one-time press assembly. The same reference notes these bands are
"rule-of-thumb, not vendor-verified" and recommends a test coupon before
trusting a clearance that matters — not yet done for this lib, hence
`//VERIFY`. (The repo's own precedent value, `wall_gap = 0.25mm` in
`projects/bpir4-1u-chassis/params.scad`, is a lid-to-wall clearance for a
different kind of fit — not reused here since 0.4mm is deliberately at the
looser end of the same band for a repeated-insertion slide fit, not a
snug lid seat.)

## `rack_support_rail_size() = [40, 10]` mm (`[width_X, height_Z]`)

The tongue cross-section. No external part or standard to size this
against — it is sized purely for this library's own structural role: wide
and tall enough to resist bending/twist under the shelf load it's meant to
help carry (the rear-support plate's whole purpose per the lib header is
converting a front-cantilevered tray into a two-end-supported beam), while
staying small enough to fit inside a 1U rack10 device envelope without
eating significant usable depth. 40mm width sits comfortably under
`rack10`'s narrowest `clear_width` vendor preset; 10mm height is a modest
fraction of a single 1U's ~44.45mm pitch (`rack10_u()`). No `design-for-print`
page gives a numeric "tongue size" rule (there is no such generic
mechanical-part class in that skill), so this pair is a plain engineering
judgment call, not derived from a cited formula — `//VERIFY design`,
pending a real print/load check once Tasks 3-4 build the modules that
consume it.

## `rack_support_engagement_depth() = 12` mm

How far (Y) the tongue must insert into the plate's channel before it's
considered seated/engaged. `tolerances-fits.md`'s "Fit strategy: short
engagement land, not full-depth friction" section argues for a **short**
mating-surface engagement over full-depth friction contact, for exactly the
reason this lib's mating interface needs it: predictable insertion force,
without straight-run/corner clearance errors compounding across a long
contact length. 12mm is chosen as a "short land" in that sense — enough
depth to resist tongue rotation/tip-out under the vertical shelf load
(more than a token few mm) while staying well short of "full-depth" for a
typical rack10 device depth (`rack10_depth_preset()` presets run
200-240mm — see `libraries/rack10/RESEARCH.md`). No source gives a numeric
formula for "how many mm of land resists tip-out for a given tongue
cross-section and shelf load" — this is a design judgment informed by the
short-land *strategy*, not a derived number. `//VERIFY design`, pending a
physical print/load test once Tasks 3-4 build the plate/tongue geometry.

## `rack_support_floor_thickness() = 2` mm

Bearing-floor material thickness inside `rack_support_plate()` (`Z` in
`[0,floor_t]`); the floor's TOP face (`Z=floor_t`) is the actual
load-bearing contact surface, not the floor's bottom (`Z=0`, resting on the
shared rack10 U-floor datum). Originally a `rack_support_plate()`-local
literal (Task 3); promoted to a function in Task 4 because
`rack_support_tongue()` must seat on the exact same Z-offset to bear
correctly against the plate's real floor — a duplicated literal in two
modules would violate this repo's single-source-of-truth rule the moment
one changed without the other. No external spec for "how thick should this
bearing shelf be" — sized as a modest, printable wall thickness (2mm,
above the 0.8mm-ish minimum for a single/few-perimeter shelf on the P1S/PETG
target) that still leaves headroom for the tongue's `rack_support_rail_
size()[1]=10mm` cross-section within a 1U device envelope (`rack10_device_
height(1)` ≈ 43.66mm). `//VERIFY design`, same footing as the other three
mating-interface values — pending a physical print/load check.

## Relationship to `rack10_rear_post_y()` (Task 1)

`rack-support.scad` `use`s `rack10/rack10.scad` for the rear plate's
width/hole/depth context, including `rack10_rear_post_y(standard)` (added in
Task 1, wraps `rack10_depth_preset(standard)`) as the Y coordinate where the
rear-support plate mounts to the rear rack posts. That function's own tier
is `[C]//VERIFY` (it inherits `depth_ftf`'s tier — see
`libraries/rack10/RESEARCH.md`) and is **not** re-derived or re-tiered here;
this file only documents the four DESIGN-value accessors this library adds.
The rear-mirror-of-front-mounting assumption itself (rack10 has no modeled
rear rack posts) remains `//VERIFY`. `rack_support_plate()` (Task 3) now
mounts at that Y coordinate, and `rack_support_tongue()` + the
`assembly.scad` reference demo (Task 4) confirm — via `verify-scad-geometry`
— that a tongue placed at `rack10_rear_post_y(standard) -
rack_support_engagement_depth()` actually seats in the plate's channel; the
underlying `[C]//VERIFY` tier on `rack10_rear_post_y()` itself is unchanged
by that confirmation (it verifies the *mechanism*, not the *rack10 depth
number*).

## No fetch-method narrative

Per this repo's convention, this file cites content source (design-for-print
skill sections, cross-referenced by page/heading) and tier/DESIGN status
only — not how those pages were retrieved.
