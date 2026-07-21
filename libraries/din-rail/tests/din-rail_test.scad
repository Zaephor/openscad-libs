use <din-rail/din-rail.scad>;
assert(din_known_rails() == ["ts35-7.5","ts35-15"], "rail list");
assert(din_rail_size("ts35-7.5")[0] == 35, "ts35 width");
assert(din_rail_size("ts35-15")[1] == 15, "ts35-15 depth");
assert(din_rail_size("ts35-7.5")[1] == 7.5, "ts35-7.5 depth");

// din_clip() engagement (Task 3): the clip is an inner-grip snap — two prongs
// enter the hat channel and catch the INWARD return lips with outward barbs.
// The catch span (barb-tip to barb-tip) must land in the lip catch zone: wider
// than the gap between the two lips' inner edges (so each barb overlaps its lip
// = engagement) but narrower than the gap between the leg inner faces (so the
// barb clears the leg on entry, no gross clip-through). This bounds the clip's
// catch geometry to the rail data for BOTH depth variants.
module _din_clip_engages(type, clr) {
    sz  = din_rail_size(type);       // [w, d, t, pitch]
    lip = din_rail_lip(type);        // [lip_h, lip_return]
    lip_inner = sz[0] - 2*sz[2] - 2*lip[1]; // Y-span between the two lips' inner edges
    leg_inner = sz[0] - 2*sz[2];            // Y-span between the two leg inner faces
    span = din_clip_catch_span(type, clr);
    assert(span > lip_inner, str(type, ": clip catch span must overlap the return lips"));
    assert(span < leg_inner, str(type, ": clip catch span must clear the rail legs"));
}
_din_clip_engages("ts35-7.5", 0.4);
_din_clip_engages("ts35-15",  0.4);

echo("din-rail_test OK");
