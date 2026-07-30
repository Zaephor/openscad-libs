// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts_height.scad — negative-control regression for rack10-device-
// tray's 1U-height fit-assert. Rendered directly by
// tests/test_rack10_device_tray.sh. Same include-then-override idiom as
// rla_ps1.scad — see that file's header comment for why `include` (not
// `use`) and why the override must come AFTER the include.
include <../rack10-device-tray.scad>;

// device height 45mm > _int_h() (rack10_device_height(1) - floor_th ≈
// 40.66mm at defaults) — MUST abort the 1U-height fit-assert. Width/depth
// (158/102) stay well within budget, so this exercises ONLY the height
// assert. If this file ever renders cleanly, the height fit-assert has
// silently broken.
device_size = [158, 102, 45];
