#!/usr/bin/env bash
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
sh="$root/scripts/openscad.sh"

# Stub openscad so we test our wrapper, not the renderer.
tmp="$(mktemp -d)"
cat > "$tmp/openscad" <<'EOF'
#!/usr/bin/env bash
echo "OPENSCADPATH=$OPENSCADPATH"
echo "ARGS=$*"
EOF
chmod +x "$tmp/openscad"

out="$(PATH="$tmp:$PATH" "$sh" --version 2>/dev/null)"

echo "$out" | grep -q "OPENSCADPATH=$root/libraries" || { echo "bad OPENSCADPATH: $out"; exit 1; }
echo "$out" | grep -q "ARGS=--version" || { echo "args not forwarded: $out"; exit 1; }
echo ok
