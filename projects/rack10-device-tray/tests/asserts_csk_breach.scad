// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts_csk_breach.scad — negative-control regression for rack10-
// device-tray's countersunk-secure-hole "no top-face breach" fit-assert
// (the countersink cone must not rise taller than floor_th, or it would
// punch through the floor's top face into the device cavity). Rendered
// directly by tests/test_rack10_device_tray.sh. Same include-then-override
// idiom as rla_ps1.scad -- see that file's header comment for why
// `include` (not `use`) and why the override must come AFTER the include.
include <../rack10-device-tray.scad>;

// csk_dia=14 with the default secure_holes dia=3.4: cone height =
// (14-3.4)/2 = 5.3mm > floor_th=3.0mm -- MUST abort the no-breach assert.
// csk_dia (14) still exceeds every hole dia (3.4), so the positive-cone-
// height assert above it passes cleanly -- this exercises ONLY the
// breach assert.
csk_dia = 14;
