// You can write your code in this editor

var col = hovered ? global.hover_color : c_white;

draw_sprite_ext(
    sprite_index, 0,
    gui_x, gui_y,
    button_w / sprite_width,
    button_h / sprite_height,
    0, col, 1
);

draw_button_label(gui_x, gui_y, button_w, button_h, label, col, label_scale);

