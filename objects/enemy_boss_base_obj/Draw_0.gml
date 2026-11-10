// ============================================================
// BOSS BASE - DRAW
// ============================================================

// The health bar needs the full health (set once).
if (!hp_initialized)
{
    total_hp = hp;
    hp_initialized = true;
}

// The middle and size of the boss's body.
var _cx = (bbox_left + bbox_right) / 2;
var _cy = (bbox_top + bbox_bottom) / 2;
var _half_w = (bbox_right - bbox_left) / 2;

// ---------- shadow on the ground ----------
draw_set_alpha(0.35);
draw_set_colour(c_black);
draw_ellipse(x - _half_w * 0.9, y - _half_w * 0.26, x + _half_w * 0.9, y + _half_w * 0.26, false);
draw_set_alpha(1);
draw_set_colour(c_white);

// ---------- three orbs of the boss's magic circling it ----------
// they spin faster when the boss is enraged.
var _spin = 2;

if (boss_enraged)
{
    _spin = 3.4;
}

// The orbs that are behind the boss are drawn first.
for (var _i = 0; _i < 3; _i++)
{
    var _a = boss_aura_t * _spin + _i * 120;
    var _ox = _cx + lengthdir_x(_half_w + 16, _a);
    var _oy = _cy + lengthdir_y((_half_w + 16) * 0.35, _a) - 6;

    if (lengthdir_y(1, _a) < 0)
    {
        draw_sprite_ext(magic_orb_spr, 0, _ox, _oy, 0.7, 0.7, 0, boss_accent, 0.85);
    }
}

// ---------- the boss ----------
// A worn-out boss is drawn darker and sags a little (it is breathing hard).
if (state == ENEMY_STATE.EXHAUSTED)
{
    draw_sprite_ext(sprite_index, image_index, x, y + 1 + sin(boss_aura_t * 0.12), 1, 1, 0, make_colour_rgb(135, 135, 160), 1);
}
else
{
    draw_self();
}

// A pulse of color while the boss charges a spell, and red while it
// charges the attack the player has to dodge.
if (state == ENEMY_STATE.ATTACK && is_struct(boss_cur) && boss_t < boss_cur.windup)
{
    var _glow = make_colour_rgb(255, 60, 40);

    if (boss_attack == BOSS_ATTACK.MAGIC || boss_attack == BOSS_ATTACK.AREA)
    {
        _glow = boss_accent;
    }

    gpu_set_blendmode(bm_add);
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, _glow, 0.18 + 0.14 * sin(boss_t * 0.5));
    gpu_set_blendmode(bm_normal);
}

// White flash when the boss takes a hit.
if (boss_flash > 0 && (boss_flash mod 4) < 2)
{
    gpu_set_fog(true, c_white, 0, 1);
    draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_white, 0.75);
    gpu_set_fog(false, c_white, 0, 1);
}

// The orbs that are in front of the boss.
for (var _i = 0; _i < 3; _i++)
{
    var _a = boss_aura_t * _spin + _i * 120;
    var _ox = _cx + lengthdir_x(_half_w + 16, _a);
    var _oy = _cy + lengthdir_y((_half_w + 16) * 0.35, _a) - 6;

    if (lengthdir_y(1, _a) >= 0)
    {
        draw_sprite_ext(magic_orb_spr, 0, _ox, _oy, 0.7, 0.7, 0, boss_accent, 0.85);
    }
}

// ---------- WARNING sign: "dodge or parry this one!" ----------
if (state == ENEMY_STATE.ATTACK && boss_attack == BOSS_ATTACK.SPECIAL && is_struct(boss_cur) && boss_t < boss_cur.windup)
{
    draw_sprite_ext(boss_warning_spr, floor(boss_aura_t * 0.2) mod 4, _cx, bbox_top - 4, 1.5, 1.5, 0, c_white, 1);
}
