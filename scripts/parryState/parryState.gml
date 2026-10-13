function startParryState(){


    // runs ONCE when the parry button (X) is pressed
    state = PlayerState.PARRY;

	parry_dir = facing;
	parry_dir4 = round(parry_dir/90) mod 4;   // kept for later: the block sprite needs it when the guard is up

	parry_exhuast_timer = parry_exhuast;

	parry_charged = false;   // new parry: start charging again
	parry_charge_timer = 0;  // empty circle
	sword_sweep = 0;         // rainbow starts at the bottom
	sword_hue = 0;           // every parry starts on red + yellow

	if (parry_raise_spr[parry_dir4] != -1) {
		// play the guard-raise animation - it IS the charge-up,
		// and Animation End finishes the charge when it's done
		parry_raising = true;
		sprite_index = parry_raise_spr[parry_dir4];
		image_index = 0;
		// speed it up or slow it down so it lasts exactly parry_charge_time steps
		image_speed = image_number / (sprite_get_speed(sprite_index) * parry_charge_time / game_get_speed(gamespeed_fps));
	}
	else {
		// no raise animation for this direction: go straight to the block loop and charge on the timer
		parry_raising = false;
		sprite_index = parry_block_spr[parry_dir4];
		image_index = 0;   // start the block animation from the first frame
		image_speed = 1;   // let it loop the whole time X is held
	}

}

/// the guard is fully up: switch to the block loop, release the shockwave, light up the sword
function parryChargeComplete(){

	if (parry_raising) {
		// raise animation finished -> swap to the looping block animation
		sprite_index = parry_block_spr[parry_dir4];
		image_index = 0;
		image_speed = 1;
	}

	parry_raising = false;
	parry_charged = true;

	var _w = instance_create_depth(x, y, depth + 1, parry_shockwave_obj);
	_w.colour     = parry_fx_colour;
	_w.radius     = parry_circle_radius;      // starts at the edge of the full circle...
	_w.max_radius = parry_circle_radius * 3;  // ...and bursts out to 3x its size
}

function parryStateMC(){

	// let go of X -> drop the guard (and stop here, nothing else this step)
	if(!keyboard_check(parryBtn)){
		state = PlayerState.NORMAL;
		parry_raising = false;
		return;
	}

	if (!parry_charged) {
		// ---- still charging ----
		// with a raise animation, Animation End finishes the charge (see parryChargeComplete)
		// without one, count up the timer instead
		if (!parry_raising) {
			parry_charge_timer += 1;
			if (parry_charge_timer >= parry_charge_time) {
				parryChargeComplete();
			}
		}
	}
	else {
		// ---- fully charged: move the rainbow up the sword, start again from the bottom when it's gone off the top ----
		sword_sweep += sword_sweep_speed;
		if (sword_sweep > 1 + sword_band + sword_trail_len) {
			sword_sweep = 0;
			sword_hue = frac(sword_hue + sword_colours / 6);   // next pass = the next colours round the rainbow
		}
	}

	//if (parry_cooldown <= 0 && parry_was_hit) {
	//	parry_cooldown = parry_cooldown_t;
	//	state = PlayerState.NORMAL;
	//}
	//else if(!parry_was_hit){
	//	state = PlayerState.NORMAL;
	//}

}
