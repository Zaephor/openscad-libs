// asserts.scad — render-time invariants for the fan-grille project.
// `use` doesn't import variables (see reference_openscad_gotchas), so the
// default-render check below relies on fan-grille.scad's own top-level
// assert() + fan_grille() call; the size-validity assert here is a second,
// independent check against the fans lib directly.
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;
use <../fan-grille.scad>;

// Default entry renders clean (fan-grille.scad's own top-level fan_grille()
// call already does this; re-assert the size validity here independently).
assert(len([for (s = fan_known_sizes()) if (s == 40) s]) > 0,
    "fan-grille: default fan_size 40 missing from fan_known_sizes()");

fan_grille();

// A second known size, to prove the module is actually parametric (not
// hard-coded to 40mm) -- mirrors tests/test_fan_grille.sh's shell-side check.
fan_grille(fan_size = 120);
