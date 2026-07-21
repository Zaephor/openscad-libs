// din-rail library.
// EN 60715 TS35 top-hat DIN rail: profile data (Task 2) + support-free
// mounting clip (Task 3). See RESEARCH.md for tiered dimensional sourcing.
//
// Multi-role component convention (see docs/LIBRARY-AUTHORING.md):
//   1. Data        — functions returning constants / [x,y] coord lists
//                    (expose as functions: OpenSCAD `use` does not import variables)
//   2. Placeholder — envelope solid for fit checks
//   3. Hole-stamp  — mounting/cutout stamps for a consumer difference()
// Conventions: centered origin X/Y, bottom face on Z=0; clearances from named
// functions; millimeters; central $fn. Provenance: tag each value [A]/[B]/[C]
// with a source; use //VERIFY for weak/unconfirmed values.
//
// NOTE: OpenSCAD identifiers cannot contain hyphens (parsed as the minus
// operator) — the template's naive __NAME__ substitution produces invalid
// identifiers (e.g. "din-rail_width") for this hyphenated library name.
// Task 2/3 must name functions/modules with underscores instead
// (e.g. din_rail_width(), din_rail_placeholder()), not the literal
// "din-rail" library/file name.
//
// Scaffold only (Task 1) — no rail data or geometry yet.
// Task 2 adds profile data + reference module; Task 3 adds the clip.

$fn = 48;
