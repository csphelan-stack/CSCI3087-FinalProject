

// ============================================================
// SPECIAL ATTACKS: which one runs depends on special_equipped (see the SpecialState enum in the player's Create)
// the player only has ONE special state (PlayerState.SPECIAL). these two functions pick the equipped special
// to add a new special: give it a name in SpecialState, then add a case to both switches below
// ============================================================

/// runs ONCE when the special key is pressed: starts whichever special is equipped
function startSpecial(){
	state = PlayerState.SPECIAL;

	switch (special_equipped) {
		case SpecialState.TSUNAMI:     // this script, below
			startTsunamiCharge();
			break;

		case SpecialState.BUTTERFLY:   // special_attack_butterfly_script
			startButterfly();
			break;

		case SpecialState.DANCE:       // special_dance_attack_script
			startDance();
			break;

		default:   // no special equipped (or one without code yet): back to normal
			state = PlayerState.NORMAL;
			break;
	}
}

/// runs EVERY step while state == PlayerState.SPECIAL
function specialStateMC(){
	switch (special_equipped) {
		case SpecialState.TSUNAMI:
			// charging until it's full, then the wave
			if (tsunami_charged) tsunamiStateMC();
			else tsunamiChargeStateMC();
			break;
		case SpecialState.BUTTERFLY:
			// the window runs in the background (butterflyStep). he's only in this state for the rewind and the choice
			butterflyPhaseStep();
			break;
		case SpecialState.DANCE:
			// wind-up, then dashing and striking enemy to enemy
			danceStateMC();
			break;
		default:
			state = PlayerState.NORMAL;
			break;
	}
}


// ============================================================
// BLADED TSUNAMI (SpecialState.TSUNAMI): hold S to charge, and the moment it's full he becomes a tsunami
// ============================================================
// hold the special key -> charges for tsunami_charge_time steps (charge circle + glow, he raises his guard)
// fully charged -> a wave bursts out and he goes STRAIGHT into the tsunami (no need to let go):
//                  he whirls round for tsunami_time steps. every tsunami_tick_time steps a wave crashes out,
//                  hitting everything in tsunami_radius and throwing it outward (tsunamiHit)
//                  in between, the undertow drags every enemy in tsunami_pull_radius back in toward him
//                  (tsunamiPull), so they get thrown out, sucked back in, and hit again
//                  you can still steer him slowly
// let go before it's full -> nothing happens (no cooldown)
// hit while charging -> the charge is lost (short cooldown, see Enemy_damage_applying)
// after the tsunami -> the heavy cooldown (tsunami_cooldown_t)
// the charge circle, glow and sword colours are the fx functions at the bottom of parryState
// picking the Bladed Tsunami card equips it (special_equipped = SpecialState.TSUNAMI)
// the numbers and colours are in the player's Create, under "Bladed Tsunami"
// ============================================================

/// runs ONCE when the special key is pressed (called by startSpecial)
function startTsunamiCharge(){
	audio_play_sound(snd_charge, 15, true);

	tsunami_dir4 = round(facing / 90) mod 4;
	tsunami_charge_timer = 0;
	tsunami_charged = false;
	sword_sweep = 0;   // colour band starts at the bottom
	sword_hue = 0;     // on the first sword_palette colours

	// the guard-raise animation is the wind-up, sped up or slowed down to last exactly tsunami_charge_time
	sprite_index = parry_raise_spr[tsunami_dir4];
	image_index = 0;
	image_speed = image_number / (sprite_get_speed(sprite_index) * tsunami_charge_time / game_get_speed(gamespeed_fps));
}

/// runs EVERY step while charging
function tsunamiChargeStateMC(){
	if (global.gameIsPaused) return;

	// let go before it's full: just stop, no cooldown
	if (!keyboard_check(global.special_button))
 {
	    audio_stop_sound(snd_charge);
		state = PlayerState.NORMAL;
		image_speed = 1;
		return;
	}

	tsunami_charge_timer += 1;
	if (tsunami_charge_timer >= tsunami_charge_time) {
		// fully charged: a wave bursts out and he goes straight into the tsunami
		tsunami_charged = true;
		fxShockwaveBurst(tsunami_colour, parry_circle_radius, parry_circle_radius * 3);
		startTsunami();
	}
}

/// runs ONCE the moment the charge is full
function startTsunami(){
	audio_stop_sound(snd_charge);
    audio_play_sound(snd_spin, 20, true);
	tsunami_timer = tsunami_time;
	tsunami_angle = tsunami_dir4 * 90;   // starts facing the way he was
	tsunami_tick_timer = 0;              // the first wave crashes straight away
	tsunami_ghost_timer = 0;
	image_speed = 0;                     // the pose is picked by hand every step while he whirls

	// launched off the way he was facing
	tsunami_vx = lengthdir_x(tsunami_launch, tsunami_dir4 * 90);
	tsunami_vy = lengthdir_y(tsunami_launch, tsunami_dir4 * 90);
	tsunami_wobble_dir = random(360);

	fxShockwaveBurst(tsunami_wave_colours[3], parry_circle_radius * 0.5, parry_circle_radius * 2);

	// a splash of water out of him
	tsunamiSplash(x, y - 14, 16, 2, 5);
}

/// runs EVERY step while the tsunami is going
function tsunamiStateMC(){
	if (global.gameIsPaused) return;

	// turn: show the attack pose for whichever way he's facing right now
	tsunami_angle = (tsunami_angle + tsunami_turn_rate) mod 360;
	var _dir4 = floor(tsunami_angle / 90 + 0.5) mod 4;
	facing = _dir4 * 90;
	sprite_index = attack_spr[_dir4];
	image_index = tsunami_frame;
	fxRainbowSwordStep();

	// movement: faster than walking but slippery. the keys only NUDGE him (tsunami_accel),
	// he keeps sliding (tsunami_drag) and the current shoves him around (tsunami_wobble)
	var _h = keyboard_check(global.right_button) - keyboard_check(global.left_button);
	var _v = keyboard_check(global.down_button)  - keyboard_check(global.up_button);
	if (_h != 0 || _v != 0) {
		var _d = point_direction(0, 0, _h, _v);
		tsunami_vx += lengthdir_x(tsunami_accel, _d);
		tsunami_vy += lengthdir_y(tsunami_accel, _d);
	}

	// the wobble pushes him in a direction that slowly wanders round, so he drifts off course
	tsunami_wobble_dir += random_range(-25, 25);
	tsunami_vx += lengthdir_x(tsunami_wobble, tsunami_wobble_dir);
	tsunami_vy += lengthdir_y(tsunami_wobble, tsunami_wobble_dir);

	tsunami_vx *= tsunami_drag;
	tsunami_vy *= tsunami_drag;

	// top speed
	var _spd = point_distance(0, 0, tsunami_vx, tsunami_vy);
	if (_spd > tsunami_speed) {
		tsunami_vx = tsunami_vx / _spd * tsunami_speed;
		tsunami_vy = tsunami_vy / _spd * tsunami_speed;
	}

	move_and_collide(tsunami_vx, tsunami_vy, obj_wall);

	// the undertow: drags enemies back in toward him every step
	tsunamiPull();

	// a wave crashes out every tsunami_tick_time steps: damage, and everything in reach gets thrown out
	tsunami_tick_timer -= 1;
	if (tsunami_tick_timer <= 0) {
		tsunami_tick_timer = tsunami_tick_time;
		tsunamiHit();
		fxShockwaveBurst(tsunami_wave_colours[tsunami_timer mod array_length(tsunami_wave_colours)], tsunami_radius * 0.5, tsunami_radius * 1.4);
	}

	// water being sucked in from the edge of the undertow
	repeat (2) {
		var _a = random(360);
		var _r = tsunami_pull_radius * random_range(0.8, 1);
		tsunamiDropAdd(x + lengthdir_x(_r, _a), y - 14 + lengthdir_y(_r, _a) * 0.45, 0, 0, true);
	}

	// coloured afterimages, like the dash, so he leaves a wake behind him
	tsunami_ghost_timer -= 1;
	if (tsunami_ghost_timer <= 0) {
		tsunami_ghost_timer = tsunami_ghost_gap;
		var _g = instance_create_depth(x, y, depth + 1, dash_afterimage_obj);
		_g.sprite_index = sprite_index;
		_g.image_index  = image_index;
		_g.image_xscale = image_xscale;
		_g.image_yscale = image_yscale;
		_g.image_alpha  = 0.5;
		_g.start_alpha  = 0.5;
		_g.ghost_colour = tsunami_ghost_colour[(tsunami_timer div tsunami_ghost_gap) mod array_length(tsunami_ghost_colour)];
		_g.fade_time    = 10;
		_g.hold         = 0;
	}

	// done: back to normal and the heavy cooldown starts
	tsunami_timer -= 1;
	if (tsunami_timer <= 0) {
	    audio_stop_sound(snd_spin);
		state = PlayerState.NORMAL;
		image_speed = 1;
		special_cooldown = tsunami_cooldown_t;

		// one last wave as it breaks
		fxShockwaveBurst(tsunami_colour, tsunami_radius, tsunami_pull_radius);
		tsunamiSplash(x, y - 14, 20, 2, 6);

		// he skids out of it: hand his speed over to the knockback push, which fades it out
		push_x = tsunami_vx;
		push_y = tsunami_vy;
		tsunami_vx = 0;
		tsunami_vy = 0;
	}
}

/// one wave crashing out: hits every enemy within tsunami_radius of his middle and throws it outward
function tsunamiHit(){
	var _list = ds_list_create();
	var _n = collision_circle_list(x, y - 14, tsunami_radius, Enemy_base_obj, false, true, _list, false);

	for (var i = 0; i < _n; i++) {
		var _e = _list[| i];
		if (_e.state == ENEMY_STATE.DEAD) continue;

		_e.hp -= tsunami_damage;

		// thrown outward, away from the middle of the wave (the undertow brings it back)
		var _kb_dir = point_direction(x, y, _e.x, _e.y);
		_e.kb_x = lengthdir_x(tsunami_knockback, _kb_dir);
		_e.kb_y = lengthdir_y(tsunami_knockback, _kb_dir);
		with (_e) enemy_change_state(ENEMY_STATE.HURT);

		damagePopupAdd(_e, tsunami_damage, false);

		// a little splash off it, flying the way it's thrown
		tsunamiSplash(_e.x, _e.y - 12, 3, 1, 3);
	}

	ds_list_destroy(_list);
}

/// the undertow: every enemy within tsunami_pull_radius gets dragged back in toward him, swirling round as it comes
/// enemies that were just thrown out fly out first (their knockback is stronger), then get pulled back
function tsunamiPull(){
	var _px     = x;
	var _py     = y;
	var _radius = tsunami_pull_radius;
	var _speed  = tsunami_pull_speed;
	var _min    = tsunami_pull_min;
	var _swirl  = tsunami_pull_swirl;

	with (Enemy_base_obj) {
		if (state == ENEMY_STATE.DEAD) continue;

		var _d = point_distance(x, y, _px, _py);
		if (_d > _radius || _d < _min) continue;   // out of reach, or already right up against him

		// pulled harder the further out it is, like the water rushing back
		var _dir = point_direction(x, y, _px, _py) + _swirl;   // the swirl curves them round him as they come in
		var _s = _speed * (0.5 + 0.5 * _d / _radius);
		var _dx = lengthdir_x(_s, _dir);
		var _dy = lengthdir_y(_s, _dir);

		// walls stop it, the same way enemies normally move
		if (!place_meeting(x + _dx, y, obj_wall)) x += _dx;
		if (!place_meeting(x, y + _dy, obj_wall)) y += _dy;
	}
}


// ---- the water: little droplets, either sucked in toward him or splashing out ----

/// adds one droplet. _inward = true: it's sucked toward him (the undertow); false: it flies off with (_vx, _vy) and falls
function tsunamiDropAdd(_x, _y, _vx, _vy, _inward){
	if (array_length(tsunami_drops) >= tsunami_drop_max) return;
	var _life = _inward ? irandom_range(20, 30) : irandom_range(18, 28);
	array_push(tsunami_drops, {
		x: _x, y: _y,
		px: _x, py: _y,   // where it was last step, so it can be drawn as a streak
		vx: _vx, vy: _vy,
		inward: _inward,
		life: _life, max_life: _life,
		col: tsunami_wave_colours[irandom(array_length(tsunami_wave_colours) - 1)]
	});
}

/// a burst of droplets flying out of (_x, _y) in every direction
function tsunamiSplash(_x, _y, _count, _spd_min, _spd_max){
	repeat (_count) {
		var _a = random(360);
		var _s = random_range(_spd_min, _spd_max);
		tsunamiDropAdd(_x, _y, lengthdir_x(_s, _a), lengthdir_y(_s, _a) - 1, false);
	}
}

/// moves the droplets (called from the player's Step, so they finish after the tsunami ends)
function tsunamiDropsStep(){
	if (global.gameIsPaused) return;

	var _tx = x;
	var _ty = y - 14;
	for (var i = array_length(tsunami_drops) - 1; i >= 0; i--) {
		var _p = tsunami_drops[i];
		_p.px = _p.x;
		_p.py = _p.y;

		if (_p.inward) {
			// swirls in toward him, faster as it gets close
			var _dir = point_direction(_p.x, _p.y, _tx, _ty) + 35;
			var _d = point_distance(_p.x, _p.y, _tx, _ty);
			var _s = 2 + 4 * (1 - min(1, _d / tsunami_pull_radius));
			_p.vx = lerp(_p.vx, lengthdir_x(_s, _dir), 0.3);
			_p.vy = lerp(_p.vy, lengthdir_y(_s, _dir), 0.3);
			if (_d < 10) _p.life = 0;   // reached him
		} else {
			// splashing out: slows and falls
			_p.vx *= 0.93;
			_p.vy = _p.vy * 0.93 + 0.12;
		}

		_p.x += _p.vx;
		_p.y += _p.vy;
		_p.life -= 1;
		if (_p.life <= 0) array_delete(tsunami_drops, i, 1);
	}
}

/// draws the droplets as short glowing streaks (Draw, any state)
function tsunamiDropsDraw(){
	var _n = array_length(tsunami_drops);
	if (_n == 0) exit;

	gpu_set_blendmode(bm_add);
	for (var i = 0; i < _n; i++) {
		var _p = tsunami_drops[i];
		var _f = _p.life / _p.max_life;
		draw_set_colour(_p.col);
		draw_set_alpha(0.8 * _f);
		draw_line_width(_p.px - _p.vx, _p.py - _p.vy, _p.x, _p.y, 1 + _f);
	}
	draw_set_alpha(1);
	draw_set_colour(c_white);
	gpu_set_blendmode(bm_normal);
}

/// the water swirling round him while the tsunami is going (Draw, after the player)
function tsunamiRingDraw(){
	var _cy = y - 14;   // around his middle

	gpu_set_blendmode(bm_add);

	// the edge of the undertow: a faint ring that breathes in and out, so you can see how far it reaches
	var _pr = tsunami_pull_radius * (0.95 + 0.05 * sin(current_time / 120));
	draw_set_colour(tsunami_colour);
	draw_set_alpha(0.18);
	draw_ellipse(x - _pr, _cy - _pr * 0.45, x + _pr, _cy + _pr * 0.45, true);

	// the waves: four arcs chasing each other round, each in one of the card colours,
	// squashed like the charge circle so it looks flat on the ground
	var _arcs = array_length(tsunami_wave_colours);
	for (var a = 0; a < _arcs; a++) {
		var _r = tsunami_radius * (0.8 + 0.2 * (a mod 2));   // alternating sizes, like rolling waves
		var _start = tsunami_angle + a * (360 / _arcs);
		var _px = x + lengthdir_x(_r, _start);
		var _py = _cy + lengthdir_y(_r, _start) * 0.45;
		draw_set_colour(tsunami_wave_colours[a]);
		for (var s = 1; s <= 10; s++) {
			var _ang = _start + s * 8;
			var _nx = x + lengthdir_x(_r, _ang);
			var _ny = _cy + lengthdir_y(_r, _ang) * 0.45;
			draw_set_alpha(0.15 + 0.65 * s / 10);   // fades in toward the leading edge
			draw_line_width(_px, _py, _nx, _ny, 1 + 2 * s / 10);   // and gets thicker, like a wave's crest
			_px = _nx;
			_py = _ny;
		}
	}

	draw_set_alpha(1);
	draw_set_colour(c_white);
	gpu_set_blendmode(bm_normal);
}

/// Draw GUI: "Special ready" at the bottom center of the screen.
/// The cooldown countdown is shown by the cooldown orb, so it isn't drawn here
function specialHudDraw(){
	if (special_equipped == SpecialState.NONE) exit;   // no special yet, nothing to be ready
	if (special_cooldown > 0) exit;   // still cooling down, the orb shows the timer

	var _x = display_get_gui_width() / 2;
	var _y = display_get_gui_height() - 50;

	var _pulse = 0.6 + 0.4 * abs(sin(current_time / 300));

	draw_set_alpha(_pulse);
	draw_menu_text(_x, _y, "Special ready", make_colour_rgb(230, 190, 90), 1, fa_center);
	draw_set_alpha(1);   // always reset
}
