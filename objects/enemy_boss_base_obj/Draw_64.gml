// ============================================================
// BOSS BASE - DRAW GUI
// ============================================================
// the boss health bar at the top of the screen.

// No bar once the boss is dead.
if (state == ENEMY_STATE.DEAD)
{
    exit;
}

var _gui_w = display_get_gui_width();

// Size and place of the bar.
var _w = min(_gui_w * 0.6, 420);
var _h = 12;
var _x = (_gui_w - _w) / 2;
var _y = 26;

// How much health is left (0 to 1).
var _pct = clamp(hp / max(total_hp, 1), 0, 1);

// The boss's name above the bar.
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_colour(c_black);
draw_text(_gui_w / 2 + 1, _y - 3, boss_name);
draw_set_colour(boss_accent);
draw_text(_gui_w / 2, _y - 4, boss_name);

// The bar: dark back, colored health, a mark at half health (when it gets enraged).
draw_set_colour(make_colour_rgb(16, 12, 20));
draw_rectangle(_x - 3, _y - 3, _x + _w + 3, _y + _h + 3, false);

draw_set_colour(make_colour_rgb(50, 40, 56));
draw_rectangle(_x, _y, _x + _w, _y + _h, false);

draw_set_colour(boss_accent);

if (boss_enraged)
{
    // Enraged: the bar flashes.
    draw_set_colour(merge_colour(boss_accent, c_white, 0.3 + 0.3 * sin(current_time * 0.012)));
}

draw_rectangle(_x, _y, _x + _w * _pct, _y + _h, false);

draw_set_colour(c_black);
draw_line(_x + _w / 2, _y, _x + _w / 2, _y + _h);

// Put the drawing settings back to normal.
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
