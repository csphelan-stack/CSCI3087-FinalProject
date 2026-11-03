// GUI size matches the arena and start screen
display_set_gui_size(768, 432);

// The arena hides the system cursor, so show it again here
window_set_cursor(cr_default);

// Same font and hover color guards as the start menu
if (!variable_global_exists("font_medieval")) {
    global.font_medieval = font_add_sprite_ext(gui_font_medieval_spr, " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,!?:;-+'\"()/%&*_", true, 1);
}
if (!variable_global_exists("hover_color")) {
    global.hover_color = c_teal;
}

menu_items = ["Restart", "Main Menu", "Exit Game"];
selected   = -1;

btn_sprite  = gui_dark_button_grey_spr;
btn_w       = 240;
btn_h       = 72;
btn_gap     = 16;
btn_start_y = display_get_gui_height() * 0.52;

prev_mx = device_mouse_x_to_gui(0);
prev_my = device_mouse_y_to_gui(0);

activate_item = function(_index) {
    switch (_index) {
        case 0: // Restart
            if (variable_global_exists("gameIsPaused")) global.gameIsPaused = false;
            room_goto(Collesium);
            break;
        case 1: // Main Menu
            if (variable_global_exists("gameIsPaused")) global.gameIsPaused = false;
            room_goto(rm_start);
            break;
        case 2: // Exit
            game_end();
            break;
    }
}