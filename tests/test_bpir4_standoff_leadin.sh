#!/usr/bin/env bash
# #75: verifies each board standoff post (parts/tray.scad's board-standoff
# block in tray()) presents a heat-set LEAD-IN CHAMFER at its mouth, the same
# way the lid posts already do via heatset_pocket() (_lid_post_corner()).
# Before this fix, sbc_standoffs() cut a plain constant-diameter pilot bore,
# so the mouth measured heatset_pilot_dia(board_insert_size) (4.01mm) all the
# way to the post's top face.
#
# Renders the FULL tray.scad (not an isolated harness) so the check exercises
# the real assembly, including the fact that the pocket loop
# (`for (h = sbc_holes(BOARD, "structural-mount")) ...`) must land on the
# SAME structural-mount posts sbc_standoffs() itself renders.
#
# Discriminator: slices the exported mesh at a standoff's world (x,y,z) top-
# face position (read live from params.scad/sbc.scad — never hand-literaled),
# keeping only vertices radially close to that post's axis (a radius cutoff
# strictly between the mouth radius and the post OD radius, so post-wall
# vertices never leak in) within a thin Z-band around the top face. The
# widest radius among those is the mouth's measured radius; doubled, that is
# the measured mouth diameter — compared against heatset_pilot_dia() (plain,
# unchamfered — the pre-fix/RED value) and
# heatset_pilot_dia()+2*heatset_lead_in() (chamfered — the expected/GREEN
# value), both read from the heatset lib rather than hardcoded, so the test
# tracks a future insert-table change.
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
cleanup() { rm -rf "$tmp"; rm -f "$dims_scad"; }
trap cleanup EXIT

# --- Read every structural-mount standoff's world (x,y) center + top-face Z,
# plus the expected mouth/pilot diameters, all live from the libs/params
# (never hand-literaled). One echo'd line per hole "x y", then the shared
# scalars.
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
EOF
dims_out="$("$osc" --export-format stl -o "$tmp/dims_dummy.stl" "$dims_scad" 2>&1)"
if echo "$dims_out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: could not read standoff dims from params/sbc/heatset:"; echo "$dims_out"; exit 1
fi

mapfile -t echo_lines < <(echo "$dims_out" | grep '^ECHO:' | sed 's/^ECHO: //; s/^"//; s/"$//')
n_lines="${#echo_lines[@]}"
if [ "$n_lines" -lt 5 ]; then
  echo "FAIL: expected >=5 ECHO lines (>=1 post + 4 scalars), got $n_lines:"; echo "$dims_out"; exit 1
fi

n_posts=$((n_lines - 4))
ztop="${echo_lines[$n_posts]}"
pilot_dia="${echo_lines[$((n_posts + 1))]}"
mouth_dia="${echo_lines[$((n_posts + 2))]}"
struct_count="${echo_lines[$((n_posts + 3))]}"

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

if [ "$fail" -ne 0 ]; then
  echo "FAIL: skipping mouth-diameter measurement (prerequisite checks above failed)"
  exit 1
fi

# --- Measure the mouth diameter at each structural-mount post.
py_out="$(python3 - "$tmp/tray.stl" "$ztop" "$pilot_dia" "$mouth_dia" "${echo_lines[@]:0:$n_posts}" <<'PY'
import struct, sys, math

path, ztop, pilot_dia, mouth_dia = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
posts = [tuple(float(v) for v in line.split()) for line in sys.argv[5:]]

d = open(path, 'rb').read()
n = struct.unpack('<I', d[80:84])[0]
off = 84
verts = []
for i in range(n):
    for v in range(3):
        base = off + i*50 + 12 + v*12
        x, y, z = struct.unpack('<3f', d[base:base+12])
        verts.append((x, y, z))

# Radius cutoff strictly between the chamfered mouth radius and the post OD
# radius (mouth_dia/2 + 2*heatset_min_wall, always well over 1mm further out),
# so post-wall vertices can never leak into the measurement.
r_cut = mouth_dia/2 + 0.5
z_band = 1.0

tol = 0.15
ok = True
for (x0, y0) in posts:
    near = [(x, y, z) for (x, y, z) in verts
            if abs(z - ztop) < z_band and math.hypot(x - x0, y - y0) < r_cut]
    if not near:
        print(f"FAIL: no vertices found near post ({x0},{y0}) at ztop={ztop} within r<{r_cut}")
        ok = False
        continue
    measured_r = max(math.hypot(x - x0, y - y0) for (x, y, z) in near)
    measured_dia = 2 * measured_r
    if abs(measured_dia - mouth_dia) < tol:
        print(f"ok: post ({x0},{y0}) mouth dia {measured_dia:.3f} ~= chamfered {mouth_dia}")
    else:
        print(f"FAIL: post ({x0},{y0}) mouth dia measured {measured_dia:.3f}, "
              f"expected chamfered {mouth_dia} (pilot-only would be {pilot_dia})")
        ok = False

sys.exit(0 if ok else 1)
PY
)"
py_status=$?
echo "$py_out"
[ "$py_status" -ne 0 ] && fail=1

[ "$fail" -eq 0 ] && echo "ok ($struct_count/$struct_count posts show the $mouth_dia mm chamfered mouth)"
exit "$fail"
