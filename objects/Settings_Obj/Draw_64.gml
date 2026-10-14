


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
	
		
	if (surface_exists(pause_surface)) { draw_surface(pause_surface, 0, 0); } 
// Draw a semi-transparent overlay 
draw_set_alpha(0.5); 
draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(), c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

draw_sprite_stretched_ext(background_spr,0,startx_b,starty_b,width_settings_background,height_settings_background,c_white,.9);



    draw_set_alpha(1);

	if (menu_page == "settings") draw_settings_page();
	else if (menu_page == "options") draw_options_page();
	else {
		// title centered at the top of the frame
		draw_button_label(startx_b, starty_b + 50, width_settings_background, 60, "Paused", c_white, 3);
	}

	
	
	
}

draw_buttons_settings();