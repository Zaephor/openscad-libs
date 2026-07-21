#!/usr/bin/env bash
# Render project PNG(s) via the dind sidecar. The native `make render` GL/PNG
# path (scripts/render.sh) segfaults where there is no X/GL and no sudo to
# install xvfb/mesa. This runs the SAME pipeline inside a Docker container that
# has xvfb + software GL. CI (.github/workflows/render.yml) uses its own xvfb on
# the runner and does NOT use this script. Image is debian bookworm => OpenSCAD
# 2021.01, matching local + CI so committed PNGs stay consistent.
# dind has its OWN filesystem: bind mounts don't see our files, so we tar-pipe
# the tree in and tar-pipe the rendered PNGs back out.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="openscad-render:bookworm"
TARGET="${1:-}"

[ -n "$TARGET" ] || { echo "Usage: render-dind.sh <project>|--all" >&2; exit 2; }

command -v docker >/dev/null 2>&1 || {
  echo "render-dind: docker not found — render via CI or a display machine." >&2; exit 3; }
docker version >/dev/null 2>&1 || {
  echo "render-dind: docker daemon unreachable — render via CI or a display machine." >&2; exit 3; }

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "render-dind: building $IMAGE (first run) ..." >&2
  docker build -t "$IMAGE" - >&2 <<'DOCKERFILE'
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends openscad xvfb libgl1-mesa-dri make ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /w
DOCKERFILE
fi

if [ "$TARGET" = "--all" ]; then MK="render-all"; else MK="render P=$TARGET"; fi

# Tree in -> run existing pipeline under xvfb+software GL -> PNGs out.
tar -C "$ROOT" -c libraries projects Makefile scripts \
 | docker run --rm -i "$IMAGE" sh -c '
     set -e
     mkdir -p /w && tar -C /w -x
     cd /w
     xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe make '"$MK"' 1>&2
     tar -c projects/*/renders/*.png
   ' \
 | tar -C "$ROOT" -x --overwrite

echo "render-dind: done ($MK)" >&2
