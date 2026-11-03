// how wide the card is right now (1 = full, 0 = edge-on)
var _squash = abs(cos(flip * pi));
var _w = card_w * _squash;

// squash from the middle so it turns in place
var _cx = card_x + card_w / 2;

// first half of the flip shows the back, second half the front
var _spr = upg.spriteB;
var _img = upg.indexB;
if (flip >= 0.5) {
	_spr = upg.spriteF;
	_img = upg.indexF;
}

if (!burning) {
	draw_sprite_stretched_ext(_spr, _img, _cx - _w / 2, card_y, _w, card_h, c_white, card_alpha);
}
else {
	//burn from the bottom up, one pixel column at a time
	var _cols = sprite_get_width(_spr);    //23
	var _rows = sprite_get_height(_spr);   //35
	var _s = card_w / _cols;               //screen pixels per card pixel

	for (var c = 0; c < _cols; c++) {
		//how much of this column is left
		var _left = clamp(1 - burn + burn_offset[c], 0, 1);
		var _h = floor(_rows * _left);
		if (_h <= 0) continue;

		//the part of the column that hasn't burnt yet
		draw_sprite_part_ext(_spr, _img, c, 0, 1, _h, card_x + c * _s, card_y, _s, _s, c_white, card_alpha);

		//the glowing edge where the fire is right now
		if (_h < _rows) {
			var _ey  = card_y + _h * _s;
			var _col = (c mod 2 == 0) ? make_colour_rgb(255, 200, 40) : make_colour_rgb(230, 90, 20);
			draw_rectangle_colour(card_x + c * _s, _ey - _s, card_x + (c + 1) * _s - 1, _ey - 1, _col, _col, _col, _col, false);
		}
	}
}

// read the card: only once it's fully face up and the mouse is on it
if (flip >= 1 && hovered) {
	draw_set_font(global.font_medieval);

	var _text   = upg.name + "\n\n" + upg.desc;
	var _text_w = card_w * 3;   // how wide a line can get before it wraps
	var _margin = 8;            // gap to keep from the screen edge

	// centre the text box under the card...
	var _text_x = card_x + card_w / 2 - _text_w / 2;

	// ...then push it back on screen if it hangs off either side
	_text_x = clamp(_text_x, _margin, display_get_gui_width() - _text_w - _margin);

	draw_text_ext(_text_x, card_y + card_h + 8, _text, 14, _text_w);
}