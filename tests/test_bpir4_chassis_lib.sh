#!/usr/bin/env bash
# Verifies the bpir4-1u-chassis project renders (both fan modes) with no asserts.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"

run() { # <stl-out> <scad> <extra-D...>
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format stl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"; rm -f "$proj"/tests/_t78_pad_fill_*.scad' EXIT
fail=0

check_render() { # <label> <scad> <extra-D...>
  local label="$1"; shift
  local scad="$1"; shift
  local stl="$tmp/out.stl"
  local out; out="$(run "$stl" "$scad" "$@")"
  if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
    echo "FAIL[$label]: render errored:"; echo "$out"; fail=1; return
  fi
  if [ ! -s "$stl" ]; then
    echo "FAIL[$label]: empty STL"; fail=1; return
  fi
}

for ex in true false; do
  check_render "assembly[fan=$ex]" "$proj/assembly.scad"  -D "enable_exhaust=$ex"
  check_render "tray[fan=$ex]"     "$proj/parts/tray.scad" -D "enable_exhaust=$ex"
done
check_render "lid" "$proj/parts/lid.scad"
check_render "assembly[show_rack=true]" "$proj/assembly.scad" -D "show_rack=true"

# Item 1: rendering the tray must NOT emit the sbc multi-role warning
# (standoffs now pass an explicit role).
out="$(run "$tmp/out.stl" "$proj/parts/tray.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "tray still triggers the unfiltered-role warning"; echo "$out"; exit 1; } || true

# Item 3: ear_hole_type modes render clean (slot default + round option)
for eh in "\"slot\"" "\"10-32\"" "\"round\""; do
  out="$(run "$tmp/out.stl" "$proj/parts/tray.scad" -D "ear_hole_type=$eh")"
  echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
    && { echo "ear_hole_type=$eh render errored"; echo "$out"; exit 1; } || true
done

# Geometry invariants (asserts.scad aborts the render on violation), both fan modes.
for ex in true false; do
  out="$(run "$tmp/out.stl" "$proj/tests/asserts.scad" -D "enable_exhaust=$ex")"
  if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "FAIL[asserts fan=$ex]: geometry invariant failed:"; echo "$out"; fail=1
  fi
done

# Item 2 (#78 Part A): fan-pad honeycomb-cell fill must be genuinely SOLID at
# each filled cell -- not merely "renders without error". A manifold/assert
# smoke check on the whole tray CANNOT catch a mask-direction bug (unioning
# the pad-fill hexes into the void pattern instead of subtracting them from
# it, so union(A, subset_of_A) == A leaves the cells void): that broken
# variant still renders cleanly, no assert, no non-manifold warning.
#
# Discriminator (measured off the exported mesh, never off the source): for
# each pad, take its nearest fill cell that lies OUTSIDE the plain
# fan_pad_dia bearing-pad radius (a cell INSIDE that radius is already made
# solid regardless of the hex-fill mechanism, via the always-present round
# pad-disc cut elsewhere in _rear_openings(), so it wouldn't discriminate
# this bug). Intersect the real tray with a small probe cylinder centred on
# that cell and measure its solid volume fraction via the divergence theorem
# (same technique tests/test_bpir4_fan_opening.sh's pad-annulus check uses).
# Measured while diagnosing this exact bug: a broken (still-void) fill
# leaves only a small CGAL degenerate-duplicate-union sliver there (~7% of
# the probe volume); a working fill fills essentially the whole probe
# (~99%). MIN_FILL_FRACTION is set well below the working figure and well
# above the broken one so mesh-tessellation noise cannot cause either a
# false pass or a false failure.
MIN_FILL_FRACTION=0.5
PROBE_R=1.5
dims_scad="$proj/tests/_t78_pad_fill_dims.scad"
cat > "$dims_scad" <<'EOF'
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
include <../params.scad>;
use <fans/fans.scad>;
use <honeycomb/honeycomb.scad>;

cs   = _fan_x_centres(fan_size, fan_count);
band = _fan_band_x(fan_size, fan_count);
zc   = floor_th + int_h()/2;
r_cell = honeycomb_cell/2;
r_pad  = fan_pad_dia/2;
centres = honeycomb_cell_centres(band[1]-band[0], fan_size, honeycomb_cell, honeycomb_wall);

echo(str("KEY yw ", rear_wall_y(true)));
echo(str("KEY wall ", wall));

// Same fill-selection filter _rear_openings() actually uses, for every pad
// (both fans, all 4 structural-mount holes each) -- single source of truth,
// not a re-derived/hardcoded coordinate.
for (cx = cs)
    for (p = fan_mount_holes(fan_size, "structural-mount")) {
        pad_local = [cx + p[0] - band[0], p[1] + fan_size/2];
        fill = [for (c = centres) if (norm(c - pad_local) <= r_pad + r_cell) c];
        fill_outside = [for (c = fill) if (norm(c - pad_local) > r_pad) c];
        if (len(fill_outside) > 0) {
            fc = fill_outside[0];
            echo(str("PROBE ", band[0] + fc[0], " ", (zc - fan_size/2) + fc[1]));
        }
    }
EOF
dims_out="$(run "$tmp/dims.stl" "$dims_scad")"
if echo "$dims_out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: could not read pad-fill probe geometry:"; echo "$dims_out"; exit 1
fi
YW="$(echo "$dims_out" | sed -n 's/^ECHO: "KEY yw //p' | tr -d '"' | head -1)"
WALLV="$(echo "$dims_out" | sed -n 's/^ECHO: "KEY wall //p' | tr -d '"' | head -1)"
mapfile -t PROBES < <(echo "$dims_out" | sed -n 's/^ECHO: "PROBE //p' | tr -d '"')
if [ "${#PROBES[@]}" -eq 0 ]; then
  echo "FAIL: no pad-fill probe location found outside the plain pad radius for any pad (unexpected geometry change -- cannot test the fill mechanism)"
  exit 1
fi

i=0
probe_stls=()
for pr in "${PROBES[@]}"; do
  read -r px pz <<<"$pr"
  ps="$proj/tests/_t78_pad_fill_probe_${i}.scad"
  cat > "$ps" <<EOF
use <../parts/tray.scad>
intersection() {
    tray(enable_exhaust = true, fan_count = 2, fan_size = 40);
    translate([$px, $YW - $WALLV, $pz])
        rotate([-90, 0, 0])          // local +Z -> chassis +Y, matching the
            cylinder(h = $WALLV, r = $PROBE_R); // fill loop's own local frame
}
EOF
  pstl="$tmp/pfprobe_${i}.stl"
  pout="$("$root/scripts/openscad.sh" --export-format binstl -o "$pstl" "$ps" 2>&1)"
  if echo "$pout" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "FAIL: pad-fill probe $i render errored:"; echo "$pout"; fail=1
  elif echo "$pout" | grep -qi 'top level object is empty' || [ ! -s "$pstl" ]; then
    # A fully-empty intersection (no STL written, or a zero-byte one) IS a
    # valid, informative result here -- it means the probe found ZERO solid
    # material at this fill-cell location, i.e. 0% solid, an unambiguous
    # FAIL -- not a script error. Report it as such instead of letting the
    # python volume step crash on a missing file.
    echo "FAIL: pad-fill probe $i found NO solid material at all (fill cell fully void)"
    fail=1
  else
    probe_stls+=("$pstl")
  fi
  i=$((i + 1))
done

if [ "$fail" -eq 0 ]; then
  py_out="$(python3 - "$WALLV" "$PROBE_R" "$MIN_FILL_FRACTION" "${probe_stls[@]}" <<'PY'
import struct, sys, math

wall, probe_r, min_frac = float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
stl_paths = sys.argv[4:]

def load_binstl(path):
    d = open(path, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]
    tris = []
    for i in range(n):
        base = 84 + i*50 + 12
        tris.append(tuple(struct.unpack('<3f', d[base + v*12: base + v*12 + 12])
                          for v in range(3)))
    return tris

def volume(tris):
    total = 0.0
    for (a, b, c) in tris:
        total += (a[0]*(b[1]*c[2] - b[2]*c[1])
                  - a[1]*(b[0]*c[2] - b[2]*c[0])
                  + a[2]*(b[0]*c[1] - b[1]*c[0])) / 6.0
    return abs(total)

full = math.pi * probe_r**2 * wall
ok = True
for i, p in enumerate(stl_paths):
    v = volume(load_binstl(p))
    frac = v / full
    if frac < min_frac:
        print(f"FAIL: pad-fill probe {i} is only {frac*100:.1f}% solid "
              f"({v:.3f} of {full:.3f} mm^3) -- the fill cell is still "
              f"(mostly) VOID; the pad-fill mask direction is likely wrong "
              f"(union instead of difference)")
        ok = False
    else:
        print(f"ok: pad-fill probe {i} is {frac*100:.1f}% solid "
              f"({v:.3f} of {full:.3f} mm^3)")
sys.exit(0 if ok else 1)
PY
)"
  py_status=$?
  echo "$py_out"
  [ "$py_status" -ne 0 ] && fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
