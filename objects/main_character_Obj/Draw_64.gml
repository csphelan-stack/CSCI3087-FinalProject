/// @desc Health Bar

healthbar_x = display_get_gui_width() / 2;
healthbar_y = display_get_gui_height() - 82;

draw_sprite(
    gui_dark_bar_frame_gold_spr_background,
    0,
    healthbar_x,
    healthbar_y
);

draw_sprite_stretched(
    healthbar,
    0,
    healthbar_x,
    healthbar_y,
    (hp / total_hp) * healthbar_width,
    healthbar_height
);

draw_sprite(
    gui_dark_bar_frame_gold_spr_border,
    0,
    healthbar_x,
    healthbar_y
);
