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

# 5. DFA page is indexed, present, and references the assembly self-check.
grep -q 'reference/assembly-order.md' "$skill/SKILL.md" || { echo "DFA page not in SKILL.md index"; fail=1; }
[ -f "$skill/reference/assembly-order.md" ] || { echo "DFA page missing"; fail=1; }
grep -qi 'assembly.scad' "$skill/reference/assembly-order.md" || { echo "DFA page missing self-check ref"; fail=1; }

# 6. The DFA page must carry runnable verification gates, not just principles.
#    (#86 — the prose principles were already present when a 3.248mm^3
#    uninstallable-board collision shipped; these are the techniques.)
dfa="$skill/reference/assembly-order.md"
for needle in \
  'Measure interference, don.t eyeball it' \
  'Non-printed devices are part of the assembly' \
  'Verify the install MOTION, not just the seated pose' \
  'intersection()' \
  'coincident-face' \
  'minkowski' ; do
  grep -qiE "$needle" "$dfa" || { echo "assembly-order.md missing: $needle"; fail=1; }
done

# 7. Opening-vs-mating-part sizing (#86 — a faceplate whose port cutouts were
#    sized to the connector BODIES fouled on every real plug).
tf="$skill/reference/tolerances-fits.md"
for needle in \
  'size to the MATING part' \
  'lower bound' \
  'overmold' ; do
  grep -qiE "$needle" "$tf" || { echo "tolerances-fits.md missing: $needle"; fail=1; }
done

# 8. Fastener availability + partial test prints (#86).
hr="$skill/reference/house-rules.md"
for needle in \
  'Fastener availability is a design input' \
  'Test-print the risky interfaces first' ; do
  grep -qiE "$needle" "$hr" || { echo "house-rules.md missing: $needle"; fail=1; }
done

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
