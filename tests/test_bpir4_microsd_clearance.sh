#!/usr/bin/env bash
# Verifies the inserted microSD card (#76) clears both the rear exhaust fan
# (active/exhaust mode) and the rear wall (passive mode).
#
# Bug: an inserted microSD stands 2.3mm proud of the board's rear edge
# (libraries/sbc/sbc.scad's microsd_1_card row), which neither fan_plenum nor
# rear_gap accounted for: active mode overlapped the fan by 0.8mm, and
# passive mode -- with no fan at all -- overlapped the rear wall by 0.7mm, so
# the card could not be inserted. Fixed by deriving both rear datums from
# params.scad's _rear_media_protrusion(), read live from the sbc row.
#
# Both checks read card_y_end from sbc_connectors(BOARD)'s microsd_1_card row
# directly -- never a retyped 2.3/15.0/11.0 -- so this guard tracks the data,
# not a copy of it.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
osc="$root/scripts/openscad.sh"

# probe must live under projects/bpir4-1u-chassis/ so its relative
# `include <params.scad>` resolves (mirrors test_bpir4_fan_clearance.sh's
# reasoning).
probe="$proj/_t76_microsd_clearance_probe.scad"
cleanup() { rm -f "$probe"; }
trap cleanup EXIT

cat > "$probe" <<'EOF'
enable_exhaust=true; fan_size=40; fan_count=2; ear_hole_type="slot";
include <params.scad>;
use <sbc/sbc.scad>;
use <fans/fans.scad>;
_card = [for (c = sbc_connectors(BOARD)) if (c[0] == "microsd_1_card") c][0];
_card_y_end = _card[1][1] + _card[2][1];
// Active mode: card keep-out must not reach the fan's interior face.
echo(str("ACTIVE_MARGIN=", (rear_wall_y(true) - wall - fan_default_thickness(fan_size)) - (board_y() + _card_y_end)));
// Passive mode: card keep-out must not reach the rear wall's inner face.
echo(str("PASSIVE_MARGIN=", (rear_wall_y(false) - wall) - (board_y() + _card_y_end)));
EOF

fail=0
out="$("$osc" --export-format stl -o /dev/null "$probe" 2>&1)"

active_margin="$(echo "$out" | grep -oE 'ACTIVE_MARGIN=-?[0-9.]+' | head -1 | sed 's/ACTIVE_MARGIN=//')"
passive_margin="$(echo "$out" | grep -oE 'PASSIVE_MARGIN=-?[0-9.]+' | head -1 | sed 's/PASSIVE_MARGIN=//')"

if [ -z "$active_margin" ] || [ -z "$passive_margin" ]; then
  echo "FAIL: render produced no ACTIVE_MARGIN/PASSIVE_MARGIN echo:"; echo "$out"
  fail=1
else
  echo "active mode: ACTIVE_MARGIN=$active_margin (fan inner face - card end; must be >= 0)"
  echo "passive mode: PASSIVE_MARGIN=$passive_margin (rear wall inner face - card end; must be >= 0)"

  if awk -v m="$active_margin" 'BEGIN{exit !(m>=0)}'; then
    echo "ok: active mode -- microSD card clears the fan (margin ${active_margin}mm)"
  else
    echo "FAIL: active mode -- microSD card OVERLAPS the fan by $(awk -v m="$active_margin" 'BEGIN{printf "%.2f", -m}')mm"
    fail=1
  fi

  if awk -v m="$passive_margin" 'BEGIN{exit !(m>=0)}'; then
    echo "ok: passive mode -- microSD card clears the rear wall (margin ${passive_margin}mm)"
  else
    echo "FAIL: passive mode -- microSD card OVERLAPS the rear wall by $(awk -v m="$passive_margin" 'BEGIN{printf "%.2f", -m}')mm"
    fail=1
  fi
fi

[ "$fail" -eq 0 ] && echo "ok (microSD card clears both the fan and the rear wall)"
exit "$fail"
