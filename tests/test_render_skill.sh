#!/usr/bin/env bash
# Drives the verify-scad-geometry skill's render_stl.py in both modes.
# Runs real openscad (binstl export) + matplotlib Agg — both headless.
# First run may pip-install numpy/numpy-stl/matplotlib (self-bootstrap).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
script="$root/.claude/skills/verify-scad-geometry/render_stl.py"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo 'cube([10,10,10]);' > "$tmp/a.scad"
echo 'translate([5,0,0]) cube([10,10,10]);' > "$tmp/b.scad"

# Mode 1: single render
python3 "$script" "$tmp/a.scad" --out "$tmp/a.png" >/dev/null || { echo "single render failed"; exit 1; }
[ -s "$tmp/a.png" ] || { echo "no single png produced"; exit 1; }

# Mode 2: colored overlap
python3 "$script" --overlay "$tmp/a.scad" "$tmp/b.scad" --out "$tmp/ov.png" >/dev/null || { echo "overlay failed"; exit 1; }
[ -s "$tmp/ov.png" ] || { echo "no overlay png produced"; exit 1; }

# Missing input must exit non-zero and write no PNG
if python3 "$script" "$tmp/missing.scad" --out "$tmp/x.png" >/dev/null 2>&1; then echo "missing input did not fail"; exit 1; fi
[ -e "$tmp/x.png" ] && { echo "PNG written despite failure"; exit 1; }

# --overlay with one file must exit non-zero
if python3 "$script" --overlay "$tmp/a.scad" >/dev/null 2>&1; then echo "overlay<2 did not fail"; exit 1; fi

echo ok
