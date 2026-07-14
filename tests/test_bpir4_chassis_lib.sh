#!/usr/bin/env bash
# Verifies the bpir4-1u-chassis project renders (both fan modes) with no asserts.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"

run() { # <stl-out> <scad> <extra-D...>
  local stl="$1"; shift
  local scad="$1"; shift
  "$root/scripts/openscad.sh" --export-format stl -o "$stl" "$scad" "$@" 2>&1
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

check_render() { # <label> <scad> <extra-D...>
  local label="$1"; shift
  local scad="$1"; shift
  local stl="$tmp/out.stl"
  local out; out="$(run "$stl" "$scad" "$@")"
  if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
    echo "FAIL[$label]: render errored:"; echo "$out"; fail=1; return
  fi
  if [ ! -s "$stl" ]; then
    echo "FAIL[$label]: empty STL"; fail=1; return
  fi
}

for ex in true false; do
  check_render "assembly[fan=$ex]" "$proj/assembly.scad"  -D "enable_exhaust=$ex"
  check_render "tray[fan=$ex]"     "$proj/parts/tray.scad" -D "enable_exhaust=$ex"
done
check_render "lid" "$proj/parts/lid.scad"
check_render "assembly[show_rack=true]" "$proj/assembly.scad" -D "show_rack=true"

# Item 1: rendering the tray must NOT emit the sbc multi-role warning
# (standoffs now pass an explicit role).
out="$(run "$tmp/out.stl" "$proj/parts/tray.scad")"
echo "$out" | grep -qiE 'WARNING:.*role categories' \
  && { echo "tray still triggers the unfiltered-role warning"; echo "$out"; exit 1; } || true

# Item 3: ear_hole_type modes render clean (slot default + round option)
for eh in "\"slot\"" "\"10-32\"" "\"round\""; do
  out="$(run "$tmp/out.stl" "$proj/parts/tray.scad" -D "ear_hole_type=$eh")"
  echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
    && { echo "ear_hole_type=$eh render errored"; echo "$out"; exit 1; } || true
done

# Geometry invariants (asserts.scad aborts the render on violation), both fan modes.
for ex in true false; do
  out="$(run "$tmp/out.stl" "$proj/tests/asserts.scad" -D "enable_exhaust=$ex")"
  if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
    echo "FAIL[asserts fan=$ex]: geometry invariant failed:"; echo "$out"; fail=1
  fi
done

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
