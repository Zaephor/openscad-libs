// css610-underdesk-mount — L-bracket (printed L+R pair) to hang a MikroTik
// CSS610-8G-2S+IN under a desk: bolts to the device side M3 pattern, top flange
// flush with the device top, wood screws up into the desk. Standalone (no libs);
// device data project-local [A] MikroTik dimensional drawing. See RESEARCH/README.

/* [Device data — MikroTik CSS610-8G-2S+IN, [A] dimensional drawing] */
function _css610_size() = [200.9, 166.6, 47.1];  // W, D, H [A]
// side mount holes (per side): 25x25 square, X from mounting-end edge, Z from bottom. M3.
function _css610_side_holes() = [[9.5,9.5],[9.5,34.5],[34.5,9.5],[34.5,34.5]]; // [A] positions

/* [Bracket] */
leg_thickness = 3; flange_thickness = 4; gusset = 8;
mount_hole = 3.4;   // M3 clearance [A]/[B] user-confirmed
wood_screw = 4; csk_dia = 8;
flange_len = 25; flange_width = 40; standoff = 0;

assert(len(_css610_side_holes()) == 4, "CSS610 side pattern = 4 holes");
assert(_css610_size()[2] == 47.1, "CSS610 height (flange datum)");
