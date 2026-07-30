// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts_csk_positive.scad — negative-control regression for rack10-
// device-tray's countersunk-secure-hole "positive cone height" fit-assert
// (csk_dia must exceed each secure hole's own dia). Rendered directly by
// tests/test_rack10_device_tray.sh. Same include-then-override idiom as
// rla_ps1.scad -- see that file's header comment for why `include` (not
// `use`) and why the override must come AFTER the include.
include <../rack10-device-tray.scad>;

// Single hole at 8.5mm dia, >= the default csk_dia=8: (csk_dia > h[2]) is
// false, so the cone height would be negative -- MUST abort the positive-
// cone-height assert. Position (44.25,51) stays inside the default
// device's own footprint, so this exercises ONLY the csk-positive assert
// (the breach assert below it never gets evaluated -- it fires first).
secure_holes = [[44.25, 51, 8.5]];
