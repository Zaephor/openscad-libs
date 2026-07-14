#!/usr/bin/env bash
# Verifies the sbc library asserts via OpenSCAD stderr (exit code unreliable;
# --export-format echo swallows assert failures on OpenSCAD 2021.01).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/sbc/tests/sbc_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "sbc_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/bad_test.scad" <<'EOF'
use <sbc/sbc.scad>;
assert(sbc_size("pi4b") == [1, 1], "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

cat > "$tmp/bad_board.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_size("bogus");
EOF
out="$(run "$tmp/bad_board.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown board:"; echo "$out"; exit 1
fi

# Multi-role board, UNFILTERED access -> must emit the role-categories warning.
#
# Task 2 classified bpir4's 16 holes into 2 real role categories
# ("component-mount" x12, "structural-mount" x4 — see libraries/sbc/
# RESEARCH.md "bpi-r4 hole roles", incl. its "Follow-up re-review" section:
# a first pass found 0 structural-mount / 2 keep-out, then a follow-up
# review (requested after the first pass) upgraded 4 edge-inset holes —
# including the original 2 keep-out ones — to structural-mount, landing on
# 0 keep-out / 12 component-mount / 4 structural-mount. The warning only
# cares about the *count* of distinct roles present (2), not which ones, so
# this test is unaffected by that reclassification. This replaces the
# Task-1-era placeholder block (see git history) that stood in for this
# exact assertion while bpir4 was still provisionally single-role — this is
# now the genuine end-to-end positive control the plan originally called
# for.
cat > "$tmp/warn_bpir4.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4");   // role omitted -> undef; bpir4 now spans 2 roles
EOF
out="$(run "$tmp/warn_bpir4.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  || { echo "expected multi-role warning for unfiltered bpir4 access (bpir4 is classified into >1 role as of Task 2)"; echo "$out"; exit 1; }

cat > "$tmp/warn_mechanism.scad" <<'EOF'
present = ["structural-mount", "component-mount"];
x = let (_warn = len(present) > 1
        ? echo(str("WARNING: sbc 'synthetic' holes span ", len(present),
                   " role categories ", present,
                   "; no role filter selected — returning all. ",
                   "Pass a role (e.g. \"structural-mount\") or \"all\" to silence."))
        : undef) present;
EOF
out="$(run "$tmp/warn_mechanism.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  || { echo "warning mechanism (echo-in-let) failed to emit expected text"; echo "$out"; exit 1; }

# Explicit "all" -> must NOT warn.
cat > "$tmp/nowarn.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4", "all");
EOF
out="$(run "$tmp/nowarn.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "explicit all-role access must not warn"; echo "$out"; exit 1; } || true

# Unknown role -> must assert.
cat > "$tmp/badrole.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4", "bogus");
EOF
out="$(run "$tmp/badrole.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "unknown role must assert"; echo "$out"; exit 1; }

echo ok
