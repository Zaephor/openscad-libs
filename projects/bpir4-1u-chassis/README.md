# bpir4-1u-chassis

Enclosed 1U 10-inch (LabRax) rack chassis for the Banana Pi BPI-R4.
Two printed parts: a single-body tray and a flush countersunk lid. The body
is narrowed to hug the board (`body_w()` ≈170mm, not the full rack-clear
width) with four support-free corner posts beside it, each bonded to
**both** walls of its corner as a full-height square column (fillet on the
two internal post↔wall junctions, chamfer on the one exposed free edge —
no angled buttress). Rear exhaust fans are behind an `enable_exhaust` toggle
exposed in the assembly customizer alongside `fan_size`/`fan_count` (fixed:
the toggle now actually drives tray/lid geometry via the Customizer or
`-D enable_exhaust=false`, instead of being silently overridden); passive
mode swaps the fan bores for a rear vent-slot array. Intake air runs through
a self-supporting honeycomb hex-vent band above the IO connector cluster
(not side margins), for a straight cross-chassis path over the SFP/connector
tops — no supports needed, since each hex cell's own bridge is only a few mm
(`parts/_honeycomb.scad`, shared with the lid). The lid carries the same
honeycomb pattern over the board's hot zone (`lid_vents`, on by default),
also support-free. Rack ears default to slotted mounting holes
(`ear_hole_type`), with round options available.

All hardware dimensions are pulled live from the repo libraries (`sbc`,
`rack10`, `fans`, `hardware`).

![assembly](renders/bpir4-1u-chassis.png)

## Render / build

    make render P=bpir4-1u-chassis
    make run    P=bpir4-1u-chassis   # GUI

## Parameters

See `params.scad`. Key: `enable_exhaust` (rear fans on/off, customizer
`/* [Cooling] */` group), `fan_size`, `fan_count`, `stack_gap`,
`ear_hole_type` (`"slot"` default; `"10-32"`/`"m6"`/`"round"` also available),
`lid_vents` (honeycomb hex vents over the lid's hot-zone band, on by
default), `honeycomb_cell`/`honeycomb_wall` (hex size/spacing shared by the
faceplate and lid vent bands).

## Assembly reference

`assembly.scad` has a `show_rack` toggle (`/* [Show] */` group) that renders
a translucent 3U `rack10_placeholder` framing the chassis as the middle U —
a quick sanity check against neighboring rack gear before printing.
