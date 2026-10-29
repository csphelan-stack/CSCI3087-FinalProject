//This is where we draw the 3-5 options and show them on screen



//darken everything behind the cards (the cards draw after this, so they stay on top)
if (bg_alpha > 0.01) {
	draw_set_alpha(bg_alpha);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
	draw_set_alpha(1);
	draw_set_colour(c_white);
}

//title only while picking (the big card covers that spot)
if (phase == "choose") {
	draw_set_font(global.font_medieval);

	draw_text_ext_transformed_colour(card_text_x,card_text_y,card_text,text_sep,100,3,3,0,text_colour,text_colour,text_colour,text_colour,.90);
}


