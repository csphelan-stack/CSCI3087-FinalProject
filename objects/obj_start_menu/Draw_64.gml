// Match the arena's GUI size (640x360 base * 1.2 scaling) so the pixel font looks the same here
display_set_gui_size(768, 432);


// Same font, same guard as the controller, so it only gets created once
if (!variable_global_exists("font_medieval")) {
    global.font_medieval = font_add_sprite_ext(gui_font_medieval_spr, " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,!?:;-+'\"()/%&*_", true, 1);
}



var _count = array_length(menu_items);
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();


// Dim the art so buttons stay readable
draw_set_alpha(0.35);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);
draw_set_alpha(1);

// Title
if (variable_global_exists("font_medieval")) {
    draw_set_font(global.font_medieval);
}
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
// Title drawn in pixel art
// draw_text_transformed(_gw/2, _gh * 0.22, "YOUR GAME TITLE", 2, 2, 0);

// Buttons
for (var i = 0; i < _count; i++) {
    var _cy  = btn_start_y + i * (btn_h + btn_gap);
    var _sel = (i == selected);
    var _col = _sel ? global.hover_color : c_white;

    draw_sprite_stretched_ext(btn_sprite, 0,
        _gw/2 - btn_w/2, _cy - btn_h/2, btn_w, btn_h, _col, 1);

    draw_set_color(_col);
    draw_text_transformed(_gw/2, _cy, menu_items[i], 2, 2, 0);
}
draw_set_color(c_white);

/* OG button loop
// Buttons
for (var i = 0; i < _count; i++) {
    var _cy = _start_y + i * (btn_h + btn_gap);
    var _sel = (i == selected);

    draw_set_color(_sel ? c_orange : c_dkgray);
    draw_set_alpha(_sel ? 0.9 : 0.7);
    draw_roundrect(_gw/2 - btn_w/2, _cy - btn_h/2, _gw/2 + btn_w/2, _cy + btn_h/2, false);

    draw_set_alpha(1);
    draw_set_color(_sel ? c_black : c_white);
    draw_text(_gw/2, _cy, menu_items[i]);
}
*/

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);