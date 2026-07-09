// Assert-only test for the drives library. Run via:
// OPENSCADPATH=$PWD/libraries scripts/openscad.sh --export-format stl -o /dev/null \
//   libraries/drives/tests/drives_test.scad
use <drives/drives.scad>;

// scaffold smoke: type list is a list (populated in Task 2).
assert(is_list(drive_known_types()), "known_types is a list");

echo("drives_test OK");
