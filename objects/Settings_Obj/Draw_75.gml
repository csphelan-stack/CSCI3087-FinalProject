if(global.gameIsPaused){
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);

	draw_sprite(gui_cursor_spr, 0, _mx, _my);

	draw_set_colour(c_white);
}