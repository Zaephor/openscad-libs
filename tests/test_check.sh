#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1

# Stub openscad so compile-checks succeed without the real renderer.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/openscad" <<'EOF'
#!/usr/bin/env bash
out=""; prev=""
for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done
[ -n "$out" ] && : > "$out"
exit 0
EOF
chmod +x "$tmp/openscad"
export PATH="$tmp:$PATH"

cleanup() { rm -rf libraries/_clib projects/_cok projects/_cbad; }
cleanup

# A well-formed library and project must pass.
bash scripts/new-lib.sh _clib
bash scripts/new-project.sh _cok
# The template README references renders/<name>.png — create it so the embed check passes.
: > projects/_cok/renders/_cok.png
bash scripts/check.sh || { echo "valid tree failed check"; cleanup; exit 1; }

# Every .scad under libraries/ and projects/ must carry the SPDX header on line 1.
cp libraries/_clib/_clib.scad "$tmp/_clib.scad.bak"
tail -n +2 "$tmp/_clib.scad.bak" > libraries/_clib/_clib.scad
if bash scripts/check.sh >/dev/null 2>&1; then echo "missing SPDX header not caught"; cleanup; exit 1; fi
cp "$tmp/_clib.scad.bak" libraries/_clib/_clib.scad

# lib.json must declare a license.
cp libraries/_clib/lib.json "$tmp/lib.json.bak"
jq 'del(.license)' "$tmp/lib.json.bak" > libraries/_clib/lib.json
if bash scripts/check.sh >/dev/null 2>&1; then echo "lib.json missing license not caught"; cleanup; exit 1; fi
cp "$tmp/lib.json.bak" libraries/_clib/lib.json

# The restored tree passes again — proves the two checks above failed for the stated reason.
bash scripts/check.sh || { echo "restored tree failed check"; cleanup; exit 1; }

# A project missing PRINTING.md must fail.
bash scripts/new-project.sh _cbad
: > projects/_cbad/renders/_cbad.png
rm projects/_cbad/PRINTING.md
if bash scripts/check.sh >/dev/null 2>&1; then echo "missing PRINTING.md not caught"; cleanup; exit 1; fi

cleanup
echo ok
