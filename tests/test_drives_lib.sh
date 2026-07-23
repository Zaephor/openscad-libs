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

# Negative control: unknown/typo'd hole role must assert (not silently return []).
cat > "$tmp/bad_role.scad" <<'EOF'
use <drives/drives.scad>;
x = drive_bottom_holes("hdd35", "structural-moutn"); // typo, must assert
EOF
out="$(run "$tmp/bad_role.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown hole role (drive_bottom_holes):"; echo "$out"; exit 1
fi

cat > "$tmp/bad_role_side.scad" <<'EOF'
use <drives/drives.scad>;
x = drive_side_holes("hdd35", "bogus-role"); // unknown role, must assert
EOF
out="$(run "$tmp/bad_role_side.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown hole role (drive_side_holes):"; echo "$out"; exit 1
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

# Module role= end-to-end: an explicit matching role still cuts holes cleanly,
# and an explicit non-present role ("keep-out") is a legal no-op cut (0 holes,
# no error) rather than an assert -- exercises drive_holes()'s own role param,
# not just the underlying accessor functions.
cat > "$tmp/role_consumer.scad" <<'EOF'
use <drives/drives.scad>;
difference() {
    cube([150, 105, 30]);
    drive_holes("hdd35", "both", role = "structural-mount");
    drive_holes("hdd35", "bottom", role = "keep-out"); // present-but-empty filter: legal no-op
}
EOF
out="$(run "$tmp/role_consumer.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "role= consumer render failed:"; echo "$out"; exit 1
fi

# Negative control: unknown role on a CARD-family type (drive_card_hole has no
# role param of its own; drive_holes()'s card branch must validate inline).
cat > "$tmp/bad_role_card.scad" <<'EOF'
use <drives/drives.scad>;
difference() {
    cube([25, 85, 5]);
    drive_holes("m2_2280", role = "bogus-role");
}
EOF
out="$(run "$tmp/bad_role_card.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown role on a card-family type:"; echo "$out"; exit 1
fi

# Positive control: role="all" is a silent wildcard synonym for undef -- must
# render cleanly (no assert) for both block and card families.
cat > "$tmp/role_all.scad" <<'EOF'
use <drives/drives.scad>;
difference() {
    cube([150, 105, 30]);
    drive_holes("hdd35", "both", role = "all");
    translate([0, 0, -1]) drive_holes("m2_2280", role = "all");
}
EOF
out="$(run "$tmp/role_all.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "role=\"all\" consumer render failed:"; echo "$out"; exit 1
fi

# Bay form factors (#41 Part A): known-types membership + a side-hole render
# for the new block types.
cat > "$tmp/bay_known.scad" <<'EOF'
use <drives/drives.scad>;
types = drive_known_types();
assert(len([for (t=types) if (t=="bay525_hh"||t=="bay525_fh"||t=="bay35") t]) == 3,
       "bay types missing from drive_known_types()");
EOF
out="$(run "$tmp/bay_known.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "bay known-types control failed:"; echo "$out"; exit 1
fi

cat > "$tmp/bay_side_holes.scad" <<'EOF'
use <drives/drives.scad>;
difference() {
    cube([210, 150, 90]);
    drive_holes("bay525_hh", "side");
}
EOF
out="$(run "$tmp/bay_side_holes.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "bay525_hh side-hole render failed:"; echo "$out"; exit 1
fi

echo ok
