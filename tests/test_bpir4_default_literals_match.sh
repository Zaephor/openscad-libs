#!/usr/bin/env bash
# Guards against re-introducing the defaults.scad include regression
# (ec94126, reverted): assembly.scad/parts/tray.scad/parts/lid.scad/
# tests/asserts.scad each hand-declare enable_exhaust/fan_size/fan_count/
# ear_hole_type as plain top-level literals BEFORE `include <params.scad>`,
# so OpenSCAD's Customizer GUI exposes them per entry file (Customizer only
# lists variables declared directly in the open file, not via include/use).
# This test doesn't render anything -- it just greps the 4 literal lines out
# of each file and asserts they're byte-identical everywhere, so the four
# copies can't silently drift out of sync without a human noticing.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"

files=(
  "$proj/assembly.scad"
  "$proj/parts/tray.scad"
  "$proj/parts/lid.scad"
  "$proj/tests/asserts.scad"
)

# Each var's assignment line, stripped of any trailing comment, so the
# literal (identifier + value) must match; explanatory comments may differ.
vars=(enable_exhaust fan_size fan_count ear_hole_type)

fail=0

extract() { # <file> <var> -> "var = value;" (no comment, no whitespace runs)
  local file="$1" var="$2"
  grep -E "^${var}[[:space:]]*=" "$file" \
    | sed -E 's#//.*$##' \
    | sed -E 's/[[:space:]]+/ /g; s/ *$//'
}

for var in "${vars[@]}"; do
  ref_file=""
  ref_val=""
  for f in "${files[@]}"; do
    [ -e "$f" ] || { echo "FAIL: missing file $f"; fail=1; continue 2; }
    val="$(extract "$f" "$var")"
    if [ -z "$val" ]; then
      echo "FAIL: $var not declared as a top-level literal in $f"
      fail=1
      continue
    fi
    if [ -z "$ref_file" ]; then
      ref_file="$f"; ref_val="$val"
    elif [ "$val" != "$ref_val" ]; then
      echo "FAIL: $var diverged -- $ref_file has '$ref_val', $f has '$val'"
      fail=1
    fi
  done
done

[ "$fail" -eq 0 ] && echo "ok (enable_exhaust/fan_size/fan_count/ear_hole_type literals match across ${#files[@]} files)"
exit "$fail"
