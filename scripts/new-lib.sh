#!/usr/bin/env bash
# Scaffold a new library from templates/library.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:?Usage: new-lib.sh <name>}"
dest="$ROOT/libraries/$name"
[ -e "$dest" ] && { echo "Refusing: $dest already exists" >&2; exit 1; }

cp -r "$ROOT/templates/library" "$dest"
mv "$dest/__NAME__.scad" "$dest/$name.scad"
# Substitute placeholder in all files.
grep -rl '__NAME__' "$dest" | while read -r f; do
  sed -i "s/__NAME__/$name/g" "$f"
done
echo "Created library $dest"
