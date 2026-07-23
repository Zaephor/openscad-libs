// rack-support — generic rear-support faceplate + slide-in tongue/slot mating
// interface for rack10 device trays (#40). The rear plate bolts to the rear
// rack posts and presents a forward-facing channel; a consumer tray adds
// rack_support_tongue() at its rear and slides in. Converts a front cantilever
// into a two-end-supported beam (creep mitigation — see README consumer
// contract). Consumes rack10 for widths/holes/depth. See RESEARCH.md for
// provenance: the mating dims are DESIGN values (fit clearances), not measured.
use <rack10/rack10.scad>;

// --- mating interface (single source of truth; DESIGN values, //VERIFY,
// bench-tunable P1S/PETG — see design-for-print) ---
function rack_support_rail_size()      = [40, 10]; // tongue [width_X, height_Z] mm //VERIFY design
function rack_support_slot_clearance() = 0.4;      // per-side slide fit gap    //VERIFY design
function rack_support_engagement_depth() = 12;     // tongue insertion depth Y  //VERIFY design
