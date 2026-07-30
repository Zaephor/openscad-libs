#!/usr/bin/env bash
# #75: verifies each board standoff post (parts/tray.scad's board-standoff
# block in tray()) presents a heat-set LEAD-IN CHAMFER at its mouth, the same
# way the lid posts already do via heatset_pocket() (_lid_post_corner()).
# Before the leadin fix, sbc_standoffs() cut a plain constant-diameter pilot
# bore, so the mouth measured heatset_pilot_dia(board_insert_size) (4.01mm)
# all the way to the post's top face.
#
# A LATER regression (also #75, caught in review) had the pocket call sitting
# as a bare sibling under a plain translate(){ } block instead of inside a
# difference() -- heatset_pocket() is a NEGATIVE cutter (a union of solid
# cylinders meant for a consumer difference()), so a bare-sibling union ADDS
# the pocket's solid geometry onto the post instead of cutting it. That bug
# is invisible to a vertex-radius check alone: the unioned (uncut) frustum's
# own outer edge still lands at the expected chamfered radius at the top
# face, so a radius-only check reports a false PASS while the post is
# actually a solid plug with no cavity for an insert at all. This script
# therefore checks BOTH:
#   (1) the mouth's vertex radius (position check, kept from the original
#       version of this test), and
#   (2) an actual point-in-solid (ray-cast) check that a point on-axis,
#       mid-depth inside the expected pocket cavity, is VOID -- not solid.
#       (2) is the one with real discriminating power against the sibling-
#       union bug; (1) alone cannot catch it (see above).
#
# The point-in-solid method is self-validated against a known-simple case
# (a plain hollow tube) before being trusted against the real geometry --
# do not skip that step when modifying this script.
#
# Renders the FULL tray.scad (not an isolated harness) so the check exercises
# the real assembly, including the fact that the pocket loop
# (`for (h = sbc_holes(BOARD, "structural-mount")) ...`) must land on the
# SAME structural-mount posts sbc_standoffs() itself renders.
#
# Discriminator (1): slices the exported mesh at a standoff's world (x,y,z)
# top-face position (read live from params.scad/sbc.scad -- never
# hand-literaled), keeping only vertices radially close to that post's axis
# (a radius cutoff strictly between the mouth radius and the post OD radius,
# so post-wall vertices never leak in) within a thin Z-band around the top
# face. The widest radius among those is the mouth's measured radius; doubled,
# that is the measured mouth diameter -- compared against
# heatset_pilot_dia() (plain, unchamfered -- the original pre-fix value) and
# heatset_pilot_dia()+2*heatset_lead_in() (chamfered -- the expected value),
# both read from the heatset lib rather than hardcoded, so the test tracks a
# future insert-table change.
#
# Discriminator (2): casts several non-axis-aligned rays from a point at
# (post x, post y, mid-pocket-depth Z) and counts ray/triangle crossings
# (odd = inside solid, even = outside/void), majority-voted across rays for
# robustness against a ray grazing a facet edge. Mid-pocket-depth Z is
# ztop - (insert_length + lead_in)/2 -- comfortably inside the cavity, away
# from both the mouth chamfer geometry and the pocket-bottom cap.
#
# Checks EVERY structural-mount hole (not just one), which also demonstrates
# the pocket loop's role filter lines up with sbc_standoffs()' own role
# filter one-for-one (a role-filter mismatch would leave some structural-
# mount posts unchamfered).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"
fail=0

tmp="$(mktemp -d)"
dims_scad="$proj/tests/_t75_standoff_dims.scad"
tube_scad="$tmp/_t75_tube.scad"
cleanup() { rm -rf "$tmp"; rm -f "$dims_scad"; }
trap cleanup EXIT

# --- Read every structural-mount standoff's world (x,y) center + top-face Z,
# plus the expected mouth/pilot diameters and the pocket-depth components,
# all live from the libs/params (never hand-literaled). One echo'd line per
# hole "x y", then the shared scalars.
cat > "$dims_scad" <<'EOF'
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <../params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <heatset/heatset.scad>;
for (h = sbc_holes(BOARD, "structural-mount"))
    echo(str(board_x() + h[0], " ", board_y() + h[1]));
echo(floor_th + standoff_h);
echo(heatset_pilot_dia(board_insert_size));
echo(heatset_pilot_dia(board_insert_size) + 2*heatset_lead_in(board_insert_size));
echo(len(sbc_holes(BOARD, "structural-mount")));
echo(heatset_insert_length(board_insert_size) + heatset_lead_in(board_insert_size));
EOF
dims_out="$("$osc" --export-format stl -o "$tmp/dims_dummy.stl" "$dims_scad" 2>&1)"
if echo "$dims_out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: could not read standoff dims from params/sbc/heatset:"; echo "$dims_out"; exit 1
fi

mapfile -t echo_lines < <(echo "$dims_out" | grep '^ECHO:' | sed 's/^ECHO: //; s/^"//; s/"$//')
n_lines="${#echo_lines[@]}"
if [ "$n_lines" -lt 6 ]; then
  echo "FAIL: expected >=6 ECHO lines (>=1 post + 5 scalars), got $n_lines:"; echo "$dims_out"; exit 1
fi

n_posts=$((n_lines - 5))
ztop="${echo_lines[$n_posts]}"
pilot_dia="${echo_lines[$((n_posts + 1))]}"
mouth_dia="${echo_lines[$((n_posts + 2))]}"
struct_count="${echo_lines[$((n_posts + 3))]}"
pocket_depth="${echo_lines[$((n_posts + 4))]}"

if [ "$n_posts" -ne "$struct_count" ]; then
  echo "FAIL: harness parsed $n_posts post coordinate lines but sbc_holes() reports $struct_count structural-mount holes"
  fail=1
fi
echo "structural-mount post count: $struct_count"

# --- Render the full tray once.
out_tray="$("$osc" --export-format binstl -o "$tmp/tray.stl" "$proj/parts/tray.scad" 2>&1)"
if echo "$out_tray" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: tray.scad render errored:"; echo "$out_tray"; fail=1
fi
if [ ! -s "$tmp/tray.stl" ]; then
  echo "FAIL: empty tray STL"; fail=1
fi

# --- Render a plain hollow tube (OD10, bore d4, h10) to self-validate the
# point-in-solid method before trusting it against the real geometry.
cat > "$tube_scad" <<'EOF'
$fn = 48;
difference() {
    cylinder(h = 10, d = 10);
    translate([0, 0, -1]) cylinder(h = 12, d = 4);
}
EOF
out_tube="$("$osc" --export-format binstl -o "$tmp/tube.stl" "$tube_scad" 2>&1)"
if echo "$out_tube" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: validation-tube render errored:"; echo "$out_tube"; fail=1
fi
if [ ! -s "$tmp/tube.stl" ]; then
  echo "FAIL: empty validation-tube STL"; fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "FAIL: skipping measurement (prerequisite checks above failed)"
  exit 1
fi

# --- Measure the mouth diameter + point-in-solid void state at each
# structural-mount post.
py_out="$(python3 - "$tmp/tray.stl" "$tmp/tube.stl" "$ztop" "$pilot_dia" "$mouth_dia" "$pocket_depth" "${echo_lines[@]:0:$n_posts}" <<'PY'
import struct, sys, math

(path, tube_path, ztop, pilot_dia, mouth_dia, pocket_depth) = (
    sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4]),
    float(sys.argv[5]), float(sys.argv[6]))
posts = [tuple(float(v) for v in line.split()) for line in sys.argv[7:]]

def load_binstl(path):
    d = open(path, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]
    off = 84
    verts = []
    tris = []
    for i in range(n):
        tri = []
        for v in range(3):
            base = off + i*50 + 12 + v*12
            x, y, z = struct.unpack('<3f', d[base:base+12])
            tri.append((x, y, z))
        verts.extend(tri)
        tris.append(tri)
    return verts, tris

# --- Ray/triangle intersection (Moller-Trumbore), used for point-in-solid. ---
EPS = 1e-9

def ray_tri_intersect(orig, dirv, tri):
    v0, v1, v2 = tri
    e1 = tuple(v1[i] - v0[i] for i in range(3))
    e2 = tuple(v2[i] - v0[i] for i in range(3))
    def cross(a, b):
        return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
    def dot(a, b):
        return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
    pvec = cross(dirv, e2)
    det = dot(e1, pvec)
    if -EPS < det < EPS:
        return False  # parallel to the triangle plane
    inv_det = 1.0 / det
    tvec = tuple(orig[i] - v0[i] for i in range(3))
    u = dot(tvec, pvec) * inv_det
    if u < 0.0 or u > 1.0:
        return False
    qvec = cross(tvec, e1)
    v = dot(dirv, qvec) * inv_det
    if v < 0.0 or u + v > 1.0:
        return False
    t = dot(e2, qvec) * inv_det
    return t > EPS  # strictly ahead of the ray origin (excludes t<=0 grazes)

# Several non-axis-aligned ray directions (majority vote): reduces the chance
# any single ray degenerately grazes a facet edge/vertex of the $fn=48
# discretized cylinders in this geometry.
RAY_DIRS = [
    (0.6123, 0.3411, 1.0000),
    (-0.4187, 0.7331, 0.9102),
    (0.2077, -0.8931, 1.1300),
    (-0.7345, -0.2214, 1.0501),
    (0.9012, 0.1147, -1.0000),
]

def point_in_solid(tris, point):
    votes_in = 0
    for dirv in RAY_DIRS:
        count = sum(1 for tri in tris if ray_tri_intersect(point, dirv, tri))
        if count % 2 == 1:
            votes_in += 1
    return votes_in > len(RAY_DIRS) / 2

# --- Step A: self-validate point_in_solid against a known-simple case
# (plain hollow tube, OD10mm, through-bore d4mm, h10mm) before trusting it
# against the real geometry.
_, tube_tris = load_binstl(tube_path)
tube_cases = [
    ("axis mid-height (expect VOID, inside the bore)",      (0.0, 0.0, 5.0), False),
    ("wall mid-height (expect SOLID, inside the wall)",     (3.5, 0.0, 5.0), True),
    ("outside the OD (expect VOID)",                        (10.0, 0.0, 5.0), False),
    ("below the part (expect VOID)",                        (0.0, 0.0, -5.0), False),
    ("above the part (expect VOID)",                        (0.0, 0.0, 15.0), False),
]
tube_ok = True
for label, pt, expect in tube_cases:
    got = point_in_solid(tube_tris, pt)
    status = "ok" if got == expect else "FAIL"
    if got != expect:
        tube_ok = False
    print(f"{status}: [self-validation] {label}: point_in_solid={got}")

if not tube_ok:
    print("FAIL: point-in-solid method failed self-validation on the known hollow-tube "
          "case -- refusing to trust it against the real geometry")
    sys.exit(1)
print("ok: point-in-solid method self-validated against the known hollow-tube case")

# --- Step B: real checks against the tray's structural-mount posts.
_, tray_tris = load_binstl(path)
verts = [v for tri in tray_tris for v in tri]

r_cut = mouth_dia/2 + 0.5   # strictly between mouth radius and post-wall radius
z_band = 1.0
tol = 0.15
mid_pocket_z = ztop - pocket_depth/2  # comfortably inside the pocket cavity

ok = True
for (x0, y0) in posts:
    # (1) mouth vertex-radius check (position; kept from the original test).
    near = [(x, y, z) for (x, y, z) in verts
            if abs(z - ztop) < z_band and math.hypot(x - x0, y - y0) < r_cut]
    if not near:
        print(f"FAIL: no vertices found near post ({x0},{y0}) at ztop={ztop} within r<{r_cut}")
        ok = False
    else:
        measured_r = max(math.hypot(x - x0, y - y0) for (x, y, z) in near)
        measured_dia = 2 * measured_r
        if abs(measured_dia - mouth_dia) < tol:
            print(f"ok: post ({x0},{y0}) mouth dia {measured_dia:.3f} ~= chamfered {mouth_dia}")
        else:
            print(f"FAIL: post ({x0},{y0}) mouth dia measured {measured_dia:.3f}, "
                  f"expected chamfered {mouth_dia} (pilot-only would be {pilot_dia})")
            ok = False

    # (2) point-in-solid check: the pocket cavity must be VOID, not solid.
    # This is the check with real discriminating power against the
    # sibling-union (bare translate(){} instead of difference()) bug: that
    # bug leaves the mouth's vertex radius looking correct (the unioned
    # frustum's own edge still lands at the chamfered radius) while the
    # cavity itself is actually filled solid.
    cavity_pt = (x0, y0, mid_pocket_z)
    solid = point_in_solid(tray_tris, cavity_pt)
    if solid:
        print(f"FAIL: post ({x0},{y0}) pocket cavity at z={mid_pocket_z:.3f} is SOLID, "
              f"not void -- heat-set pocket is not actually cut (sibling-union bug?)")
        ok = False
    else:
        print(f"ok: post ({x0},{y0}) pocket cavity at z={mid_pocket_z:.3f} is void (not solid)")

sys.exit(0 if ok else 1)
PY
)"
py_status=$?
echo "$py_out"
[ "$py_status" -ne 0 ] && fail=1

[ "$fail" -eq 0 ] && echo "ok ($struct_count/$struct_count posts show the $mouth_dia mm chamfered mouth AND a void pocket cavity)"
exit "$fail"
