// Shell / Wall thickness: a hollow shelled box, cut away on one side to
// show the cross-section and the resulting wall thickness.
wt = 3; ow = 30; od = 30; oh = 20;

difference() {
    cube([ow, od, oh]);
    translate([wt, wt, wt]) cube([ow - 2 * wt, od - 2 * wt, oh - wt + 1]);
    // cut away the front half to reveal the shell cross-section
    translate([-1, od / 2, -1]) cube([ow + 2, od / 2 + 1, oh + 2]);
}
