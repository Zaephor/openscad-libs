#!/usr/bin/env bash
# Scaffold a new project from templates/project-single or project-multipart.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name="${1:?Usage: new-project.sh <name> [--multipart]}"

# Reject names that contain unsafe characters for sed delimiters.
if ! [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: name must match ^[A-Za-z0-9._-]+$ (got: $name)" >&2
  exit 1
fi

tpl="project-single"
[ "${2:-}" = "--multipart" ] && tpl="project-multipart"
dest="$ROOT/projects/$name"
[ -e "$dest" ] && { echo "Refusing: $dest already exists" >&2; exit 1; }

cp -r "$ROOT/templates/$tpl" "$dest"
[ -f "$dest/__NAME__.scad" ] && mv "$dest/__NAME__.scad" "$dest/$name.scad"
{ grep -rl '__NAME__' "$dest" || true; } | while read -r f; do
  sed -i "s/__NAME__/$name/g" "$f"
done
echo "Created project $dest ($tpl)"
