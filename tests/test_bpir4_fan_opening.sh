#!/usr/bin/env bash
# #66: verifies the ACTIVE (enable_exhaust=true) rear-wall fan opening is a
# self-supporting honeycomb field with solid bearing pads around the mount
# screws -- not the round fan_bore() cylinder it used to be.
#
# The defect this guards against: fan_bore() is a plain cylinder, and the rear
# wall is vertical, so rotating the bore onto the wall's normal put a
# fan_size*0.92 (36.8mm) hole on a HORIZONTAL axis -- its crown is a
# 90-degree-from-vertical overhang, which cannot print without supports. A
# 45-degree teardrop of that bore does not fit either: it needs r*sqrt(2) =
# 26.02mm above the bore centre and the lid ledge is only 20mm above it.
#
# Discriminators (all measured off the exported mesh -- never off the source,
# so a comment or a dead code path cannot produce a false pass):
#
#   1. NO ROUND BORE. Isolate the rear wall's fan band by intersecting the
#      tray with a box spanning exactly the band's X range, the wall's Y
#      slab, and the fan_size Z band around the bore centre. A 36.8mm
#      circular hole leaves that band as a frame around two smooth cylinders;
#      a honeycomb leaves a lattice of flat hex facets, which needs many more
#      triangles to describe. Measured on the isolated band (not the whole
#      tray, whose count is dominated by unrelated geometry): 4668 facets for
#      the honeycomb against 2616 for the two bores it replaced. The floor
#      below sits between them, not near either.
#
#   2. EVERY SCREW HOLE IS RINGED BY SOLID MATERIAL. For each mount hole,
#      intersect the tray with an annular probe (ID = the hole diameter,
#      OD = fan_pad_dia, axis along +Y through the wall slab) and compare the
#      result against the full annulus volume. A hole sitting in bare 1.2mm
#      hex lattice returns a small fraction of it; a hole through a solid
#      bearing pad returns essentially all of it. This is what proves the M3
#      head has material to seat on rather than a lattice edge.
#
#   3. OPEN-AREA REGRESSION GUARD. From check 1's isolated band, take the
#      material volume V by the divergence theorem and derive the open area
#      as (band_area * wall - V) / wall. Asserted as a BAND around the
#      measured baseline rather than a pinned figure, so mesh-tessellation
#      noise cannot cause a false failure while a honeycomb_cell /
#      honeycomb_wall change that strangles airflow still trips it.
#
# Every dimension below is read live from params.scad / the fans library --
# the fan centres, the band, the pad diameter and the hole positions are all
# echoed out of OpenSCAD, never retyped here. That is deliberate: the fan X
# centres are DERIVED from the sbc board rows, so a future re-caliper of the
# board must move this test's probes with the geometry.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"
fail=0

# --- Recorded baselines: measured on the as-built geometry, then asserted as
# a floor / a band. Re-measured 2026-08-01 (final #78 review) after two real
# changes to what this probe covers: (a) #78 Part B split the active-mode
# field into one honeycomb band PER FAN with the inter-fan strip left solid
# (this test's isolated-band box spans BOTH fans' bands, so it now also
# spans that solid strip), and (b) the fix-#1 correction to
# _rear_honeycomb_bands() (iterate all of `cs`, not just `[min(cs),
# max(cs)]`) -- behaviorally a no-op for this test's fan_count=2 fixture
# (union of the two extremes over 2 elements IS all of `cs`), so this
# re-measurement is driven by (a), not (b). The two figures below (facets,
# open area) are BOTH markedly lower than the stale pre-#78-Part-B baseline
# recorded here previously (4668 facets / 2450.3 mm^2) -- expected, since a
# solid inter-fan strip now sits in what used to be open lattice. Round-bore
# comparator figures (2616 facets / 2239.8 mm^2, the geometry the honeycomb
# replaced) predate the honeycomb feature entirely and are unaffected by
# either change; still valid as the "other side" of the discriminator.
#
# Isolated-band facet count: 3800 as built (two per-fan hex bands + the
# solid inter-fan strip), against 2616 for the two round bores. Floor set
# at their midpoint (~3208, rounded to 3200) for roughly symmetric headroom
# on both sides (600 facets / ~19% below the real figure, 584 / ~18% above
# the bore figure) -- comfortably discriminates a lattice from a smooth bore
# without sitting close to either.
MIN_BAND_FACETS=3200
# Open area over the fan band: 1565.8 mm^2 as built, against 2239.8 mm^2 for
# the two bores over this same band -- the honeycomb now moves LESS air than
# the bores it replaced (opposite of the pre-#78-Part-B relationship): #78
# Part B trades open area for closing the inter-fan recirculation gap,
# leaving that strip of wall solid rather than open lattice. See
# projects/bpir4-1u-chassis/README.md for the same tradeoff stated in prose.
# This figure INCLUDES the 8 mount screw holes (8 * pi/4 * 4.3^2 = 116.2
# mm^2), which are genuinely open.
EXPECTED_OPEN_AREA=1565.8
OPEN_AREA_TOL_PCT=5
# Fraction of the full annulus volume a pad must deliver. Not 1.0: the mesh
# is a faceted approximation of both cylinders, so the intersection is a
# chord-polygon slightly inside the true annulus.
MIN_PAD_FRACTION=0.95

tmp="$(mktemp -d)"
dims_scad="$proj/tests/_t66_fan_dims.scad"
band_scad="$proj/_t66_band.scad"
probe_scads=()
cleanup() {
  rm -rf "$tmp"
  rm -f "$dims_scad" "$band_scad"
  for f in "${probe_scads[@]:-}"; do [ -n "$f" ] && rm -f "$f"; done
}
trap cleanup EXIT

# --- Read the geometry live. Lives under $proj/tests/ so `include
# <../params.scad>` resolves the way the project's own files do. ---
cat > "$dims_scad" <<'EOF'
enable_exhaust = true;
fan_size  = 40;
fan_count = 2;
ear_hole_type = "slot";
// fan_thickness (#79) must mirror the literal the entry files carry: this
// probe's reference rear_wall_y() (KEY yw, below) comes from its OWN
// `include <../params.scad>`, but the geometry it measures comes from
// `use <../parts/tray.scad>` (via band_scad/probe_scads), which carries its
// own file-scope fan_thickness=20. Without it here, this probe's reference
// frame falls back to the library default (rear_wall_y 116.7) while the real
// tray sits 10mm further back (126.7), and the isolated-band/annular probe
// boxes below all land in empty space.
fan_thickness = 20;
include <../params.scad>;
use <fans/fans.scad>;
echo(str("KEY band ", _fan_band_x()[0], " ", _fan_band_x()[1]));
echo(str("KEY zc ", floor_th + int_h()/2));
echo(str("KEY fan_size ", fan_size));
echo(str("KEY wall ", wall));
echo(str("KEY yw ", rear_wall_y(true)));
echo(str("KEY pad ", fan_pad_dia));
echo(str("KEY holedia ", fan_mount_holes(fan_size, "structural-mount")[0][3]));
echo(str("KEY centres ", _fan_x_centres()));
for (cx = _fan_x_centres())
    for (p = fan_mount_holes(fan_size, "structural-mount"))
        echo(str("HOLE ", cx + p[0], " ", floor_th + int_h()/2 + p[1]));
EOF
dims_out="$("$osc" --export-format stl -o "$tmp/dims.stl" "$dims_scad" 2>&1)"
if echo "$dims_out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: could not read the fan-opening geometry from params.scad:"; echo "$dims_out"; exit 1
fi

key() { echo "$dims_out" | sed -n "s/^ECHO: \"KEY $1 //p" | tr -d '"' | head -1; }
read -r BAND0 BAND1 <<<"$(key band)"
ZC="$(key zc)"; FS="$(key fan_size)"; WALL="$(key wall)"; YW="$(key yw)"
PAD="$(key pad)"; HOLEDIA="$(key holedia)"; CENTRES="$(key centres)"
mapfile -t HOLES < <(echo "$dims_out" | sed -n 's/^ECHO: "HOLE //p' | tr -d '"')

for v in "$BAND0" "$BAND1" "$ZC" "$FS" "$WALL" "$YW" "$PAD" "$HOLEDIA"; do
  case "$v" in
    ''|*[!0-9.eE+-]*)
      echo "FAIL: a required geometry value did not resolve to a number (got '$v')."
      echo "      params.scad must expose _fan_band_x()/_fan_x_centres()/fan_pad_dia."
      echo "$dims_out"; exit 1;;
  esac
done
if [ "${#HOLES[@]}" -eq 0 ]; then
  echo "FAIL: no mount-hole positions resolved from fan_mount_holes()"; exit 1
fi
echo "band=[$BAND0, $BAND1] centres=$CENTRES zc=$ZC wall=$WALL pad=$PAD holedia=$HOLEDIA holes=${#HOLES[@]}"

# --- Render the isolated band: the tray intersected with a box spanning the
# fan band's X range, the rear wall's Y slab and the fan_size Z band. #78
# Part B split the active-mode field into one honeycomb band per fan
# (_rear_honeycomb_band_frame()), each anchored exactly at its own fan's
# footprint edges (cx +/- fan_size/2) -- which coincide EXACTLY with this
# probe's outer X clip and with the fan_size Z band used below, so an exact
# (zero-margin) box lands a hex vertex precisely tangent to the clip plane at
# more than one place, which CGAL's exact-arithmetic booleans render as a
# degenerate (non-manifold) coincident face -- confirmed on the real tray
# render ("Simple: yes"), so this is a probe artifact, not a geometry defect.
# BAND_EPS nudges the probe box outward by a hair past every tangent plane
# (same "nudge past exact tangency" technique this project's own
# _lid_post_corner() fillets use -- see tray.scad's `ov` constant) so the
# clip never lands exactly on a hex vertex. The extra sliver of counted
# volume is a thin (BAND_EPS-tall/wide) rim around the probed box, negligible
# next to the ~2000mm^2 measured open area and the 5% tolerance below. ---
BAND_EPS=0.05
cat > "$band_scad" <<EOF
use <parts/tray.scad>
intersection() {
    tray(enable_exhaust = true, fan_count = 2, fan_size = $FS);
    translate([$BAND0 - $BAND_EPS, $YW - $WALL, $ZC - $FS/2 - $BAND_EPS])
        cube([$BAND1 - ($BAND0) + 2*$BAND_EPS, $WALL, $FS + 2*$BAND_EPS]);
}
EOF
band_out="$("$osc" --export-format binstl -o "$tmp/band.stl" "$band_scad" 2>&1)"
if echo "$band_out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: isolated-band render errored:"; echo "$band_out"; fail=1
fi
if [ ! -s "$tmp/band.stl" ]; then
  echo "FAIL: isolated-band render produced an empty STL"; fail=1
fi

# --- Render one annular probe per mount hole. ---
i=0
for h in "${HOLES[@]}"; do
  read -r hx hz <<<"$h"
  ps="$proj/_t66_probe_${i}.scad"
  probe_scads+=("$ps")
  cat > "$ps" <<EOF
use <parts/tray.scad>
intersection() {
    tray(enable_exhaust = true, fan_count = 2, fan_size = $FS);
    translate([$hx, $YW - $WALL, $hz])
        rotate([-90, 0, 0])                       // local +Z -> chassis +Y
            difference() {
                cylinder(h = $WALL, d = $PAD);
                translate([0, 0, -1]) cylinder(h = $WALL + 2, d = $HOLEDIA);
            }
}
EOF
  pout="$("$osc" --export-format binstl -o "$tmp/probe_${i}.stl" "$ps" 2>&1)"
  if echo "$pout" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "FAIL: annular probe $i render errored:"; echo "$pout"; fail=1
  fi
  i=$((i + 1))
done

if [ "$fail" -ne 0 ]; then
  echo "FAIL: skipping measurement (a prerequisite render above failed)"
  exit 1
fi

py_out="$(python3 - "$tmp" "${#HOLES[@]}" "$BAND0" "$BAND1" "$FS" "$WALL" "$PAD" "$HOLEDIA" \
                  "$MIN_BAND_FACETS" "$EXPECTED_OPEN_AREA" "$OPEN_AREA_TOL_PCT" "$MIN_PAD_FRACTION" <<'PY'
import math, os, struct, sys

tmp, n_holes = sys.argv[1], int(sys.argv[2])
band0, band1, fs, wall, pad, holedia = (float(v) for v in sys.argv[3:9])
min_facets = int(sys.argv[9])
expected_area, tol_pct, min_frac = (float(v) for v in sys.argv[10:13])

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
    # Divergence theorem: the enclosed volume is the sum of the signed
    # tetrahedron volumes formed by the origin and each outward-oriented facet.
    total = 0.0
    for (a, b, c) in tris:
        total += (a[0]*(b[1]*c[2] - b[2]*c[1])
                  - a[1]*(b[0]*c[2] - b[2]*c[0])
                  + a[2]*(b[0]*c[1] - b[1]*c[0])) / 6.0
    return abs(total)

ok = True

# --- 1. No round bore: the isolated band must be a lattice, not a frame. ---
band_tris = load_binstl(os.path.join(tmp, 'band.stl'))
n_facets = len(band_tris)
if n_facets < min_facets:
    print(f"FAIL: isolated fan band has only {n_facets} facets (floor {min_facets}) -- "
          f"that is a smooth round bore, not a honeycomb lattice")
    ok = False
else:
    print(f"ok: isolated fan band has {n_facets} facets (floor {min_facets}) -- a hex lattice")

# --- 2. Every screw hole is ringed by solid material. ---
full_annulus = math.pi/4 * (pad**2 - holedia**2) * wall
for i in range(n_holes):
    v = volume(load_binstl(os.path.join(tmp, f'probe_{i}.stl')))
    frac = v / full_annulus
    if frac < min_frac:
        print(f"FAIL: mount hole {i} is ringed by only {frac*100:.1f}% of a full "
              f"{pad}mm pad ({v:.2f} of {full_annulus:.2f} mm^3) -- the M3 head "
              f"would bear on hex lattice, not on solid material")
        ok = False
    else:
        print(f"ok: mount hole {i} pad annulus {frac*100:.1f}% solid "
              f"({v:.2f} of {full_annulus:.2f} mm^3)")

# --- 3. Open-area regression guard. ---
v_band = volume(band_tris)
open_area = ((band1 - band0) * fs * wall - v_band) / wall
lo = expected_area * (1 - tol_pct/100)
hi = expected_area * (1 + tol_pct/100)
if not (lo <= open_area <= hi):
    print(f"FAIL: open area over the fan band is {open_area:.1f} mm^2, outside "
          f"[{lo:.1f}, {hi:.1f}] (expected ~{expected_area:.0f}) -- the vent has "
          f"been strangled or opened up; re-measure before moving the baseline")
    ok = False
else:
    print(f"ok: open area over the fan band {open_area:.1f} mm^2 "
          f"(expected ~{expected_area:.0f} +/-{tol_pct:.0f}%)")

sys.exit(0 if ok else 1)
PY
)"
py_status=$?
echo "$py_out"
[ "$py_status" -ne 0 ] && fail=1

[ "$fail" -eq 0 ] && echo "ok (fan band is a honeycomb lattice, all ${#HOLES[@]} mount holes ringed by solid pads, open area within tolerance)"
exit "$fail"
