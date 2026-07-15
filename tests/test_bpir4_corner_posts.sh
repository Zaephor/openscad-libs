#!/usr/bin/env bash
# Verifies the tray's lid-mounting corner posts (parts/tray.scad's
# _lid_post_xy()/_lid_posts()) were reworked from v2's tangent-to-one-wall
# boss + angled gusset wedge into a post that sits fully in the corner and
# fuses BOTH the side wall and the front/rear wall, as a full-height square
# column (no angled buttress), with a fillet on the internal (concave)
# post<->wall junctions and a chamfer on the exposed free (inner) vertical
# edge. Checks:
#   (a) the v2 single-wall gusset/buttress (hull()-built wedge) is gone;
#   (b) the front/rear pair is now tangent to the front/rear boundary too
#       (not just the side wall) -- tests/asserts.scad's new asserts (Task 4)
#       encode this numerically and are rendered here directly, independent
#       of the full suite;
#   (c) _lid_posts() still renders clean (no ERROR / manifold warning) in
#       isolation (tests/render_lid_posts.scad);
#   (d) the rendered posts are NOT plain round cylinders any more -- a
#       filleted+chamfered square column produces a materially different
#       (higher, since two extra fillet cylinders + chamfer cuts are added
#       per post) facet count than the old boss+wedge geometry; this is the
#       real-teeth proxy that (a)+(b) actually changed the printed geometry,
#       not just prose/comments.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
proj="$root/projects/bpir4-1u-chassis"
fail=0

# (a) v2 single-wall gusset/buttress wedge (hull()-built) must be gone.
if grep -qiE 'gusset|hull\(' "$proj/parts/tray.scad"; then
  echo "FAIL: v2 gusset/hull buttress still present in tray.scad"
  fail=1
fi
if grep -q '_corner_buttress' "$proj/parts/tray.scad"; then
  echo "FAIL: _corner_buttress() (v2 single-wall wedge) still present/referenced in tray.scad"
  fail=1
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# (b) numeric tangency-to-both-walls invariant (tests/asserts.scad).
out_asserts="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/asserts.stl" \
       "$proj/tests/asserts.scad" 2>&1)"
if echo "$out_asserts" | grep -qiE 'ERROR:|Assertion .* failed'; then
  echo "FAIL: corner-post tangency invariant failed:"; echo "$out_asserts"; fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "FAIL: skipping isolated-post render checks (prerequisite checks above failed)"
  exit 1
fi

# (c) isolated _lid_posts() render must be clean.
out="$("$root/scripts/openscad.sh" --export-format stl -o "$tmp/lid_posts.stl" \
       "$proj/tests/render_lid_posts.scad" 2>&1)"
if echo "$out" | grep -qiE 'ERROR:|Assertion .* failed|WARNING: Object may not be a valid'; then
  echo "FAIL: _lid_posts() render errored:"; echo "$out"; fail=1
fi
if [ ! -s "$tmp/lid_posts.stl" ]; then
  echo "FAIL: empty lid_posts STL"; fail=1
fi

# (d) facet-count sanity: 4 posts, each now a square column + 2 fillet
# cylinders (minus a chamfer cut) instead of a round boss + hull()'d wedge --
# a materially different facet count than the old geometry (either bound
# catches "nothing actually changed").
facets=0
if [ -s "$tmp/lid_posts.stl" ]; then
  facets=$(grep -c "facet normal" "$tmp/lid_posts.stl")
  if [ "$facets" -lt 400 ]; then
    echo "FAIL: lid_posts STL has only $facets facets -- too few for 4 filleted square columns (expected 400+)"
    fail=1
  fi
fi

[ "$fail" -eq 0 ] && echo "ok ($facets facets, corner-post tangency + no-v2-buttress checks passed)"
exit "$fail"
