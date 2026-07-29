# rack-support — evidence source log

Evidence/provenance log for `rack-support.scad`'s mating-interface accessors
(`rack_support_rail_size()`, `rack_support_slot_clearance()`,
`rack_support_engagement_depth()`, `rack_support_floor_thickness()`,
`rack_support_gusset_rib()`) and the `rack_support_plate_keepout()` module's
`margin` default. Unlike most libraries in this repo, these values are
**not** measured or spec-sourced dimensions of a real-world part — there is
no vendor part, standard, or physical artifact to measure. They are
**DESIGN values**: fit-clearance and engagement choices for a slide-in
tongue/slot mechanism this library itself defines (rear-support plate
presenting a channel; a consumer tray's `rack_support_tongue()` slides
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

## `rack_support_gusset_rib() = 10` mm (each of two ribs flanking the channel)

Width of the 45° gusset rib left standing on either side of the channel
slot, after the channel-cavity cut removes the gusset's central,
slot-width band (see `rack_support_plate()`'s own header comment for the
cut geometry). An earlier revision built the gusset full panel-width
before that cut, which made the plate's solid envelope span the entire
panel over `Z` in `[0, engagement_depth]` — that collided with any
consumer body reaching the rear post plane (#63, measured 875.89mm³ and
3554.86mm³ interference in this library's own reference tray and the
`bay-enclosure` project respectively). No external spec exists for a
mechanism this library invents; 10mm is a plain engineering judgment —
wide enough that each rib stays solidly bonded to both the bearing floor
slab and the mounting wall (this library's own structural role: the
gusset braces the floor's cantilever, see that module's Z-DATUM comment),
while narrow enough to leave most of the panel width free for consumer
geometry per `design-for-print` guidance on keeping ribs/gussets minimal
rather than over-built. `//VERIFY design`, same footing as the other
mating-interface values — pending a physical print/load check.

## `rack_support_plate_keepout(margin)` default `= 0` mm

`margin` inflates the keep-out envelope's two free gusset-wedge vertices
and the floor slab's reach/width, for a consumer that wants assembly
clearance beyond an exact fit (the channel-cavity cut itself is excluded
from `margin`'s effect — see the module's own header comment and the
README's "channel-cavity exclusion" note). The default of `0` mm gives the
exact envelope `rack_support_plate()` actually occupies — no external spec
governs this either, and unlike the other DESIGN values above it isn't
even a fit-clearance choice: it is the identity/no-op default for an
inflation parameter, chosen so a consumer that doesn't need extra margin
gets a keep-out that matches the plate's real solid material exactly, per
this library's own single-source-of-truth structure (the keep-out is
composed from the same accessors the plate itself reads) and
`design-for-print` guidance to avoid unnecessary blanket clearance.
`bay-enclosure` overrides it to `0.2`mm for its own assembly-clearance
reasons (see that project's own comment at the subtraction site); that
override is project-local judgment, not a change to this library's
default. `//VERIFY design`.

## Relationship to `rack10_rear_post_y()` (Task 1)

`rack-support.scad` `use`s `rack10/rack10.scad` for the rear plate's
width/hole/depth context, including `rack10_rear_post_y(standard)` (added in
Task 1, wraps `rack10_depth_preset(standard)`) as the Y coordinate where the
rear-support plate mounts to the rear rack posts. That function's own tier
is `[C]//VERIFY` (it inherits `depth_ftf`'s tier — see
`libraries/rack10/RESEARCH.md`) and is **not** re-derived or re-tiered here;
this file only documents the DESIGN-value accessors this library adds
(the four mating-interface values above, plus `rack_support_gusset_rib()`
and `rack_support_plate_keepout()`'s `margin` default). The
rear-mirror-of-front-mounting assumption itself (rack10 has no modeled
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
