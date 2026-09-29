var col = hovered ? c_yellow : c_white;

draw_sprite_ext(
    sprite_index, 0,
    gui_x, gui_y,
    button_w / sprite_width,
    button_h / sprite_height,
    0, col, 1
);

