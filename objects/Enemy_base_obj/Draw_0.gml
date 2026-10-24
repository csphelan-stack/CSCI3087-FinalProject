/// @desc - Enemy healthbar

draw_self();

// new enemies healthbar fix 
// lock in the real max HP once, after the child's Create has run
if (!hp_initialized) {
    total_hp = hp;
    hp_initialized = true;
}

// only show the bar once the enemy has taken damage
// (remove this "if" and its closing brace to always show it)
if (hp < total_hp) {

    var _w = 24;   // bar width in pixels
    var _h = 2;    // bar height in pixels

    // center the bar over the enemy, above the top of their hitbox
    var _cx = (bbox_left + bbox_right) / 2;
    var _x  = _cx - _w / 2;
    var _y  = bbox_top - 8;

    var _pct = clamp(hp / total_hp, 0, 1);

    // black outline
    draw_set_color(c_black);
    draw_rectangle(_x - 1, _y - 1, _x + _w, _y + _h, false);

    // empty portion
    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _w - 1, _y + _h - 1, false);

    // health portion
    if (_pct > 0) {
        draw_set_color(c_red);
        draw_rectangle(_x, _y, _x + (_w * _pct) - 1, _y + _h - 1, false);
    }

    draw_set_color(c_white); // reset so nothing drawn afterward is tinted
}

// USE FOR BUG FIXING INVIS ENEMIES
// TURN ON ENEMY HEALTH / TOTAL I.E. 10/10
/*
draw_text(x, y, string(hp) + "/" + string(total_hp));
*/

// ============================================================
// MAGIC VISUAL EFFECTS
// These effects are drawn in-world so each spell uses the same clear
// target circle/star, while the element changes the color and impact shape.
// ============================================================
if (magic_enabled)
{
    // The marker stays fixed on the last place the caster saw the player.
    if (state == ENEMY_STATE.ATTACK)
    {
        draw_sprite_ext(magic_target_spr, 0, magic_target_x, magic_target_y,
                        1, 1, 0, magic_color, 0.88);
    }

    // A small colored orb flashes above the caster at the start of the cast.
    if (state == ENEMY_STATE.ATTACK && magic_orb_timer > 0)
    {
        var _orb_alpha = clamp(magic_orb_timer / max(1, magic_orb_duration), 0.3, 1);
        draw_sprite_ext(magic_orb_spr, 0, x, y - 20,
                        1, 1, 0, magic_color, _orb_alpha);
        draw_set_color(c_white);
        draw_set_alpha(_orb_alpha);
        draw_circle(x, y - 20, 3, false);
        draw_set_alpha(1);
    }

    // Elemental energy bursts outward from the marked location on the hit frame.
    if (magic_effect_timer > 0)
    {
        var _mx = magic_target_x;
        var _my = magic_target_y;
        var _elapsed = magic_effect_duration - magic_effect_timer;
        var _fade = clamp(magic_effect_timer / 5, 0.15, 1);

        draw_set_alpha(_fade);
        draw_set_color(magic_color);
        draw_circle(_mx, _my, 8 + (_elapsed mod 6) * 2, false);

        switch (magic_element)
        {
            case "lightning":
                // Blue, jagged bolts leap from the rune into the air.
                draw_line(_mx - 2, _my + 5, _mx + 3, _my - 2);
                draw_line(_mx + 3, _my - 2, _mx - 4, _my - 8);
                draw_line(_mx - 4, _my - 8, _mx + 5, _my - 15);
                draw_line(_mx + 5, _my - 15, _mx + 1, _my - 24);
                draw_line(_mx - 12, _my + 3, _mx - 8, _my - 5);
                draw_line(_mx - 8, _my - 5, _mx - 13, _my - 12);
                draw_line(_mx + 11, _my + 3, _mx + 8, _my - 5);
                draw_line(_mx + 8, _my - 5, _mx + 13, _my - 12);
                draw_set_color(c_white);
                draw_line(_mx, _my + 3, _mx + 2, _my - 3);
            break;

            case "fire":
                // Three tongues of flame flare upward from the impact rune.
                draw_triangle(_mx - 16, _my + 8, _mx - 8, _my - 12, _mx, _my + 8, false);
                draw_triangle(_mx - 8, _my + 8, _mx + 1, _my - 21, _mx + 7, _my + 8, false);
                draw_triangle(_mx + 3, _my + 8, _mx + 12, _my - 13, _mx + 18, _my + 8, false);
                draw_set_color(c_yellow);
                draw_triangle(_mx - 7, _my + 5, _mx + 1, _my - 12, _mx + 5, _my + 5, false);
            break;

            case "earth":
                // Stone spikes erupt upward from the ground around the circle.
                draw_triangle(_mx - 19, _my + 8, _mx - 10, _my - 13, _mx - 2, _my + 8, false);
                draw_triangle(_mx - 8, _my + 8, _mx + 1, _my - 22, _mx + 10, _my + 8, false);
                draw_triangle(_mx + 7, _my + 8, _mx + 15, _my - 10, _mx + 21, _my + 8, false);
                draw_set_color(make_color_rgb(210, 195, 150));
                draw_line(_mx - 10, _my - 10, _mx - 7, _my + 3);
                draw_line(_mx + 1, _my - 18, _mx + 3, _my + 3);
            break;

            case "light":
                // Golden light rays burst out in all directions.
                draw_circle(_mx, _my, 15 + (_elapsed mod 5) * 2, false);
                for (var _ray = 0; _ray < 8; _ray++)
                {
                    var _a = _ray * 45 + 22;
                    draw_line(_mx + lengthdir_x(6, _a), _my + lengthdir_y(6, _a),
                              _mx + lengthdir_x(22 + (_elapsed mod 4) * 2, _a),
                              _my + lengthdir_y(22 + (_elapsed mod 4) * 2, _a));
                }
                draw_set_color(c_white);
                draw_circle(_mx, _my, 5, false);
            break;

            default:
                // Dark/necrotic energy spirals out in purple tendrils.
                draw_circle(_mx, _my, 12 + (_elapsed mod 5) * 2, false);
                draw_circle(_mx, _my, 18 + (_elapsed mod 4) * 2, false);
                for (var _tendril = 0; _tendril < 6; _tendril++)
                {
                    var _ta = _tendril * 60 + _elapsed * 7;
                    draw_line(_mx + lengthdir_x(5, _ta), _my + lengthdir_y(5, _ta),
                              _mx + lengthdir_x(21, _ta + 12), _my + lengthdir_y(21, _ta + 12));
                }
                draw_set_color(c_white);
                draw_circle(_mx, _my, 4, false);
            break;
        }

        draw_set_alpha(1);
        draw_set_color(c_white);
    }
}
