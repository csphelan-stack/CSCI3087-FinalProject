// ============================================================
// MAGIC CIRCLE - STEP
// ============================================================

// Do nothing while the game is paused.
if (global.gameIsPaused)
{
    exit;
}

timer++;
total_time++;

switch (phase)
{
    // ========================================================
    // 0 - CHARGING
    // ========================================================
    case 0:

        // Grow the circle in (starts fast, then slows down).
        var _grow = clamp(total_time / appear_time, 0, 1);
        scale = _grow * (2 - _grow);

        // How charged the spell is: 0 at the start, 1 on the release frame.
        charge = clamp(total_time / max(charge_time, 1), 0, 1);

        // The circle gets brighter and spins faster as it charges.
        alpha = lerp(0.5, 1, charge) * _grow;
        spin += lerp(1, 5, charge);

        if (released)
        {
            // The caster let the spell go: start erupting.
            phase = 1;
            timer = 0;
            alpha = 1;

            // Make the lightning / fire / earth / light / dark effect.
            // It is drawn in front of the characters so it covers the player.
            // A big spell makes several effects, spread over the circle.
            for (var _b = 0; _b < burst_count; _b++)
            {
                var _bx = x;
                var _by = y;
                var _wait = 0;

                // The first one is in the middle. The others land at random
                // spots inside the circle, a little later each.
                if (_b > 0)
                {
                    var _bang = random(360);
                    var _brad = sqrt(random(1)) * hit_radius * 0.82;
                    _bx = x + lengthdir_x(_brad, _bang);
                    _by = y + lengthdir_y(_brad, _bang);
                    _wait = irandom(burst_spread);
                }

                instance_create_depth(_bx, _by, depth - 40, magic_fx_obj, {
                    kind:          "burst",
                    element:       element,
                    colour:        colour,
                    effect_sprite: effect_sprite,
                    frame_time:    frame_time,
                    start_delay:   _wait
                });
            }
        }
        else
        {
            // Is the caster still winding up the spell?
            var _casting = false;

            if (instance_exists(caster))
            {
                _casting = (caster.state == ENEMY_STATE.ATTACK);
            }

            if (!_casting || total_time > life_limit)
            {
                // The caster was hurt, died or lost the attack before the release.
                // The spell falls apart.
                fizzled = true;
                fade_alpha = alpha;
                fade_scale = scale;
                phase = 2;
                timer = 0;
            }
        }

    break;


    // ========================================================
    // 1 - ERUPTING
    // ========================================================
    case 1:

        // The circle keeps spinning fast and pulses while the spell is out.
        spin += 6;
        scale = 1 + 0.06 * sin(timer * 0.6);

        // Hurt the player a few frames after the release.
        // (a big spell, like a lingering cloud, can hurt more than once)
        if (hits_done < hit_ticks && timer >= hit_delay + hits_done * tick_gap)
        {
            hits_done++;

            // Is the player standing inside the circle?
            var _player = collision_circle(x, y, hit_radius, main_character_Obj, false, true);

            if (_player != noone)
            {
                // Use the same damage function as the enemies' normal attacks,
                // so parry, blocking and invincibility frames all still work.
                // (the caster is passed in as the attacker)
                with (_player)
                {
                    Enemy_damage_applying(other.damage, other.caster);
                }
            }
        }

        // When the effect has finished playing, fade the circle away.
        if (timer >= erupt_time)
        {
            fade_alpha = alpha;
            fade_scale = scale;
            phase = 2;
            timer = 0;
        }

    break;


    // ========================================================
    // 2 - FADING
    // ========================================================
    case 2:

        var _fade = clamp(timer / fade_time, 0, 1);
        alpha = fade_alpha * (1 - _fade);

        // A fizzled spell also shrinks away.
        if (fizzled)
        {
            scale = fade_scale * (1 - 0.5 * _fade);
        }

        spin += 2;

        if (timer >= fade_time)
        {
            instance_destroy();
        }

    break;
}
