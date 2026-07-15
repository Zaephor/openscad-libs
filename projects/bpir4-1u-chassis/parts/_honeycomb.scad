// _honeycomb.scad — reusable self-supporting hex-hole vent cutter.
//
// Consumed by parts/tray.scad (faceplate above-IO band) and, per the v3 plan,
// parts/lid.scad (lid vents) via `use <_honeycomb.scad>`. Keep the module
// signature stable -- honeycomb_vent(width, height, depth, cell, wall) --
// callers depend on it verbatim.
//
// Orientation: flat-top hexagons (a horizontal edge at the top/bottom of
// each cell, not a vertex) -- circle(r, $fn=6) already places vertices at
// 0/60/120/180/240/300 degrees, which is exactly this orientation, so no
// extra rotate() is needed. This is a deliberate self-support trade-off, not
// an accident: a pointy-top hex would need zero bridging (its void tapers to
// a vertex), but a flat-top hex's void ends in a genuine flat span -- the
// hexagon's top edge, of length cell/2 -- that the layer above must bridge.
// We accept that short, known bridge (see design-for-print's bridging
// table: <=5mm is "reliably self-supporting, minimal-to-no sag") in
// exchange for the flat-top look real honeycomb vents use. `cell` is sized
// below so that bridge (cell/2) stays safely under the 5mm ceiling.
//
// Geometry: `cell` is the hex's point-to-point width (2x circumradius);
// `wall` is the solid gap kept between adjacent hex holes. Hexes tile in
// columns (flat-top hexes pack column-wise, not row-wise): columns spaced by
// 0.75*cell + wall, with alternate columns offset vertically by half the row
// pitch (hex flat-to-flat height + wall).
//
// Local frame (matches this project's cube-cutter convention -- corner-
// anchored, not centered): X in [0, width], Y in [0, height], Z in
// [0, depth]. The hex array is built in the local XY plane and linear-
// extruded along local Z by `depth`; callers rotate/translate the whole call
// to align local Z with whichever axis they're actually cutting through
// (see parts/tray.scad's _faceplate() for the faceplate's rotate([90,0,0])
// call, which puts local Z onto the chassis Z axis and local Y -- depth --
// onto the chassis Y axis, matching the old cube cutter it replaces).
module honeycomb_vent(width, height, depth, cell, wall) {
    r      = cell / 2;                  // circumradius
    hex_h  = r * sqrt(3);               // flat-to-flat height (vertical)
    hex_w  = 2 * r;                     // point-to-point width (horizontal) == cell
    col_pitch = 0.75 * hex_w + wall;    // horizontal spacing between columns
    row_pitch = hex_h + wall;           // vertical spacing within a column

    n_cols = ceil(width  / col_pitch) + 3;  // pad past both edges so clipped
    n_rows = ceil(height / row_pitch) + 3;  // boundary cells look intentional
    x0 = -col_pitch;
    y0 = -row_pitch;

    linear_extrude(height = depth)
        intersection() {
            square([width, height]);
            union() {
                for (cx = [0 : n_cols])
                    for (cy = [0 : n_rows]) {
                        x = x0 + cx * col_pitch;
                        y = y0 + cy * row_pitch + ((cx % 2 == 0) ? 0 : row_pitch / 2);
                        translate([x, y])
                            circle(r = r, $fn = 6);   // flat-top hex (see header note)
                    }
            }
        }
}
