#!/usr/bin/env bash
# Verifies the drives library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/drives/tests/drives_test.scad"

run() { OPENSCADPATH="$root/libraries" "$root/scripts/openscad.sh" \
          --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "drives_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: unknown type must assert.
cat > "$tmp/bad_type.scad" <<'EOF'
use <drives/drives.scad>;
x = drive_family("bogus");
EOF
out="$(run "$tmp/bad_type.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type:"; echo "$out"; exit 1
fi

# Negative control: wrong-family accessor must assert.
cat > "$tmp/bad_family.scad" <<'EOF'
use <drives/drives.scad>;
x = drive_size("m2_2280");   // card has no block size
EOF
out="$(run "$tmp/bad_family.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong-family call:"; echo "$out"; exit 1
fi

# Negative control: unknown face must assert.
cat > "$tmp/bad_face.scad" <<'EOF'
use <drives/drives.scad>;
drive_faceplate_cutout("hdd35","nope");
EOF
out="$(run "$tmp/bad_face.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown face:"; echo "$out"; exit 1
fi

# Backward-compat control: a no-role consumer must render cleanly with NO
# WARNING (every drive type today has exactly one hole role present, so the
# multi-role WARNING idiom must never fire in practice).
cat > "$tmp/no_role_consumer.scad" <<'EOF'
use <drives/drives.scad>;
difference() {
    cube([150, 105, 30]);
    drive_holes("hdd35", "both");
    translate([0, 0, -1]) drive_holes("m2_2280");
}
EOF
out="$(run "$tmp/no_role_consumer.scad")"
if echo "$out" | grep -qi 'WARNING:'; then
  echo "no-role consumer unexpectedly warned:"; echo "$out"; exit 1
fi
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "no-role consumer render failed:"; echo "$out"; exit 1
fi

echo ok
