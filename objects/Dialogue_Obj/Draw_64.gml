if (dialogue_in_progress && index < array_length(lines)) {

    // portrait
    var _slot_w = sprite_get_width(MCpotraitSpr) * scale_potrait;   // same slot the old portrait used
var _slot_h = dialogue_height;

if (is_array(portrait_crop)) {
    // backing panel behind the face
    draw_sprite_stretched(dialogue_spr, 0, potrait_x, potrait_y, _slot_w, _slot_h);

    // scale the face to fit the slot, centred
    var _s  = min(_slot_w / portrait_crop[2], _slot_h / portrait_crop[3]);
    var _dx = potrait_x + (_slot_w - portrait_crop[2] * _s) / 2;
    var _dy = potrait_y + (_slot_h - portrait_crop[3] * _s) / 2;

    draw_sprite_part_ext(portrait_spr, floor(current_time / 400) mod sprite_get_number(portrait_spr), portrait_crop[0], portrait_crop[1], portrait_crop[2], portrait_crop[3], _dx, _dy, _s, _s, c_white, 1);
} else if (portrait_spr == MCpotraitSpr) {
    draw_sprite_ext(portrait_spr, 0, potrait_x, potrait_y, scale_potrait, scale_potrait, 0, c_white, 1);
}

    // box
    draw_sprite_stretched(dialogue_spr, 0, dialogue_box_x, dialogue_box_y, dialogue_width, dialogue_height);

    // name
    draw_menu_text(dialogue_box_x + 16, dialogue_box_y + 16, speaker, make_colour_rgb(230, 190, 90), 2, fa_left);

    // text, wrapped
    var _scale = 1.5;
    draw_set_font(global.font_medieval);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_text_ext_transformed(dialogue_box_x + 16, dialogue_box_y + 34, string_copy(lines[index], 1, floor(shown)), 18, (dialogue_width - 32) / _scale, _scale, _scale, 0);
	
}

