#!/usr/bin/env bash
# Verifies #70 Task 3's two bpir4-side chamfers:
#   (a) _faceplate()'s panel blank adopts the rack10 library's chamfered
#       silhouette (rack10_panel_profile()) instead of a plain cube: the
#       extreme |x|=127 vertices (panel_w()/2) must span z in
#       [3.0, ext_h()-3.0] = [3.0, 41.0], not the full 0..44.00 a square
#       corner would give. bpir4's own ext_h() is 44.00 -- NOT
#       rack10_device_height(1) (43.66) -- so this is a DIFFERENT bound than
#       Task 1's rack10 test (which used 40.66).
#   (b) _tray_shell()'s two rear outer vertical corners are chamfered at
#       _tray_rear_corner_chamfer() (1.2mm): no vertex sits at the exact
#       (+/-body_w()/2, rear_wall_y(true), z) corner line for any z, and the
#       chamfer face (the side-wall face still full width short of the rear,
#       the rear-wall face still full depth short of the side) is present.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"
fail=0

tmp="$(mktemp -d)"
consumers=()
cleanup() {
  rm -rf "$tmp"
  for c in "${consumers[@]:-}"; do [ -n "$c" ] && rm -f "$c"; done
}
trap cleanup EXIT

# --- (a) faceplate blank corners: reuse the isolated _faceplate() render. ---
out_fp="$("$osc" --export-format binstl -o "$tmp/faceplate.stl" "$proj/tests/render_faceplate.scad" 2>&1)"
if echo "$out_fp" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: faceplate render errored:"; echo "$out_fp"; fail=1
fi
if [ ! -s "$tmp/faceplate.stl" ]; then
  echo "FAIL: empty faceplate STL"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  python3 - "$tmp/faceplate.stl" <<'PY' || { echo "FAIL: faceplate blank corners not chamfered per rack10_panel_profile"; fail=1; }
import struct, sys
d = open(sys.argv[1], 'rb').read()
n = struct.unpack('<I', d[80:84])[0]
off = 84
vs = set()
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        vs.add(tuple(round(c, 4) for c in struct.unpack('<3f', d[b:b+12])))
xs = [v[0] for v in vs]
zs = [v[2] for v in vs]
ext = [v for v in vs if abs(abs(v[0]) - 127.0) < 1e-3]
ok = (abs(min(xs) + 127.0) < 0.01 and abs(max(xs) - 127.0) < 0.01     # X span intact (+/-panel_w()/2)
      and abs(min(zs)) < 0.01 and abs(max(zs) - 44.00) < 0.01         # Z span intact (0..ext_h())
      and ext                                                         # edge exists
      and abs(min(q[2] for q in ext) - 3.0) < 0.01                    # corner clipped low
      and abs(max(q[2] for q in ext) - 41.0) < 0.01)                  # corner clipped high (ext_h()-3.0)
sys.exit(0 if ok else 1)
PY
fi

# --- (b) rear outer vertical corner chamfer on the tray shell. ---
# Consumer written under $proj (not $tmp) so its `use <parts/tray.scad>`
# resolves relative to the consumer file's own directory, matching the
# render_faceplate.scad / render_lid_posts.scad / test_bpir4_tray_params.sh
# idiom (`use` doesn't share cwd, and doesn't import variables -- see
# reference_openscad_gotchas -- hence the toggle re-declare + include below).
consumer="$proj/_t3_rear_shell.scad"
consumers+=("$consumer")
cat > "$consumer" <<'EOF'
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <params.scad>;
use <rack10/rack10.scad>;
use <sbc/sbc.scad>;
use <parts/tray.scad>;
echo(str("BODY_W=", body_w()));
echo(str("REAR_Y=", rear_wall_y(true)));
_tray_shell();
EOF
out_rear="$("$osc" --export-format binstl -o "$tmp/rear_shell.stl" "$consumer" 2>&1)"
if echo "$out_rear" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: _tray_shell() render errored:"; echo "$out_rear"; fail=1
fi
if [ ! -s "$tmp/rear_shell.stl" ]; then
  echo "FAIL: empty _tray_shell() STL"; fail=1
fi

body_w="$(echo "$out_rear" | grep -o 'BODY_W=[0-9.eE+-]*' | tail -1 | cut -d= -f2)"
rear_y="$(echo "$out_rear" | grep -o 'REAR_Y=[0-9.eE+-]*' | tail -1 | cut -d= -f2)"
if [ -z "$body_w" ] || [ -z "$rear_y" ]; then
  echo "FAIL: could not read BODY_W/REAR_Y from render echo output"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  python3 - "$tmp/rear_shell.stl" "$body_w" "$rear_y" <<'PY' || { echo "FAIL: rear outer corners not chamfered"; fail=1; }
import struct, sys
d = open(sys.argv[1], 'rb').read()
n = struct.unpack('<I', d[80:84])[0]
off = 84
vs = set()
for i in range(n):
    for v in range(3):
        b = off + i*50 + 12 + v*12
        vs.add(tuple(round(c, 4) for c in struct.unpack('<3f', d[b:b+12])))
body_w2 = float(sys.argv[2]) / 2.0
rear_y = float(sys.argv[3])
tol = 0.01

def near(a, b, t=tol):
    return abs(a - b) < t

ok = True
for sx in (-1, 1):
    x_target = sx * body_w2
    # (1) the exact corner vertex must be gone at every z.
    at_corner = [v for v in vs if near(v[0], x_target) and near(v[1], rear_y)]
    if at_corner:
        ok = False
    # (2) chamfer face proxy: the side-wall face still reaches full |x| a
    # short distance shy of the rear wall, and the rear-wall face still
    # reaches full depth a short distance shy of this side -- i.e. the two
    # walls' own faces are unaffected away from the corner, and only the
    # corner itself is cut, which is what a chamfer (vs. e.g. shrinking the
    # whole wall) looks like.
    side_face = [v for v in vs if near(v[0], x_target) and v[1] < rear_y - 0.5]
    rear_face = [v for v in vs if near(v[1], rear_y) and abs(v[0]) < body_w2 - 0.5]
    if not side_face or not rear_face:
        ok = False
sys.exit(0 if ok else 1)
PY
fi

[ "$fail" -eq 0 ] && echo "ok (faceplate silhouette + rear corner chamfers verified)"
exit "$fail"
