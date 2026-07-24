use <honeycomb/honeycomb.scad>;

// Positive control: valid honeycomb_vent call with safe parameters.
// width=40, height=16, depth=2 (reasonable vent aperture),
// cell=8, wall=1.2 (standard print-tuning values for self-support).
honeycomb_vent(width=40, height=16, depth=2, cell=8, wall=1.2);

echo("honeycomb_test OK");
