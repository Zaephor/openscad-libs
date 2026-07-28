// asserts_depth.scad — negative-control regression for drive-tray's grid-
// depth fit-assert (_usable_depth(), Task 2). Rendered directly by
// tests/test_drive_tray.sh. Same include-then-override idiom as
// asserts.scad (the width negative control) -- see that file's header
// comment for why `include` (not `use`) and why the override must come
// AFTER the include.
include <../drive-tray.scad>;

// rows=20 at the default drive_type (hdd35, _dlen()=147) blows _grid_d()
// (rows*147 + (rows-1)*4 = 3016mm) well past labrax's usable depth budget
// (225mm) -- MUST abort drive-tray.scad's own depth fit-assert. cols stays
// at its default (2), so this exercises ONLY the depth assert, not the
// width one (they can't both be tested in one file: whichever assert is
// declared first in drive-tray.scad wins and aborts before the other is
// ever reached). If this file ever renders cleanly, the depth fit-assert
// has silently broken.
rows = 20;
