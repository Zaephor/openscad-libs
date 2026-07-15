#!/usr/bin/env bash
# Verifies the design-for-print skill: examples render, referenced images exist,
# SKILL.md index links resolve.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
skill="$root/.claude/skills/design-for-print"
renderer="$root/.claude/skills/verify-scad-geometry/render_stl.py"
fail=0
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# 1. Every example renders headlessly with no error.
for f in "$skill"/examples/*.scad; do
  out="$(python3 "$renderer" "$f" --out "$tmp/$(basename "$f" .scad).png" 2>&1)"
  echo "$out" | grep -qiE 'ERROR:|Traceback' && { echo "render failed: $f"; echo "$out"; fail=1; }
done

# 2. Every image referenced by a reference/*.md exists in images/.
grep -rhoE '\]\(\.\./images/[A-Za-z0-9_-]+\.png\)' "$skill"/reference/*.md \
  | sed -E 's#\]\(\.\./images/##; s#\)##' | sort -u | while read -r img; do
    [ -f "$skill/images/$img" ] || { echo "missing image: $img"; exit 3; }
  done || fail=1

# 3. Every reference file named in SKILL.md's index exists.
grep -oE 'reference/[A-Za-z0-9_-]+\.md' "$skill/SKILL.md" | sort -u | while read -r ref; do
  [ -f "$skill/$ref" ] || { echo "missing reference file: $ref"; exit 3; }
done || fail=1

# 4. Image embeds must be real markdown, not wrapped in code spans (else GitHub
#    renders literal text). Flag any line where ![..](..) is inside backticks.
while IFS= read -r hit; do
  echo "image embed wrapped in code span: $hit"; fail=1
done < <(grep -rnE '`[^`]*!\[[^]]*\]\([^)]*\)[^`]*`' "$skill"/reference/*.md)

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
