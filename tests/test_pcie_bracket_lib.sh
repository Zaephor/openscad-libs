#!/usr/bin/env bash
# Verifies the pcie-bracket library asserts via OpenSCAD stderr (exit code
# unreliable) plus STL-bbox/volume geometry checks (Task 3).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/pcie-bracket/tests/pcie-bracket_test.scad"

run() { OPENSCADPATH="$root/libraries" "$root/scripts/openscad.sh" \
          --export-format stl -o /dev/null "$1" 2>&1; }
runbin() { OPENSCADPATH="$root/libraries" "$root/scripts/openscad.sh" \
          --export-format binstl -o "$2" "$1" 2>/dev/null; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "pcie-bracket_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control: unknown type must assert.
cat > "$tmp/bad_type.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_size("bogus");
EOF
out="$(run "$tmp/bad_type.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type:"; echo "$out"; exit 1
fi

# Negative control: unknown type must assert on the holes accessor too.
cat > "$tmp/bad_type_holes.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_holes("bogus");
EOF
out="$(run "$tmp/bad_type_holes.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown type (pcie_bracket_holes):"; echo "$out"; exit 1
fi

# Negative control: unknown/typo'd hole role must assert (not silently return []).
cat > "$tmp/bad_role.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_holes("full-height", "structural-moutn"); // typo, must assert
EOF
out="$(run "$tmp/bad_role.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown hole role:"; echo "$out"; exit 1
fi

# Positive control: a known-but-absent role ("keep-out") is a legal no-op
# filter (0 holes, no error), not an assert -- exercises the vocab/data split.
cat > "$tmp/keep_out.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
x = pcie_bracket_holes("low-profile", "keep-out");
assert(x == [], "keep-out should be a legal empty filter");
EOF
out="$(run "$tmp/keep_out.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "keep-out no-op filter unexpectedly failed:"; echo "$out"; exit 1
fi

# Positive control: role="all" is a silent wildcard synonym for undef -- must
# render cleanly (no assert) and return the same single hole.
cat > "$tmp/role_all.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
assert(pcie_bracket_holes("full-height", "all") == pcie_bracket_holes("full-height"), "all == undef");
EOF
out="$(run "$tmp/role_all.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "role=\"all\" consumer failed:"; echo "$out"; exit 1
fi

### Geometry checks (Task 3) -- module: pcie_bracket() / pcie_bracket_mount_holes().

zheight() { # $1 = binstl path -> prints (max z - min z)
  python3 - "$1" <<'PY'
import struct, sys
d = open(sys.argv[1], 'rb').read()
n = struct.unpack('<I', d[80:84])[0]
off = 84
zs = []
for i in range(n):
    for v in range(3):
        base = off + i * 50 + 12 + v * 12
        zs.append(struct.unpack('<3f', d[base:base + 12])[2])
print(max(zs) - min(zs))
PY
}

volume() { # $1 = binstl path -> prints mesh signed volume (abs)
  python3 - "$1" <<'PY'
import struct, sys
d = open(sys.argv[1], 'rb').read()
n = struct.unpack('<I', d[80:84])[0]
off = 84
vol = 0.0
for i in range(n):
    base = off + i * 50 + 12
    v0 = struct.unpack('<3f', d[base:base + 12])
    v1 = struct.unpack('<3f', d[base + 12:base + 24])
    v2 = struct.unpack('<3f', d[base + 24:base + 36])
    vol += (v0[0] * (v1[1] * v2[2] - v1[2] * v2[1])
          - v0[1] * (v1[0] * v2[2] - v1[2] * v2[0])
          + v0[2] * (v1[0] * v2[1] - v1[1] * v2[0])) / 6.0
print(abs(vol))
PY
}

cat > "$tmp/fh.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
pcie_bracket("full-height");
EOF
cat > "$tmp/fh_blank.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
pcie_bracket("full-height", blank=true);
EOF
cat > "$tmp/lp.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
pcie_bracket("low-profile");
EOF

runbin "$tmp/fh.scad" "$tmp/fh.stl"
runbin "$tmp/fh_blank.scad" "$tmp/fh_blank.stl"
runbin "$tmp/lp.scad" "$tmp/lp.stl"
for f in fh fh_blank lp; do
  [ -s "$tmp/$f.stl" ] || { echo "pcie_bracket() failed to export STL ($f) -- module missing/erroring"; exit 1; }
done

# Coarse bounding-height check: rendered Z bbox must be within a couple mm of
# pcie_bracket_size(type)[0] (the height field) -- a *little* over is expected
# (the foot hangs th below the Z=0 fold datum, per the geometry-frame note in
# the header), so allow up to thickness+1mm of slack rather than an exact match.
cat > "$tmp/fh_size.scad" <<'EOF'
use <pcie-bracket/pcie-bracket.scad>;
echo(pcie_bracket_size("full-height")[0]);
EOF
want_fh="$(run "$tmp/fh_size.scad" | grep -oE 'ECHO: [0-9.]+' | grep -oE '[0-9.]+')"
got_fh="$(zheight "$tmp/fh.stl")"
python3 -c "
import sys
want, got = float('$want_fh'), float('$got_fh')
diff = got - want
sys.exit(0 if 0 <= diff <= 2.0 else 1)
" || { echo "full-height bbox height $got_fh not within tolerance of pcie_bracket_size height $want_fh"; exit 1; }

# blank=true has no card window -> strictly greater solid volume than the
# windowed (blank=false) variant of the same type.
vol_fh="$(volume "$tmp/fh.stl")"
vol_fh_blank="$(volume "$tmp/fh_blank.stl")"
python3 -c "
import sys
sys.exit(0 if float('$vol_fh_blank') > float('$vol_fh') else 1)
" || { echo "blank=true volume ($vol_fh_blank) not greater than windowed volume ($vol_fh) -- card cutout not detected"; exit 1; }

echo ok
