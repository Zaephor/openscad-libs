#!/usr/bin/env bash
# Verifies the rack19 library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack19/tests/rack19_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack19_test.scad asserts failed:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Negative control 1: a wrong assert must be caught.
cat > "$tmp/bad_test.scad" <<'EOF'
use <rack19/rack19.scad>;
assert(rack19_u() == 1, "intentionally wrong");
EOF
out="$(run "$tmp/bad_test.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch a wrong assert:"; echo "$out"; exit 1
fi

# Negative control 2: an unknown thread must assert.
cat > "$tmp/bad_thread.scad" <<'EOF'
use <rack19/rack19.scad>;
x = rack19_screw_clearance("bogus");
EOF
out="$(run "$tmp/bad_thread.scad")"
if ! echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "harness failed to catch an unknown thread:"; echo "$out"; exit 1
fi

# Slot renders non-empty, no errors.
cat > "$tmp/slot.scad" <<'EOF'
use <rack19/rack19.scad>;
difference() {
  rack19_panel(1, 3);
  rack19_holes(1, hole_type="slot", dia=rack19_screw_clearance("M6"));
}
EOF
out="$(run "$tmp/slot.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "slot panel errored"; echo "$out"; exit 1; } || true

# Elongation: a single stamped slot is wider in X than tall in Z.
cat > "$tmp/slot1.scad" <<'EOF'
use <rack19/rack19.scad>;
rack19_holes(1, hole_type="slot", dia=5, slot_travel=8, depth=6);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/slot1.stl" "$tmp/slot1.scad" 2>/dev/null
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
# separation, not by any single slot's elongation -- the same test would
# "pass" even with hole_type="round" at the same dia. This block calls the
# real rack19_slot_profile() module directly (the same one rack19_holes()
# uses for its "slot" branch), standalone, with no rail/U stamping and no
# rotate, so its bbox isolates the obround shape and exercises the actual
# code path: X-span must be dia+slot_travel (13), Y-span must be dia (5).
cat > "$tmp/slot_iso.scad" <<'EOF'
use <rack19/rack19.scad>;
linear_extrude(6) rack19_slot_profile(5, 8);
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

# Negative control 3: slot with dia=0 asserts.
cat > "$tmp/slotbad.scad" <<'EOF'
use <rack19/rack19.scad>;
rack19_holes(1, hole_type="slot", dia=0);
EOF
out="$(run "$tmp/slotbad.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "slot dia=0 must assert"; echo "$out"; exit 1; }

# Panel height uses device_height (stacking gap), NOT raw u*pitch.
cat > "$tmp/panel_h19.scad" <<'EOF'
use <rack19/rack19.scad>;
rack19_panel(1, 3);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/panel_h19.stl" "$tmp/panel_h19.scad" 2>/dev/null
python3 - "$tmp/panel_h19.stl" <<'PY' || { echo "rack19_panel height is not device_height(1)=43.66"; exit 1; }
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


# #7 rackpost context (parity). rack19_u()=44.45; default hole_type square.
zbox19() { python3 - "$1" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12; zs.append(struct.unpack('<3f',d[b:b+12])[2])
print(round(min(zs),3), round(max(zs)-min(zs),3))
PY
}
cat > "$tmp/r19ctx.scad" <<'EOF'
use <rack19/rack19.scad>;
rack19_rackpost_context(device_u=1, pad_u=1, depth_ftf=300);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/r19.stl" "$tmp/r19ctx.scad" 2>/dev/null
read z19 s19 < <(zbox19 "$tmp/r19.stl")
awk "BEGIN{exit !(($z19<-44.4)&&($z19>-44.5)&&($s19>133.2)&&($s19<133.5))}" \
  || { echo "rack19 rackpost_context(1,1) Z wrong: min=$z19 span=$s19"; exit 1; }
# Equivalence to inline pattern. Compared as a canonical (sorted) triangle SET
# rather than raw `cmp -s` bytes: this OpenSCAD/CGAL build does not guarantee a
# stable per-triangle export order between separate invocations of the SAME
# .scad file (verified for rack10's parity test), so byte equality is not a
# viable equivalence check here even though the geometry itself is deterministic.
cat > "$tmp/r19inl.scad" <<'EOF'
use <rack19/rack19.scad>;
translate([0,0,-rack19_u()]) rack19_placeholder(3, 300);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/r19i.stl" "$tmp/r19inl.scad" 2>/dev/null
python3 - "$tmp/r19.stl" "$tmp/r19i.stl" <<'PY' || { echo "rack19 rackpost_context != inline"; exit 1; }
import struct,sys
def tris(path):
    d = open(path, 'rb').read()
    n = struct.unpack('<I', d[80:84])[0]
    off = 84
    out = []
    for i in range(n):
        rec = d[off + i*50 : off + i*50 + 48]  # normal(3f) + 3 verts(3f each)
        out.append(tuple(round(v, 4) for v in struct.unpack('<12f', rec)))
    return sorted(out)
a, b = tris(sys.argv[1]), tris(sys.argv[2])
sys.exit(0 if a == b else 1)
PY

echo ok
