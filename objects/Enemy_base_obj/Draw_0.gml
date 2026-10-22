/// @desc - Enemy healthbar

draw_self();

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