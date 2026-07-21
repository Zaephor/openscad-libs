# vesa (library)

VESA FDMI (Flat Display Mounting Interface) / MIS (Mounting Interface
Standard) hole patterns for mounting a display (or a display-mountable
device) to a wall bracket or arm. Units: **mm**.

## Patterns covered (v1)

- **MIS-D 75** — 75x75mm square, 4 holes, M4.
- **MIS-D 100** — 100x100mm square, 4 holes, M4.
- **MIS-E** — 200x100mm rectangle, 4-corner subset, M4.

**MIS-F** (200x200mm and larger, M6/M8, big-TV class) is intentionally NOT
modeled — no in-repo consumer needs it yet (YAGNI). A future pass can add
MIS-F rows if a consumer needs >200mm.

## Import

```scad
use <vesa/vesa.scad>;
```

## Usage

```scad
use <vesa/vesa.scad>;

vesa_placeholder("mis-d-100");   // reference plate + stamped holes

// or, in a consumer part:
difference() {
    my_panel();
    vesa_mount_holes("mis-d-100");   // hole cutters only
}
```

## Reference

`name` is one of `vesa_known_patterns()`: `mis-d-75`, `mis-d-100`, `mis-e`.
Every accessor `assert()`s on an unknown `name`.

| Function | Returns |
|---|---|
| `vesa_known_patterns()` | list of all valid `name` keys |
| `vesa_known_hole_roles()` | the 4 canonical role strings, in table order |
| `vesa_spacing(name)` | `[w,h]` mm hole-pattern spacing |
| `vesa_screw(name)` | screw-thread string (e.g. `"m4"`) |
| `vesa_holes(name, role=undef)` | list of `[x,y,role,dia]` mm hole tuples, centered on the origin, filtered by `role` |
| `vesa_holes_xy(name, role=undef)` | `[x,y]`-only convenience, same filtering |

| Module | Produces |
|---|---|
| `vesa_mount_holes(name, dia=-1, depth=6)` | mount-hole cutters for a consumer `difference()`; `dia=-1` uses each hole's own per-hole tagged dia, pass a positive value to override uniformly |
| `vesa_placeholder(name, margin=10, thickness=3)` | reference plate the size of the pattern + margin, holes stamped — a flat extrude, trivially support-free |

## Hole roles

Every mount-hole tuple returned by `vesa_holes()`/`vesa_holes_xy()` is
`[x, y, role, dia]`, not just `[x, y]` — mirrors `sbc`'s hole-role schema (see
`libraries/sbc/README.md` "Hole roles"). The 4 canonical roles (from
`vesa_known_hole_roles()`, shared vocabulary — not redefined per-lib):
`structural-mount`, `component-mount`, `keep-out`, `alignment`.

Every VESA hole in this library today is `structural-mount` — VESA mounting
holes are single-role by construction, so `vesa_holes()` omits `sbc`'s
multi-role unfiltered-access WARNING path (there is nothing to warn about; a
future pattern with mixed roles could add it back).

## Sources

Provenance tiers (see `docs/LIBRARY-AUTHORING.md` / `RESEARCH.md`): **[A]**
fetched + read this pass (vendor datasheet or governing standard), **[B]**
corroborated across >=2 independent peers, **[C]** single-sourced / derived
/ named-standard-cited-but-not-fetched. `//VERIFY` marks a weak value
pending stronger corroboration.

| Type | Spacing tier | Screw tier | Source(s) |
|---|---|---|---|
| mis-d-75 | B | B | Wikipedia "VESA mount"; Oeveo "All about the VESA pattern"; vesa-standard.com "VESA MIS-D Standard 75/100" |
| mis-d-100 | B | B | Wikipedia "VESA mount"; Oeveo "All about the VESA pattern"; vesa-standard.com "VESA MIS-D Standard 75/100" |
| mis-e | B | B | Wikipedia "VESA mount"; Oeveo "All about the VESA pattern" |
| VESA FDMI/MIS mounting standard | C, named-not-fetched (member-paywalled) | — | backs the spacings/screw at [B] via the published peers above — no [A] claim is made anywhere in this library |
| M4 through-hole clearance (4.5mm) | — | B (referenced, not re-derived) | `libraries/rack19/rack19.scad`'s ISO 273 medium-fit series comment — single source of truth, see RESEARCH.md |

## Coverage / gaps

- **MIS-E's 6-hole variant** (4 corners + 2 extra holes at the mid-points of
  the long sides, per Wikipedia) is `[C] //VERIFY` and NOT modeled — v1 ships
  the 4-corner subset only, matching this library's stated coverage
  (monitors / SBC brackets / small-TV mounts, all of which the 4-corner
  pattern serves). Noted here as a documented future extension (YAGNI, no
  current consumer needs the middle pair), same treatment as MIS-F below.
- **Screw thread-in / boss depth is device-dependent** — no consistent
  published figure exists for how deep a display's own internal boss
  threads (as opposed to the mount-bracket's own 10mm max screw-protrusion
  allowance, which is bracket-side and `[C] //VERIFY`). Omitted rather than
  guessed, per `docs/LIBRARY-AUTHORING.md`'s gap-handling rule.
- **MIS-F** (200x200+, M6/M8) — out of scope, not modeled.

**Unify audit:** no existing in-repo VESA consumer today; the first future
consumer is backlog #4 (rpi4b SSD case) — retrofitting that project onto
this library is deferred until #4 is actually built.

See `RESEARCH.md` for the full per-pattern evidence, tiering, and the
corner-coordinate math each pattern implies.
