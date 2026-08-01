# openscad-libs

An OpenSCAD monorepo of reusable **libraries** (real-world data + component helpers) and printable **projects**.

## Quick start

```bash
make help                 # list all targets
make run P=cable-clip      # open a project in OpenSCAD (OPENSCADPATH preset)
make render P=cable-clip   # regenerate a project's render
make new-lib NAME=foo      # scaffold a library
make new-project NAME=bar [MULTIPART=1]
make check                 # lint conventions + compile-check all .scad
make list                  # list libraries and projects
```

Libraries are imported namespaced by folder once `OPENSCADPATH` points at `libraries/`
(the `make`/`scripts/openscad.sh` launcher sets this for you):

```scad
use <fans/fans.scad>;
```

## Libraries

- [connectors](libraries/connectors) — connector body/shell envelope dimensions for PC/SBC panel + slot connectors.
- [din-rail](libraries/din-rail) — EN 60715 TS35 rail profile + support-free snap clip.
- [drives](libraries/drives) — storage-drive mechanical envelopes.
- [embedded](libraries/embedded) — ESP32/ESP8266 dev-board mounting reference.
- [fans](libraries/fans) — PC fan frame sizes + mount hole geometry.
- [heatset](libraries/heatset) — brass heat-set insert data + geometry (M2–M6).
- [honeycomb](libraries/honeycomb) — self-supporting hex-hole vent cutter.
- [keystone](libraries/keystone) — keystone-jack snap footprint (opening/cutout/insert).
- [motherboards](libraries/motherboards) — mini-ITX/microATX/ATX mounting reference.
- [multibuild](libraries/multibuild) — MultiBoard-compatible mount/hole interface + MultiBin/Fix-Point accessory geometry.
- [pcie-bracket](libraries/pcie-bracket) — PCIe low-profile + full-height expansion-slot brackets.
- [rack-support](libraries/rack-support) — rear-support plate + slide-in tongue/slot mating interface for rack10 device trays.
- [rack10](libraries/rack10) — 10-inch mini-rack reference (LabRax/DeskPi/TecMojo).
- [rack19](libraries/rack19) — 19-inch EIA-310-D rack reference.
- [sbc](libraries/sbc) — SBC mechanical reference (Raspberry Pi B/Zero families + BPI-R4).
- [vesa](libraries/vesa) — VESA FDMI (MIS) display-mount hole patterns.

## Projects

- [bay-enclosure](projects/bay-enclosure) — 1U/2U rack10 enclosure for 5.25"/3.5" bay devices (#40 rear mate)
- [bpir4-1u-chassis](projects/bpir4-1u-chassis) — 1U 10-inch rack chassis for the BananaPi BPI-R4.
- [cable-clip](projects/cable-clip) — single-part M3-mounted cable clip.
- [css610-underdesk-mount](projects/css610-underdesk-mount) — under-desk L-bracket for a MikroTik CSS610 switch
- [drive-tray](projects/drive-tray) — parametric 1U rack10 drive tray (2×3.5" / 6×2.5"), #40 rear-support mate
- [fan-grille](projects/fan-grille) — flat honeycomb fan finger-guard.
- [keystone-blank](projects/keystone-blank) — printable caliper-faithful keystone blank insert.
- [keystone-faceplate](projects/keystone-faceplate) — parametric 1U 10-inch N-port keystone faceplate.
- [mitx-1u-chassis](projects/mitx-1u-chassis) — 1U 10" rack chassis for a mini-ITX board (front IO, #40 rear mate)
- [mitx-2u-chassis](projects/mitx-2u-chassis) — 2U 10" rack chassis for a mini-ITX board + low-profile PCIe (front IO, #40 rear mate)
- [rack10-device-tray](projects/rack10-device-tray) — parametric 1U 10" cradle tray for rigid-box devices (GS308/GS308T/RLA-PS1), #40 rear mate
- [two-piece-box](projects/two-piece-box) — multipart box with exploded view.

## License

Copyright (c) 2026 Zaephor.

Licensed under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0
International](LICENSE) (`CC-BY-NC-SA-4.0`). You may use, modify, print, and
share this work for **non-commercial** purposes, with attribution, and any
derivative you share must carry the same license.

**Commercial use** — selling prints, bundling this work into a product, or any
other revenue-generating use — is **not** granted by the public license. It is
available separately: [open an
issue](https://github.com/Zaephor/openscad-libs/issues) to discuss terms.

**Dimensional data is not claimed.** The measured values in `RESEARCH.md` files
and returned by data accessors (`rack10_u()`, `keystone_pitch()`, and the rest)
are facts about physical objects, not creative expression. Reuse the numbers for
any purpose, commercial included. What the license covers is the expression
around them: prose, organization, provenance analysis, and all geometry code.

**Third-party sources.** External references are cited for provenance (see
[docs/LIBRARY-AUTHORING.md](docs/LIBRARY-AUTHORING.md)), which is a repo
convention independent of licensing. Where third-party *code* is ever
incorporated, its own license notice is preserved alongside it — for example
[spuder/10-Inch-Rack-OpenSCAD](https://github.com/spuder/10-Inch-Rack-OpenSCAD)
(MIT, © 2025 Spencer Owen).

See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.
