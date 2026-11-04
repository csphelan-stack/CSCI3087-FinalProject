// ============================================================
// MAGIC FX - CREATE
// ============================================================
// one object, two jobs (set by "kind"):
//   "orb"   - the glowing colored orb on the enemy while it charges a spell
//   "burst" - the lightning / fire / earth / light / dark effect that comes
//             out of the magic circle
// it is made by enemy_magic_begin() and the magic circle, which hand it:
//   kind, caster, colour, grow_time, orb_scale     (orb)
//   kind, element, colour, effect_sprite, frame_time   (burst)
// the defaults below are only used if one is placed by hand for testing.
// ============================================================

if (!variable_instance_exists(id, "kind"))          kind          = "burst";
if (!variable_instance_exists(id, "caster"))        caster        = noone;
if (!variable_instance_exists(id, "element"))       element       = MAGIC_ELEMENT.FIRE;
if (!variable_instance_exists(id, "colour"))        colour        = c_white;
if (!variable_instance_exists(id, "effect_sprite")) effect_sprite = magic_fire_spr;
if (!variable_instance_exists(id, "frame_time"))    frame_time    = 4;
if (!variable_instance_exists(id, "grow_time"))     grow_time     = 45;
if (!variable_instance_exists(id, "orb_scale"))     orb_scale     = 1;
if (!variable_instance_exists(id, "start_delay"))   start_delay   = 0;     // a burst can wait before it starts

// frames since this object was created
timer = 0;

// ---------- orb only ----------
// the orb flares out and fades when the spell is released (or interrupted)
fading     = false;
fade_timer = 0;
fade_time  = 10;
