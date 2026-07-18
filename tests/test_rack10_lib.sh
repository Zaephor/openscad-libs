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

# Elongation, isolated: slot1.scad above stamps holes at every rail h-center x
# every per-U z-offset, so its STL bbox X-span is dominated by rail-column
# separation (~241mm), not by any single slot's elongation -- the same test
# would "pass" even with hole_type="round" at the same dia. This block calls
# the real rack10_slot_profile() module directly (the same one rack10_holes()
# uses for its "slot" branch), standalone, with no rail/U stamping and no
# rotate, so its bbox isolates the obround shape and exercises the actual
# code path: X-span must be dia+slot_travel (13), Y-span must be dia (5).
cat > "$tmp/slot_iso.scad" <<'EOF'
use <rack10/rack10.scad>;
linear_extrude(6) rack10_slot_profile(5, 8);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/slot_iso.stl" "$tmp/slot_iso.scad" 2>/dev/null
python3 - "$tmp/slot_iso.stl" <<'PY' || { echo "isolated slot not horizontally elongated"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[];ys=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        x,y,z=struct.unpack('<3f',d[base:base+12]); xs.append(x); ys.append(y)
sys.exit(0 if (max(xs)-min(xs))>(max(ys)-min(ys)) else 1)
PY

# Negative control: slot with dia=0 asserts.
cat > "$tmp/slotbad.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="slot", dia=0);
EOF
out="$(run "$tmp/slotbad.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "slot dia=0 must assert"; echo "$out"; exit 1; }

# Panel height uses device_height (stacking gap), NOT raw u*pitch.
cat > "$tmp/panel_h.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_panel("labrax", 1, 3);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/panel_h.stl" "$tmp/panel_h.scad" 2>/dev/null
python3 - "$tmp/panel_h.stl" <<'PY' || { echo "rack10_panel height is not device_height(1)=43.66"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        zs.append(struct.unpack('<3f',d[base:base+12])[2])
span=max(zs)-min(zs)
sys.exit(0 if abs(span-43.66)<0.01 else 1)   # 44.45 - 0.79 = 43.66
PY

# #26: dia>0 overrides the named clearance for m6 (was silently ignored).
# Holes sit at ±hole_h_span/2, so STL X-span = 236.525 + hole_diameter.
span_x() { python3 - "$1" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
xs=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12
        xs.append(struct.unpack('<3f',d[b:b+12])[0])
print(round(max(xs)-min(xs),3))
PY
}
# m6 WITH dia=5 -> Ø5 -> X-span 241.525 (override honored)
cat > "$tmp/m6_override.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="m6", dia=5, depth=6);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/m6o.stl" "$tmp/m6_override.scad" 2>/dev/null
so="$(span_x "$tmp/m6o.stl")"
awk "BEGIN{exit !(($so>241.4)&&($so<241.7))}" \
  || { echo "m6 dia override failed: X-span $so (expected ~241.525 for Ø5)"; exit 1; }
# m6 WITHOUT dia -> named default Ø6.6 -> X-span 243.125 (unchanged)
cat > "$tmp/m6_named.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="m6", depth=6);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/m6n.stl" "$tmp/m6_named.scad" 2>/dev/null
sn="$(span_x "$tmp/m6n.stl")"
awk "BEGIN{exit !(($sn>243.0)&&($sn<243.3))}" \
  || { echo "m6 named default changed: X-span $sn (expected ~243.125 for Ø6.6)"; exit 1; }
# square IGNORES dia (regression guard): square WITH dia=5 must equal square
# WITHOUT dia (both cut rack10_square_size()). Proves square is untouched — the
# keystone-faceplate square-ear guard depends on this.
cat > "$tmp/sq_dia.scad"   <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="square", dia=5, depth=6);
EOF
cat > "$tmp/sq_named.scad" <<'EOF'
use <rack10/rack10.scad>;
rack10_holes("labrax", 1, hole_type="square", depth=6);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/sqd.stl" "$tmp/sq_dia.scad"   2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/sqn.stl" "$tmp/sq_named.scad" 2>/dev/null
sqd="$(span_x "$tmp/sqd.stl")"; sqn="$(span_x "$tmp/sqn.stl")"
awk "BEGIN{exit !(($sqd==$sqn))}" \
  || { echo "square honored dia (regression!): dia=5 X-span $sqd vs named $sqn — square must ignore dia"; exit 1; }

echo ok
