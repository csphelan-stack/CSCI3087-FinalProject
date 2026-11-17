




if (global.gameIsPaused) exit;

//"choose" needs nothing here: the cards handle hover/flip/click themselves
switch (phase) {

	case "confirm":
		//darken the background, grow the picked card into the middle
		//(lerp moves 20% of the way each step, so it glides in fast then slows down)
		bg_alpha = lerp(bg_alpha, 0.7, 0.15);
		chosen.card_x = lerp(chosen.card_x, big_x, 0.2);
		chosen.card_y = lerp(chosen.card_y, big_y, 0.2);
		chosen.card_w = lerp(chosen.card_w, big_w, 0.2);
		chosen.card_h = lerp(chosen.card_h, big_h, 0.2);

		//fade the cards that weren't picked
		with (upgrade_card_obj) {
			if (id != other.chosen) card_alpha = lerp(card_alpha, 0.15, 0.15);
		}

		//Yes / No buttons (measure the text with the same font and scale it's drawn with)
		draw_set_font(global.font_medieval);
		var _mx = device_mouse_x_to_gui(0);
		var _my = device_mouse_y_to_gui(0);
		yes_hover = point_in_rectangle(_mx, _my, yes_x, btn_y, yes_x + string_width("Yes") * btn_scale, btn_y + string_height("Yes") * btn_scale);
		no_hover  = point_in_rectangle(_mx, _my, no_x,  btn_y, no_x  + string_width("No")  * btn_scale, btn_y + string_height("No")  * btn_scale);

		//only take clicks once the card has finished growing
		//(stops the click that picked the card from also landing on Yes)
		var _grown = abs(chosen.card_w - big_w) < 1;

		if (_grown && mouse_check_button_pressed(mb_left)) {
			if (yes_hover) {
				applyUpgrade(chosen.upg);
			    audio_play_sound(snd_burn, 20, false);
				//snap to the big size so the burn lines up with the pixels
				chosen.card_x = big_x;
				chosen.card_y = big_y;
				chosen.card_w = big_w;
				chosen.card_h = big_h;
				chosen.burning = true;
				phase = "burn";
			}
			else if (no_hover) {
				phase = "back";
			}
		}
		break;

	case "back":
		//said No: background clears, card shrinks back into the row, the others come back
		bg_alpha = lerp(bg_alpha, 0, 0.2);
		chosen.card_x = lerp(chosen.card_x, chosen.home_x, 0.25);
		chosen.card_y = lerp(chosen.card_y, chosen.home_y, 0.25);
		chosen.card_w = lerp(chosen.card_w, chosen.home_w, 0.25);
		chosen.card_h = lerp(chosen.card_h, chosen.home_h, 0.25);
		with (upgrade_card_obj) card_alpha = lerp(card_alpha, 0.9, 0.2);

		//close enough: snap it home and let the player choose again
		if (abs(chosen.card_w - chosen.home_w) < 1) {
			chosen.card_x = chosen.home_x;
			chosen.card_y = chosen.home_y;
			chosen.card_w = chosen.home_w;
			chosen.card_h = chosen.home_h;
			chosen.depth = depth - 1;
			chosen = noone;
			bg_alpha = 0;
			with (upgrade_card_obj) card_alpha = 0.9;
			phase = "choose";
		}
		break;

	case "burn":
		chosen.burn += 1 / 45;   //about 3/4 of a second

		//the other cards: stay dim if there's another pick to make, fade away if this was the last one
		var _fade_to = (picks_left > 1 && cards_left > 1) ? 0.15 : 0;
		with (upgrade_card_obj) {
			if (id != other.chosen) card_alpha = lerp(card_alpha, _fade_to, 0.15);
		}

		//all burnt
		if (chosen.burn >= 1.3) {
			picks_left -= 1;
			cards_left -= 1;

			if (picks_left <= 0 || cards_left <= 0) {
				//no picks (or cards) left: end the event (the player's Step destroys this object and the cards when the flag is off)
				main_character_Obj.event_go_upgrade = false;
			}
			else {
				//another pick: the rest of the cards slide together, then the player chooses again
				regroup_row(chosen);
				instance_destroy(chosen);
				chosen = noone;
				phase = "regroup";
			}
		}
		break;

	case "regroup":
		//the background clears and the cards that are left slide into their new spots and light back up
		bg_alpha = lerp(bg_alpha, 0, 0.2);

		var _done = true;
		with (upgrade_card_obj) {
			card_x = lerp(card_x, home_x, 0.2);
			card_alpha = lerp(card_alpha, 0.9, 0.2);
			if (abs(card_x - home_x) > 1 || card_alpha < 0.88) _done = false;
		}

		//close enough: snap them in place and let the player choose again
		if (_done) {
			with (upgrade_card_obj) {
				card_x = home_x;
				card_alpha = 0.9;
			}
			bg_alpha = 0;
			phase = "choose";
		}
		break;
}
