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

The flagship `keystone_insert()` (#54) — a caliper-faithful, support-free
printable blank insert — is consumed as-is by the
[keystone-blank](../../projects/keystone-blank) project.

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

## Retention styles (#38)

The library supports two retention styles — **pass `style=` to
`keystone_opening()` and `keystone_cutout()` to choose**:

- **`"face"` (face-grip)** — `[14.70, 16.40]` mm. Retention by front/rear
  plate-thickness squeeze. Original Samm Teknoloji suggested panel cutout
  [A]. Use for face-plate panels where the latch mechanism relies on plate
  clamping.
- **`"standard"` (push-to-click channel, **default**)** — `[15.3, 22.25]` mm
  (#38, the directly measured max window at slit onset from one of two
  independently mesh-sectioned panel/skirt STLs — see Sources below; the
  cross-model corroboration between the two covers the *shape*, not this
  exact figure, which stays `//VERIFY`, single-model). A `[`-shaped channel
  (back wall + top/bottom walls) with a wide
  slit cut clean through EACH of the top and bottom walls. The jack is
  presented near-flush and pushed straight in (no rotation): a solid
  **fulcrum** on its underside and a flexing **arm** on its top each carry a
  small triangular notch, and both notches click into their respective slit
  at the SAME insertion depth. See `keystone_slot()` for the channel/slit
  geometry and `keystone_notch()` for the jack-side fulcrum/arm geometry.
  Use for 3D-printed plastic plates where the click mechanism (rather than
  plate thickness) drives retention; pair `keystone_cutout(...,"standard")`
  with `keystone_boss(...,"standard")` (see Reference below) since the
  mechanism needs more Z depth than a thin panel alone provides.

**`"lip"` is a deprecated alias for `"standard"`.** #31 originally measured
a *different* real keystone mechanism (rotate-and-snap: a rigid hook near
the front engaging first, then a flexible latch further back, staged at
different depths) under the key `"lip"`. #38 corrected course: that
mechanism, while real, is not what the overwhelming majority of
commodity/generic keystone jacks and panels actually use — the de-facto
standard is the push-to-click, same-depth channel+slit mechanism above.
`"lip"` now resolves to `"standard"` rather than naming a second first-class
style; existing code passing `style="lip"` keeps working unchanged.

**Backward-compatibility note:** Pre-#28 code called `keystone_opening()`
with no arguments and got `[14.70, 16.40]` (the face-grip window). As of
#28, the default changed to the taller/snap-retention style; as of #38, that
default style is `"standard"` and its value is `[15.3, 22.25]` (previously
`[14.90, 22.90]` under the now-superseded `"lip"` reading — see Sources
below). If your design relies on the original behavior, pass
`style="face"` explicitly to `keystone_opening()` and `keystone_cutout()`.

**Accessor vs. physical cut, `"standard"` only:** `keystone_opening()`'s
height (22.25mm) is RESEARCH.md's directly measured max window and is
deliberately a bit larger than what `keystone_cutout()`/`keystone_boss()`
actually cut (21.42mm, `keystone_slot()`'s `mouth_h + 2*wall_thickness` —
see that module's comment). The real slit opens asymmetrically
(bottom +1.5mm, top +2.35mm) while `wall_thickness` is a separate,
symmetric, residual-material quantity — the two aren't interchangeable, and
`keystone_slot()` doesn't carry a distinct asymmetric-opening field. Using
the true measured max for `keystone_opening()` keeps it a safe (if slightly
conservative) upper bound for consumers like a flange, without changing the
already-verified, self-consistent cutout/boss geometry.

## Import

```scad
use <keystone/keystone.scad>;
```

Ships all four roles: **data** (functions — `use` doesn't import
variables), **placeholder** (`keystone_placeholder()`, a jack-envelope
keep-out solid for interference viz), **hole-stamp**
(`keystone_cutout()`/`keystone_boss()`/`keystone_insert()` — a consumer
`difference()` window, the local positive material a thin "standard" panel
needs to host that window (#38), and a geometric mate-reference body), and
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
f = keystone_face();                  // [14.5, 16.0] invariant jack face
o = keystone_opening("standard");     // [15.3, 22.25] standard channel+slit (default; #38)
o = keystone_opening("face");         // [14.70, 16.40] face-grip (original)
b = keystone_body();                  // [17.5, 19.5, 28.60]
pt = keystone_plate_thickness();      // [1.5, 3.0]
sl = keystone_slot("standard");       // [back_wall_depth,wall_thickness,mouth_w,mouth_h,top_slit_w,top_slit_len,top_slit_depth,bot_slit_w,bot_slit_len,bot_slit_depth] (#38)
nt = keystone_notch("standard");      // [fulcrum_base,fulcrum_protrusion,fulcrum_z,arm_thickness,arm_length,arm_root_z,topnotch_base,topnotch_protrusion,topnotch_z] (#38)

// Port-spacing fit check before laying out N ports across a faceplate
// (style-aware -- "standard" is boss-footprint-driven, wider than the raw
// opening; "face" is unchanged):
xs = [for (i = [0:3]) i * keystone_pitch()];
assert(keystone_layout_ok(xs, "standard"), "ports too close together");
keystone_pitch_assert(keystone_pitch(), "standard"); // hard-fail at render if too tight

// A faceplate with standard-style windows (default) -- pair keystone_boss()
// with keystone_cutout() since the "standard" channel needs more Z depth
// than a thin panel alone provides (#38):
difference() {
    union() {
        translate([-30, -20, -3]) cube([60, 40, 3]);
        keystone_boss(plate_thickness = 3.0);   // default style="standard"
    }
    keystone_cutout(plate_thickness = 3.0);  // default style="standard"
}
color("orange") keystone_placeholder();

// Face-grip style (original, if needed):
difference() {
    translate([-30, -20, -3]) cube([60, 40, 3]);
    keystone_cutout(plate_thickness = 3.0, style = "face");
}

// Virtual mate-check: drop the insert into the cutout (see renders/ below).
// NOTE: keystone_insert()'s "standard" branch (#38 Task 3) is the real
// fulcrum+flexing-arm mechanism -- a solid fulcrum rib and a flexing arm
// each carry a keystone_notch()-derived notch that seats in keystone_slot()'s
// top/bottom wall-slits at the same insertion depth. It's a geometric
// mate-reference, not yet print-tuned (backlog #22).
keystone_insert(plate_thickness = 3.0);
```

## Reference

| Function/module | Returns / does |
|---|---|
| `keystone_known_styles()` | `["standard", "face"]` — list of supported retention styles. `"lip"` is a deprecated alias for `"standard"`, not a third style |
| `keystone_face()` | `[14.5, 16.0]` — invariant jack face / plug cross-section, mm |
| `keystone_opening(style="standard")` | `[ow, oh]` — plate window (X width, Y height) per retention style, mm. `"standard"`: width reuses `keystone_slot()`'s `mouth_w`; height (22.25mm) is RESEARCH.md's directly measured max window at slit onset, a conservative upper bound slightly larger than the physical cutout (21.42mm, `mouth_h + 2*wall_thickness` — see `keystone_cutout()`'s comment and the "Accessor vs. physical cut" note above) |
| `keystone_body()` | `[bw, bh, bd]` — jack envelope keep-out (X, Y, Z-depth behind panel), mm |
| `keystone_plate_thickness()` | `[tmin, tmax]` — accepted faceplate thickness range, mm |
| `keystone_pitch()` | nominal center-to-center port spacing in a strip, mm |
| `keystone_min_wall()` | minimum printable material wall between adjacent openings, mm |
| `keystone_tab(style="standard")` | `[hook_ledge_z, tab_thickness, hook_edge, latch_edge]` — mate-reference placeholder numerics for `keystone_insert()`'s `"face"` branch ONLY (#38 Task 3: `"standard"` no longer reads this, see `keystone_notch()` instead) |
| `keystone_slot(style="standard")` | `[back_wall_depth, wall_thickness, mouth_w, mouth_h, top_slit_w, top_slit_len, top_slit_depth, bot_slit_w, bot_slit_len, bot_slit_depth]` (#38) — REAL measured `[`-channel/slit geometry (RESEARCH.md, STL-mesh, `[C]`/`//VERIFY` per field); `"standard"` only (`"face"` has no channel). Single source of truth for `keystone_opening("standard")`, `keystone_cutout(...,"standard")`, and `keystone_boss(...,"standard")` |
| `keystone_notch(style="standard")` | `[fulcrum_base, fulcrum_protrusion, fulcrum_z, arm_thickness, arm_length, arm_root_z, topnotch_base, topnotch_protrusion, topnotch_z]` (#38) — REAL measured jack-side fulcrum/flex-arm geometry (RESEARCH.md, STL-mesh, `[C]`/`//VERIFY` per field); `"standard"` only. Consumed by `keystone_insert()`'s real `"standard"` branch (#38 Task 3, see that module's comment) for its fulcrum/arm notch geometry |
| `keystone_boss_footprint(style="standard", clearance=0.25)` | `[w, h, y_center]` — rectangular footprint for `keystone_boss()`: the `"standard"` channel's max envelope (from `keystone_slot()`) + `keystone_min_wall()` margin per side; `y_center == 0` (the standard channel's top/bottom slits are symmetric, unlike #31's superseded asymmetric "lip" reading). `"standard"` only |
| `keystone_min_pitch(style="standard")` | minimum center-to-center that still leaves a printable wall. `"face"`: `keystone_opening(style)[0] + keystone_min_wall()` (unchanged). `"standard"`: `keystone_boss_footprint(style)[0]` — boss-footprint-driven, since two adjacent bosses (not just the raw openings) must clear each other |
| `keystone_pitch_ok(pitch, style="standard")` | true if `pitch >= keystone_min_pitch(style)` |
| `keystone_layout_ok(xs, style="standard")` | true if every adjacent gap in ascending X-center list `xs` clears `keystone_min_pitch(style)` |
| `keystone_pitch_assert(pitch, style="standard")` | module; hard-fails render (stderr assert) if `pitch` is below `keystone_min_pitch(style)` |
| `keystone_placeholder()` | module; jack envelope solid (`keystone_body()`), flange face at `Z=0`, body into `-Z` — fit/interference viz only |
| `keystone_cutout(plate_thickness=3.0, clearance=0.25, style="standard")` | module; `"face"`: plain rectangular through-hole for a consumer `difference()`, sized `keystone_opening(style)` + `2*clearance` per side, overcut 1mm above/below the plate (unchanged). `"standard"` (#38): the REAL channel negative — a mouth void plus a slit cut clean through each of the top and bottom walls (`keystone_slot()`), closed at the back by a pyramidal, self-supporting taper (print-safety addition, see the module comment). Its Z-extent is **plate-thickness-independent** (the ~10mm+ channel exceeds `keystone_plate_thickness()`'s range) — pair with `keystone_boss()` below so the cut always lands in solid material. Print orientation: panel front face **down** on the bed (pins the support-free taper direction — see the module comment) |
| `keystone_boss(plate_thickness=3.0, clearance=0.25, style="standard")` | module (#38); `"face"`: no-op. `"standard"`: LOCAL positive material behind a thin panel — a constant-footprint rectangular pedestal (front flush with the panel front, `Z=0`, growing `-Z` past the full channel depth + taper via `keystone_boss_footprint()`) so `keystone_cutout(...,"standard")` always cuts real solid regardless of `plate_thickness`. `union()` this into the plate *before* differencing the cutout (see Usage above) |
| `keystone_insert(plate_thickness=3.0, fit=0.2, style="standard")` | module; geometric mate-reference body (flange + through-plug + retention geometry), narrowed by `fit` per side so it threads `keystone_cutout(style)`'s window. `"face"`: `+Y` hook + `-Y` latch bump grip the plate's front/rear faces (plate-thickness squeeze), unchanged. `"standard"` (#38 Task 3): the real push-to-click mechanism — a solid fulcrum rib (default bottom) and a flexing cantilever arm (default top, swappable via `flex_side`), each carrying a `keystone_notch()`-derived triangular notch that seats in `keystone_slot()`'s respective wall-slit at the same insertion depth; `deflect` (0..1) is a motion-viz parameter (assembly.scad drives it) pulling both notches inward for the push-in sweep. Geometric mate-reference only, not print-tuned (backlog #22) |

## Verification

`keystone_insert()` dropped into a plate with `keystone_cutout()` removed
(both at default params) is the library's virtual mate-check — the plug
should fill the window and the flange should stop flush at the front face
(`Z=0`). For `"face"`: the `+Y` hook should sit inside the cutout window
without touching solid frame material, and the `-Y` latch should clear the
plate rear. For `"standard"` (default, #38 Task 3): `keystone_insert()`'s branch is the
real `keystone_notch()`-derived fulcrum/flexing-arm mechanism (see that
module's comment) — its mate-check is meaningful evidence for the notch/slit
engagement geometry, though the mechanism itself remains a geometric
mate-reference, not yet print-tuned (backlog #22). The channel/slit geometry itself
(`keystone_cutout()`/`keystone_boss()`) is instead verified directly by
real geometric section checks in `tests/test_keystone_lib.sh` (a slab
`intersection()` at a Z inside the slit's range shows a void reaching the
slit's outer wall edge; a slab at a Z before the slit shows the void
confined to the plain mouth, with real wall material occupying the band
beyond it) — render-without-error alone is not proof of correct geometry
(a union()/difference() of overlapping solids is still perfectly manifold).

![keystone insert/cutout overlay mate-check](renders/mate-overlay-yz.png)

![+Y hook detail, zoomed](renders/hook-detail-yz.png)

**These renders predate #31 and #38** and were generated against the
original pre-#28 `"face"`-style single-hook geometry; they have not been
regenerated since, so they visually show only that old mechanism — don't
rely on them for `"standard"`'s current channel/slit shape.

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
| ["Keystone Jack v2 integration aide" by SimplifiedLife, Printables 1027864](https://www.printables.com/model/1027864) / ["Keystone blank" by pmichaud, Printables 587874](https://www.printables.com/model/587874) / ["(Parametric) Keystone Connector" by Paul Hatcher, Printables 537480](https://www.printables.com/model/537480) | C (front face) / `//VERIFY` (retention geometry) | **Superseded by #38** — these three mesh-measured a *different*, real rotate-and-snap mechanism (staged hook-then-latch) under the now-deprecated `"lip"` key; kept here only as 2nd/3rd independent corroboration of `keystone_face()`. Not used for `"standard"`'s current channel/slit or notch geometry |
| ["Ethernet RJ45 keystone socket wall plate", Printables 1014552](https://www.printables.com/model/1014552) | C (`back_wall_depth`, same-depth top/bottom slit start, jointly with 533549) / `//VERIFY` (mouth/window/slit-length/wall-thickness specifics, single-model) | `keystone_slot("standard")` (#38) — the channel/slit geometry `keystone_cutout("standard")`/`keystone_boss("standard")` are built from |
| ["Voron 0.2r1 Rear Skirt w/keystone", Printables 533549](https://www.printables.com/model/533549) | C (`back_wall_depth`, same-depth top/bottom slit start, jointly with 1014552) / `//VERIFY` (mouth/window specifics, single-model) | Cross-model corroboration for `keystone_slot("standard")` (#38); 3mf-sourced mesh |
| ["SMA-Keystone Modul", Printables 366437](https://www.printables.com/model/366437) | C (front face; fulcrum-notch and arm-notch shape+position, jointly with 314383) / `//VERIFY` (exact notch/arm mm, body envelope, single-model) | `keystone_notch("standard")` (#38) — single self-contained STL modeling both the fulcrum and flex-arm mechanism |
| ["SFP+ Cable Keystone Jack", Printables 314383](https://www.printables.com/model/314383) | C (fulcrum-notch and arm-notch shape+position, jointly with 366437) / `//VERIFY` (exact notch/arm mm, body envelope, single-model) | Cross-model corroboration for `keystone_notch("standard")` (#38); split Left/Right/Hook parts |

### Coverage / not yet covered

- Sourced + tiered: `keystone_opening("face")` [A] (Samm)/[B] (Wikipedia
  corroboration), `keystone_face()` [B] (Wikipedia, corroborated [C] by four
  independent models across #31 and #38), `keystone_slot("standard")`'s
  `back_wall_depth` and same-depth-start finding [C] (#38, cross-model
  1014552+533549), `keystone_notch("standard")`'s notch-on-fulcrum and
  notch-at-arm-tip shape/position findings [C] (#38, cross-model
  366437+314383), `keystone_pitch()` [B], `keystone_plate_thickness()[0]`
  (tmin) [A].
- Still `//VERIFY` (flagged for a future research pass, not invented): every
  individual mm figure in `keystone_slot("standard")` and
  `keystone_notch("standard")` other than `back_wall_depth` itself (#38 —
  single-model readings; the same-depth-start and notch-shape/position
  *findings* are [C]-corroborated across two independent models each, but
  the exact millimeter values are not), `keystone_body()[0]`/`[1]` (bw, bh —
  axis-mapping from the vendor drawing unresolved), `keystone_body()[2]`
  (bd — single, non-decomposed drawing reading, not corroborated by a
  second source), `keystone_plate_thickness()[1]` (tmax — no
  accepted-upper-bound source found), `keystone_min_wall()` (no source at
  all — repo print-process convention, not a keystone-specific spec),
  `keystone_tab()` (all fields — mate-reference-only placeholder numerics,
  not derived from `keystone_slot()`/`keystone_notch()`; `keystone_insert()`
  does not currently read it for `"standard"` either, see below). Per
  backlog #16, every `keystone_slot()`/`keystone_notch()` figure should be
  re-measured with calipers against the user's own keystone hardware before
  being treated as final — see RESEARCH.md's "Caliper-upgradeable" notes.
- All four roles are implemented: data, `keystone_placeholder()`,
  `keystone_cutout()`/`keystone_boss()`/`keystone_insert()`, and the
  fit-check family (`keystone_pitch_assert()` included, style-aware). The
  channel/slit geometry (`keystone_cutout()`/`keystone_boss()`, #38) is the
  real, verified mechanism (see Verification above); `keystone_insert()`'s
  `"standard"` branch (#38 Task 3) is the real `keystone_notch()`-derived
  fulcrum/flexing-arm mechanism (see that module's comment) — it is a
  geometric mate-reference, not yet print-tuned, so it should not be printed
  as a functional latch until backlog #22 (the print-ready flexing-latch
  insert) lands.
