// ============================================================
// MAGIC FX - DRAW
// ============================================================

// A burst that is still waiting to start is not drawn yet.
if (start_delay > 0)
{
    exit;
}

if (kind == "orb")
{
    // ========================================================
    // ORB
    // ========================================================

    // The orb grows while the spell charges and pulses gently.
    var _grow = clamp(timer / max(grow_time, 1), 0, 1);
    var _size = orb_scale * lerp(0.35, 1, _grow) * (1 + 0.12 * sin(timer * 0.5));
    var _alpha = 0.95;

    // When the spell is released, the orb flares outward and fades.
    if (fading)
    {
        var _fade = fade_timer / fade_time;
        _size *= 1 + _fade * 0.9;
        _alpha *= 1 - _fade;
    }

    // The orb itself, tinted with the spell's color.
    draw_sprite_ext(magic_orb_spr, 0, x, y, _size, _size, 0, colour, _alpha);

    // A soft glow around it (added light).
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(magic_orb_spr, 0, x, y, _size * 1.4, _size * 1.4, 0, colour, _alpha * 0.45);
    gpu_set_blendmode(bm_normal);
}
else
{
    // ========================================================
    // BURST
    // ========================================================

    // Which frame of the effect is showing right now.
    var _frame = min(floor(timer / frame_time), sprite_get_number(effect_sprite) - 1);

    draw_sprite_ext(effect_sprite, _frame, x, y, 1, 1, 0, c_white, 1);

    // The bright kinds of magic get a little extra glow on top.
    if (element == MAGIC_ELEMENT.LIGHTNING || element == MAGIC_ELEMENT.LIGHT || element == MAGIC_ELEMENT.FIRE)
    {
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(effect_sprite, _frame, x, y, 1, 1, 0, colour, 0.35);
        gpu_set_blendmode(bm_normal);
    }
}
