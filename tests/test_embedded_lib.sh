#!/usr/bin/env bash
# Verifies the embedded library asserts via OpenSCAD stderr (exit code
# unreliable; --export-format echo swallows assert failures on OpenSCAD
# 2021.01 — use --export-format stl instead). Mirrors tests/test_sbc_lib.sh.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/embedded/tests/embedded_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "embedded_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Intentionally-wrong assert -> must be CAUGHT (harness sanity check).
cat > "$tmp/bad_test.scad" <<'EOF'
use <embedded/embedded.scad>;
assert(embedded_size("esp32_devkitc") == [1, 1], "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

# Unknown board -> must assert.
cat > "$tmp/bad_board.scad" <<'EOF'
use <embedded/embedded.scad>;
x = embedded_size("bogus");
EOF
out="$(run "$tmp/bad_board.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown board:"; echo "$out"; exit 1
fi

# Unknown role -> must assert.
cat > "$tmp/badrole.scad" <<'EOF'
use <embedded/embedded.scad>;
x = embedded_holes_xy("wemos_d1_mini", "bogus");
EOF
out="$(run "$tmp/badrole.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "unknown role must assert"; echo "$out"; exit 1; }

# Explicit "all" -> must NOT warn (wemos_d1_mini is single-role, so the
# unfiltered-access warning wouldn't fire here anyway; "all" must stay silent
# regardless of role count).
cat > "$tmp/nowarn.scad" <<'EOF'
use <embedded/embedded.scad>;
x = embedded_holes_xy("wemos_d1_mini", "all");
EOF
out="$(run "$tmp/nowarn.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "explicit all-role access must not warn"; echo "$out"; exit 1; } || true

# NOTE on the multi-role WARNING positive control: unlike sbc (whose bpir4
# board genuinely spans 2 hole-role categories), NO embedded board is
# classified into more than one hole-role category — 4 of 5 boards have zero
# mounting holes at all, and wemos_d1_mini's 2 holes are both
# structural-mount (see RESEARCH.md; the brief explicitly says not to invent
# a fake multi-role board just to exercise this path). So there is no
# real-board end-to-end positive control for the WARNING here. Unfiltered
# access on the one board that HAS holes must stay silent (single role ->
# no warning) — verified below — and the WARNING mechanism itself (the
# echo-in-let construct copied verbatim from sbc.scad) is verified
# synthetically, same as sbc's own warn_mechanism.scad sub-test.

# Unfiltered access to wemos_d1_mini (single role present) -> must NOT warn.
cat > "$tmp/nowarn_unfiltered.scad" <<'EOF'
use <embedded/embedded.scad>;
x = embedded_holes_xy("wemos_d1_mini");   // role omitted; only 1 role present -> silent
EOF
out="$(run "$tmp/nowarn_unfiltered.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "single-role unfiltered access must not warn"; echo "$out"; exit 1; } || true

# Synthetic exercise of the warning mechanism itself (echo-in-let), same
# construct as embedded_holes()'s _warn let-binding, copied verbatim from
# sbc.scad's own warn_mechanism.scad sub-test.
cat > "$tmp/warn_mechanism.scad" <<'EOF'
present = ["structural-mount", "component-mount"];
x = let (_warn = len(present) > 1
        ? echo(str("WARNING: embedded 'synthetic' holes span ", len(present),
                   " role categories ", present,
                   "; no role filter selected — returning all. ",
                   "Pass a role (e.g. \"structural-mount\") or \"all\" to silence."))
        : undef) present;
EOF
out="$(run "$tmp/warn_mechanism.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  || { echo "warning mechanism (echo-in-let) failed to emit expected text"; echo "$out"; exit 1; }

echo ok
