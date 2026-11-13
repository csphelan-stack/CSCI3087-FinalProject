function enemy_push_state(){


	if(instance_exists(circle_push_obj)){
		

		var _dir  = point_direction(circle_push_obj.x, circle_push_obj.y, x, y); 


		var _mx = lengthdir_x(circle_push_obj.grow_speed, _dir);   // how far to move sideways
		var _my = lengthdir_y(circle_push_obj.grow_speed, _dir);   // how far to move up/down

		move_and_collide(_mx, _my, wall_obj);
		
		//// which way is "away from the circle"
		//var _dist = point_distance(circle_push_obj.x, circle_push_obj.y, x, y);   // how far from the centre now
		//var _gap  = circle_push_obj.radius - _dist;                                // how far inside the edge it is

		//if (_gap > 0) {
		//	move_and_collide(lengthdir_x(_gap, _dir), lengthdir_y(_gap, _dir), wall_obj);
		//}
					
	}
	else{
		enemy_change_state(ENEMY_STATE.STUN);
		exit;
	}

}