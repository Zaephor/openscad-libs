// two-piece-box — multipart assembly with tuneable exploded view.
// Render: make render P=two-piece-box
use <parts/body.scad>;
use <parts/lid.scad>;

/* [Exploded View] */
explode = 0; // [0:0.01:1]

/* [Parts] */
show_body = true;
show_lid  = true;

// Each part offsets along its own vector scaled by `explode`
// (0 = assembled, 1 = fully exploded).
module assembly() {
    if (show_body) body();
    if (show_lid) translate([0, 0, 40] * explode) translate([0, 0, 20]) lid();
}

assembly();
