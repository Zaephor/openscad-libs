# din-rail (library)

EN 60715 top-hat (TS35) DIN-rail profile dimensions for both standard
(35x7.5mm) and deep (35x15mm) depth variants, plus (Task 3) a support-free
printable rail-mounting snap clip. All dimensions in millimeters.

**Status: Task 1 (research + scaffold) only.** `RESEARCH.md` has the full
evidence log (per-dimension tiered sources for both variants). No profile
data table or geometry modules are implemented yet — `din-rail.scad`
currently holds only a header comment. Task 2 adds the profile-data
functions + reference module; Task 3 adds the clip.

## Import

```scad
use <din-rail/din-rail.scad>;
```

## Known gaps (see RESEARCH.md for detail)

- Return-edge lip geometry (height / return length / bend radius) — the
  retention-critical feature a snap clip catches on — was not numerically
  confirmed by any published source found this pass. Modeled as a
  conservative placeholder nominal, `[C]//VERIFY`.
- TS35x15 material thickness: real vendor spread reported (1.2-2.3mm
  elsewhere); 1.5mm nominal used (WAGO's own catalog figure), `[B]//VERIFY`.

## Sources

See `lib.json` `sources[]` and `RESEARCH.md` for the full per-dimension
evidence and tiering.
