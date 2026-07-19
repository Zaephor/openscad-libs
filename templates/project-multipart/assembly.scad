// __NAME__ — multipart assembly with tuneable exploded view.
// Render: make render P=__NAME__

// use <fans/fans.scad>;   // import libraries as needed
use <parts/body.scad>;

/* [Exploded View] */
explode = 0; // [0:0.01:1]

/* [Parts] */
show_body = true;

// Each part offsets along its own vector scaled by `explode`
// (0 = assembled, 1 = fully exploded).
module assembly() {
    if (show_body) translate([0, 0, 0] * explode) body();
    // Add parts here, each with its own explode vector and show_<part> bool.
}

assembly();
