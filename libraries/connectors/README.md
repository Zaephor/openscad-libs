# connectors (library)

Connector body (housing/shell) envelope dimensions for common PC/SBC panel
and slot connectors: USB Type-A / Type-A-stacked / Type-C / Micro-B, RJ45 /
RJ45-stacked, HDMI Type-A / mini / micro, PCIe x1/x4/x8/x16 card-edge slot,
and a 2.54mm-pitch 2x20 GPIO header. All dimensions in millimeters.

**Status: Task 1 (research) only.** `RESEARCH.md` has the full evidence log
(fetched drawing values, tiers, seed/sbc/motherboards cross-checks). The
type table and `connector_body()`/`connector_cutout()` modules described in
 are not yet
implemented — `connectors.scad` currently holds only the canonical frame +
provenance-legend header.

## Import

```scad
use <connectors/connectors.scad>;
```

## Known gaps (see RESEARCH.md for detail)

- `mini_hdmi`, `micro_hdmi`: no independent vendor drawing found/reachable
  this pass — seed values only, `[C] //VERIFY (cited-not-fetched)`.
- `pcie_x1`/`x4`/`x8`/`x16`: Molex 87715 / PCI-SIG CEM named but not
  fetched (Molex is a JS SPA; CEM spec is member-paywalled) — `[C] //VERIFY
  (cited-not-fetched)`. Note: `libraries/motherboards/motherboards.scad`
  currently carries an unverified soft `[A]` claim for these same numbers;
  RESEARCH.md flags this for a deferred retrofit.
- `gpio_2x20` height (8.5mm): width/depth are solid 2.54mm-pitch arithmetic
  `[A]`; the only 2.54mm header datasheet reachable this pass was a
  shorter/different (6.0mm) variant, so height stays `[C] //VERIFY`.
- `micro_usb` depth: fetched drawing gives two plausible readings (5.48mm /
  9.20mm) that need re-checking against the source PDF, not a guess.

## Sources

See `lib.json` `sources[]` and `RESEARCH.md` for the full per-type evidence
and fetch-method notes.
