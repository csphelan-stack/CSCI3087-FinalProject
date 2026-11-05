if (state == PlayerState.ATTACK){

	state = PlayerState.NORMAL;
	attack_cooldown = attack_cooldown_time; //starts cooldown
	if (butterflyOn()) attack_cooldown /= butterfly_cd_mult;   // Butterfly Effect: next swing comes sooner
	attack_is_countered = false;            //the counter swing (if it was one) is over
}

// death animation finished: lie still on the last frame and start the restart countdown (see playerHurtDeath)
if (state == PlayerState.DEAD && death_hold_timer < 0){
	image_speed = 0;
	image_index = image_number - 1;
	death_hold_timer = death_hold_time;
}

// Bladed Tsunami wind-up animation finished a hair before the charge timer: hold the guard pose
if (state == PlayerState.SPECIAL && special_equipped == SpecialState.TSUNAMI && !tsunami_charged
	&& sprite_index == parry_raise_spr[tsunami_dir4]){
	sprite_index = parry_block_spr[tsunami_dir4];
	image_index = 0;
	image_speed = 1;
}
