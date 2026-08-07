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
  'Test-print the risky interfaces first' \
  'Standing default: prefer M3' ; do
  grep -qiE "$needle" "$hr" || { echo "house-rules.md missing: $needle"; fail=1; }
done

# 9. Repo clearance/precedent numbers cited across the skill must track
#    params.scad, not drift from it (#86 -- 4 of 6 house-rules.md table rows
#    went stale/dead silently, the same dead `boss_wall` param turned up
#    uncaught in strength-physics.md and glossary.md too, a first replay
#    showed an earlier version of this gate still passed a row reverted to
#    its old stale literal, and a SECOND replay showed the version that fixed
#    that still passed a plain rename -- because "exists in params.scad" was
#    checked with a bare word grep, which is satisfied by a COMMENT mentioning
#    the old name (params.scad:244 mentions `boss_wall` only in a comment;
#    that comment is exactly what let a dead-row reintroduction slip past a
#    bare-word check, which is why the standalone dead-name blocklist below
#    used to be load-bearing). What this block still cannot do: evaluate
#    whether a cited VALUE is numerically correct (a grep can't run OpenSCAD).
#    So a derived row keeping its accessor call but stating the wrong number,
#    a row citing the wrong accessor for what it claims to be, a wrong
#    argument to a correct accessor, or outright deletion of the wall_gap /
#    csk_head_extra / heatset_min_wall(...) rows would all still pass. Two
#    checks, both structural, neither a value check:
#    (a) every symbol the table cites by name (extracted from the table
#        itself, not a hardcoded list, so a NEW row citing an invented name
#        is caught the same way as an old one being renamed) must be
#        DEFINED, not merely mentioned, in params.scad or heatset.scad --
#        matched against the actual declaration shape both files use
#        (`name = ...;` or `function name(...) = ...;`), not a bare `grep -q`
#        that a comment can satisfy;
#    (b) the two rows whose own Name column documents a derivation under a
#        DIFFERENT symbol (board_insert_bore/lid_insert_bore, both citing
#        heatset_pilot_dia()) must still cite that call in the Value column,
#        not a bare re-literalised number. heatset_min_wall(lid_insert_size)
#        does not get an entry here: its Name column IS the accessor call,
#        so a same-line "does the row contain its own name" check would be
#        tautological -- it can only fire on that row's outright deletion,
#        which check (a) already can't see either (check (a) only walks rows
#        that still exist). That row's deletion is accordingly NOT gated;
#        disclosing rather than shipping a check that looks like coverage.
pf="$root/projects/bpir4-1u-chassis/params.scad"
hf="$root/libraries/heatset/heatset.scad"
sp="$skill/reference/strength-physics.md"
gl="$skill/reference/glossary.md"

mapfile -t hr_rows < <(grep -E '^\| `' "$hr")
for row in "${hr_rows[@]}"; do
  sym="$(printf '%s' "$row" | sed -E 's/^\| `([^`]+)`.*/\1/')"
  base="${sym%%(*}"
  grep -qE "^[[:space:]]*(function[[:space:]]+)?${base}[[:space:]]*[=(]" "$pf" "$hf" \
    || { echo "house-rules.md table cites '$sym' but it is not DEFINED (only mentioned, or absent) in params.scad or heatset.scad"; fail=1; }
done

for row_sym_call in 'board_insert_bore:heatset_pilot_dia(' \
                     'lid_insert_bore:heatset_pilot_dia(' ; do
  rsym="${row_sym_call%%:*}"; call="${row_sym_call#*:}"
  line="$(grep -F "| \`$rsym\`" "$hr")"
  if [ -z "$line" ]; then
    echo "house-rules.md table missing expected derived row: $rsym"; fail=1
  elif ! printf '%s' "$line" | grep -qF "$call"; then
    echo "house-rules.md row '$rsym' no longer cites $call) -- looks re-literalised"; fail=1
  fi
done

# Retired: the old `for dead in boss_wall post_wall_gap` blocklist. The
# definition-shaped check above now catches both names on its own -- proven
# by restoring a `boss_wall` row and confirming (a) still fails it, since
# params.scad's only trace of `boss_wall` is a comment, not a definition
# (see task-3-report.md fix round 5 for the probe). A hand-maintained list of
# names known dead TODAY doesn't generalise to a name nobody has invented
# yet; the structural check does.
# strength-physics.md and glossary.md still cite dead names in PROSE, not a
# table the definition-shaped check above walks, so they keep their own
# direct check.
for f in "$sp" "$gl" ; do
  for dead in boss_wall post_wall_gap ; do
    grep -qE "\`$dead\`" "$f" && { echo "$(basename "$f") still cites dead param: $dead"; fail=1; }
  done
done

# 10. SKILL.md must index the new material AND be retrievable for it (#86).
for needle in \
  'Verify assembly numerically' \
  'mating part' \
  'install motion' ; do
  grep -qiE "$needle" "$skill/SKILL.md" || { echo "SKILL.md missing: $needle"; fail=1; }
done
# The frontmatter description drives retrieval; an unindexed trigger means the
# skill is never loaded for these questions.
desc="$(sed -n '/^description:/,/^---$/p' "$skill/SKILL.md")"
for needle in 'interference' 'mating' ; do
  echo "$desc" | grep -qi "$needle" || { echo "SKILL.md description missing trigger: $needle"; fail=1; }
done

# 11. assembly-order.md points at tests/test_bpir4_board_fit.sh as the worked
#     implementation of the interference/motion techniques it describes
#     (#86) -- gate the path so that reference cannot rot into a dangling
#     pointer the way the precedent-table rows did above.
bf="$root/tests/test_bpir4_board_fit.sh"
grep -q 'test_bpir4_board_fit.sh' "$dfa" || { echo "assembly-order.md missing worked-example ref: test_bpir4_board_fit.sh"; fail=1; }
[ -f "$bf" ] || { echo "assembly-order.md cites test_bpir4_board_fit.sh but it no longer exists"; fail=1; }

[ "$fail" -eq 0 ] && echo ok
exit "$fail"
