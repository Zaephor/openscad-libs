// defaults.scad — single source of truth for the cooling/ear-hole toggle
// defaults; every entry file (assembly.scad, parts/tray.scad, parts/lid.scad,
// tests/asserts.scad) `include`s this BEFORE `include <params.scad>`, which
// only consumes them (never re-assigns — see params.scad's comment on why).
// CAVEAT: OpenSCAD's Customizer GUI only lists variables declared directly
// in the file it has open (not through include/use), so these 4 no longer
// show as separate Customizer widgets in assembly.scad/tray.scad/lid.scad —
// override via `-D name=value` on the CLI (as the test suite does), or edit
// the literals below directly. Verified against the OpenSCAD manual
// (files.openscad.org/documentation/manual/Customizer.html): "Only variables
// in the main file are evaluated. Files from includes and use are not
// considered."
enable_exhaust = true;
fan_size       = 40;
fan_count      = 2;
ear_hole_type  = "slot";
