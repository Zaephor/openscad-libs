# bpir4-1u-chassis

Enclosed 1U 10-inch (LabRax) rack chassis for the Banana Pi BPI-R4.
Two printed parts: a single-body tray and a flush countersunk lid. Rear
exhaust fans are behind an `enable_exhaust` toggle (`params.scad`).

All hardware dimensions are pulled live from the repo libraries (`sbc`,
`rack10`, `fans`, `hardware`).

![assembly](renders/bpir4-1u-chassis.png)

## Render / build

    make render P=bpir4-1u-chassis
    make run    P=bpir4-1u-chassis   # GUI

## Parameters

See `params.scad`. Key: `enable_exhaust` (rear fans on/off), `fan_size`,
`fan_count`, `stack_gap`.
