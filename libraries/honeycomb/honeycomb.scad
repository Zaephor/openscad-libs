// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// honeycomb_vent(width, height, depth, cell, wall) — self-supporting hex-hole
// vent cutter for ventilation openings and cutouts.
//
// A reusable library module consumed by any project: `use <honeycomb/honeycomb.scad>`.
// Produces flat-top hexagon patterns that are designed to be self-supporting
// (no print supports needed). Keep the module signature stable --
// honeycomb_vent(width, height, depth, cell, wall) -- callers depend on it verbatim.
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
// (typically derived from board/connector geometry by the calling project,
// not a hand-picked literal) and is essentially never an exact multiple of
// `row_pitch`. A
// naive `intersection()` with `square([width, height])` clips whichever hex
// straddles y=0 or y=height at WHATEVER point its own vertical position
// happens to land -- and a flat-top hex's cross-section width varies from
// cell/2 (at its own flat top/bottom edge, the intended <=5mm bridge) up to
// the full `cell` (at its equator, the two side vertices). Clipping near
// the equator instead of the flat edge can expose a span close to `cell`
// -- e.g. with cell=8/wall=1.2 defaults and a real caller's band height
// (15.9mm), the naive clip left a ~7.59mm top-row span, blowing past the
// design-for-print <=5mm reliably-self-supporting ceiling.
// Fix: test every boundary-straddling hex individually (`_hex_is_safe()`)
// against that same width-at-offset formula, and simply omit (don't draw)
// any hex whose clip would expose more than `max_safe_span`. Hexes fully
// inside the band are unaffected (their natural flat edges are already
// cell/2); the only visible effect at the top/bottom row is that a column
// whose boundary hex would clip unsafely shows one fewer partial hex there
// (a hair less vent area at that edge) instead of an oversized opening.
// This makes the module safe for ANY caller-supplied height without the
// caller having to pick a row_pitch-aligned value -- see
// `tests/test_honeycomb_lib.sh`'s worst-case-span check.
//
// Left/right (X / `width`) boundary clipping does NOT need the same
// treatment: X is the direction perpendicular to the extrusion's bridging
// span (the flat top/bottom edge runs in X), so clipping in X can only
// shorten that edge (or the hex's side facets, which run vertically and
// need no bridging support at all) -- it can never lengthen the span that
// has to bridge in the extrusion direction. Confirmed by inspection of the
// vertex geometry below (worst case is a shortened, not widened, edge).
//
// Local frame (a corner-anchored cube-cutter convention, not centered):
// X in [0, width], Y in [0, height], Z in [0, depth]. The hex array is
// built in the local XY plane and linear-extruded along local Z by `depth`;
// callers rotate/translate the whole call to align local Z with whichever
// axis they're actually cutting through (e.g. a vertical wall vent might
// rotate([90,0,0]) so local Z lands on the assembly's vertical axis and
// local Y -- depth -- lands on the assembly's depth axis, matching whatever
// cube cutter it replaces).
// Shared hex-grid math -- top-level functions so both honeycomb_vent() (the
// module, below) and honeycomb_cell_centres() (the accessor) call the exact
// same code. There is exactly one place this grid is computed; a future
// change to any of these must be made once, and draw/report can never
// silently disagree.

// design-for-print's bridging ceiling: <=5mm is "reliably self-supporting,
// minimal-to-no sag" (see reference/overhangs-supports.md).
function _honeycomb_max_safe_span() = 5;

// Width of a flat-top hex's cross-section at vertical offset `dy` from its
// OWN center (valid for dy in [-hex_h/2, hex_h/2]).
function _honeycomb_span_at(dy, cell, hex_h) = cell * (1 - abs(dy) / hex_h);

// Is it safe to draw the hex centered at local y (before the caller's
// [0,height] clip)? See the module-level header comment block above for the
// full derivation.
function _honeycomb_hex_is_safe(y, height, cell, hex_h) =
    let (top = y + hex_h/2, bot = y - hex_h/2, max_span = _honeycomb_max_safe_span())
    (bot >= 0 && top <= height) ? true
    : (top <= 0 || bot >= height) ? true
    : (bot < 0 && top > height) ? false
    : (top > height) ? (_honeycomb_span_at(height - y, cell, hex_h) <= max_span)
    : (_honeycomb_span_at(0 - y, cell, hex_h) <= max_span);

// Real exposed clip span of the hex actually drawn at local y (0 if nothing
// is drawn there at all -- see honeycomb_vent()'s original regression-guard
// comment for why this is computed independently of the boolean gate above).
function _honeycomb_drawn_span(y, height, cell, hex_h) =
    let (top = y + hex_h/2, bot = y - hex_h/2)
    (bot >= 0 && top <= height) ? cell/2
  : (top <= 0 || bot >= height) ? 0
  : (bot < 0 && top > height)   ? cell
  : (top > height) ? _honeycomb_span_at(height - y, cell, hex_h)
  : _honeycomb_span_at(0 - y, cell, hex_h);

// Every hex centre (local frame) that honeycomb_vent(width, height, cell,
// wall) actually draws for these arguments -- single source of truth for
// "which hexes exist", consumed by both the module's own union() and by
// honeycomb_cell_centres() below.
function _honeycomb_centres(width, height, cell, wall) =
    let (r = cell / 2,
         hex_h = r * sqrt(3),
         hex_w = 2 * r,
         col_pitch = 0.75 * hex_w + wall,
         row_pitch = hex_h + wall,
         n_cols = ceil(width  / col_pitch) + 3,
         n_rows = ceil(height / row_pitch) + 3,
         x0 = -col_pitch,
         y0 = -row_pitch)
    [
        for (cx = [0 : n_cols])
            for (cy = [0 : n_rows])
                let (y = y0 + cy * row_pitch + ((cx % 2 == 0) ? 0 : row_pitch / 2),
                     x = x0 + cx * col_pitch)
                if (_honeycomb_hex_is_safe(y, height, cell, hex_h)) [x, y]
    ];

module honeycomb_vent(width, height, depth, cell, wall) {
    r     = cell / 2;
    hex_h = r * sqrt(3);
    centres = _honeycomb_centres(width, height, cell, wall);
    echo(str("HONEYCOMB_CENTRES_COUNT=", len(centres)));

    // Regression guard -- independent of trusting _honeycomb_hex_is_safe()'s
    // boolean. See the header comment block above for the full rationale.
    worst_span = max([for (c = centres) _honeycomb_drawn_span(c[1], height, cell, hex_h)]);
    echo(str("HONEYCOMB_WORST_SPAN=", worst_span, " max_safe_span=", _honeycomb_max_safe_span()));
    assert(worst_span <= _honeycomb_max_safe_span() + 1e-6,
        str("honeycomb boundary hex exposes span ", worst_span, "mm > max_safe_span ",
            _honeycomb_max_safe_span(), "mm -- self-support ceiling violated"));

    linear_extrude(height = depth)
        intersection() {
            square([width, height]);
            union() {
                for (c = centres)
                    translate(c)
                        circle(r = r, $fn = 6);   // flat-top hex (see header note)
            }
        }
}

// honeycomb_cell_centres(width, height, cell, wall) -- returns [[x,y], ...],
// the local-frame centre of every hex honeycomb_vent() actually draws for the
// SAME arguments (same _honeycomb_hex_is_safe() gate, same underlying
// _honeycomb_centres() call the module itself uses -- not a re-derived
// copy). Lets a consumer that must re-add a foreign solid into the field
// (e.g. a fastener bearing pad) know which cells are really there, without
// re-deriving the grid math itself -- see libraries/honeycomb/README.md's
// "self-check does not certify embedded solids" note for why a consumer
// cannot just trust HONEYCOMB_WORST_SPAN for this. Pure geometry-facts
// accessor: no region/filter param -- callers do their own overlap
// filtering (e.g. against a pad's own radius).
function honeycomb_cell_centres(width, height, cell, wall) =
    _honeycomb_centres(width, height, cell, wall);
