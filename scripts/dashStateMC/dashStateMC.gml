function startDashState(){


    // runs ONCE when the dash button (space) is pressed
    state = PlayerState.DASH;

	image_blend = c_orange;
	
	dash_dir = facing; 

    // dash_dir is an angle, so snap it to 0 right, 1 up, 2 left, 3 down to pick the run sprite
    sprite_index = run_spr[round(dash_dir / 90) mod 4];
    image_index = 0;   // the first frame of the run
    image_speed = 0;   // frozen on that frame for the whole dash

	dash_ghosts_made = 0;  // new dash, no shadows yet

	dash_timer = dash_time;  // how many steps the dash lasts
	      // lock the direction now so he can't steer mid-dash


}
function dashStateMC(){

	// don't move while paused (pausing shouldn't happen mid-fight, but just in case)
	if (global.gameIsPaused) return;

	var _elapsed = dash_time - dash_timer;   // steps since the dash started (0, 1, 2...)

	// remember where he is BEFORE this step's move
	var _prev_x = x;
	var _prev_y = y;

	// move a slice of the dash
	var _dash_spd = dash_length / dash_time;
	var _dx = lengthdir_x(_dash_spd, dash_dir);
	var _dy = lengthdir_y(_dash_spd, dash_dir);
	move_and_collide(_dx, _dy, obj_wall);

	// ---- drop every shadow that's due during this step ----
	while (dash_ghosts_made < dash_ghost_count) {

		var _i = dash_ghosts_made;   // which shadow this is: 0, 1, 2...

		// when this shadow is due, in steps (can be a fraction, like 1.67)
		var _due = _i * dash_time / dash_ghost_count;
		if (_due >= _elapsed + 1) break;   // not due until a later step, stop for now

		// how far through this step it's due (0 = start of the step, 1 = end)
		var _f = _due - _elapsed;

		// place it that far between where he was and where he is now
		var _gx = lerp(_prev_x, x, _f);
		var _gy = lerp(_prev_y, y, _f);

		var _g = instance_create_depth(_gx, _gy, depth + 1, dash_afterimage_obj);
		_g.sprite_index = sprite_index;
		_g.image_index  = image_index;
		_g.image_xscale = image_xscale;
		_g.image_yscale = image_yscale;

		// opacity: spread evenly from first to last
		var _alpha = lerp(dash_ghost_alpha_first, dash_ghost_alpha_last, _i / max(1, dash_ghost_count - 1));
		_g.image_alpha = _alpha;
		_g.start_alpha = _alpha;

		// colour: next one in the list, wrapping round to the start if we run out
		_g.ghost_colour = dash_ghost_colour[_i mod array_length(dash_ghost_colour)];
		_g.fade_time    = dash_ghost_fade;

		// the step the LAST shadow gets dropped on
		var _last_step = floor((dash_ghost_count - 1) * dash_time / dash_ghost_count);
		// wait until the last one is out, then fade one by one: each shadow waits stagger steps longer than the one before
		_g.hold = (_last_step - _elapsed) + dash_ghost_hold + _i * dash_ghost_stagger;

		dash_ghosts_made += 1;
	}

	// count the dash down, and finish when time runs out
	dash_timer -= 1;

	if (dash_timer <= 0) {
		dash_cooldown = dash_cooldown_t;
		image_blend = c_white;
		state = PlayerState.NORMAL;
	}
}