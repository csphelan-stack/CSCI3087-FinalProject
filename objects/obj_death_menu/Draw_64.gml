var _count = array_length(menu_items);
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

// Dark red tint over whatever is behind it
draw_set_alpha(0.6);
draw_set_color(make_colour_rgb(40, 0, 0));
draw_rectangle(0, 0, _gw, _gh, false);
draw_set_alpha(1);

draw_set_font(global.font_medieval);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

// Title
draw_set_color(c_red);
draw_text_transformed(_gw/2, _gh * 0.22, "YOU DIED", 4, 4, 0);

// Buttons
for (var i = 0; i < _count; i++) {
    var _cy  = btn_start_y + i * (btn_h + btn_gap);
    var _col = (i == selected) ? global.hover_color : c_white;

    draw_sprite_stretched_ext(btn_sprite, 0,
        _gw/2 - btn_w/2, _cy - btn_h/2, btn_w, btn_h, _col, 1);

    draw_set_color(_col);
    draw_text_transformed(_gw/2, _cy, menu_items[i], 2, 2, 0);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);