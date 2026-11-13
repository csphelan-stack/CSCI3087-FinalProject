if (targets_hit >= number_of_targets_HOC - 1 && alarm[1] < 0) {
		alarm[1] = 60;
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
				targets[i].hp -= damage_HOC;
				}
			}
		}