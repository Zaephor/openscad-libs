#!/usr/bin/env bash
# #70: rack10 and rack19 deliberately duplicate the panel-silhouette chamfer
# (sibling standards, no natural dependency direction -- see the inline
# comments on both accessors). This guards the pair against drifting apart.
# It checks GEOMETRY, not just the constant: an accessor-only check would sail
# past a changed polygon.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"

run() { "$root/scripts/openscad.sh" --export-format stl -o /dev/null "$1" 2>&1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/drift.scad" <<'EOF'
use <rack10/rack10.scad>;
use <rack19/rack19.scad>;
// The constant.
assert(abs(rack10_panel_corner_chamfer() - rack19_panel_corner_chamfer()) < 1e-9,
    "drift: rack10/rack19 panel corner chamfer constants differ");
// The geometry. Same w/h/chamfer into both -> identical point lists, in order.
a = rack10_panel_profile_pts(300, 43.66, 3.0);
b = rack19_panel_profile_pts(300, 43.66, 3.0);
assert(len(a) == len(b), "drift: profile point counts differ");
assert([for (i = [0:len(a)-1]) if (norm(a[i] - b[i]) > 1e-9) i] == [],
    "drift: profile points differ");
// Same again with the chamfer disabled, so the degenerate branch is covered too.
a0 = rack10_panel_profile_pts(300, 43.66, 0);
b0 = rack19_panel_profile_pts(300, 43.66, 0);
assert(len(a0) == len(b0), "drift: square-corner point counts differ");
assert([for (i = [0:len(a0)-1]) if (norm(a0[i] - b0[i]) > 1e-9) i] == [],
    "drift: square-corner points differ");
EOF
out="$(run "$tmp/drift.scad")"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "rack panel drift check failed:"; echo "$out"; exit 1
fi

# Negative control: the check must actually be able to fail.
cat > "$tmp/drift_bad.scad" <<'EOF'
use <rack10/rack10.scad>;
use <rack19/rack19.scad>;
a = rack10_panel_profile_pts(300, 43.66, 3.0);
b = rack19_panel_profile_pts(300, 43.66, 4.0);   // deliberately mismatched
assert([for (i = [0:len(a)-1]) if (norm(a[i] - b[i]) > 1e-9) i] == [],
    "intentionally wrong");
EOF
out="$(run "$tmp/drift_bad.scad")"
echo "$out" | grep -qiE 'ERROR:|Assertion .* failed' \
  || { echo "drift negative control did not fail"; echo "$out"; exit 1; }

echo ok
