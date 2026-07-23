#!/usr/bin/env bash
# Verifies the rack-support library asserts via OpenSCAD stderr (exit code unreliable).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
testscad="$root/libraries/rack-support/tests/rack_support_test.scad"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

out="$(run "$testscad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack_support_test.scad asserts failed:"; echo "$out"; exit 1
fi

# No validation logic exists yet to drive a real negative control -- the
# accessors are plain constants with nothing to reject (Task 3/4 add
# rack_support_plate()/rack_support_tongue() and their own negative
# controls once there's real geometry/argument validation to break). For
# now, additionally require the accessor file renders with NO warnings at
# all (not just no errors), so a broken `use` path or an unknown-function
# typo in the test itself can't silently pass via WARNING-only output.
if echo "$out" | grep -qiE 'WARNING:'; then
  echo "rack_support_test.scad rendered with unexpected warnings:"; echo "$out"; exit 1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# --- rack_support_plate() presence checks (#40 Task 3) ---
# The channel/gusset design deliberately extends below the device-bottom
# Z=0 datum (see rack-support.scad module doc + RESEARCH.md): the bearing
# floor's TOP face sits at Z=0 (per DESIGN NOMINALS -- "slot floor + tongue
# underside at Z=0"), so its material occupies Z<0, and the 45deg gusset
# bracing it sits further below that. That means the plate's real Z-span is
# LARGER than a bare rack10_device_height(1)=43.66 top-only span (this is a
# deliberate, verify-scad-geometry-gated deviation from a naive "everything
# stays inside [0,h]" assumption -- confirmed floor@Z=0 / gusset<=45deg &
# clear of the slot / rear holes penetrate / support-free in the flat print
# orientation via that gate). So this checks BOTH boundaries independently
# rather than a single span number: the panel TOP is unaffected
# (still == device_height), and the gusset tip reaches down to
# -(floor_t=2 + engagement_depth=12) = -14.
cat > "$tmp/plate.scad" <<'EOF'
use <rack-support/rack-support.scad>;
rack_support_plate("labrax", 1);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/plate.stl" "$tmp/plate.scad" 2>/dev/null
python3 - "$tmp/plate.stl" <<'PY' || { echo "rack_support_plate Z-extent wrong (want max~43.66, min~-14)"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        b=off+i*50+12+v*12
        zs.append(struct.unpack('<3f',d[b:b+12])[2])
zmax=max(zs); zmin=min(zs)
ok = abs(zmax-43.66)<0.05 and abs(zmin-(-14.0))<0.1
sys.exit(0 if ok else 1)
PY

# Slot cavity is a real removed-material void, not just a modeled-but-solid
# feature: probe a small box centered in X (X in [-1,1]), within the
# engagement zone forward of the mounting face (Y in [-8,-4], inside
# [-ed,0]=[-12,0]) and within the channel's Z-band (Z in [3,7], inside
# [0,slot_h]=[0,10.4]) -- this must render EMPTY (OpenSCAD prints "Current
# top level object is empty." and writes no STL) if the cavity was actually
# cut. A plain panel (or a plate with the slot merely drawn but not
# subtracted) would NOT be empty here.
cat > "$tmp/probe_center.scad" <<'EOF'
use <rack-support/rack-support.scad>;
intersection() {
    rack_support_plate("labrax", 1);
    translate([-1, -8, 3]) cube([2, 4, 4]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_center.stl" "$tmp/probe_center.scad" 2>&1)"
if [ -f "$tmp/probe_center.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "slot cavity band is NOT empty at center -- cavity not actually removed:"; echo "$out"; exit 1
fi

# Positive control: the SAME Z-band, off to the side (X~30, well outside the
# slot_w=~40.8mm-wide channel but still inside the panel's own Y=[0,thickness]
# range where the panel is unconditionally solid) must be non-empty --
# proves the plate isn't just globally hollow at that Z, only narrower at
# the slot band (the actual claim under test).
cat > "$tmp/probe_side.scad" <<'EOF'
use <rack-support/rack-support.scad>;
intersection() {
    rack_support_plate("labrax", 1);
    translate([30, 1, 3]) cube([2, 2, 4]);
}
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_side.stl" "$tmp/probe_side.scad" 2>/dev/null
if [ ! -s "$tmp/probe_side.stl" ]; then
  echo "positive control (off-slot panel material) unexpectedly empty"; exit 1
fi

# Rear mounting holes penetrate: probe a small box straddling one hole
# center (X = hole_h_span/2 = 118.2625, first hole Z = 6.35) must be EMPTY
# (the round clearance hole actually punches through), matching the same
# "is empty" idiom above.
cat > "$tmp/probe_hole.scad" <<'EOF'
use <rack-support/rack-support.scad>;
intersection() {
    rack_support_plate("labrax", 1);
    translate([118.2625 - 1, -1, 6.35 - 1]) cube([2, 2, 2]);
}
EOF
out="$("$root/scripts/openscad.sh" --export-format binstl -o "$tmp/probe_hole.stl" "$tmp/probe_hole.scad" 2>&1)"
if [ -f "$tmp/probe_hole.stl" ] || ! echo "$out" | grep -qi 'is empty'; then
  echo "rear mounting hole does NOT penetrate (expected empty at a hole center):"; echo "$out"; exit 1
fi

echo ok
