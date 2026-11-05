// Character_potrait_drawing: draw_character_potrait() draws the player portrait and the
// dialogue box behind it. Run on Dialogue_Obj in a draw event; no arguments.
function draw_character_potrait(){


	draw_sprite_ext(MCpotraitSpr,0,potrait_x,potrait_y,scale_potrait,scale_potrait,0,c_white,0.95);

	draw_sprite_stretched_ext(dialogue_spr,0,dialogue_box_x,dialogue_box_y,dialogue_width,dialogue_height,c_white,0.95);




}