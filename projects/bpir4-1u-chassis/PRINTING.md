# Printing — bpir4-1u-chassis

- Printer/material: Bambu P1S, PETG.
- Orientation: tray floor-down (254 mm front face on the bed); lid flat.
- Supports: none needed for the tray if fan bores/vents stay vertical; none for lid.
- Heat-set inserts: M2.5 in the board standoffs (installed top-down), M3 in the
  lid posts. Install with a soldering iron before assembly.
- Fasteners: M2.5 × 6 mm (board), M3 × 8 mm countersunk (lid), M3 (fans).
- Fan mode: set `enable_exhaust=false` in `params.scad` to print the shorter
  passive box if the board's own heatsink+fan kit is sufficient (decide on the bench).
