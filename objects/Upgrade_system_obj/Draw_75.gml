
	//confirm question + Yes / No (Draw GUI End, so it's on top of the cards)
	if (phase == "confirm") {
		draw_set_font(global.font_medieval);

		draw_set_halign(fa_center);
		draw_set_colour(c_white);
		draw_text_transformed(display_get_gui_width() / 2, prompt_y, "Take " + chosen.upg.name + "?", 2, 2, 0);
		draw_set_halign(fa_left);

		draw_set_colour(yes_hover ? global.hover_color : c_white);
		draw_text_transformed(yes_x, btn_y, "Yes", btn_scale, btn_scale, 0);
		draw_set_colour(no_hover ? global.hover_color : c_white);
		draw_text_transformed(no_x, btn_y, "No", btn_scale, btn_scale, 0);
	}

	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);

	draw_sprite(gui_cursor_spr, 0, _mx, _my);

	draw_set_colour(c_white);
