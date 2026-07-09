// Assert-only test for the connectors library. No geometry — run via
// OPENSCADPATH=$PWD/libraries scripts/openscad.sh --export-format stl -o /dev/null libraries/connectors/tests/connectors_test.scad
use <connectors/connectors.scad>;

// full v1 type list present, in order
assert(connector_known_types() == [
    "usb_a", "usb_a_stack2", "usb_c", "micro_usb",
    "rj45", "rj45_stack2", "hdmi", "mini_hdmi", "micro_hdmi",
    "pcie_x1", "pcie_x4", "pcie_x8", "pcie_x16", "gpio_2x20",
    /* SP1 additions: */ "usb_a_stack2_shielded", "rj45_shallow"], "type list");

// opening axes (fixed design decision)
assert(connector_opening("usb_a")    == "+Y", "usb_a opening");
assert(connector_opening("rj45")     == "+Y", "rj45 opening");
assert(connector_opening("micro_hdmi") == "+Y", "micro_hdmi opening");
assert(connector_opening("pcie_x16") == "+Z", "pcie opening");
assert(connector_opening("gpio_2x20")== "+Z", "gpio opening");

// strongest-sourced / representative dims (see per-line tiers)
assert(connector_size("pcie_x16") == [89, 7.5, 11.25], "pcie_x16 body");     // [C] //VERIFY cited-not-fetched
assert(connector_size("gpio_2x20") == [50.8, 5.08, 8.5], "gpio_2x20 body");  // w/d [A], h [B] (SP1 upgrade)

// SP1 reconciled bodies (values per RESEARCH.md SP1 table)
assert(connector_size("usb_a_stack2_shielded") == [17, 18, 16.0], "usb_a_stack2_shielded body");
assert(connector_size("rj45_shallow") == [21, 18.75, 13.5], "rj45_shallow body");

// --- body renders + arithmetic guard (geometry verified by render step) ---
// pcie_x16 body volume = 89*7.5*11.25 = 7509.375 mm^3
assert(connector_size("pcie_x16")[0] * connector_size("pcie_x16")[1]
     * connector_size("pcie_x16")[2] == 7509.375, "pcie_x16 volume");

// fully-[A] fetched rows — locked exact values (RESEARCH.md)
assert(connector_size("usb_a") == [13.66, 14.6, 6.94], "usb_a body");
assert(connector_size("usb_c") == [8.94, 6.90, 3.16], "usb_c body");
assert(connector_size("rj45")  == [16.36, 30.48, 13.67], "rj45 body");
assert(connector_size("hdmi")  == [14.50, 11.06, 6.17], "hdmi body");

// shape/consistency: every row is [w,d,h] (3 positive numbers)
module _check_dims(t) {
    s = connector_size(t);
    assert(len(s) == 3 && s[0] > 0 && s[1] > 0 && s[2] > 0, str(t, " dims"));
}
for (t = connector_known_types()) _check_dims(t);

// --- cutout: opening axes drive which face is cut (verified by render step) ---
assert(connector_opening("usb_a") == "+Y" && connector_opening("pcie_x16") == "+Z",
       "cutout axis source");

echo("connectors_test OK");
