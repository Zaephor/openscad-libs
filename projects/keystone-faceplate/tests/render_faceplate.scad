// render_faceplate.scad — isolates the faceplate for verify-scad-geometry.
// Params threaded as args (use-scope; -D would false-pass).
use <keystone/keystone.scad>;
use <rack10/rack10.scad>;
use <../keystone-faceplate.scad>;

keystone_faceplate("labrax", 6, keystone_pitch(), 3.0, port_style = "lip");
