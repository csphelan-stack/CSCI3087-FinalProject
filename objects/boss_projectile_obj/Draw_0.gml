// ============================================================
// BOSS PROJECTILE - DRAW
// ============================================================

// A small shadow on the ground shows where it really is,
// so the player can judge whether it will hit.
draw_set_alpha(0.3);
draw_set_colour(c_black);
draw_ellipse(x - 8, y - 3, x + 8, y + 3, false);
draw_set_alpha(1);
draw_set_colour(c_white);

// The angle, kept between 0 and 360.
var _angle = ((dir mod 360) + 360) mod 360;

// Skulls fly lower once they have launched.
var _lift = lift;

if (kind == "skull" && launched)
{
    _lift = 16;
}

if (kind == "wave")
{
    var _frame = floor(timer * 0.25) mod 4;

    draw_sprite_ext(boss_wave_spr, _frame, x, y - _lift, 1, 1, _angle, c_white, 1);

    // A soft glow on top (added light).
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(boss_wave_spr, _frame, x, y - _lift, 1, 1, _angle, make_colour_rgb(110, 205, 255), 0.35);
    gpu_set_blendmode(bm_normal);
}
else
{
    var _frame = floor(timer * 0.3) mod 4;

    // Keep the skull the right way up when it flies to the left.
    var _flip = 1;

    if (_angle > 90 && _angle < 270)
    {
        _flip = -1;
    }

    draw_sprite_ext(boss_skull_spr, _frame, x, y - _lift, 1.5, 1.5 * _flip, _angle, c_white, 1);

    gpu_set_blendmode(bm_add);
    draw_sprite_ext(boss_skull_spr, _frame, x, y - _lift, 1.8, 1.8 * _flip, _angle, make_colour_rgb(120, 235, 70), 0.4);
    gpu_set_blendmode(bm_normal);
}
