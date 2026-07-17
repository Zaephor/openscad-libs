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

Ships all four roles: **data** (functions — `use` doesn't import
variables), **placeholder** (`keystone_placeholder()`, a jack-envelope
keep-out solid for interference viz), **hole-stamp**
(`keystone_cutout()`/`keystone_insert()`, a consumer `difference()` window
and a geometric mate-reference body), and **fit-check**
(`keystone_pitch()`/`keystone_min_pitch()`/`keystone_pitch_ok()`/
`keystone_layout_ok()`/`keystone_pitch_assert()`, a single-source
port-spacing guard).

`keystone_insert()` is a geometric mate-reference only — **not
print-tuned** (a print-ready flexing-latch insert is out of scope for
v1); it exists so a consumer can drop it into `keystone_cutout()` for a
virtual mate-check (see Verification below), not to print as a
functional jack.

## Usage

```scad
use <keystone/keystone.scad>;

o = keystone_opening();          // [14.70, 16.40]
b = keystone_body();             // [17.5, 19.5, 28.60]
pt = keystone_plate_thickness(); // [1.5, 3.0]

// Port-spacing fit check before laying out N ports across a faceplate:
xs = [for (i = [0:3]) i * keystone_pitch()];
assert(keystone_layout_ok(xs), "ports too close together");
keystone_pitch_assert(keystone_pitch()); // hard-fail at render if too tight

// A faceplate: cut the window, place a jack keep-out for interference viz.
difference() {
    translate([-30, -20, -3]) cube([60, 40, 3]);
    keystone_cutout(plate_thickness = 3.0);
}
color("orange") keystone_placeholder();

// Virtual mate-check: drop the insert into the cutout (see renders/ below).
keystone_insert(plate_thickness = 3.0);
```

## Reference

| Function/module | Returns / does |
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
| `keystone_pitch_assert(pitch)` | module; hard-fails render (stderr assert) if `pitch` is below `keystone_min_pitch()` |
| `keystone_placeholder()` | module; jack envelope solid (`keystone_body()`), flange face at `Z=0`, body into `-Z` — fit/interference viz only |
| `keystone_cutout(plate_thickness=3.0, clearance=0.25)` | module; plain rectangular through-hole for a consumer `difference()`, sized `keystone_opening()` + `2*clearance` per side, overcut 1mm above/below the plate |
| `keystone_insert(plate_thickness=3.0, fit=0.2)` | module; geometric mate-reference body (flange + through-plug + `+Y` hook + `-Y` latch bump), narrowed by `fit` per side so it threads `keystone_cutout()`'s window |

## Verification

`keystone_insert()` dropped into a plate with `keystone_cutout()` removed
(both at default params) is the library's virtual mate-check — the plug
should fill the window, the flange should stop flush at the front face
(`Z=0`), the latch should clear the plate rear, and the `+Y` hook should
sit inside the cutout window without touching solid frame material.

![keystone insert/cutout overlay mate-check](renders/mate-overlay-yz.png)

![+Y hook detail, zoomed](renders/hook-detail-yz.png)

The hook detail render overlays the cutout window's Y-bound (`o[1]/2 +
clearance`, red) and the raw opening edge (`o[1]/2`, green) against the
hook body (orange): the hook's Y-extent is clamped to end exactly at the
raw opening edge, so it never reaches — let alone crosses — the window
bound, for any `clearance >= 0` a consumer chooses.

## Sources

Provenance tiers (see `keystone.scad` header / `RESEARCH.md` for the full
evidence log): **[A]** vendor datasheet / governing drawing, **[B]**
corroborated across >=2 independent peers, **[C]** reverse-engineered from a
public STL/SCAD mesh (cite the artifact URL). `//VERIFY` marks a weak/
unsourced value — never a tier it didn't earn (a single, non-decomposed
drawing reading or a single secondary source does NOT qualify as `[C]`/`[B]`).

| Source | Tier | Backs |
|---|---|---|
| [Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical drawing](https://telecom.samm.com/Data/EditorFiles/Datasheets/9-copper-network-products/Unshielded-ISO-IEC-Keystone-Jack-Drawing-Samm-Teknoloji.pdf) | A | `keystone_opening()` (Plastic suggested panel cutout), `keystone_plate_thickness()[0]` (tmin); also the sole reading behind `keystone_body()[2]` (bd, `//VERIFY`) |
| [Wikipedia, "Keystone module"](https://en.wikipedia.org/wiki/Keystone_module) | B | corroborates `keystone_opening()`; also the sole secondary source behind the qualitative fixed-hook/flexing-latch asymmetry behind `keystone_tab()` (`//VERIFY`) |
| [Monoprice keystone jack patch-panel listings](https://www.monoprice.com/category/networking/patch-panels/keystone-jack-panel) | B | `keystone_pitch()` (3/4in / 19.05mm de-facto port spacing) |

### Coverage / not yet covered

- Sourced + tiered: `keystone_opening()` [A]/[B], `keystone_pitch()` [B],
  `keystone_plate_thickness()[0]` (tmin) [A].
- Still `//VERIFY` (flagged for a future research pass, not invented):
  `keystone_body()[0]`/`[1]` (bw, bh — axis-mapping from the vendor drawing
  unresolved), `keystone_body()[2]` (bd — single, non-decomposed drawing
  reading, not corroborated by a second source), `keystone_plate_thickness()[1]`
  (tmax — no accepted-upper-bound source found), `keystone_min_wall()` (no
  source at all — repo print-process convention, not a keystone-specific
  spec), `keystone_tab()[0]`/`[1]` (hook_ledge_z, tab_thickness — no numeric
  latch source found; both carried unchanged from the task seed), and
  `keystone_tab()[2]`/`[3]` (hook_edge, latch_edge — asymmetric-mechanism
  claim backed by exactly one secondary source, not the >=2 independent
  sources `[B]` requires). See `RESEARCH.md`'s `//VERIFY` census before
  treating these as load-bearing for a tight-fit design — in particular,
  `keystone_insert()` is a geometric mate-reference built on the
  `//VERIFY` tab numerics, **not** print-tuned, so it should not be printed
  as a functional latch without a real jack/drawing measurement first.
- All four roles are implemented: data, `keystone_placeholder()`,
  `keystone_cutout()`/`keystone_insert()`, and the fit-check family
  (`keystone_pitch_assert()` included). The insert's `+Y` hook Y-extent is
  clamped to `fit` (not the full `tab_thickness`) specifically so it can
  never protrude past the cutout window for any non-negative `clearance` —
  see the overlay mate-check render above.
