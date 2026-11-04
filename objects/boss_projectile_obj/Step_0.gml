// ============================================================
// BOSS PROJECTILE - STEP
// ============================================================

// Do nothing while the game is paused.
if (global.gameIsPaused)
{
    exit;
}

timer++;

// If the boss that threw this is gone, so is the projectile.
if (!instance_exists(caster))
{
    instance_destroy();
    exit;
}

// ============================================================
// A SKULL THAT HAS NOT LAUNCHED YET: it circles the boss
// ============================================================
if (!launched)
{
    // If the boss gets staggered before the skull launches, it fizzles.
    if (caster.state != ENEMY_STATE.ATTACK)
    {
        instance_destroy();
        exit;
    }

    orbit_ang += 4;

    x = caster.x + lengthdir_x(orbit_r, orbit_ang);
    y = caster.y + lengthdir_y(orbit_r * 0.5, orbit_ang);

    // Face along its path while circling.
    dir = orbit_ang + 90;

    // Time to launch: aim at where the player is RIGHT NOW.
    if (timer >= launch_at)
    {
        var _player = instance_nearest(x, y, main_character_Obj);

        if (_player != noone)
        {
            dir = point_direction(x, y, _player.x, _player.y);
        }

        launched = true;
        timer = 0;
    }

    exit;
}

// ============================================================
// FLYING
// ============================================================
x += lengthdir_x(spd, dir);
y += lengthdir_y(spd, dir);

// Did it reach the player?
var _hit = collision_circle(x + lengthdir_x(hit_off, dir), y + lengthdir_y(hit_off, dir), hit_radius, main_character_Obj, false, true);

if (_hit != noone)
{
    // Same damage function as every other enemy attack, so a parry or a
    // block works on it. (the boss is passed in as the attacker)
    with (_hit)
    {
        Enemy_damage_applying(other.damage, other.caster);
    }

    instance_destroy();
    exit;
}

// It disappears on a wall or when its time runs out.
if (place_meeting(x, y, obj_wall) || timer > life)
{
    instance_destroy();
}
