#!/usr/bin/env bash
# Verifies the keystone-blank project renders + asserts (OpenSCAD exit code
# unreliable; grep stderr). Geometry checks via STL bbox/facet count.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/keystone-blank"
run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }
tri() { python3 - "$1" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read(); print(struct.unpack('<I',d[80:84])[0])
PY
}
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Default entry renders clean.
out="$(run "$proj/keystone-blank.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "default keystone-blank errored"; echo "$out"; exit 1; } || true

# Body Z-extent must equal keystone_insert_depth() (single source of truth --
# the blank's full depth is never a copied literal, see keystone.scad).
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/kb.stl" \
  "$proj/keystone-blank.scad" 2>/dev/null
python3 - "$tmp/kb.stl" <<'PY' || { echo "keystone-blank Z-extent != keystone_insert_depth()=20"; exit 1; }
import struct,sys
d=open(sys.argv[1],'rb').read(); n=struct.unpack('<I',d[80:84])[0]; off=84
zs=[]
for i in range(n):
    for v in range(3):
        base=off+i*50+12+v*12
        zs.append(struct.unpack('<3f',d[base:base+12])[2])
sys.exit(0 if abs((max(zs)-min(zs))-20) < 0.01 else 1)
PY

# Drift checks + bench-tuned variants (Task 4 asserts.scad).
out="$(run "$proj/tests/asserts.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  && { echo "asserts.scad failed"; echo "$out"; exit 1; } || true

# guides=true must add more facets than guides=false (proxy for "ribs are
# actually being added", mirrors the faceplate lib's port on/off check).
# NOTE: OPENSCADPATH is only libraries/ (scripts/openscad.sh) — projects/ is
# NOT on it, so temp scad files call keystone_insert() from the keystone lib
# directly (no need to reach into this project's own entry file).
cat > "$tmp/g_on.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(fit=0.2, latch_wall=1.0, blank=true, guides=true);
EOF
cat > "$tmp/g_off.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(fit=0.2, latch_wall=1.0, blank=true, guides=false);
EOF
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/on.stl" "$tmp/g_on.scad" 2>/dev/null
"$root/scripts/openscad.sh" --export-format binstl -o "$tmp/off.stl" "$tmp/g_off.scad" 2>/dev/null
[ "$(tri "$tmp/on.stl")" -gt "$(tri "$tmp/off.stl")" ] \
  || { echo "guides=true has no more facets than guides=false -> ribs not added"; exit 1; }

# A latch_wall thick enough to violate the root-gusset print-safety margin
# MUST hard-fail at render (regression: the bench-tuning range documented in
# README has a real ceiling, see keystone.scad's root_margin_mm assert).
expect_assert() { # $1 = scad file, $2 = label
  local o; o="$(run "$1")"
  echo "$o" | grep -qiE 'ERROR:|Assertion .* failed' \
    || { echo "expected assert: $2"; echo "$o"; exit 1; }
}
cat > "$tmp/badlatch.scad" <<EOF
use <keystone/keystone.scad>;
keystone_insert(fit=0.2, latch_wall=1.5, blank=true);
EOF
expect_assert "$tmp/badlatch.scad" "latch_wall too thick for root-gusset margin"

echo ok
