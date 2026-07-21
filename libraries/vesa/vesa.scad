// vesa — VESA FDMI (MIS) display-mount hole patterns.
// Data are FUNCTIONS (use<> does not import variables). Default orientation:
// pattern plane in X/Y, origin centered, holes cut along -Z; mm; central $fn.
// Provenance: [A] fetched spec/datasheet | [B] >=2 independent peers |
//             [C] single/derived or named-not-fetched | //VERIFY weak, confirm.
$fn = 48;

// M4 through-hole clearance — ISO 273 medium fit. Not re-derived here: this
// repo's single source of truth for the ISO 273 medium-fit series is the
// comment at libraries/rack19/rack19.scad:68 ("ISO 273's published medium
// fit series: M3->3.4, M4->4.5, M5->5.5, M6->6.6"). rack19_screw_clearance()
// itself has no "M4" case (rack19's own hardware doesn't use M4), so there is
// no accessor to call — this reuses the named convention directly rather
// than inventing a fresh literal. // [B] ISO 273 (named, not re-fetched)
function _vesa_m4_clearance() = 4.5;

// rows: [name, [spacing_w, spacing_h], screw, hole_dia]   // per-row tier comment
function _vesa_table() = [
    ["mis-d-75",  [75,75],   "m4", _vesa_m4_clearance()],  // [B] FDMI MIS-D 75, peers in RESEARCH.md
    ["mis-d-100", [100,100], "m4", _vesa_m4_clearance()],  // [B] FDMI MIS-D 100
    ["mis-e",     [200,100], "m4", _vesa_m4_clearance()],  // [B] FDMI MIS-E (4-corner subset modeled; see RESEARCH.md re: 6-hole variant not modeled)
];

function vesa_known_patterns()  = [for (e=_vesa_table()) e[0]];
function vesa_known_hole_roles() = ["structural-mount","component-mount","keep-out","alignment"];

function _vesa_row(name) =
    let (m = [for (e=_vesa_table()) if (e[0]==name) e])
    len(m)>0 ? m[0] : assert(false, str("vesa: unknown pattern '", name, "'"));

function vesa_spacing(name) = _vesa_row(name)[1];
function vesa_screw(name)   = _vesa_row(name)[2];

// four corner holes of the centered rectangle, all structural-mount
function vesa_holes(name, role=undef) =
    let (s = vesa_spacing(name), d = _vesa_row(name)[3],
         all = [ for (sx=[-1,1]) for (sy=[-1,1])
                 [sx*s[0]/2, sy*s[1]/2, "structural-mount", d] ])
    role==undef || role=="all" ? all
    : assert(len([for (r=vesa_known_hole_roles()) if (r==role) r])>0,
             str("vesa: unknown role '", role, "'"))
      [for (h=all) if (h[2]==role) h];

function vesa_holes_xy(name, role=undef) = [for (h=vesa_holes(name,role)) [h[0],h[1]]];

// hole-stamp cutter: dia=-1 → per-hole tagged dia; positive → uniform override.
module vesa_mount_holes(name, dia=-1, depth=6) {
    for (h = vesa_holes(name)) {
        r = (dia<0 ? h[3] : dia)/2;
        translate([h[0], h[1], -depth]) cylinder(h=depth+0.02, r=r);
    }
}

// reference plate placeholder (non-print demo): a thin centered plate the size of
// the pattern + margin, holes stamped. Support-free (flat).
module vesa_placeholder(name, margin=10, thickness=3) {
    s = vesa_spacing(name);
    difference() {
        translate([0,0,0]) linear_extrude(thickness)
            square([s[0]+2*margin, s[1]+2*margin], center=true);
        vesa_mount_holes(name, depth=thickness);
    }
}

// Visual self-check when opened directly.
vesa_placeholder("mis-d-100");
