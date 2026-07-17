# keystone (library)

Reference data for the de-facto **keystone-jack snap footprint** — the
single, near-universal rectangular snap profile used by network-jack
(RJ45/RJ45A, coax, fiber, HDMI, etc.) modules and the wall plates / patch
panels / equipment-tray faceplates that host them. "Keystone" isn't one
manufacturer's part; it's an interchangeable footprint any compliant
jack/plate shares, so this library's job is to be the **single source of
truth** for that footprint's opening, body keep-out, plate-thickness range,
port pitch, minimum printable wall, and retention-tab geometry — every
consumer library/project reads these accessors rather than copying numbers.
Units: **mm**.

## Datum

Panel-mount default orientation: the panel **front face sits on `Z=0`**,
**centered in X/Y**. The jack **body grows into `-Z`** (behind the panel),
and the opening / show-face faces **+Z**. `keystone_opening()` is the X
width x Y height of the plate window a consumer cuts; `keystone_body()` is
the X, Y extents x Z depth of the jack envelope behind the panel (a
keep-out volume, not print geometry). Consumers rotate the whole port to
match their own panel orientation (e.g. `rotate([-90,0,0])` for a vertical
1U faceplate) rather than this library baking in a rack/panel-specific
orientation.

## Import

```scad
use <keystone/keystone.scad>;
```

Role-1 **data** library (this task) — functions only, no top-level
variables (`use` does not import them). Placeholder/cutout/insert
geometry (roles 2-3) and the `keystone_pitch_assert()` guard are added in
later tasks; this version ships data + accessors + the fit-check helper
functions the geometry roles will build on.

## Usage

```scad
use <keystone/keystone.scad>;

o = keystone_opening();          // [14.70, 16.40]
b = keystone_body();             // [17.5, 19.5, 28.60]
pt = keystone_plate_thickness(); // [1.5, 3.0]

// Port-spacing fit check before laying out N ports across a faceplate:
xs = [for (i = [0:3]) i * keystone_pitch()];
assert(keystone_layout_ok(xs), "ports too close together");
```

## Reference

| Function | Returns |
|---|---|
| `keystone_opening()` | `[ow, oh]` — plate window (X width, Y height), mm |
| `keystone_body()` | `[bw, bh, bd]` — jack envelope keep-out (X, Y, Z-depth behind panel), mm |
| `keystone_plate_thickness()` | `[tmin, tmax]` — accepted faceplate thickness range, mm |
| `keystone_pitch()` | nominal center-to-center port spacing in a strip, mm |
| `keystone_min_wall()` | minimum printable material wall between adjacent openings, mm |
| `keystone_tab()` | `[hook_ledge_z, tab_thickness, hook_edge, latch_edge]` — retention-tab geometry; `hook_edge`/`latch_edge` are `"+Y"`/`"-Y"` naming the fixed-hook vs. flexing-latch long edge |
| `keystone_min_pitch()` | `keystone_opening()[0] + keystone_min_wall()` — minimum center-to-center that still leaves a printable wall |
| `keystone_pitch_ok(pitch)` | true if `pitch >= keystone_min_pitch()` |
| `keystone_layout_ok(xs)` | true if every adjacent gap in ascending X-center list `xs` clears `keystone_min_pitch()` |

## Sources

Provenance tiers (see `keystone.scad` header / `RESEARCH.md` for the full
evidence log): **[A]** vendor datasheet / governing drawing, **[B]**
corroborated across >=2 independent peers, **[C]** single-sourced /
drawing-derived. `//VERIFY` marks a weak/unsourced value.

| Source | Tier | Backs |
|---|---|---|
| [Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical drawing](https://telecom.samm.com/Data/EditorFiles/Datasheets/9-copper-network-products/Unshielded-ISO-IEC-Keystone-Jack-Drawing-Samm-Teknoloji.pdf) | A | `keystone_opening()` (Plastic suggested panel cutout), `keystone_body()[2]` (bd, assembly depth), `keystone_plate_thickness()[0]` (tmin) |
| [Wikipedia, "Keystone module"](https://en.wikipedia.org/wiki/Keystone_module) | B | corroborates `keystone_opening()`; backs the qualitative fixed-hook/flexing-latch asymmetry behind `keystone_tab()` |
| [Monoprice keystone jack patch-panel listings](https://www.monoprice.com/category/networking/patch-panels/keystone-jack-panel) | B | `keystone_pitch()` (3/4in / 19.05mm de-facto port spacing) |

### Coverage / not yet covered

- Sourced + tiered this pass: `keystone_opening()` [A]/[B], `keystone_pitch()`
  [B], `keystone_plate_thickness()[0]` (tmin) [A], `keystone_body()[2]` (bd)
  [C], and the qualitative hook/latch edge asymmetry behind `keystone_tab()`
  [B].
- Still `//VERIFY` (flagged for a future research pass, not invented):
  `keystone_body()[0]`/`[1]` (bw, bh — axis-mapping from the vendor drawing
  unresolved), `keystone_plate_thickness()[1]` (tmax — no accepted-upper-
  bound source found), `keystone_tab()[0]`/`[1]` (hook_ledge_z,
  tab_thickness — no numeric latch source found). See `RESEARCH.md`'s
  `//VERIFY` census before treating these as load-bearing for a tight-fit
  design.
- Not yet implemented (future tasks per the keystone-lib plan):
  `keystone_placeholder()` (role 2), `keystone_cutout()`/`keystone_insert()`
  (role 3), `keystone_pitch_assert()`.
