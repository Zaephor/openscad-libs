# drives (library)

Storage-drive mechanical reference for 3.5"/2.5"/U.2 block drives and M.2
(2230/2242/2260/2280) cards: envelope, bottom/side mounting-hole coordinates,
and connector position. Units: **mm**.

**Task 1 scaffold only.** `drives.scad` currently ships just the header
comment, provenance-tier legend, and a `drive_known_types()` stub over empty
data tables -- see `RESEARCH.md` for the full tiered value table Task 2
transcribes from. Nothing here should be treated as ready to consume yet.

Datum (see `RESEARCH.md` for the reasoning): `X=0` at the drive's connector
end (`+X` toward the free end), `Y=0` at the edge nearest the smaller
edge-inset hole column, `Z=0` at the bottom face (`+Z` up).

## Import

```scad
use <drives/drives.scad>;
```

## Sources

Full source list + per-value tiers + fetch/read notes are in `RESEARCH.md`.
Summary (also in `lib.json`):

- SFF-8301 Rev 1.9 -- 3.5" Form Factor Drive Dimensions (SNIA)
- SFF-8201 Rev 3.4 -- 2.5" Form Factor Drive Dimensions (SNIA)
- SFF-8223 Rev 2.7 -- 2.5" Drive Form Factor w/Serial Attached Connector (SNIA)
- SFF-TA-8639 Rev 2.2 -- Multifunction 6X Unshielded Connector / U.2 (SNIA)
- Viking Technology M.2 2280 SATA SSD datasheet (`PSFEM5xxxxBxxx`)
- Viking Technology M.2 2280 NVMe SSD manual (`PSFNP5xxxx5xxx`)

**Nothing in this library is tier `[A]` by inflation** -- every `[A]` tag
means the governing spec or vendor drawing was fetched and read this pass;
gaps (values no source covered) and `//VERIFY` items (inferred, not
explicitly labeled) are recorded honestly in `RESEARCH.md` rather than
silently filled in.
