/// @desc Draws a circular cooldown indicator with an icon
/// @param {real} _cx        center x (GUI coords)
/// @param {real} _cy        center y (GUI coords)
/// @param {real} _r         radius in pixels
/// @param {real} _remaining frames left on the cooldown
/// @param {real} _total     full cooldown length in frames
/// @param {asset} _icon     sprite for the center (-1 for none)
function draw_cooldown_orb(_cx, _cy, _r, _remaining, _total, _icon = -1, _off_x = 0, _off_y = 0, _frame = 0) {

    var _ready = (_remaining <= 0);
    var _frac  = clamp(_remaining / max(_total, 1), 0, 1);

    // background disc
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_circle(_cx, _cy, _r, false);
    draw_set_alpha(1);

    // icon: full brightness when ready, faint afterimage while cooling down
    if (_icon != -1) {
        var _fit = 0.8;   // how much of the orb's diameter the icon fills
        var _s   = (_r * 2 * _fit) / max(sprite_get_width(_icon), sprite_get_height(_icon));
        var _ix = _cx - (sprite_get_width(_icon)  * _s) / 2 + sprite_get_xoffset(_icon) * _s + _off_x;
		var _iy = _cy - (sprite_get_height(_icon) * _s) / 2 + sprite_get_yoffset(_icon) * _s + _off_y;

        var _col   = _ready ? c_white : c_gray;   // slight darkening while on cooldown
        var _alpha = _ready ? 1 : 0.3;            // the afterimage opacity
        draw_sprite_ext(_icon, 0, _ix, _iy, _s, _s, 0, _col, _alpha);
    }

    // radial sweep over the part still on cooldown
    if (!_ready) {
        var _steps = 40;
        draw_primitive_begin(pr_trianglefan);
        draw_vertex_color(_cx, _cy, c_black, 0.55);
        for (var i = 0; i <= _steps; i++) {
            var _a = 90 - (360 * _frac * (i / _steps));
            draw_vertex_color(_cx + lengthdir_x(_r, _a), _cy + lengthdir_y(_r, _a), c_black, 0.55);
        }
        draw_primitive_end();
    }

    // ring: gold when ready, gray while cooling down
    draw_set_color(_ready ? c_yellow : c_gray);
    draw_circle(_cx, _cy, _r, true);

    // countdown seconds
    if (!_ready) {
        var _secs = ceil(_remaining / game_get_speed(gamespeed_fps));
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(_cx, _cy, string(_secs));
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }

    draw_set_color(c_white);
}