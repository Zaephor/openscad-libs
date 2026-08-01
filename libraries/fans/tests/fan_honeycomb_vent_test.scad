// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// Render fixture for fan_honeycomb_vent() (#72) -- run via
// tests/test_fans_lib.sh. Single-fan case matching mitx-1u-chassis's own
// default geometry (fan_size=40, pad_dia=9), verified by hand in a sandbox
// pass: 688 facets, manifold ("Simple: yes"), HONEYCOMB_WORST_SPAN=4.04736
// (<=5mm ceiling).
use <fans/fans.scad>;
fan_honeycomb_vent(40, 40, 4.4, 8.0, 1.2, [[20, 20]], 40, 9);
