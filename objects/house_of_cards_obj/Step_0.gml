// finished once the strike has landed (strike_frame 2) and the lightning has finished
// drawing (strike_frame goes past the number of targets)
if (strike_frame > max(2, number_of_targets_HOC)) {
	instance_destroy();
}

	if(strike_frame == 2){
	target_drawn = true;
	}
	else{
		target_drawn = false;
	}


		for(var i =0; i<=number_of_targets_HOC-1;i++){

			if(instance_exists(targets[i])){


				if(target_drawn){
					main_character_Obj.stun_min = true;
					targets[i].hp -= damage_HOC;
					// and stun it. Inside with(), "other" is this House of Cards object
					with (targets[i]) {
						enemy_stun_state();
					}
				}
			}
		}