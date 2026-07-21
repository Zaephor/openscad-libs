// din-rail/assembly.scad — din_clip() / din_rail_profile() mate demo (Task 3).
// Geometric correctness gate for the snap clip: places the reference rail
// profile and the printable clip in their seated (mated) pose so
// verify-scad-geometry can confirm the clip's catch barbs hook the rail's
// return lips (din_rail_lip) with no gross rigid-body clip-through of the rail
// body. Physical snap tension is NOT checked here — it is bench-tuned by the
// caller via din_clip()'s clearance/wall/flex_len (see README "Coverage").
//
// Render (headless, no GL):
//   python3 .claude/skills/verify-scad-geometry/render_stl.py \
//     libraries/din-rail/assembly.scad --out /tmp/din_mate.png
// Side-profile overlay (rail vs clip, yz-axis) — the engagement check:
//   python3 .claude/skills/verify-scad-geometry/render_stl.py --overlay \
//     <(echo 'use <din-rail/din-rail.scad>; din_rail_profile("ts35-7.5",10);') \
//     <(echo 'use <din-rail/din-rail.scad>; din_clip("ts35-7.5");') \
//     --axis yz --out /tmp/din_overlay.png
use <din-rail/din-rail.scad>;

/* [Mate] */
type = "ts35-7.5"; // ["ts35-7.5", "ts35-15"]
rail_len = 60;
clip_width = 15;

// Reference rail (fit/context geometry, not itself a print).
din_rail_profile(type, rail_len);
// The printable clip, seated: barbs hook the rail's inward return lips.
color("orange") din_clip(type, width = clip_width);
