if (state == PlayerState.ATTACK){


	state = PlayerState.NORMAL;
	attack_cooldown = attack_cooldown_time; //starts cooldown
	attack_is_countered = false;            //the counter swing (if it was one) is over
}

// special wind-up animation finished a hair before the charge timer: hold the guard pose
if (state == PlayerState.SPECIAL_CHARGE && sprite_index == parry_raise_spr[special_dir4]){
	sprite_index = parry_block_spr[special_dir4];
	image_index = 0;
	image_speed = 1;
}
