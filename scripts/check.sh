#!/usr/bin/env bash
# Lint monorepo conventions and compile every .scad headless.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
errors=0
err() { echo "VIOLATION: $*"; errors=$((errors + 1)); }

# Libraries
for d in libraries/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  [ -f "$d/README.md" ] || err "$name: missing README.md"
  if [ -f "$d/lib.json" ]; then
    jq -e '.name and .description and .version and (.sources|type=="array")' "$d/lib.json" >/dev/null 2>&1 \
      || err "$name: lib.json missing required fields (name, description, version, sources[])"
  else
    err "$name: missing lib.json"
  fi
done

# Projects
for d in projects/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  [ -f "$d/README.md" ] || err "$name: missing README.md"
  [ -f "$d/PRINTING.md" ] || err "$name: missing PRINTING.md"
  if [ -f "$d/README.md" ]; then
    grep -Eq '!\[[^]]*\]\(renders/[^)]+\)' "$d/README.md" \
      || err "$name: README.md does not embed a renders/ image"
  fi
  if [ -d "$d/parts" ]; then
    [ -f "$d/assembly.scad" ] || err "$name: multipart project missing assembly.scad"
  fi
done

# Compile every .scad headless (templates excluded; they hold placeholders).
# Use --export-format echo so OpenSCAD accepts /dev/null as the output path
# regardless of extension.  The test stub ignores --export-format and still works.
while IFS= read -r -d '' f; do
  if ! "$ROOT/scripts/openscad.sh" --export-format echo -o /dev/null "$f" >/dev/null 2>&1; then
    err "compile failed: $f"
  fi
done < <(find libraries projects -name '*.scad' -print0 2>/dev/null)

if [ "$errors" -gt 0 ]; then
  echo "check failed: $errors violation(s)"
  exit 1
fi
echo "check passed"
