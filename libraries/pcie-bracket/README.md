# pcie-bracket (library)

PCIe/PCI card I/O bracket (faceplate) mechanical reference + printable
geometry — low-profile (MD1/MD2) and full-height bracket/card envelopes,
screw hole-stamp, and a support-free `pcie_bracket()` module (faceplate +
chassis-mounting foot, with an optional card-slot cutout or solid blank).
Units: **mm**.

## Import

```scad
use <pcie-bracket/pcie-bracket.scad>;
```

## Functions

| Function | Returns | Notes |
|---|---|---|
| `pcie_known_brackets()` | `["full-height", "low-profile"]` | valid `type` keys |
| `pcie_known_hole_roles()` | `["structural-mount", "component-mount", "keep-out", "alignment"]` | full repo-standard hole-role vocab (only `"structural-mount"` is populated today) |
| `pcie_bracket_size(t)` | `[height, foot_width, thickness]` | see `pcie-bracket.scad` header for the field-order docs and for the two fields (tab length, card-edge offset) deliberately NOT carried as data fields |
| `pcie_bracket_holes(t, role=undef)` | `[[x, y, role, dia], ...]` | one `"structural-mount"` screw hole per type; `role="all"` is a synonym for `undef`; an unknown `role` (not in the vocab) asserts, a known-but-absent role legally returns `[]` |
| `pcie_bracket_holes_xy(t, role=undef)` | `[[x, y], ...]` | `pcie_bracket_holes()` coordinate pairs only |

## Modules

| Module | Signature | Notes |
|---|---|---|
| `pcie_bracket_mount_holes` | `(type, dia=-1, depth=6)` | vertical (Z-axis) hole-stamp for the structural-mount screw(s); `dia<0` uses each hole's own tabulated clearance diameter |
| `pcie_bracket` | `(type, blank=false)` | faceplate + chassis-mounting foot, in the reference/installed frame (see header: `Y=0` back plane, `X=0` card-slot centerline, foot at `Z<0`, faceplate growing `+Z`); `blank=false` (default) cuts a card-slot window sized from this bracket's own envelope, `blank=true` ships a solid filler panel; the screw hole from `pcie_bracket_mount_holes()` is always cut |

## Print orientation

The reference frame above (foot lying in the XY plane, faceplate standing up
in Z) **is** the recommended print orientation — print un-rotated, straight
off this frame, no `rotate()` needed. The faceplate's footprint (`foot_width`
x `thickness`, only 0.8mm deep in Y) sits entirely within the wider foot's
footprint (`foot_width` x 15mm tab depth in Y) at their shared Z=0 seam, so
every faceplate layer has solid foot material directly below it — no
overhang, no cantilever.

An earlier version of this note recommended rotating the part **90° about
X** (`rotate([-90,0,0])`) before slicing, on the theory that it would lay the
faceplate flat and turn the foot into a self-supporting wall
("printed-in-plane"). That was **wrong** and was disproven by rendering it:
under that rotation the wide, up-to-120.65mm faceplate ends up balanced on
top of the foot's narrow 0.8mm-thin post — a severe unsupported cantilever.
Do not rotate this part before slicing.

The tall faceplate's tip/warp/snap risk when standing in Z is a real
slicer-level concern (use a brim or an orientation lock in the slicer if
needed) but is not a geometry problem and does not change the support-free
verdict above. See `pcie-bracket.scad`'s header comment for the full
design-for-print reasoning: in the un-rotated orientation the faceplate
footprint sits fully within the foot footprint, so there is no unsupported
overhang.

## Sources

Full source list + per-value tiering is in `RESEARCH.md`. Tiers (see
`docs/LIBRARY-AUTHORING.md`): **[A]** governing spec/vendor drawing fetched +
read this pass; **[B]** corroborated across ≥2 independent peers, including a
named standard cited (not fetched, e.g. member-paywalled) but whose figures
are repeated consistently by independent secondary sources; **[C]**
single-sourced / derived (`//VERIFY` marks a weak value pending stronger
corroboration).

Both governing PCI-SIG documents (the Low Profile PCI ECN for low-profile
brackets, the CEM spec for full-height) are member-paywalled and were not
fetched this pass — every dimension below is `[B]`/`[C]` via corroborated
secondary sources, never `[A]`.

| Type | Dim tier | Hole tier | Source(s) |
|---|---|---|---|
| low-profile (LP) | `[B]` height/foot-width (accio.com + flykantech.com, attributed to PCI-SIG's Low Profile PCI ECN — community-corroborated, paywalled); `[C]` `//VERIFY` thickness (single PL-Tronic drawing) | `//VERIFY` screw Y position (reasoned placeholder, not tiered — see `pcie-bracket.scad` header); `[B]` LP-vs-FH screw delta (−1.35mm) | PCI-SIG "Low Profile PCI" ECN (named, paywalled); accio.com; flykantech.com; PL-Tronic/brackets.nl `pcb3.gif` |
| full-height (FH) | `[B]` height/foot-width (accio.com, attributed to PCI-SIG's CEM spec — community-corroborated, paywalled); `[C]` `//VERIFY` thickness (shared LP figure, not independently confirmed for FH) | `//VERIFY` screw Y position (reasoned placeholder, not tiered) | PCI-SIG PCI Express CEM Spec (named, paywalled); accio.com; flykantech.com; PL-Tronic/brackets.nl `pcb2.gif` |

Two values are deliberately **not** re-researched here because another
library already owns them (single-source-of-truth rule): PCIe slot pitch
(`mobo_pcie_pitch()`, `libraries/motherboards/motherboards.scad`) and the
motherboard-side rear-edge-to-connector `setback` (`mobo_pcie_ports()`, same
file) — see `RESEARCH.md`'s cross-reference notes.

Task 3's two print-design constants (`_pcie_tab_depth()` = 15mm foot Y-depth,
`_pcie_cutout_width_frac()`/`_pcie_cutout_height_frac()` = 0.65/0.55 card-slot
cutout fractions) are **not** sourced dimensions — they are reasoned
design-for-print/design choices tagged `//VERIFY` in `pcie-bracket.scad`, not
`[B]`/`[C]` tiered claims. See the header comment for the full reasoning.

## Coverage

- Both bracket classes (low-profile, full-height): overall height, shared
  foot/flange width, sheet-metal thickness gauge, one structural-mount screw
  hole (position is a reasoned placeholder, not sourced — see header).
- `pcie_bracket()` models the faceplate + chassis-mounting foot and cuts
  either a card-slot window (sized from this bracket's own envelope, a
  design choice — NOT derived from `motherboards.scad`'s `setback`, a
  different measurement) or ships a solid blank filler panel.
- **Not covered** (see `RESEARCH.md`'s gap list): tab/notch fold geometry
  beyond the flat foot-width figure (Task 3 substitutes a reasoned
  print-design constant, not a sourced dimension); a bracket-specific
  card-edge-to-bracket offset (cross-referenced, not re-derived, from
  `motherboards.scad`); full-height screw-to-screw spacing for 2-hole
  variants (two disagreeing single-sourced figures, neither adopted); an
  independent full-height thickness figure (the LP figure is applied to
  both classes, unconfirmed for FH).

## Unify audit

No existing in-repo PCIe consumer; this is a precursor lib — future **#43**
(2U mini-ITX chassis) will consume it (build-on, not retrofit).
