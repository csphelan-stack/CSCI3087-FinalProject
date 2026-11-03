
//the point of the upgrade system is to change the main characters variables according 
//to the upgrades that have been unlocked or allowed.



/*
if(main_character_Obj.special_upgrade_available){
	u_special_upgrade_available = true;
}
else{
	u_special_upgrade_available = false;
}
*/

//only build the upgrade list the first time, so picks (upgrades_possible) aren't reset every time the cards open
if (!variable_global_exists("Character_Upgrades")) {
	Upgrade_system_data();
}






card_gap = 18;   //space between two cards (same spacing as before)
card_start_y =150;

multiple_size = 4;
card_height = 35 * multiple_size;
card_width = 23 *multiple_size;

card_border_sep = 0;

card_text_x = 100;
card_text_y= card_start_y - 100;
text_sep = 15; 
card_text = " 'Pick A Card        Any Card' ";
card_text_2 = "All Upgrades are Final";

text_colour = c_fuchsia;


//shuffling the cards after getting it from the upgradeCheckPossibleFunction
available_upgrades = [];
available_upgrades = upgradeCheckPossible();
shuffled_upgrades = [];
shuffled_upgrades = array_shuffle(available_upgrades);

card_number = irandom_range(3,5);   //whole number of cards
card_number = min(card_number, array_length(shuffled_upgrades));   //can't show more cards than there are upgrades left


//the event goes "choose" -> "confirm" -> "burn" (or "back" to "choose" if you say No)
phase  = "choose";
chosen = noone;      //the card that was clicked
bg_alpha = 0;        //how dark the background is

//the big card in the middle (a whole-number multiple so the pixels stay sharp)
big_mult = 6;
big_w = 23 * big_mult;
big_h = 35 * big_mult;
big_x = floor((display_get_gui_width() - big_w) / 2);
big_y = 24;

//Yes / No under the big card
btn_scale = 2;
prompt_y  = big_y + big_h + 12;
btn_y     = prompt_y + 36;
yes_x     = display_get_gui_width() / 2 - 80;
no_x      = display_get_gui_width() / 2 + 40;
yes_hover = false;
no_hover  = false;


// centre the row on the screen: how wide all the cards + the gaps between them are together
var _row_w = card_number * card_width + (card_number - 1) * card_gap;
var _row_x = floor((display_get_gui_width() - _row_w) / 2);   // left edge of the first card

// deal the cards: one card object per upgrade
for (var i = 0; i < card_number; i++) {
	var _c = instance_create_depth(0, 0, depth - 1, upgrade_card_obj);
	_c.upg    = shuffled_upgrades[i];
	_c.card_x = _row_x + i * (card_width + card_gap);   // each card is one card + one gap further right
	_c.card_y = card_start_y;
	_c.card_w = card_width;
	_c.card_h = card_height;

	//remember its spot in the row so "No" can put it back
	_c.home_x = _c.card_x;
	_c.home_y = card_start_y;
	_c.home_w = card_width;
	_c.home_h = card_height;
}