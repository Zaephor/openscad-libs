# pcie-bracket (library)

PCIe/PCI card I/O bracket (faceplate) mechanical reference — low-profile
(MD1/MD2) and full-height bracket/card geometry: overall bracket height,
chassis-foot width, card-length classes, and screw thread. Units: **mm**.

**Status: Task 1 (research + scaffold) only.** `pcie-bracket.scad` currently
ships the unmodified `make new-lib` template stub (placeholder envelope
numbers, no real data) — accessor functions and geometry land in a later
task. See `RESEARCH.md` for the sourced values Task 2 will transcribe.

## Import

```scad
use <pcie-bracket/pcie-bracket.scad>;
```

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

| Source | URL |
|---|---|
| PCI-SIG "Low Profile PCI" ECN (low-profile bracket + MD1/MD2 card classes) | named standard, not fetched — member-paywalled (see `RESEARCH.md`) |
| PCI-SIG PCI Express CEM Spec (full-height bracket) | named standard, not fetched — member-paywalled (see `libraries/connectors/RESEARCH.md`'s existing `pcie_x1`..`pcie_x16` precedent) |
| PL-Tronic BV / brackets.nl distributor guideline drawings | https://www.brackets.nl/images/producten/pcb2.gif (full-height), https://www.brackets.nl/images/producten/pcb3.gif (low-profile) |
| accio.com "PCIe Bracket Dimensions" | https://www.accio.com/plp/pcie-bracket-dimensions |
| flykantech.com "Standard Profile vs. Low Profile PCIe Card Bracket Specifications" | https://www.flykantech.com/blog-detail/standard-profile-vs-low-profile-pcie-card-bracket-specifications |

Two values are deliberately **not** re-researched here because another
library already owns them (single-source-of-truth rule): PCIe slot pitch
(`mobo_pcie_pitch()`, `libraries/motherboards/motherboards.scad`) and the
motherboard-side rear-edge-to-connector `setback` (`mobo_pcie_ports()`, same
file) — see `RESEARCH.md`'s cross-reference notes.
