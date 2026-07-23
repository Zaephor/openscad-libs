use <keystone/keystone.scad>;
// Printable keystone blank insert. Tune fit/latch_wall on the bench (P1S/PETG).
fit = 0.2;         // slot-engagement clearance
latch_wall = 1.0;  // cantilever beam thickness (PETG compliance)
module keystone_blank() { keystone_insert(fit=fit, latch_wall=latch_wall, blank=true); }
keystone_blank();
