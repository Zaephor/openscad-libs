// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// asserts_port.scad — negative-control regression for rack10-device-
// tray's port-cutout-vs-#70-chamfered-panel-corner fit-assert. Rendered
// directly by tests/test_rack10_device_tray.sh. Same include-then-override
// idiom as rla_ps1.scad -- see that file's header comment for why
// `include` (not `use`) and why the override must come AFTER the include.
include <../rack10-device-tray.scad>;

// port_cutout=[252,40] with the default floor_th=3: the port's TOP edge
// lands at z=43 (floor_th+40), inside the panel's top chamfer band
// (h-c..h = 40.66..43.66 for the labrax 1U panel: h=rack10_device_height(1)
// =43.66, c=rack10_panel_corner_chamfer()=3.0) where the silhouette has
// already narrowed by 2.34mm per side -- the port's half-width (126) then
// exceeds the panel's max half-width there (124.66) and MUST abort the
// port-in-panel fit-assert. The port's BOTTOM edge (z=3, exactly at the
// bottom chamfer boundary) stays clear, and device_size/secure_holes are
// untouched, so this exercises ONLY the port-corner-clip assert -- no
// other fit-assert should fire first. If this file ever renders cleanly,
// that assert has silently broken.
port_cutout = [252, 40];
