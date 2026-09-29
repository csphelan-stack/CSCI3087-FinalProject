


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


    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_text(40, 10, "  Paused:");

	
	
	
}

draw_buttons_settings();