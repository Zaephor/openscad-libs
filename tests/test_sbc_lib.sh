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
# DEVIATION FROM PLAN (see task-1-report.md "Concerns"): the plan's literal
# positive control targets bpir4 for this assertion. As of Task 1, EVERY board
# (including bpir4) is intentionally single-role — Pi/Zero corner holes are all
# "structural-mount", and bpir4's 16 holes are all "component-mount" per Step 5's
# explicit, binding conservative-classification instruction (never fabricate role
# diversity ahead of Task 2's DXF-evidence-based classification). Since the
# warning only fires when >1 role is present on a board (verbatim Step 3 logic,
# also required so the pi4b self-check does NOT warn), no real board can trigger
# it yet. Asserting it against bpir4 today would be true only by first breaking
# the conservative-classification constraint. Two controls stand in for it here:
#   1. bpir4 unfiltered access today must NOT warn (documents true current state;
#      TODO(Task 2): once bpir4 is classified into >1 real role, replace this
#      block with the plan's original "must warn for unfiltered bpir4" assertion
#      — it will then be a genuine end-to-end positive control).
#   2. A mechanism-level check that the echo-in-let warning pattern (same syntax
#      sbc_holes uses) actually emits the expected WARNING text when >1 role
#      categories are present, proving the mechanism itself works correctly.
cat > "$tmp/nowarn_bpir4_currently_single_role.scad" <<'EOF'
use <sbc/sbc.scad>;
x = sbc_holes_xy("bpir4");   // role omitted -> undef; bpir4 is single-role today
EOF
out="$(run "$tmp/nowarn_bpir4_currently_single_role.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "bpir4 is single-role provisionally; unfiltered access must not warn until Task 2 classifies it"; echo "$out"; exit 1; } || true

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
