#!/usr/bin/env bash
# Runs every tests/test_*.sh; fails if any fails.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
for t in tests/test_*.sh; do
  [ -e "$t" ] || continue
  echo "== $t =="
  if bash "$t"; then
    echo "PASS $t"
  else
    echo "FAIL $t"
    fail=1
  fi
done
exit "$fail"
