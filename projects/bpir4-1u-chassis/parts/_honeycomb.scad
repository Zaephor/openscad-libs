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
// Boundary rows (self-support fix): `height` is a caller-supplied value
// (derived from board/connector geometry in this project, not a hand-picked
// literal) and is essentially never an exact multiple of `row_pitch`. A
// naive `intersection()` with `square([width, height])` clips whichever hex
// straddles y=0 or y=height at WHATEVER point its own vertical position
// happens to land -- and a flat-top hex's cross-section width varies from
// cell/2 (at its own flat top/bottom edge, the intended <=5mm bridge) up to
// the full `cell` (at its equator, the two side vertices). Clipping near
// the equator instead of the flat edge can expose a span close to `cell`
// -- e.g. with this project's cell=8/wall=1.2 defaults and the faceplate's
// actual band height (15.9mm), the naive clip left a ~7.59mm top-row span,
// blowing past the design-for-print <=5mm reliably-self-supporting ceiling.
// Fix: test every boundary-straddling hex individually (`_hex_is_safe()`)
// against that same width-at-offset formula, and simply omit (don't draw)
// any hex whose clip would expose more than `max_safe_span`. Hexes fully
// inside the band are unaffected (their natural flat edges are already
// cell/2); the only visible effect at the top/bottom row is that a column
// whose boundary hex would clip unsafely shows one fewer partial hex there
// (a hair less vent area at that edge) instead of an oversized opening.
// This makes the module safe for ANY caller-supplied height without the
// caller having to pick a row_pitch-aligned value -- see
// `tests/test_bpir4_honeycomb_vents.sh`'s worst-case-span check.
//
// Left/right (X / `width`) boundary clipping does NOT need the same
// treatment: X is the direction perpendicular to the extrusion's bridging
// span (the flat top/bottom edge runs in X), so clipping in X can only
// shorten that edge (or the hex's side facets, which run vertically and
// need no bridging support at all) -- it can never lengthen the span that
// has to bridge in the extrusion direction. Confirmed by inspection of the
// vertex geometry below (worst case is a shortened, not widened, edge).
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

    // design-for-print's bridging ceiling: <=5mm is "reliably self-
    // supporting, minimal-to-no sag" (see reference/overhangs-supports.md).
    max_safe_span = 5;

    // Width of a flat-top hex's cross-section at vertical offset `dy` from
    // its OWN center (valid for dy in [-hex_h/2, hex_h/2]): interpolates
    // linearly from `cell` at the equator (dy=0, the side vertices) down to
    // cell/2 at either flat edge (dy = +/-hex_h/2). This is exactly the span
    // that would be exposed if a hex were clipped at that offset.
    function _span_at(dy) = cell * (1 - abs(dy) / hex_h);

    // Is it safe to draw this hex (centered at local y, before the caller's
    // [0,height] clip)? Fully inside -> always safe (natural flat edges are
    // already <=cell/2). Fully outside -> trivially safe (nothing drawn by
    // the clip anyway). Straddling exactly one edge -> safe only if the
    // exposed span at that clip point is <= max_safe_span. Straddling BOTH
    // edges (height < hex_h) can't be resolved by omission -- reject so a
    // misconfigured caller fails visibly rather than silently.
    function _hex_is_safe(y) =
        let (top = y + hex_h/2, bot = y - hex_h/2)
        (bot >= 0 && top <= height) ? true
        : (top <= 0 || bot >= height) ? true
        : (bot < 0 && top > height) ? false
        : (top > height) ? (_span_at(height - y) <= max_safe_span)
        : (_span_at(0 - y) <= max_safe_span);

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
                        if (_hex_is_safe(y))
                            translate([x, y])
                                circle(r = r, $fn = 6);   // flat-top hex (see header note)
                    }
            }
        }
}
