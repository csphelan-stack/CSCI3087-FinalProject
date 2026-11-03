if (!audio_is_playing(snd_menu_music)) {
    audio_stop_sound(snd_game_music);
    audio_play_sound(snd_menu_music, 10, true);
}




// ---------- Window ----------
// If fullscreen only worked for you using the alarm fix, replace this line
// with: alarm[0] = 1;  (and keep your Alarm 0 event)
window_set_fullscreen(true);
is_fs = true;

// ---------- GUI size (matches the arena: 640x360 base * 1.2) ----------
display_set_gui_size(768, 432);

// Same hover color as the pause menu (guarded so it's only set once)
if (!variable_global_exists("hover_color")) {
    global.hover_color = c_teal;
}

// One sprite for every button so they all match
btn_sprite = gui_dark_button_grey_spr;

// ---------- Font (same guard as Room_controller_object, so it's only created once) ----------
if (!variable_global_exists("font_medieval")) {
    global.font_medieval = font_add_sprite_ext(gui_font_medieval_spr, " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,!?:;-+'\"()/%&*_", true, 1);
}

// ---------- Menu setup ----------
menu_items = ["Play", "Fullscreen: On", "Exit Game"];
selected = -1;   // nothing highlighted until the mouse or keyboard picks something

btn_w   = 240;
btn_h   = 72;
btn_gap = 16;
btn_start_y = display_get_gui_height() * 0.45;   // center of the first button

// Must come AFTER display_set_gui_size so the mouse coordinates are correct
prev_mx = device_mouse_x_to_gui(0);
prev_my = device_mouse_y_to_gui(0);

// ---------- What each button does ----------
activate_item = function(_index) {
    switch (_index) {
        case 0: // Play
		    audio_stop_sound(snd_menu_music);
            room_goto(Collesium);
            break;
        case 1: // Toggle fullscreen
            is_fs = !is_fs;
            window_set_fullscreen(is_fs);
            menu_items[1] = is_fs ? "Fullscreen: On" : "Fullscreen: Off";
            break;
        case 2: // Exit
            game_end();
            break;
    }
}