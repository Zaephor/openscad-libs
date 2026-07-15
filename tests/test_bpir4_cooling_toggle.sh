#!/usr/bin/env bash
# Verifies the bpir4-1u-chassis cooling toggle actually drives geometry.
# Bug: params.scad used to re-assign enable_exhaust/fan_size/fan_count with a
# self-referential is_undef(x)?default:x, so params' textually-later
# assignment always won (OpenSCAD last-assignment-wins) and the assembly's
# customizer value was silently discarded -> "overwritten in params.scad"
# warning + inert toggle. Checks: (a) no overwrite warning in either mode,
# (b) passive (enable_exhaust=false) render is shallower than active
# (rear_off() = fan_plenum(12) when on vs rear_gap(4) when off).
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0

render() { # <stl-out> <enable_exhaust>
  local stl="$1" ex="$2"
  "$root/scripts/openscad.sh" -D "enable_exhaust=$ex" --export-format stl \
    -o "$stl" "$proj/assembly.scad" 2>&1
}

ymax() { # <stl> -> max Y vertex coordinate
  awk '/vertex/ { if ($3+0 > m) m = $3+0 } END { print m+0 }' "$1"
}

# OpenSCAD's actual wording is "... but was overwritten in file params.scad,
# line N" — match loosely so a wording tweak (e.g. dropping "file") still hits.
overwrite_re='overwritten in (file )?params\.scad'

out_passive="$(render "$tmp/passive.stl" false)"
if echo "$out_passive" | grep -Eq "$overwrite_re"; then
  echo "FAIL: overwrite warning present (passive):"; echo "$out_passive"; fail=1
fi

out_active="$(render "$tmp/active.stl" true)"
if echo "$out_active" | grep -Eq "$overwrite_re"; then
  echo "FAIL: overwrite warning present (active):"; echo "$out_active"; fail=1
fi

py="$(ymax "$tmp/passive.stl")"
ay="$(ymax "$tmp/active.stl")"
if ! awk -v p="$py" -v a="$ay" 'BEGIN{exit !(p<a)}'; then
  echo "FAIL: passive Y-extent ($py) must be shorter than active Y-extent ($ay)"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "ok (passive ymax=$py < active ymax=$ay, no overwrite warnings)"
exit "$fail"
