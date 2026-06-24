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

# A project missing PRINTING.md must fail.
bash scripts/new-project.sh _cbad
: > projects/_cbad/renders/_cbad.png
rm projects/_cbad/PRINTING.md
if bash scripts/check.sh >/dev/null 2>&1; then echo "missing PRINTING.md not caught"; cleanup; exit 1; fi

cleanup
echo ok
