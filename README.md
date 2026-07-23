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

- [bpir4-1u-chassis](projects/bpir4-1u-chassis) — 1U 10-inch rack chassis for the BananaPi BPI-R4.
- [cable-clip](projects/cable-clip) — single-part M3-mounted cable clip.
- [keystone-faceplate](projects/keystone-faceplate) — parametric 1U 10-inch N-port keystone faceplate.
- [two-piece-box](projects/two-piece-box) — multipart box with exploded view.

See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.
