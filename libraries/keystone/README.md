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
and the opening / show-face faces **+Z**. `keystone_opening(style)` is the X
width x Y height of the plate window a consumer cuts; `keystone_body()` is
the X, Y extents x Z depth of the jack envelope behind the panel (a
keep-out volume, not print geometry). Consumers rotate the whole port to
match their own panel orientation (e.g. `rotate([-90,0,0])` for a vertical
1U faceplate) rather than this library baking in a rack/panel-specific
orientation.

## Retention styles (Task #28)

The library now supports two retention styles — **pass `style=` to
`keystone_opening()` and `keystone_cutout()` to choose**:

- **`"face"` (face-grip)** — `[14.70, 16.40]` mm. Retention by front/rear
  plate-thickness squeeze. Original Samm Teknoloji suggested panel cutout
  [A]. Use for face-plate panels where the latch mechanism relies on plate
  clamping.
- **`"lip"` (rotate-and-snap, **default**)** — `[14.90, 22.90]` mm (#31,
  measured from a real cutout-negative STL — see Sources below). Insert at
  an angle: a **rigid hook** on the window's top (`+Y`) edge rides a ramped
  lead-in and seats into a shallow pocket near the front; then the jack
  rotates in and a **flexible latch** on the bottom (`-Y`) edge deflects
  down a second, deeper ramp and snaps behind the bottom lip. See
  `keystone_latch()` for the full measured profile. Use for 3D-printed
  plastic plates where the snap mechanism (rather than plate thickness)
  drives retention; pair `keystone_cutout(...,"lip")` with
  `keystone_boss(...,"lip")` (see Reference below) since the mechanism needs
  more Z depth than a thin panel alone provides.

**Backward-compatibility note:** Pre-#28 code called `keystone_opening()`
with no arguments and got `[14.70, 16.40]` (the face-grip window). As of
#28, the **default has changed to `"lip"`**; as of #31, `"lip"`'s value is
`[14.90, 22.90]` (previously `[14.8, 20.3]`, a placeholder later replaced by
real STL-mesh measurement — see Sources below). If your design relies on
the original behavior, pass `style="face"` explicitly to
`keystone_opening()` and `keystone_cutout()`.

## Import

```scad
use <keystone/keystone.scad>;
```

Ships all four roles: **data** (functions — `use` doesn't import
variables), **placeholder** (`keystone_placeholder()`, a jack-envelope
keep-out solid for interference viz), **hole-stamp**
(`keystone_cutout()`/`keystone_boss()`/`keystone_insert()` — a consumer
`difference()` window, the local positive material a thin "lip" panel needs
to host that window (#31), and a geometric mate-reference body), and
**fit-check** (`keystone_pitch()`/`keystone_min_pitch()`/
`keystone_pitch_ok()`/`keystone_layout_ok()`/`keystone_pitch_assert()`, a
single-source, style-aware port-spacing guard).

`keystone_insert()` is a geometric mate-reference only — **not
print-tuned** (a print-ready flexing-latch insert is out of scope for
v1); it exists so a consumer can drop it into `keystone_cutout()` for a
virtual mate-check (see Verification below), not to print as a
functional jack.

## Usage

```scad
use <keystone/keystone.scad>;

// Basic data
f = keystone_face();             // [14.5, 16.0] invariant jack face
o = keystone_opening("lip");     // [14.90, 22.90] lip (rotate-and-snap, default; #31)
o = keystone_opening("face");    // [14.70, 16.40] face-grip (original)
b = keystone_body();             // [17.5, 19.5, 28.60]
pt = keystone_plate_thickness(); // [1.5, 3.0]
l = keystone_latch("lip");       // [width,front_h,hook_z,hook_h,pocket_z,latch_z,latch_h] (#31)

// Port-spacing fit check before laying out N ports across a faceplate
// (style-aware since #31 -- "lip" is boss-footprint-driven, wider than the
// raw opening; "face" is unchanged):
xs = [for (i = [0:3]) i * keystone_pitch()];
assert(keystone_layout_ok(xs, "lip"), "ports too close together");
keystone_pitch_assert(keystone_pitch(), "lip"); // hard-fail at render if too tight

// A faceplate with lip-style windows (default) -- pair keystone_boss() with
// keystone_cutout() since the "lip" mechanism needs more Z depth than a
// thin panel alone provides (#31):
difference() {
    union() {
        translate([-30, -20, -3]) cube([60, 40, 3]);
        keystone_boss(plate_thickness = 3.0);   // default style="lip"
    }
    keystone_cutout(plate_thickness = 3.0);  // default style="lip"
}
color("orange") keystone_placeholder();

// Face-grip style (original, if needed):
difference() {
    translate([-30, -20, -3]) cube([60, 40, 3]);
    keystone_cutout(plate_thickness = 3.0, style = "face");
}

// Virtual mate-check: drop the insert into the cutout (see renders/ below).
keystone_insert(plate_thickness = 3.0);
```

## Reference

| Function/module | Returns / does |
|---|---|
| `keystone_known_styles()` | `["lip", "face"]` — list of supported retention styles |
| `keystone_face()` | `[14.5, 16.0]` — invariant jack face / plug cross-section, mm |
| `keystone_opening(style="lip")` | `[ow, oh]` — plate window (X width, Y height) per retention style, mm |
| `keystone_body()` | `[bw, bh, bd]` — jack envelope keep-out (X, Y, Z-depth behind panel), mm |
| `keystone_plate_thickness()` | `[tmin, tmax]` — accepted faceplate thickness range, mm |
| `keystone_pitch()` | nominal center-to-center port spacing in a strip, mm |
| `keystone_min_wall()` | minimum printable material wall between adjacent openings, mm |
| `keystone_tab(style="lip")` | `[hook_ledge_z, tab_thickness, hook_edge, latch_edge]` — retention-tab geometry per retention style (mate-reference numerics only, unchanged by #31 — see `keystone_latch()` for the corrected, measurement-backed top/bottom assignment); `hook_edge`/`latch_edge` are `"+Y"`/`"-Y"` naming the two long edges. `"face"`: fixed hook (`+Y`) + flexing latch (`-Y`) grip the plate's front/rear faces. `"lip"`: fulcrum (`-Y`) + flex clip (`+Y`) grip the opening's bottom/top lips instead of the plate faces |
| `keystone_latch(style="lip")` | `[width, front_h, hook_z, hook_h, pocket_z, latch_z, latch_h]` (#31) — REAL measured hook/flex-latch retention profile (RESEARCH.md, STL-mesh, `[C]//VERIFY`); `"lip"` only. Rigid hook on top (`+Y`, shallow/near-front); flexible latch on bottom (`-Y`, deeper) — the *opposite* depth assignment from `keystone_tab()`'s pre-#28 guess. Single source of truth for `keystone_opening("lip")`, `keystone_cutout(...,"lip")`, and `keystone_boss(...,"lip")` |
| `keystone_boss_footprint(style="lip", clearance=0.25)` | `[w, h, y_center]` (#31) — rectangular footprint for `keystone_boss()`: the `"lip"` cutout's max envelope + `keystone_min_wall()` margin per side; `y_center != 0` (the mechanism's top/bottom edges are asymmetric). `"lip"` only |
| `keystone_min_pitch(style="lip")` | minimum center-to-center that still leaves a printable wall. `"face"`: `keystone_opening(style)[0] + keystone_min_wall()` (unchanged). `"lip"` (#31): `keystone_boss_footprint(style)[0]` — boss-footprint-driven, since two adjacent bosses (not just the raw openings) must clear each other |
| `keystone_pitch_ok(pitch, style="lip")` | true if `pitch >= keystone_min_pitch(style)` |
| `keystone_layout_ok(xs, style="lip")` | true if every adjacent gap in ascending X-center list `xs` clears `keystone_min_pitch(style)` |
| `keystone_pitch_assert(pitch, style="lip")` | module; hard-fails render (stderr assert) if `pitch` is below `keystone_min_pitch(style)` |
| `keystone_placeholder()` | module; jack envelope solid (`keystone_body()`), flange face at `Z=0`, body into `-Z` — fit/interference viz only |
| `keystone_cutout(plate_thickness=3.0, clearance=0.25, style="lip")` | module; `"face"`: plain rectangular through-hole for a consumer `difference()`, sized `keystone_opening(style)` + `2*clearance` per side, overcut 1mm above/below the plate (unchanged). `"lip"` (#31): the REAL lipped negative — a front window necking through a top-edge hook ramp+pocket then a bottom-edge latch ramp+plateau (`keystone_latch()`), leaving real lip material a hook/latch can engage. Its Z-extent is **plate-thickness-independent** (the ~8.3mm mechanism exceeds `keystone_plate_thickness()`'s range) — pair with `keystone_boss()` below so the cut always lands in solid material. Print orientation: panel front face **down** on the bed (pins the support-free ramp direction — see the module comment) |
| `keystone_boss(plate_thickness=3.0, clearance=0.25, style="lip")` | module (#31); `"face"`: no-op. `"lip"`: LOCAL positive material behind a thin panel — a constant-footprint rectangular pedestal (front flush with the panel front, `Z=0`, growing `-Z` the full mechanism depth via `keystone_boss_footprint()`) so `keystone_cutout(...,"lip")` always cuts real solid regardless of `plate_thickness`. `union()` this into the plate *before* differencing the cutout (see Usage above) |
| `keystone_insert(plate_thickness=3.0, fit=0.2, style="lip")` | module; geometric mate-reference body (flange + through-plug + two retention tabs), narrowed by `fit` per side so it threads `keystone_cutout(style)`'s window. `"face"`: `+Y` hook + `-Y` latch bump grip the plate's front/rear faces (plate-thickness squeeze). `"lip"` (default, #31 Task 3): `keystone_latch(style)`-derived, not `keystone_tab()`-derived — a rigid hook on `+Y` (top, shallow) fills the hook-pocket zone and a flexible latch on `-Y` (bottom, deep) fills the latch-plateau zone, grips the opening's top/bottom lips (rotate-and-snap) |

## Verification

`keystone_insert()` dropped into a plate with `keystone_cutout()` removed
(both at default params) is the library's virtual mate-check — the plug
should fill the window and the flange should stop flush at the front face
(`Z=0`). For `"lip"` (default, #31 Task 3): the rigid `+Y` hook (shallow)
should seat in the hook-pocket zone and the flexible `-Y` latch (deep)
should seat in the latch-plateau zone, both without touching solid frame
material. For `"face"`: the `+Y` hook should sit inside the cutout window
without touching solid frame material, and the `-Y` latch should clear the
plate rear.

![keystone insert/cutout overlay mate-check](renders/mate-overlay-yz.png)

![+Y hook detail, zoomed](renders/hook-detail-yz.png)

**These renders predate #31** and were generated against the pre-#31
`"face"`-style single-hook geometry; they have not been regenerated since,
so they visually show the old mechanism even though the underlying code
(`keystone_insert()`/`keystone_cutout()`) is current for both styles — don't
rely on them for `"lip"`'s current hook/latch shape.

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
| [Samm Teknoloji A.Ş., "Unshielded ISO/IEC Keystone Jack" mechanical drawing](https://telecom.samm.com/Data/EditorFiles/Datasheets/9-copper-network-products/Unshielded-ISO-IEC-Keystone-Jack-Drawing-Samm-Teknoloji.pdf) | A | `keystone_opening("face")` (Plastic suggested panel cutout), `keystone_plate_thickness()[0]` (tmin); also the sole reading behind `keystone_body()[2]` (bd, `//VERIFY`) |
| [Wikipedia, "Keystone module"](https://en.wikipedia.org/wiki/Keystone_module) | B | `keystone_face()` (invariant jack face / plug cross-section); also corroborates `keystone_opening("face")`; also the sole secondary source behind the qualitative fixed-hook/flexing-latch asymmetry behind `keystone_tab()` (`//VERIFY`) |
| [Monoprice keystone jack patch-panel listings](https://www.monoprice.com/category/networking/patch-panels/keystone-jack-panel) | B | `keystone_pitch()` (3/4in / 19.05mm de-facto port spacing) |
| ["Keystone Jack v2 integration aide" by SimplifiedLife, Printables 1027864](https://www.printables.com/model/1027864) | C//VERIFY | `keystone_latch("lip")` and, through it, `keystone_opening("lip")` (#31) — single-mesh STL cross-section reading of the cutout negative; replaces the pre-#31 `[14.8, 20.3]` community-guess placeholder |
| ["Keystone blank" by pmichaud, Printables 587874](https://www.printables.com/model/587874) / ["(Parametric) Keystone Connector" by Paul Hatcher, Printables 537480](https://www.printables.com/model/537480) | C (front face) | corroborate `keystone_face()` as a 2nd/3rd independent model (#31); retention-flare geometry stays `//VERIFY` (parametric, author-chosen, not used here) |

### Coverage / not yet covered

- Sourced + tiered: `keystone_opening("face")` [A] (Samm)/[B] (Wikipedia
  corroboration), `keystone_face()` [B] (Wikipedia, corroborated [C] by two
  more independent models per #31), `keystone_opening("lip")` and
  `keystone_latch("lip")` [C]//VERIFY (#31, single-mesh STL cross-section —
  replaces the pre-#31 width-only-[B] community placeholder), `keystone_pitch()`
  [B], `keystone_plate_thickness()[0]` (tmin) [A].
- Still `//VERIFY` (flagged for a future research pass, not invented):
  `keystone_opening("lip")`/`keystone_latch("lip")` (#31 — single-mesh
  reading, not solid-model-cross-checked and no 2nd independent
  cutout-negative model in scope this pass; **this is the default
  retention style's opening**, so treat the exact millimeter values as
  caliper-upgradeable even though the *shape* — ramp-then-pocket,
  staged hook-then-latch, ~45° angles — is now measurement-grounded),
  `keystone_body()[0]`/`[1]` (bw, bh — axis-mapping from the vendor drawing
  unresolved, though #31's insert-envelope corroboration (17.0x19.5mm)
  is a promising future-upgrade lead), `keystone_body()[2]` (bd — single,
  non-decomposed drawing reading, not corroborated by a second source),
  `keystone_plate_thickness()[1]` (tmax — no accepted-upper-bound source
  found), `keystone_min_wall()` (no source at all — repo print-process
  convention, not a keystone-specific spec), `keystone_tab()` (all fields —
  mate-reference-only numerics, unchanged by #31; its `"lip"` branch's
  hook_edge/latch_edge top/bottom assignment is the *opposite* of
  `keystone_latch("lip")`'s measured mechanism, confirmed backwards by
  `keystone_tab()`'s own doc comment (#31) — it is left as a known-stale,
  unused-for-`"lip"` accessor. `keystone_insert(...,"lip")` no longer reads
  it: as of #31 Task 3 it derives from `keystone_latch()` instead).
  See `RESEARCH.md`'s `//VERIFY` census before treating these as
  load-bearing for a tight-fit design — in particular, `keystone_insert()`
  is a geometric mate-reference built on `//VERIFY`-tier numerics
  (`keystone_tab()` for `"face"`, `keystone_latch()` for `"lip"`), **not**
  print-tuned, so it should not be printed as a functional latch without a
  real jack/drawing measurement first.
- All four roles are implemented: data, `keystone_placeholder()`,
  `keystone_cutout()`/`keystone_boss()`/`keystone_insert()`, and the
  fit-check family (`keystone_pitch_assert()` included, style-aware since
  #31). The insert's `+Y` hook Y-extent is clamped to `fit` (not the full
  `tab_thickness`) specifically so it can never protrude past the cutout
  window for any non-negative `clearance` — see the overlay mate-check
  render above (pre-#31 cutout shape; see caveat above).
