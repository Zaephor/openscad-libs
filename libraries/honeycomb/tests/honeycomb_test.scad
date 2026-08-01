// SPDX-License-Identifier: CC-BY-NC-SA-4.0
use <honeycomb/honeycomb.scad>;

// Positive control: valid honeycomb_vent call with safe parameters.
// width=40, height=16, depth=2 (reasonable vent aperture),
// cell=8, wall=1.2 (standard print-tuning values for self-support).
honeycomb_vent(width=40, height=16, depth=2, cell=8, wall=1.2);

// Cell-centre accessor: report vs draw consistency probe.
// Prints the reported centre count and first/last centre so the shell test
// can cross-check against the module's own HONEYCOMB_WORST_SPAN behavior.
centres = honeycomb_cell_centres(width=40, height=16, cell=8, wall=1.2);
echo(str("HONEYCOMB_CELL_CENTRES_COUNT=", len(centres)));
echo(str("HONEYCOMB_CELL_CENTRES_FIRST=", centres[0]));

echo("honeycomb_test OK");
