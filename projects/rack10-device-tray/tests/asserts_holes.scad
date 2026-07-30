// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts_holes.scad — negative-control regression for rack10-device-
// tray's secure_holes-inside-footprint fit-assert. Rendered directly by
// tests/test_rack10_device_tray.sh. Same include-then-override idiom as
// rla_ps1.scad — see that file's header comment for why `include` (not
// `use`) and why the override must come AFTER the include.
include <../rack10-device-tray.scad>;

// second hole's x=200 sits past the default device's own width (158) —
// MUST abort the per-hole footprint fit-assert. If this file ever renders
// cleanly, that fit-assert has silently broken.
secure_holes = [[44.25, 51, 3.4], [200, 51, 3.4]];
