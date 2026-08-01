#!/usr/bin/env bash
# Verifies the honeycomb library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/honeycomb/tests/honeycomb_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

# Positive control: test basic honeycomb_vent rendering
out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "honeycomb_test.scad asserts failed:"; echo "$out"; exit 1
fi
if ! echo "$out" | grep -q 'HONEYCOMB_WORST_SPAN'; then
  echo "honeycomb_test.scad missing HONEYCOMB_WORST_SPAN echo:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: parameters that violate self-support constraint.
# cell=12, wall=1, height=40 lands a boundary hex's equator-region clip at a
# span of 6mm (>5mm max_safe_span), which genuinely trips the module's
# assert() rather than just producing an empty render. This test verifies
# the module rejects misconfigured callers.
cat > "$tmp/bad_params.scad" <<'EOF'
use <honeycomb/honeycomb.scad>;
honeycomb_vent(width=40, height=40, depth=2, cell=12, wall=1);
EOF
out="$(run "$tmp/bad_params.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "negative control should have detected unsafe parameters:"; echo "$out"; exit 1
fi

# Consistency: honeycomb_cell_centres() must report exactly as many centres as
# honeycomb_vent() computes internally (same args). Both callsites use the same
# _honeycomb_centres() function, so their counts are identical iff neither
# function has regressed. This probe calls both in the same render and compares
# their reported counts -- catches the accessor and the module's grid computation
# drifting apart.
#
# accessor_count extraction MUST anchor on `^ECHO: "CENTRES_COUNT=` (start of
# the echoed string), not a bare `grep 'CENTRES_COUNT='` -- the module's OWN
# echo is `HONEYCOMB_CENTRES_COUNT=...`, which contains "CENTRES_COUNT=" as a
# substring, so an unanchored grep matches BOTH lines and `head -1` silently
# picks whichever one happens to render first. That happened to be the
# accessor here (its echo statement precedes the honeycomb_vent() call
# below), so the bare pattern passed by coincidence of ORDER, not by
# correctly identifying the accessor's own line -- confirmed by the final
# reviewer, who proved it breaks (comparing the module against itself,
# unable to ever fail) by reordering the two calls. The anchored pattern
# below can't collide either way.
cat > "$tmp/consistency_probe.scad" <<'EOF'
use <honeycomb/honeycomb.scad>;
centres = honeycomb_cell_centres(width=40, height=15.9, cell=8, wall=1.2);
echo(str("CENTRES_COUNT=", len(centres)));
honeycomb_vent(width=40, height=15.9, depth=2, cell=8, wall=1.2);
EOF
out="$(run "$tmp/consistency_probe.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "consistency probe asserted:"; echo "$out"; exit 1
fi
accessor_count="$(echo "$out" | grep -E '^ECHO: "CENTRES_COUNT=' | head -1 | sed 's/.*CENTRES_COUNT=\([0-9]*\).*/\1/')"
module_count="$(echo "$out" | grep 'HONEYCOMB_CENTRES_COUNT=' | head -1 | sed 's/.*HONEYCOMB_CENTRES_COUNT=\([0-9]*\).*/\1/')"
worst_span="$(echo "$out" | grep 'HONEYCOMB_WORST_SPAN=' | head -1 | sed 's/.*HONEYCOMB_WORST_SPAN=\([0-9.]*\).*/\1/')"
if [ -z "$accessor_count" ] || [ "$accessor_count" -lt 1 ]; then
  echo "FAIL: honeycomb_cell_centres() reported $accessor_count centres (expected > 0)"; exit 1
fi
if [ -z "$module_count" ] || [ "$module_count" -lt 1 ]; then
  echo "FAIL: honeycomb_vent() reported $module_count centres (expected > 0)"; exit 1
fi
if [ "$accessor_count" != "$module_count" ]; then
  echo "FAIL: accessor reported $accessor_count centres but module computed $module_count -- consistency violation"; exit 1
fi
if [ -z "$worst_span" ]; then
  echo "FAIL: honeycomb_vent() did not echo HONEYCOMB_WORST_SPAN for the same params"; exit 1
fi
echo "ok: accessor and module both report $accessor_count centres, worst_span=$worst_span"

# Cross-test with different parameters to catch regressions across param space
cat > "$tmp/consistency_probe_2.scad" <<'EOF'
use <honeycomb/honeycomb.scad>;
centres = honeycomb_cell_centres(width=30, height=20, cell=6, wall=1.0);
echo(str("CENTRES_COUNT=", len(centres)));
honeycomb_vent(width=30, height=20, depth=2, cell=6, wall=1.0);
EOF
out="$(run "$tmp/consistency_probe_2.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "consistency probe 2 asserted:"; echo "$out"; exit 1
fi
accessor_count_2="$(echo "$out" | grep -E '^ECHO: "CENTRES_COUNT=' | head -1 | sed 's/.*CENTRES_COUNT=\([0-9]*\).*/\1/')"
module_count_2="$(echo "$out" | grep 'HONEYCOMB_CENTRES_COUNT=' | head -1 | sed 's/.*HONEYCOMB_CENTRES_COUNT=\([0-9]*\).*/\1/')"
if [ "$accessor_count_2" != "$module_count_2" ]; then
  echo "FAIL: accessor reported $accessor_count_2 centres but module computed $module_count_2 (probe 2) -- consistency violation"; exit 1
fi
echo "ok: probe 2 (width=30, height=20, cell=6, wall=1.0) accessor and module both report $accessor_count_2 centres"

echo ok
