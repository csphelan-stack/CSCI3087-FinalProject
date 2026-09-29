if (hp<=0){ 
	 game_restart();
	}
	
	
if(global.gameIsPaused){
can_move =false;	
}

	

if (can_move) {

    _hor = keyboard_check(global.right_button) - keyboard_check(global.left_button);
    _ver = keyboard_check(global.down_button)  - keyboard_check(global.up_button);

    moving = (_hor != 0) || (_ver != 0);

    if (moving) {
        // update facing only while moving so the player keeps their last direction when idle
        facing = point_direction(0, 0, _hor, _ver);
    }

    // snap facing to 4 directions: 0 = right, 1 = up, 2 = left, 3 = down
    var dir4 = round(facing / 90) mod 4;

    // assign sprites
    if (moving) {
		
		image_speed = 1.2;
        switch (dir4) {
            case 0: sprite_index = skull_knight_run_right_spr; break;
            case 1: sprite_index = skull_knight_run_backward_spr;    break;
            case 2: sprite_index = skull_knight_run_left_spr;  break;
            case 3: sprite_index = skull_knight_run_forward_spr;  break;
        }
    } else {
		image_speed = 0.5;
        // the skull knight has an idle for every direction, so he keeps facing the way he last moved
        switch (dir4) {
            case 0: sprite_index = skull_knight_idle_right_spr; break;
            case 1: sprite_index = skull_knight_idle_backward_spr;    break;
            case 2: sprite_index = skull_knight_idle_left_spr;  break;
            case 3: sprite_index = skull_knight_idle_forward_spr;  break;
        }
    }

    // apply movement (runs every step, so it drops to 0 when no keys are held)
    kb_x = _hor * movespd;
    kb_y = _ver * movespd;

    var len = point_distance(0, 0, kb_x, kb_y);
    if (len > movespd) {
        kb_x = kb_x / len * movespd;
        kb_y = kb_y / len * movespd;
    }
}

x += kb_x;
y += kb_y;
