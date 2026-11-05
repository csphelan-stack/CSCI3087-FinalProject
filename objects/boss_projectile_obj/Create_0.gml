// ============================================================
// BOSS PROJECTILE - CREATE
// ============================================================
// the things bosses throw. made by the enemy_boss script, which hands
// it these values when it is created:
//   kind        "wave" (the skeleton's frost crescent) or "skull" (the cultist's)
//   caster      the boss that threw it
//   damage, spd, hit_radius
//   wave:       dir, life
//   skull:      orbit_ang, orbit_r, launch_at (frames until it launches)
// the defaults below are only used if one is placed by hand for testing.
// ============================================================

if (!variable_instance_exists(id, "kind"))       kind       = "wave";
if (!variable_instance_exists(id, "caster"))     caster     = noone;
if (!variable_instance_exists(id, "damage"))     damage     = global.enemy_stats.boss_projectile.damage;
if (!variable_instance_exists(id, "spd"))        spd        = 4;
if (!variable_instance_exists(id, "hit_radius")) hit_radius = 24;
if (!variable_instance_exists(id, "dir"))        dir        = 0;
if (!variable_instance_exists(id, "life"))       life       = 110;
if (!variable_instance_exists(id, "orbit_ang"))  orbit_ang  = 0;
if (!variable_instance_exists(id, "orbit_r"))    orbit_r    = 56;
if (!variable_instance_exists(id, "launch_at"))  launch_at  = 60;

// frames since it was created (or since it launched)
timer = 0;

// a wave is already flying. a skull first circles the boss, then launches.
launched = (kind == "wave");

// how far in front of the sprite's middle the hurt area is
hit_off = 0;

// how high the sprite is drawn above its spot on the ground
lift = 26;

if (kind == "wave")
{
    sprite_index = boss_wave_spr;
    hit_off = 14;
    lift = 24;
}
else
{
    sprite_index = boss_skull_spr;
}

// the frame is picked by hand when it is drawn
image_speed = 0;
