#!/usr/bin/env bash
# Verifies the fans library asserts via OpenSCAD stderr (exit code is unreliable
# on assert files, so we grep stderr for ERROR/Assertion).
# NOTE: --export-format echo silently swallows assert failures on OpenSCAD 2021.01;
# --export-format stl surfaces them on stderr as expected by this harness.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
testscad="$root/libraries/fans/tests/fans_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

# Positive: the real test file must NOT emit an assertion error.
out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fans_test.scad asserts failed:"; echo "$out"; exit 1
fi

# Negative: a deliberately-wrong assert MUST be caught (proves the harness has teeth).
cat > "$tmp/bad_test.scad" <<'EOF'
use <fans/fans.scad>;
assert(fan_hole_spacing(120) == 999, "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

# Negative control: an unknown hole role must assert (not silently return []).
cat > "$tmp/bad_role.scad" <<'EOF'
use <fans/fans.scad>;
x = fan_mount_holes(120, "bogus");
EOF
out="$(run "$tmp/bad_role.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fans: unknown hole role was not rejected:"; echo "$out"; exit 1
fi

# --- fan_honeycomb_vent() (#72): must render as a real hex lattice + pads,
# not a smooth bore, and the worst-case bridge span must self-report <=5mm.
fhv_scad="$root/libraries/fans/tests/fan_honeycomb_vent_test.scad"
out="$(run "$fhv_scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fan_honeycomb_vent_test.scad errored:"; echo "$out"; exit 1
fi
span_line="$(echo "$out" | grep -o 'HONEYCOMB_WORST_SPAN=[0-9.]*' | tail -1)"
if [ -z "$span_line" ]; then
  echo "fan_honeycomb_vent_test.scad: no HONEYCOMB_WORST_SPAN echo -- can't verify self-support"; exit 1
fi
span="$(echo "$span_line" | cut -d= -f2)"
if ! awk -v s="$span" 'BEGIN{exit !(s <= 5.000001)}'; then
  echo "fan_honeycomb_vent_test.scad: $span_line exceeds the 5mm self-support ceiling"; exit 1
fi
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/fhv.stl" "$fhv_scad" 2>&1)"
facets=$(grep -c "facet normal" "$tmp/fhv.stl" 2>/dev/null || echo 0)
if [ "$facets" -lt 500 ]; then
  echo "fan_honeycomb_vent_test.scad: only $facets facets -- too few for a hex lattice + pads (expected 500+)"
  exit 1
fi

# --- Negative control: pad_dia > fan_hole_spacing must abort (adjacent pads
# on the same fan would overlap). fan_hole_spacing(40)=32, so pad_dia=40 fails.
cat > "$tmp/bad_pad.scad" <<'EOF2'
use <fans/fans.scad>;
fan_honeycomb_vent(40, 40, 4.4, 8.0, 1.2, [[20,20]], 40, 40);
EOF2
out="$(run "$tmp/bad_pad.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "fan_honeycomb_vent: pad_dia=40 (> hole spacing 32) did NOT abort:"; echo "$out"; exit 1
fi
if ! echo "$out" | grep -qi 'adjacent mount pads on the same fan would overlap'; then
  echo "fan_honeycomb_vent: pad_dia=40 aborted on the WRONG assert:"; echo "$out"; exit 1
fi

echo ok
