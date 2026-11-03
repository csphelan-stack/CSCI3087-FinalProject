// ============================================================
// MAGIC FX - STEP
// ============================================================

// Do nothing while the game is paused.
if (global.gameIsPaused)
{
    exit;
}

// A burst can be told to wait before it starts (so a big spell erupts bit by bit).
if (start_delay > 0)
{
    start_delay--;
    exit;
}

timer++;

if (kind == "orb")
{
    // ========================================================
    // ORB
    // ========================================================

    // Stay on the enemy's body while it moves or gets pushed around.
    if (instance_exists(caster))
    {
        x = (caster.bbox_left + caster.bbox_right) / 2;
        y = (caster.bbox_top + caster.bbox_bottom) / 2;
    }

    if (!fading)
    {
        // Is the caster still charging the spell?
        var _charging = false;

        if (instance_exists(caster))
        {
            _charging = (caster.state == ENEMY_STATE.ATTACK && !caster.attack_hit_done);
        }

        // The orb goes away when the spell is released (the hit frame
        // has passed) or when the caster is hurt or killed.
        if (!_charging)
        {
            fading = true;
            fade_timer = 0;
        }
    }
    else
    {
        fade_timer++;

        if (fade_timer >= fade_time)
        {
            instance_destroy();
        }
    }
}
else
{
    // ========================================================
    // BURST
    // ========================================================

    // Play the effect once, then remove it.
    if (timer >= sprite_get_number(effect_sprite) * frame_time)
    {
        instance_destroy();
    }
}
