//This is where we draw the 3-5 options and show them on screen

draw_set_font(global.font_medieval);

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
	var _up_y = +20;
	//draw_text_ext_transformed_colour(card_text_x,card_text_y + _up_y,card_text,text_sep,100,3,3,0,text_colour,text_colour,text_colour,text_colour,.90);
	draw_menu_text(card_text_x +10,card_text_y + _up_y,card_text,text_colour,3,fa_none);

	//how many cards are still to take, just above the row
	var _picks_text = (picks_left == 1) ? "1 card left to take" : string(picks_left) + " cards to take";
	draw_menu_text(display_get_gui_width() / 2, card_start_y - 24, _picks_text, c_aqua, 2, fa_center);
}


