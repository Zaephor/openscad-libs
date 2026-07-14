#!/usr/bin/env bash
# Verifies the rack10 library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack10/tests/rack10_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack10_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control 1: unknown standard must assert.
cat > "$tmp/bad_std.scad" <<'EOF'
use <rack10/rack10.scad>;
x = rack10_hole_h_span("bogus");
EOF
out="$(run "$tmp/bad_std.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown standard:"; echo "$out"; exit 1
fi

# Negative control 2: unknown hole_type must assert.
cat > "$tmp/bad_hole.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, "taped");
EOF
out="$(run "$tmp/bad_hole.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown hole_type:"; echo "$out"; exit 1
fi

# Slot renders non-empty, no errors.
cat > "$tmp/slot.scad" <<'EOF'
use <rack10/rack10.scad>;
difference() {
  rack10_panel("labrax", 1, 3);
  rack10_holes("labrax", 1, hole_type="slot", dia=rack10_screw_clearance("m6"));
}
EOF
out="$(run "$tmp/slot.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "slot panel errored"; echo "$out"; exit 1; } || true

# Elongation: a single stamped slot is wider in X than tall in Z.
cat > "$tmp/slot1.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="slot", dia=5, slot_travel=8, depth=6);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/slot1.stl" "$tmp/slot1.scad" 2>/dev/null
# STL bbox X-span must exceed Z-span (obround horizontal). (python one-liner over the binary STL.)
python3 - "$tmp/slot1.stl" <<'PY' || { echo "slot not horizontally elongated"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); zs.append(z)
sys.exit(0 if (max(xs)-min(xs))>(max(zs)-min(zs)) else 1)
PY

# Negative control: slot with dia=0 asserts.
cat > "$tmp/slotbad.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="slot", dia=0);
EOF
out="$(run "$tmp/slotbad.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "slot dia=0 must assert"; echo "$out"; exit 1; }

echo ok
