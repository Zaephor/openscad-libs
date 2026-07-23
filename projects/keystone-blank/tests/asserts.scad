// asserts.scad — render-time invariants for the keystone-blank project.
// Rendered by tests/test_keystone_blank.sh. `use` doesn't import variables,
// so keystone_blank()'s own fit/latch_wall (0.2/1.0) can't be overridden from
// here (see reference_openscad_gotchas) — bench-tuned variants below call
// keystone_insert() directly instead.
use <keystone/keystone.scad>;
use <../keystone-blank.scad>;

// Default entry renders clean.
keystone_blank();

// Bench-tunable range (README: fit/latch_wall are meant to be tuned on the
// bench) renders clean at the library's own tested upper end (latch_wall=1.2,
// see keystone.scad's root-gusset margin comment) and with guides disabled.
keystone_insert(fit = 0.3, latch_wall = 1.2, blank = true);
keystone_insert(fit = 0.2, latch_wall = 1.0, blank = true, guides = false);
