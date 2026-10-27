// ============================================================
// MAGIC CIRCLE - DRAW
// ============================================================

// Nothing to draw yet (or anymore).
if (alpha <= 0.01)
{
    exit;
}

var _size = scale * circle_scale;

// A faint filled disc shows the area the spell will hit,
// so the player can see where to avoid standing.
draw_set_alpha(alpha * 0.18);
draw_circle_colour(x, y, hit_radius * scale, colour, colour, false);
draw_set_alpha(1);

// The magic circle with the star, tinted with the spell's color.
draw_sprite_ext(magic_circle_spr, 0, x, y, _size, _size, spin, colour, alpha);

// A soft glow on top (added light).
gpu_set_blendmode(bm_add);
draw_sprite_ext(magic_circle_spr, 0, x, y, _size, _size, spin, colour, alpha * 0.35);

// A quick flash that spreads outward the moment the spell is released.
if (phase == 1 && timer < 10)
{
    var _flash = 1 - timer / 10;
    var _flash_size = _size * (1 + timer * 0.05);
    draw_sprite_ext(magic_circle_spr, 0, x, y, _flash_size, _flash_size, -spin, colour, _flash * 0.8);
}

// Put the normal drawing mode back.
gpu_set_blendmode(bm_normal);
