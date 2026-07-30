// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// gs308t.scad — positive-control preset check for rack10-device-tray: the
// GS308T envelope ([158,101,30] [B] vendor datasheet) with secure_holes=[]
// (a RESEARCHED NEGATIVE, not a placeholder — the GS308T's official
// Hardware Installation Guide covers desktop/flat-surface mounting only,
// corroborated by a NETGEAR Community reply + independent inspection that
// the underside has no keyhole slots; see README.md's Presets section).
// This preset is retained by the cradle walls/floor alone, zero screws.
// Rendered directly by tests/test_rack10_device_tray.sh, which also
// confirms it stamps 0 countersunk holes (facet count matches the
// tests/no_secure_holes.scad "no holes" baseline).
//
// `include` (not `use`) required -- see rla_ps1.scad's header comment for
// why (use doesn't import variables; override must come after the
// include so it's the LAST textual assignment).
include <../rack10-device-tray.scad>;

device_size  = [158, 101, 30]; // GS308T [B]
secure_holes = [];             // researched negative -- see README.md
