// if the game is paused
// set the alpha to 0.3
// then put a blue color
// after this draw a rectangle with this color and alpha that covers the whole screen.
if(global.gameIsPaused){
	draw_set_alpha(0.3);
	draw_set_colour(c_blue);
	draw_rectangle(
		0,
		0,
		display_get_gui_width(),
		display_get_gui_height(),
		true
	);

// If the pause_surface exits then draw it onto the screen
	if (surface_exists(pause_surface)) { draw_surface(pause_surface, 0, 0); }
// Draw a semi-transparent overlay
// then use the rectangle to color this overlay black and cover the whole screen
draw_set_alpha(0.5);
draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(), c_black, c_black, c_black, c_black, false);
//use the set alpha to bring back to normal alpha 1
draw_set_alpha(1);
//then draw the background_spr using the startx and starty we set in the create along with the width and height set in create
// choose white for base color. and 0.9 for a slightly transparent feel so we can see behind a little
draw_sprite_stretched_ext(background_spr,0,startx_b,starty_b,width_settings_background,height_settings_background,c_white,.9);


//double check that alpha is 1 since we changed it to 0.9 above (not technically but still a good practice).
	draw_set_alpha(1);

//If the current menu_page is setting then call the draw_settings_page script
// if options draw options page draw script.
//else we draw the main page that shows the choices of resume game, setting, optionsadn has the exit button.
	if (menu_page == "settings") draw_settings_page();
	else if (menu_page == "options") draw_options_page();
	else {
		// title centered at the top of the frame
		draw_button_label(startx_b, starty_b + 50, width_settings_background, 60, "Paused", c_white, 3);
	}

}
//call the buttons_settings draw script.
draw_buttons_settings();