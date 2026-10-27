// ============================================================
// MAGIC CIRCLE - CREATE
// ============================================================
// the circle with a star that appears on the ground where a spell
// is about to land. it is made by enemy_magic_begin(), which hands
// it these values when it is created:
//   caster, element, colour, effect_sprite, frame_time,
//   hit_delay, damage, hit_radius, charge_time
// the defaults below are only used if one is placed by hand for testing.
// ============================================================

if (!variable_instance_exists(id, "caster"))        caster        = noone;
if (!variable_instance_exists(id, "element"))       element       = MAGIC_ELEMENT.FIRE;
if (!variable_instance_exists(id, "colour"))        colour        = c_white;
if (!variable_instance_exists(id, "effect_sprite")) effect_sprite = magic_fire_spr;
if (!variable_instance_exists(id, "frame_time"))    frame_time    = 4;
if (!variable_instance_exists(id, "hit_delay"))     hit_delay     = 8;
if (!variable_instance_exists(id, "damage"))        damage        = 1;
if (!variable_instance_exists(id, "hit_radius"))    hit_radius    = 36;
if (!variable_instance_exists(id, "charge_time"))   charge_time   = 45;

// ---------- phases ----------
// 0 = charging  (circle fades in and spins faster and faster)
// 1 = erupting  (the spell comes out and hurts the player)
// 2 = fading    (the circle fades away)
phase = 0;

// frames spent in the current phase
timer = 0;

// frames since the circle was created
total_time = 0;

// the caster sets this to true when the spell should go off
released = false;

// so the player is only hurt once per spell
hit_done = false;

// true if the caster was hurt before the release and the spell fell apart
fizzled = false;

// safety: a circle that is never released fades away after this many frames
life_limit = 300;

// ---------- looks ----------
appear_time = 14;     // frames the circle takes to grow in
fade_time   = 18;     // frames the circle takes to fade out
erupt_time  = sprite_get_number(effect_sprite) * frame_time;   // how long the effect plays

// the circle sprite is 80 pixels wide. this keeps its size matched to the hit area.
circle_scale = (hit_radius + 3) / 39;

spin   = random(360);   // current rotation
scale  = 0;             // current size (1 = full size)
alpha  = 0;             // current see-through amount (1 = solid)
charge = 0;             // how charged the spell is (0 to 1)

// values remembered when the fade-out starts
fade_alpha = 1;
fade_scale = 1;
