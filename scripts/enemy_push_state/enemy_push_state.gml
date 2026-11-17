// enemy_push_state: runs every step while an enemy is in ENEMY_STATE.PUSHSA3 (caught by Sword Art 3's wave).
// Pushes the enemy straight away from circle_push_obj by the circle's grow_speed, stopping at walls,
// and switches it to ENEMY_STATE.STUN once the circle is gone.
// Called from Enemy_base_obj Step (runs as the enemy); takes nothing in.
function enemy_push_state(){


	if(instance_exists(circle_push_obj)){


		var _dir  = point_direction(circle_push_obj.x, circle_push_obj.y, x, y);


		var _mx = lengthdir_x(circle_push_obj.grow_speed, _dir);   // how far to move sideways
		var _my = lengthdir_y(circle_push_obj.grow_speed, _dir);   // how far to move up/down

		move_and_collide(_mx, _my, wall_obj);



	}
	else{
		enemy_change_state(ENEMY_STATE.STUN);
		exit;
	}

}