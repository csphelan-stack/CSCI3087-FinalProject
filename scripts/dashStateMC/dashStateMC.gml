function startDashState(){


    // runs ONCE when the dash button (space) is pressed
    state = PlayerState.DASH;

	image_blend = c_orange;

    // same direction math as the movement code: 0 = right, 1 = up, 2 = left, 3 = down
    var dir4 = round(facing / 90) mod 4;
    switch (dir4) {
        case 0: sprite_index = skull_knight_idle_right_spr;    break;
        case 1: sprite_index = skull_knight_idle_backward_spr; break;
        case 2: sprite_index = skull_knight_idle_left_spr;     break;
        case 3: sprite_index = skull_knight_idle_forward_spr;  break;
    }
    image_index = 0;   // start the animation from the first frame
    image_speed = 1;   // play at the sprite's normal speed

	dash_timer = dash_time;  // how many steps the dash lasts
	dash_dir = facing;       // lock the direction now so he can't steer mid-dash


}
function dashStateMC(){

	// don't move while paused (pausing shouldn't happen mid-fight, but just in case)
	if (global.gameIsPaused) return;

	// move a slice of the dash EVERY step instead of all of it at once,
	// so he visibly travels and walls get checked along the way
	// (dash_length 120 over dash_time 20 = 6 px per step)
	var _dash_spd = dash_length / dash_time;

	var _dx = lengthdir_x(_dash_spd, dash_dir);
	var _dy = lengthdir_y(_dash_spd, dash_dir);

	move_and_collide(_dx, _dy, obj_wall);

	// count the dash down, and finish when time runs out
	dash_timer -= 1;

	if (dash_timer <= 0) {
		dash_cooldown = dash_cooldown_t;
		image_blend = c_white;
		state = PlayerState.NORMAL;
	}

}
