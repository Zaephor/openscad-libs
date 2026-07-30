// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// no_secure_holes.scad — positive-control preset check for rack10-device-
// tray: secure_holes=[] (the GS308T scenario -- desktop-mount-only, no
// bottom mount holes at all) must render clean, exercising the T2 binding
// correction that the countersunk-hole cutter loop and its guarding
// asserts handle an empty list cleanly (for() no-ops, no crash, no
// divide-by-len/index-0 assumption). Rendered directly by
// tests/test_rack10_device_tray.sh, and also used as the "no holes"
// facet-count baseline the script diffs the default (2-hole) render
// against to prove the countersunk holes are actually being cut.
//
// `include` (not `use`) required -- see rla_ps1.scad's header comment for
// why (use doesn't import variables; override must come after the
// include so it's the LAST textual assignment).
include <../rack10-device-tray.scad>;

secure_holes = [];
