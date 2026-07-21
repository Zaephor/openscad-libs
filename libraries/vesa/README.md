# vesa (library)

VESA FDMI (Flat Display Mounting Interface) / MIS (Mounting Interface
Standard) hole patterns for mounting a display (or a display-mountable
device) to a wall bracket or arm. Units: **mm**.

**Scope note (Task 1):** this is the research + scaffold pass. `vesa.scad`
currently holds only the `make new-lib` placeholder boilerplate — the real
`vesa_known_patterns()` / `vesa_pattern()` / `vesa_spacing()` / `vesa_screw()`
accessors and the `vesa_holes()` hole-stamp module are built in Task 2 from
the evidence in `RESEARCH.md`. This README will be filled in with the real
Import/Usage/Reference sections once Task 2 lands.

## Patterns covered (v1 target — see RESEARCH.md)

- **MIS-D 75** — 75x75mm square, M4.
- **MIS-D 100** — 100x100mm square, M4.
- **MIS-E** — 200x100mm rectangle, M4.

**MIS-F** (200x200mm and larger, M6/M8, big-TV class) is intentionally NOT
modeled — no in-repo consumer needs it yet (YAGNI). See the design spec
(`docs/superpowers/specs/2026-07-21-vesa-mount-lib-design.md`, gitignored
working notes) for the reasoning; a future pass can add MIS-F rows if a
consumer needs >200mm.

## Import

```scad
use <vesa/vesa.scad>;
```

## Sources

Provenance tiers (see `docs/LIBRARY-AUTHORING.md` / `RESEARCH.md`): **[A]**
fetched + read this pass (vendor datasheet or governing standard), **[B]**
corroborated across >=2 independent peers, **[C]** single-sourced / derived
/ named-standard-cited-but-not-fetched. `//VERIFY` marks a weak value
pending stronger corroboration.

| Source | Tier | Backs |
|---|---|---|
| [Wikipedia, "VESA mount"](https://en.wikipedia.org/wiki/VESA_mount) | B | MIS-D 75/100 + MIS-E spacing, M4 screw, position tolerance |
| [Oeveo, "All about the VESA pattern"](https://www.oeveo.com/content/320-all-about-the-vesa-pattern) | B | MIS-D 75/100 + MIS-E spacing, M4 screw |
| [vesa-standard.com, "VESA MIS-D Standard 75/100"](https://www.vesa-standard.com/vesa-mis-d.html) | B | MIS-D 75/100 spacing |
| VESA FDMI/MIS mounting standard | C, named-not-fetched (member-paywalled) | backs the MIS spacings/screw at [B] via the published peers above — no [A] claim is made anywhere in this library |
| `libraries/rack19/rack19.scad` (ISO 273 medium-fit series comment) | B (referenced, not re-derived) | M4 through-hole clearance dia (4.5mm) — single source of truth, see RESEARCH.md |

## Coverage / gaps

- **MIS-E's 6-hole variant** (4 corners + 2 extra holes at the mid-points of
  the long sides, per Wikipedia) is `[C] //VERIFY` — single-sourced this
  pass. Task 2 will decide whether v1 models the 4-corner subset only
  (sufficient for most consumers) or the full 6-hole pattern.
- **Screw thread-in / boss depth is device-dependent** — no consistent
  published figure exists for how deep a display's own internal boss
  threads (as opposed to the bracket's own 10mm max screw-protrusion
  allowance, which is bracket-side and `[C] //VERIFY`). Omitted rather than
  guessed, per `docs/LIBRARY-AUTHORING.md`'s gap-handling rule.
- **MIS-F** (200x200+, M6/M8) — out of scope, not modeled.

See `RESEARCH.md` for the full per-pattern evidence, tiering, and the
corner-coordinate math each pattern implies.
