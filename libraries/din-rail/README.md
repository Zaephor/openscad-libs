# din-rail (library)

Reference data + printable clip for the **EN 60715 TS35 top-hat DIN rail** —
the 35 mm-wide "hat"-section mounting rail used across electrical/automation
gear and homelab racks. The library is the **single source of truth** for the
TS35 profile (both the standard 7.5 mm and deep 15 mm depth variants) and
ships a **support-free snap clip** that mates with it, so a consumer project
reads these accessors and unions the clip into its own body rather than
copying numbers. Units: **mm**.

## Datum / orientation

Rail axis = **X** (length). Cross-section lies in **Y/Z**: width centered in
Y, the leg bottoms on **Z=0**, and the hat opening faces **−Z** (hollow
between the legs, under the top bridge, open at the bottom). The two inward
**return lips** — the retention feature a clip catches — sit at the
inner-bottom edge of each leg. `din_clip()` is built in this same frame so it
mates in place; see its header for print orientation.

## Import

```scad
use <din-rail/din-rail.scad>;
```

```scad
sz  = din_rail_size("ts35-7.5");   // [width, depth, material_t, slot_pitch] = [35, 7.5, 1.0, 25]
lip = din_rail_lip("ts35-7.5");    // [lip_height, lip_return]

// Reference rail profile (fit/context geometry, typically rendered % by consumers):
din_rail_profile("ts35-7.5", length = 100);

// Printable snap clip, seated on the rail — union it into your host body so the
// clip's back-plate OUTER face is co-planar with your mounting surface:
color("orange") din_clip("ts35-7.5", width = 15);
```

## Functions

| Function | Returns |
|---|---|
| `din_known_rails()` | `["ts35-7.5", "ts35-15"]` — supported rail keys |
| `din_rail_size(type)` | `[width, depth, material_t, slot_pitch]` mm |
| `din_rail_lip(type)` | `[lip_height, lip_return]` mm — the inward return-edge lip a clip catches (`[C]//VERIFY`, conservative nominal) |
| `din_clip_catch_span(type, clearance=0.4)` | outer-tip-to-outer-tip Y span of the clip's two catch barbs = `width − 2·material_t − 2·clearance`. Single source of truth for the clip's catch width and the mate assert; lands between the lip inner edges (overlap = engagement) and the leg inner faces (clears on entry) |

## Modules

| Module | Does |
|---|---|
| `din_rail_profile(type, length=100)` | Reference hat-profile solid (outer envelope − inner cavity + two return lips). Fit/context geometry, not itself print-oriented |
| `din_clip(type="ts35-7.5", width=15, clearance=0.4, wall=2.4, flex_len=undef, lead_in=1.0)` | Support-free snap clip. **Inner-grip** catch: two prongs enter the hat channel and hook the inward return lips with outward 45° barbs — one **rigid gusset-braced fixed hook**, one **unbraced flexing cantilever latch**. Prints back-plate-flat-on-bed, prongs up, every overhang ≤45° by construction (no supports). The back-plate **outer (−Z) face is the mounting face** that bonds to the consumer's part; its inner face seats against the rail front. Snap tension is bench-tuned via `clearance`/`wall` (`wall` sets cantilever stiffness — thinner = softer); `flex_len` does **not** affect tension — the catch barb's load point is pinned at `lip_h` regardless of it, so it only sets the guide-wall height above the barb (rail lead-in / insertion alignment) |

## Verification

`libraries/din-rail/assembly.scad` places `din_rail_profile()` and
`din_clip()` in their seated pose for the geometric mate-check (render via
`.claude/skills/verify-scad-geometry`). The yz side-profile overlay is the
acceptance gate: the clip's back plate captures the 35 mm rail, the catch
barbs reach the return-lip zone (engagement), the prongs stay under the top
bridge, and no barb crosses into a leg (no gross clip-through). `din-rail_test.scad`
additionally asserts `din_clip_catch_span()` lands in the lip catch zone for
both depth variants.

## Sources

Provenance tiers (see `din-rail.scad` header / `RESEARCH.md` for the full
evidence log): **[A]** governing standard / vendor datasheet fetched + read,
**[B]** corroborated across ≥2 independent peers (or a named-but-paywalled
standard cited by them), **[C]** single-sourced / derived. `//VERIFY` marks a
weak value pending stronger corroboration.

| Source | Tier | Backs |
|---|---|---|
| WAGO 210-112 (TS35×7.5) / 210-197 (TS35×15) steel carrier-rail datasheets | B | `din_rail_size()` width / depth / material_t / slot_pitch, both variants |
| Phoenix Contact NS 35/7.5 PERF / NS 35/15 PERF product data | B | corroborates width / depth / 25 mm slot pitch |
| Schneider Electric top-hat rail technical documentation (IEC 60715) | B | corroborates 35 mm width, 1 mm thickness, 7.5/15 mm depth |
| Wikipedia "DIN rail" | B | corroborates TS35 35×7.5 / 35×15 variants, EN 50022 predecessor |
| IEC/EN 60715 Annex A (paywalled — not fetched) | — | governing standard the peers cite; caps profile dims at [B], leaves the dimensioned lip cross-section unresolved |
| Return-edge lip geometry (`din_rail_lip()`) — no dimensioned drawing found | C //VERIFY | conservative nominal (lip height ≈ material_t, return ≈ 1 mm); flagged for a caliper upgrade against a physical rail |

## Coverage

- **Modeled:** EN 60715 **TS35** top-hat rail only, standard (7.5 mm) and deep
  (15 mm) depth variants — profile data, reference profile solid, and the
  support-free `din_clip()`.
- **Deferred:** other DIN rail families (**G-type** / C-section / TS15
  mini-rail) are out of scope for v1 — add them as new `_din_table()` rows
  when a consumer needs them.
- **Physical snap tension is NOT modeled or CI-validated** — it depends on
  print material/settings and the un-dimensioned lip geometry (`[C]//VERIFY`).
  The CI gate checks geometric *engagement* only; retention force is
  **bench-tuned by the user** via the exposed `clearance` and `wall`
  parameters (thinner `wall` = softer cantilever). `flex_len` does **not**
  tune tension — the catch barb's load point is pinned at `lip_h` near the
  prong's fixed root regardless of `flex_len`, so it only sets the guide-wall
  height above the barb (rail lead-in / insertion alignment), not the flex
  between root and load point. Re-measure `din_rail_lip()` against a physical
  rail with calipers to upgrade its tier before treating the snap as final.

**Unify audit:** No existing in-repo DIN consumer; first is a future homelab
tray — retrofit deferred.
