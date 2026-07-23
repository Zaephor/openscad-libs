// render_keystone_blank.scad — isolates the blank for verify-scad-geometry.
// Params threaded as args (use-scope; -D would false-pass).
use <keystone/keystone.scad>;
use <../keystone-blank.scad>;

keystone_blank();
