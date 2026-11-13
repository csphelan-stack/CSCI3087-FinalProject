function sword_art_3_script(){


	if( !attack_sa3_hit_spawned && sa3_cooldown_time <= 0){
		
		
		
		

		var dir4 = round(facing / 45) mod 8;

		opp_swing_dir_vtk = dir4*45;

		if(image_index >= sa3_frame_spawn && !flood_formation_finished){



			attack_sa3_hit_spawned = true;
			
			
				image_index = 5;	
				image_speed = 0;	
			
			
			
			_circle_push_obj = instance_create_depth(x,y,-1000,circle_push_obj);
			for(var i =0;i<8;i++){
				var _dir = 0;
				var _dir_change = 45;
				var _ang =270;
				var _ang_change =45;


				_flood_obj = instance_create_depth(x,y,-1000,flood_formation_obj);
				_flood_obj.image_angle  = (_ang + _ang_change *i) mod 360;
				_flood_obj.image_index = 0;
				_flood_obj.	image_speed = 1;
				_flood_obj.direction = _dir + _dir_change * i;
				_flood_obj.knockback = knockback_sa3;
				_flood_obj.damage = sa3_damage;
				_flood_obj.stun_time = sa3_stun_time;


			}


			if(flood_formation_finished || !instance_exists(flood_formation_obj) || !instance_exists(circle_push_obj)){
							flood_formation_finished = false;
			invuln = 0;
			image_speed =1;
			exit;
			}


		}



	}
	else if(flood_formation_finished || !instance_exists(flood_formation_obj) || !instance_exists(circle_push_obj)){
			
			flood_formation_finished = false;
			invuln = 0;
			image_speed =1;
			exit;
		}
	
	
}
