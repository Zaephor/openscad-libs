use <../css610-underdesk-mount.scad>;

// Data asserts verify device dimensions.
assert(len(_css610_side_holes()) == 4, "CSS610 side pattern = 4 holes");
assert(_css610_size()[2] == 47.1, "CSS610 height (flange datum)");

// Bracket render (Task 2): uncomment to drive bracket geometry tests.
// css610_underdesk_bracket();
