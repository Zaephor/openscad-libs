#!/usr/bin/env bash
# Verifies the bpir4-1u-chassis project renders (both fan modes) with no asserts.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"

run() { "$root/scripts/openscad.sh" --export-format stl -o "$1" "$2" 2>&1; }

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

check_render "assembly"      "$proj/assembly.scad"
check_render "tray"          "$proj/parts/tray.scad"
check_render "lid"           "$proj/parts/lid.scad"

# Geometry invariants (asserts.scad aborts the render on violation).
out="$(run "$tmp/out.stl" "$proj/tests/asserts.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL[asserts]: geometry invariant failed:"; echo "$out"; fail=1
fi

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
