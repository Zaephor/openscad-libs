#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

# Real openscad is slow/needs a display abstraction; stub it to just write the -o file.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/openscad" <<'EOF'
#!/usr/bin/env bash
out=""
prev=""
for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done
[ -n "$out" ] && printf 'PNG' > "$out"
EOF
chmod +x "$tmp/openscad"

mkdir -p "$root/projects/_t/"
echo 'cube(1);' > "$root/projects/_t/_t.scad"

PATH="$tmp:$PATH" bash "$root/scripts/render.sh" _t || { echo "render failed"; rm -rf "$root/projects/_t"; exit 1; }
test -f "$root/projects/_t/renders/_t.png" || { echo "no png"; rm -rf "$root/projects/_t"; exit 1; }

rm -rf "$root/projects/_t"
echo ok
