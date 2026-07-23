# BPI-R4 — per-board research (mechanical + electrical/GPIO)

BananaPi BPI-R4, standard variant (2x SFP + 4x RJ45, MediaTek MT7988A
Filogic 880). Mechanical data below summarizes and cites `libraries/sbc/RESEARCH.md`'s
BPI-R4 sections (own board rows/connector maps, tiers as already established
there); electrical/GPIO data is sourced independently for this doc. This is
the first per-board research file in `libraries/sbc/research/`; future SBC
boards in this library should follow the same three-section shape (mechanical
provenance, electrical/GPIO map, GPIO-usability guidance) where applicable.

## Mechanical provenance summary

- **Outline**: 148.0 x 100.5mm, tier **[A]** (BPI-R4 vendor DXF export,
  bounding box of the board-outline polyline). Corners are a true 2mm x 2mm
  45-degree chamfer, not a fillet — the library's `corner_r=2.0` is the
  nearest shape its shared row schema supports, not a faithful reproduction.
- **Thickness**: **1.4mm**, tier **[B]** (direct caliper measurement of a
  physical board), superseding an earlier 1.6mm generic-PCB placeholder
  (tier [C]).
- **Mounting holes**: 16 total. 4 form a corner-inset rectangle (3.5mm inset
  from each board edge, two of the four sitting at the chamfered corners
  themselves) and are classified `structural-mount`, tier **[B]//VERIFY**. 12
  are classified `component-mount`: 7 sit adjacent to `M2` silkscreen text
  (M.2-socket standoffs, tier **[A]**) and 2 larger-diameter holes (~3.3mm vs
  the other 14's 3.0mm) sit near the fan connector and the SoC's VCORE
  power-delivery cluster respectively (tier **[C]//VERIFY**, no silkscreen
  confirmation of "fan"/"heatsink" specifically). No single source confirms
  which real-world case product uses which of the 4 structural holes.
- **Front-panel connector heights** (board-bottom-to-connector-top,
  caliper-measured, tier **[B]**, superseding earlier generic/placeholder
  figures): SFP cage 11.8mm (9.5mm above board-top alone — the prior 13.4mm
  figure was too tall), USB3 shell 15.5mm (13.0mm alone), RJ45 4-port block
  15.1mm (13.2mm alone). The RJ45 figure corroborates, and does not replace,
  the exact-part datasheet height (13.60mm above board-top, tier **[A]**,
  kept per this library's never-downgrade-without-cause rule).
- **Expansion-slot map**: 4 sockets total — **2x M.2 + 2x mini-PCIe**, tier
  **[A]** (BPI-R4 block diagram and device-tree agree).
  One M.2 (Key-B) carries a WWAN 4G/5G modem (2242/3042/3052-length,
  top-face); the other M.2 (Key-M) carries a 2280 NVMe SSD (underside). The
  two mini-PCIe sockets (both underside, full-size 30x50.95mm) form a matched
  pair spanned by a single Wi-Fi7 NIC card. This corrects an earlier reading
  that had (incorrectly) inferred 3 M.2 sockets from the vendor's assembly
  drawing alone.
- **"Key-E" mislabel**: the BPI-R4 block diagram labels the WWAN modem M.2
  slot "Key-E". This is wrong — the device tree's own source comment
  (`/* M.2 key-B SIM1 */` above the `&pcie2` node) confirms the slot is
  **Key-B**, tier **[A]**. The device-tree reading overrides the block
  diagram's label for this one field.
- **SIM card holder type**: Direct caliper measurement of the physical
  board found 3x 2FF **mini-SIM** card holders (15mm width, matching
  `connector_size("sim_2ff")` exactly), tier **[B]**.

## Electrical / GPIO map

MT7988A SoC GPIO controller (`pio`) exposes **84 lines total** (gpio0-83),
tier **[A]** (device-tree `gpio-ranges` property).

| Function | GPIO | Polarity | Source | Tier |
|---|---|---|---|---|
| SYS/STATUS LED (green) | GPIO79 | active-high | device-tree `gpio-leds` node | [A] |
| WPS LED (blue) | GPIO63 | active-high | device-tree `gpio-leds` node | [A] |
| WPS button | GPIO14 | active-low | device-tree `gpio-keys` node | [A] |
| SFP1 (WAN cage) loss-of-signal | GPIO54 | active-high | device-tree `sfp1` node | [A] |
| SFP1 (WAN cage) mod-def0 (present) | GPIO82 | active-low | device-tree `sfp1` node | [A] |
| SFP1 (WAN cage) rate-select0 | GPIO21 | active-low | device-tree `sfp1` node | [A] |
| SFP1 (WAN cage) tx-disable | GPIO70 | active-high | device-tree `sfp1` node | [A] |
| SFP1 (WAN cage) tx-fault | GPIO69 | active-high | device-tree `sfp1` node | [A] |
| I2C mux reset (RTC/EEPROM/SFP1-I2C) | GPIO5 | active-low | device-tree `i2c2` node | [A] |

Other functions, not GPIO-backed:

- **Reset button**: a hardware reset line, not represented as a GPIO key in
  any available device-tree source — a separate physical reset circuit, not
  software-mediated. Tier **[A]** (absence of a GPIO mapping in the
  device-tree `gpio-keys` node, corroborated by the block diagram).
- **Power LED**: hardwired to a voltage rail, always on, not GPIO-controlled.
  Tier **[B]** (vendor/community documentation).
- **Per-port WAN/LAN link/activity LEDs**: integrated into the RJ45 jack
  shells and driven by the Ethernet PHY, not by host GPIOs. Tier **[A]**
  (standard PHY-integrated-LED design, block diagram).
- **SFP2 (LAN cage)** signal GPIOs: not present in the available device-tree
  sources for this board (only SFP1 has a wired `sfp1` node with GPIO
  properties) — **//VERIFY**, not confirmed either way.

**26-pin header**: 2.54mm pitch, 3.3V logic, tier **[B]** (caliper position
data + mechanical connector map already in `libraries/sbc/RESEARCH.md`).
Carries spare SoC GPIO lines but not the on-board LED nets. A full
pin-by-pin table (which header pin maps to which GPIO number) is
**//VERIFY** — unresolved; no available source gives a complete assignment.
Do not infer specific pin numbers beyond the GPIO-to-function map above.

Two `mini-PCIe` sockets map to `pcie0`/`pcie1`, the WWAN M.2 (Key-B) maps to
`pcie2`, and the NVMe M.2 (Key-M) maps to `pcie3` — tier **[A]** (device-tree
node comments/aliases), consistent with the expansion-slot map above.

## GPIO-usability guidance

- **SYS (GPIO79) and WPS (GPIO63) LEDs are solder-tap-able.** Both are
  already GPIO-driven with existing traces/pads, so relocating or duplicating
  either indicator (e.g. to a front panel) needs no device-tree change — tap
  the existing signal, or parallel a new LED across it with its own series
  resistor sized for the new LED's forward voltage/current (the original
  resistor was sized for the on-board LED, not necessarily the new one).
- **New front LEDs with no existing GPIO backing need a spare header GPIO +
  resistor + a device-tree edit.** Add a new `gpio-leds` child node mirroring
  the existing `led-green`/`led-blue` node shape (`function`, `color`,
  `gpios`, `default-state`), pointed at an unclaimed GPIO routed out through
  the 26-pin header, then size a series resistor for 3.3V logic and the new
  LED's forward voltage/current. This is the same mechanism the two on-board
  LEDs already use, just repointed at a spare pin — no new driver or kernel
  module required.
- **The WPS button (GPIO14) can be parallel-wired to a new physical button
  with zero software/device-tree change** — it is already a configured
  `gpio-keys` input (active-low, mapped to a restart action); a new switch
  wired in parallel simply pulls the same line low.
- **Reset can also be parallel-wired with zero software change** — since it
  is a hardware reset line rather than a GPIO/software input, a new switch
  wired across the existing reset pads works purely electrically.
- **Power LED and per-port WAN/LAN LEDs are not GPIO relocation candidates**
  by the same mechanism as above — the power LED is a hardwired rail tap
  (parallel LED+resistor, no device-tree involvement) and the WAN/LAN LEDs
  are PHY-integrated inside the RJ45 jacks (already front-facing, not
  practically relocatable).
- **OpenWrt config note**: a new `gpio-leds`/`gpio-keys` node takes effect by
  rebuilding/reflashing the board's device tree blob (DTB) as part of an
  OpenWrt image build, or via a device-tree overlay if the target build
  supports one — the same mechanism used to define the vendor's own
  `led-green`/`led-blue`/WPS-button nodes.
- **Which lines are free**: GPIOs 5, 14, 21, 54, 63, 69, 70, 79, and 82 are
  claimed by the on-board functions documented above (out of 84 total SoC
  GPIO lines). The full remaining allocation (SFP2, Ethernet PHY resets, fan
  control, storage interfaces, other PCIe reset lines, etc.) is **not fully
  enumerated in the available sources** — treat any GPIO not listed above as
  a *candidate* only, and confirm it is genuinely free against the full board
  schematic (or a continuity/multimeter check on the physical header) before
  wiring a new front LED to it.
