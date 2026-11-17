//If the game is paused
// return the mouse's x locations and its y location into two seperate variables.
// using these variables draw the mouse cursor sprite on top of where the x and y positions are
// moving it with any changes (this is done automatically since this event continously runs once the game is paused.
//set the color to white. BASE COLOR
if(global.gameIsPaused){
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);

	draw_sprite(gui_cursor_spr, 0, _mx, _my);

	draw_set_colour(c_white);
}