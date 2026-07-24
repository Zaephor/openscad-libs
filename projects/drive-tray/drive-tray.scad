// drive-tray — parametric 1U rack10 storage tray: cols x rows grid of bottom-
// mounted drives, honeycomb floor vents, rear #40 support tongue. Serves the
// 2x3.5" (#44) and 6x2.5" (#45) presets. Consumes drives/rack10/rack-support/
// honeycomb. Prints flat, open-top, support-free.
use <drives/drives.scad>;
use <rack10/rack10.scad>;
use <rack-support/rack-support.scad>;

/* [Rack] */
standard = "labrax";
device_u = 1;
ear_type = "slot";
/* [Drives] */
drive_type = "hdd35";  // block drive from drive_known_types()
cols = 2;
rows = 1;
/* [Print] */
wall = 2.4;
floor_th = 3.0;
drive_gap = 4.0;
faceplate_th = 3.0;

// block-drive guard (reject M.2 card types)
assert(len([for (t = drive_known_types()) if (t == drive_type && drive_family(t) == "block") t]) > 0,
    str("drive-tray: drive_type '", drive_type, "' must be a block drive"));

// drive footprint — drive_placeholder(type)/drive_holes(type,...) draw in the
// DRIVE's own datum frame (drives.scad header: +X=length, +Y=width, +Z=height).
// This tray's grid instead wants length along Y (tray depth) and width along X
// (tray width), so _dlen()/_dw() below are labeled for the TRAY frame, not a
// direct index copy of drive_size() — see _dt_device_frame() for the
// rotate([0,0,90]) that reconciles the two frames at the actual draw site
// (same fix as bay-enclosure's _be_device_frame(); do not "fix" this by
// swapping which drive_size() index feeds _dlen()/_dw(), that breaks the fit
// asserts below against the spec's target grid numbers).
function _dsz()     = drive_size(drive_type);       // [len, width, height]
function _dlen()    = _dsz()[0];                     // along Y (depth)
function _dw()      = _dsz()[1];                     // across X (width)
function _dh()      = _dsz()[2];                     // Z
function _grid_w()  = cols*_dw()  + (cols-1)*drive_gap;
function _grid_d()  = rows*_dlen() + (rows-1)*drive_gap;
function _clear()   = rack10_clear_width(standard);
function _int_h()   = rack10_device_height(device_u) - floor_th;

// Fit-assert (width + height; depth added in T2 once rear-post-Y is imported).
assert(_grid_w() <= _clear() - 2*wall + 1e-6,
    str("drive-tray: grid width ", _grid_w(), " > usable ", _clear() - 2*wall,
        " (reduce cols or drive_gap)"));
assert(_dh() <= _int_h() + 1e-6,
    str("drive-tray: drive height ", _dh(), " > 1U interior ", _int_h()));

// Depth fit-assert (grid depth vs. rack10's rear-post depth budget, minus
// the tongue's own engagement land AND this tray's faceplate thickness -- a
// deliberately conservative BUDGET, not the tight structural minimum: the
// floor/walls/tongue themselves are placed against rack10_rear_post_y()
// directly by the rack-support (#40) consumer-contract formula (see
// _reach() below), not against this reduced figure. This assert exists only
// to keep the drive grid itself from being sized so deep it leaves no depth
// margin at all for the rear wall + tongue buttress.
function _usable_depth() = rack10_rear_post_y(standard) - faceplate_th - rack_support_engagement_depth();
assert(_grid_d() <= _usable_depth() + 1e-6,
    str("drive-tray: grid depth ", _grid_d(), " > usable ", _usable_depth(),
        " for standard ", standard, " (reduce rows / pick a deeper vendor)"));

// Rear #40 support-tongue placement -- rack-support's own consumer-contract
// "Placement formula" (see libraries/rack-support/README.md): the tongue's
// TIP lands exactly at rack10_rear_post_y(standard) (rack_support_plate()'s
// own mounting plane), and its ROOT sits rack_support_engagement_depth() mm
// forward of that. Deliberately NOT _usable_depth() (rpy - faceplate_th -
// ed) -- that function is a conservative BUDGET for the grid fit-assert
// above only. Using it here would place the tongue's root (and therefore
// its tip) faceplate_th short of the doc-contract position, leaving the
// tongue faceplate_th shy of rack_support_plate()'s mounting plane and
// short of full engagement. Confirmed against the sibling #41 consumer
// (bay-enclosure)'s own STL check that its Y-max == rack10_rear_post_y(
// "labrax") == 240 (tests/test_bay_enclosure.sh) -- same placement formula.
function _reach() = rack10_rear_post_y(standard) - rack_support_engagement_depth();

// Per-cell origin (cell's low-X/low-Y corner), grid centered in X, front row at Y=0.
function _cell_xy(c, r) = [ -_grid_w()/2 + c*(_dw() + drive_gap), r*(_dlen() + drive_gap) ];

// Device datum -> tray-frame transform for cell (c,r). drive_placeholder(type)
// draws cube(drive_size(type)) with local X=length, Y=width, Z=height
// (drives.scad header); the tray frame wants the drive's length axis on tray
// Y (depth) and its width axis on tray X, per _dlen()/_dw() above. rotate([0,
// 0,90]) maps local (x,y) -> global (-y,x); translating by [cell_x + _dw(),
// cell_y, floor_th] then lands the rotated cube at global X in
// [cell_x, cell_x+_dw()], Y in [cell_y, cell_y+_dlen()] — exactly the cell
// footprint _cell_xy()/_grid_w()/_grid_d() assume. drive_holes(...) is
// applied through this SAME module (see drive_tray() below) so the stamped
// mount holes can never drift out of alignment with the placeholder — same
// single-source-of-truth idiom as bay-enclosure's _be_device_frame().
module _dt_device_frame(c, r) {
    p = _cell_xy(c, r);
    translate([p[0] + _dw(), p[1], floor_th]) rotate([0, 0, 90]) children();
}

// Front rack faceplate + ear holes (bpir4/faceplate idiom, same shape as
// bay-enclosure's _be_faceplate()). Front face at Y=-faceplate_th, back face
// (where the floor/walls join it) at Y=0 -- the rack10 front-post datum,
// matching where rack10_holes() itself stamps (Y=0-centered cutter).
module _dt_faceplate() {
    difference() {
        translate([-rack10_panel_width(standard)/2, -faceplate_th, 0])
            cube([rack10_panel_width(standard), faceplate_th, rack10_device_height(device_u)]);
        if (ear_type == "slot")
            rack10_holes(standard, device_u, hole_type = "slot", dia = rack10_screw_clearance("10-32"));
        else
            rack10_holes(standard, device_u, hole_type = ear_type);
    }
}

module drive_tray() {
    fw  = _grid_w() + 2*wall;             // overall floor/wall-pair width
    fx0 = -fw / 2;                        // floor's/left-wall's outer-X origin
    wh  = rack10_device_height(device_u); // side/rear wall height, matches the faceplate

    difference() {
        union() {
            _dt_faceplate();

            // Floor: front (Y=-wall, overlapping the faceplate's back face,
            // same idiom as the Task-1 floor) through the tongue's root
            // (_reach()) -- NOT past it. Nothing extends past _reach() into
            // the tongue's own engagement span; see the NO-buttress-shelf
            // comment below for why.
            translate([fx0, -wall, 0]) cube([fw, _reach() + wall, floor_th]);

            // Side walls: wall-thick, full device height, matching the
            // floor's Y-span.
            for (sx = [-1, 1])
                translate([sx > 0 ? fx0 + fw - wall : fx0, -wall, 0])
                    cube([wall, _reach() + wall, wh]);

            // Rear wall: closes the box; the tongue attaches to its back
            // face. NOTE: no separate 45deg gusset at the faceplate/floor or
            // wall/floor joints -- both are geometric no-ops for this
            // design, same root cause bay-enclosure documented for its own
            // front joint: at the wall X-bands, the side wall already spans
            // the FULL [0,wh] height over the SAME Y-Z footprint the
            // faceplate/floor already occupy there (one contiguous solid,
            // nothing to brace); at the center X-band (under the drive
            // grid), _dt_device_frame() parks each drive flush at
            // Z=floor_th (zero clearance, by design), so there is zero
            // headroom above the floor for ANY raised gusset material
            // without fouling drive fit.
            translate([fx0, _reach() - wall, 0]) cube([fw, wall, wh]);

            // NO rear buttress shelf under the tongue's own engagement span
            // (Y > _reach()), despite rack-support's README consumer
            // contract suggesting one ("running the tray's own floor at the
            // same Z height as the tongue's underside for the last
            // engagement_depth() mm", as rack-support's own assembly.scad
            // reference tray does). Verified empirically (verify-scad-
            // geometry + a real intersection() boolean against
            // rack_support_plate(standard, device_u) translated to
            // rack10_rear_post_y(standard)): a shelf there -- at ANY width,
            // even just the tongue's own rw -- occupies the EXACT same
            // Y=[_reach(),rpy] x Z=[0,ft] space rack_support_plate()'s own
            // bearing floor already fills once assembled (that floor spans
            // the full mouth-through-panel Y range, not just under the
            // channel cavity), producing a real ~960mm^3 solid-solid
            // interference, not a coincident-face touch -- confirmed by
            // dumping the intersection's own triangle data (all non-
            // degenerate facets bounded exactly by rw/ft/[_reach(),rpy]).
            // Two rigid printed parts can't occupy that shared volume, so
            // any buttress in this span would physically block full
            // insertion. See task-2-report.md for the full write-up; this
            // is a tension in rack-support's own consumer-contract guidance
            // (its own assembly.scad reference tray appears to have the
            // same unverified collision), not something fixable from this
            // consumer alone. Left as a flagged concern: the tongue's own
            // 12mm reach (rack_support_engagement_depth()) prints as a
            // modest, stocky (40x10mm cross-section) cantilever off the
            // rear wall's full-height, full-width anchor face at _reach()
            // -- right at this repo's own ~5-10mm "usually fine, minor
            // droop" bridging guideline (design-for-print/reference/
            // overhangs-supports.md), slightly past it and a cantilever
            // (weaker than a bridge), a real but modest print-time risk.

            // Rear #40 support tongue -- placement formula per rack-support's
            // own README consumer contract: tip lands at rack10_rear_post_y
            // (rack_support_plate()'s own mounting plane), root sits
            // engagement_depth() forward of that (see _reach() above).
            translate([0, _reach(), 0]) rack_support_tongue();
        }
        // Bottom mount-hole cutters per cell, subtracted from the floor.
        // _dt_device_frame() anchors local Z=0 at the drive's bottom face
        // (absolute Z=floor_th, the floor's TOP). drive_holes()'s cylinder
        // is center=true around ITS OWN local Z=0 (drives.scad: "pierces
        // Z=0 floor"), so shifting the local frame down by floor_th/2 lands
        // that center on the floor's MIDPLANE (absolute Z=floor_th/2) --
        // with depth=floor_th+2 the cut then spans absolute Z=[-1,
        // floor_th+1], a clean 1mm-margin through-cut of the [0,floor_th]
        // floor slab. Shifting by a full floor_th (an earlier revision of
        // this line) anchors the cylinder's center at the floor's BOTTOM
        // face instead of its midplane, so the same depth only cuts
        // [-2.5, +2.5] -- past the bottom but NOT reaching the top face at
        // floor_th=3.0, leaving a real un-perforated skin there (caught by
        // rendering to STL and point-in-mesh testing a known hole XY at
        // Z=floor_th: covered/solid at top, open at bottom -- an asymmetric,
        // wrong result for what must be a straight through-hole).
        for (c = [0:cols-1]) for (r = [0:rows-1])
            _dt_device_frame(c, r)
                translate([0, 0, -floor_th/2])
                    drive_holes(drive_type, faces = "bottom", depth = floor_th + 2);
    }
    // Drive placeholders per cell — % preview only, excluded from real geometry/export.
    for (c = [0:cols-1]) for (r = [0:rows-1])
        _dt_device_frame(c, r) % drive_placeholder(drive_type);
}
drive_tray();
