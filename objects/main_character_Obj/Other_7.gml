if (state == PlayerState.ATTACK){


	state = PlayerState.NORMAL;
	attack_cooldown = attack_cooldown_time; //starts cooldown
}

if (state == PlayerState.PARRY && parry_raising){
	// the guard-raise animation finished: the charge is complete
	parryChargeComplete();
}
