#!/usr/bin/env bash
# Plumbing test for scripts/render-dind.sh — uses a STUB docker (no live dind).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
log="$tmp/args.log"

mkdir -p "$tmp/bin"
cat > "$tmp/bin/docker" <<STUB
#!/usr/bin/env bash
echo "\$@" >> "$log"
case "\$1" in
  version) exit \${DOCKER_VERSION_RC:-0} ;;
  image)   exit 1 ;;                              # inspect: image "missing" -> triggers build
  build)   cat >/dev/null; exit 0 ;;             # consume Dockerfile from stdin
  run)     cat >/dev/null; tar -cf - -T /dev/null; exit 0 ;;  # consume tar in, emit empty tar out
  *)       exit 0 ;;
esac
STUB
chmod +x "$tmp/bin/docker"

pass=0; fail=0
ck(){ if eval "$2"; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi; }

# 1) happy path, single project
PATH="$tmp/bin:$PATH" bash "$ROOT/scripts/render-dind.sh" keystone-faceplate >/dev/null 2>&1
rc=$?
ck "single-project exits 0"        "[ $rc -eq 0 ]"
ck "builds render image"           "grep -q 'build -t openscad-render:bookworm' '$log'"
ck "wraps in xvfb-run"             "grep -q 'xvfb-run' '$log'"
ck "forces software GL"            "grep -q 'LIBGL_ALWAYS_SOFTWARE=1' '$log'"
ck "invokes make render P=proj"    "grep -q 'make render P=keystone-faceplate' '$log'"

# 2) --all target
: > "$log"
PATH="$tmp/bin:$PATH" bash "$ROOT/scripts/render-dind.sh" --all >/dev/null 2>&1
ck "--all invokes make render-all" "grep -q 'make render-all' '$log'"

# 3) daemon unreachable -> clean exit 3, no build/run attempted
: > "$log"
DOCKER_VERSION_RC=1 PATH="$tmp/bin:$PATH" bash "$ROOT/scripts/render-dind.sh" foo >/dev/null 2>&1
rc=$?
ck "unreachable daemon exits 3"    "[ $rc -eq 3 ]"

# 4) usage error on missing arg -> exit 2
PATH="$tmp/bin:$PATH" bash "$ROOT/scripts/render-dind.sh" >/dev/null 2>&1
ck "missing arg exits 2"           "[ $? -eq 2 ]"

# 5) shell-metacharacter target rejected before any docker interaction
: > "$log"
PATH="$tmp/bin:$PATH" bash "$ROOT/scripts/render-dind.sh" 'foo;bar' >/dev/null 2>&1
rc=$?
ck "injection-shaped target exits 2"   "[ $rc -eq 2 ]"
ck "rejected before docker invoked"    "[ ! -s '$log' ]"

echo "-- $pass passed, $fail failed --"
[ "$fail" -eq 0 ]
