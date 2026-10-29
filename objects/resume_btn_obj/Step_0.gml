var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

hovered = point_in_rectangle(
    mx, my,
    gui_x+button_decrease, gui_y,
    gui_x + button_w-button_decrease,
    gui_y + button_h
);

if (hovered && mouse_check_button_pressed(mb_left)) {
   global.gameIsPaused = false;
}
