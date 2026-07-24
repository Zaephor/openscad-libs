// drive-tray — parametric 1U rack10 storage tray: cols x rows grid of bottom-
// mounted drives, honeycomb floor vents, rear #40 support tongue. Serves the
// 2x3.5" (#44) and 6x2.5" (#45) presets. Consumes drives/rack10/rack-support/
// honeycomb. Prints flat, open-top, support-free.
use <drives/drives.scad>;
use <rack10/rack10.scad>;

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

module drive_tray() {
    // Floor spanning the grid (walls/faceplate/tongue added in later tasks).
    translate([-_grid_w()/2 - wall, -wall, 0])
        cube([_grid_w() + 2*wall, _grid_d() + 2*wall, floor_th]);
    // Drives + bottom mount-hole clearance per cell.
    for (c = [0:cols-1]) for (r = [0:rows-1]) {
        _dt_device_frame(c, r) {
            % drive_placeholder(drive_type);
            translate([0, 0, -floor_th])
                drive_holes(drive_type, faces = "bottom", depth = floor_th + 2);
        }
    }
}
drive_tray();
