function applyMovement(){
	
	
       if (keyboard_check_pressed(global.attack_button) && can_attack && attack_cooldown <= 0 && !global.gameIsPaused) {
       audio_play_sound(snd_sword, 20, false);
	   startAttackPlayer();
        return;
    }
	
	if(keyboard_check_pressed(global.dash_button) && can_move && dash_cooldown <=0 && !global.gameIsPaused){
		startDashState();
		return;
	}
	
		if(keyboard_check_pressed(global.parry_button) && can_move && parry_cooldown <=0 && !global.gameIsPaused){
		startParryState();
		return;
	}

	// special: hold to charge, let go to spin (see the SPECIAL ATTACK section of attackState)
	if(keyboard_check_pressed(global.special_button) && can_move && special_cooldown <= 0 && !global.gameIsPaused){
		startSpecialCharge();
		return;
	}
	
	
if(global.gameIsPaused){
	movespd = 0;
	can_move = false;
	// clear the last movement so x += kb_x below can't keep sliding him while paused
	kb_x = 0;
	kb_y = 0;
	image_speed = 0; // freeze the run animation too
	exit;
}
else{
movespd = fixedmovespd;
}

	

if (can_move || !global.gameIsPaused) {

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

// --- horizontal ---
// would moving sideways put my hitbox inside a wall?
if (place_meeting(x + kb_x, y, obj_wall)) {
    // yes: creep forward 1 pixel at a time until I'm touching it
    while (!place_meeting(x + sign(kb_x), y, obj_wall)) {
        x += sign(kb_x);
    }
    kb_x = 0; // then stop moving sideways
}
x += kb_x;

// --- vertical --- (same idea, up/down)
if (place_meeting(x, y + kb_y, obj_wall)) {
    while (!place_meeting(x, y + sign(kb_y), obj_wall)) {
        y += sign(kb_y);
    }
    kb_y = 0;
}
y += kb_y;
	
	
	
	
}