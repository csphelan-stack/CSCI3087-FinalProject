/* DUPLICATE SCRIPT - DO NOT UNCOMMENT

// ============================================================
// SPECIAL ATTACKS: which one runs depends on special_equipped (see the SpecialState enum in the player's Create)
// the player only has ONE special state (PlayerState.SPECIAL). these two functions pick the equipped special
// to add a new special: give it a name in SpecialState, then add a case to both switches below
// ============================================================

/// runs ONCE when the special key is pressed: starts whichever special is equipped
function startSpecial(){
	state = PlayerState.SPECIAL;

	switch (special_equipped) {
		case SpecialState.WHIRLWIND:
			startSpecialCharge();
			break;

		default:   // no special equipped (or one without code yet): back to normal
			state = PlayerState.NORMAL;
			break;
	}
}

/// runs EVERY step while state == PlayerState.SPECIAL
function specialStateMC(){
	switch (special_equipped) {
		case SpecialState.WHIRLWIND:
			// charging until it's full, then spinning
			if (special_charged) specialSpinStateMC();
			else specialChargeStateMC();
			break;

		default:
			state = PlayerState.NORMAL;
			break;
	}
}


// ============================================================
// WHIRLWIND (SpecialState.WHIRLWIND): hold S to charge, and the moment it's full he spins like a tornado
// ============================================================
// hold the special key -> charges for special_charge_time steps (charge circle + glow, he raises his guard)
// fully charged -> shockwave bursts out and he goes STRAIGHT into the SPIN (no need to let go):
//                  he whirls round for special_spin_time steps, hitting everything in special_radius
//                  every special_tick_time steps. you can still steer him slowly
// let go before it's full -> nothing happens (no cooldown)
// hit while charging -> the charge is lost (short cooldown, see Enemy_damage_applying)
// after the spin -> the heavy cooldown (special_cooldown_t)
// the visuals are the fx functions at the bottom of parryState
// picking the Acrobatic Tsunami card equips it (special_equipped = SpecialState.WHIRLWIND)
// ============================================================

/// runs ONCE when the special key is pressed (called by startSpecial)
function startSpecialCharge(){
	audio_play_sound(snd_charge, 15, true);

	special_dir4 = round(facing / 90) mod 4;
	special_charge_timer = 0;
	special_charged = false;
	sword_sweep = 0;   // colour band starts at the bottom
	sword_hue = 0;     // on the first sword_palette colours

	// the guard-raise animation is the wind-up, sped up or slowed down to last exactly special_charge_time
	sprite_index = parry_raise_spr[special_dir4];
	image_index = 0;
	image_speed = image_number / (sprite_get_speed(sprite_index) * special_charge_time / game_get_speed(gamespeed_fps));
}

/// runs EVERY step while charging
function specialChargeStateMC(){
	if (global.gameIsPaused) return;

	// let go before it's full: just stop, no cooldown
	if (!keyboard_check(global.special_button))
 {
	    audio_stop_sound(snd_charge);
		state = PlayerState.NORMAL;
		image_speed = 1;
		return;
	}

	special_charge_timer += 1;
	if (special_charge_timer >= special_charge_time) {
		// fully charged: shockwave bursts out and he goes straight into the spin
		special_charged = true;
		fxShockwaveBurst(special_fx_colour, parry_circle_radius, parry_circle_radius * 3);
		startSpecialSpin();
	}
}

/// runs ONCE the moment the charge is full
function startSpecialSpin(){
	audio_stop_sound(snd_charge);
    audio_play_sound(snd_spin, 20, true);
	special_spin_timer = special_spin_time;
	special_spin_angle = special_dir4 * 90;   // starts facing the way he was
	special_tick_timer = 0;                   // the first hit lands straight away
	special_ghost_timer = 0;
	image_speed = 0;                          // the pose is picked by hand every step while spinning

	// launched off the way he was facing
	special_vx = lengthdir_x(special_spin_launch, special_dir4 * 90);
	special_vy = lengthdir_y(special_spin_launch, special_dir4 * 90);
	special_wobble_dir = random(360);

	fxShockwaveBurst(c_white, parry_circle_radius * 0.5, parry_circle_radius * 2);
}

/// runs EVERY step while spinning
function specialSpinStateMC(){
	if (global.gameIsPaused) return;

	// turn: show the attack pose for whichever way he's facing right now
	special_spin_angle = (special_spin_angle + special_spin_rate) mod 360;
	var _dir4 = floor(special_spin_angle / 90 + 0.5) mod 4;
	facing = _dir4 * 90;
	sprite_index = attack_spr[_dir4];
	image_index = special_spin_frame;
	fxRainbowSwordStep();

	// movement: faster than walking but slippery. the keys only NUDGE him (special_spin_accel),
	// he keeps sliding (special_spin_drag) and the tornado shoves him around (special_spin_wobble)
	var _h = keyboard_check(global.right_button) - keyboard_check(global.left_button);
	var _v = keyboard_check(global.down_button)  - keyboard_check(global.up_button);
	if (_h != 0 || _v != 0) {
		var _d = point_direction(0, 0, _h, _v);
		special_vx += lengthdir_x(special_spin_accel, _d);
		special_vy += lengthdir_y(special_spin_accel, _d);
	}

	// the wobble pushes him in a direction that slowly wanders round, so he drifts off course
	special_wobble_dir += random_range(-25, 25);
	special_vx += lengthdir_x(special_spin_wobble, special_wobble_dir);
	special_vy += lengthdir_y(special_spin_wobble, special_wobble_dir);

	special_vx *= special_spin_drag;
	special_vy *= special_spin_drag;

	// top speed
	var _spd = point_distance(0, 0, special_vx, special_vy);
	if (_spd > special_spin_speed) {
		special_vx = special_vx / _spd * special_spin_speed;
		special_vy = special_vy / _spd * special_spin_speed;
	}

	move_and_collide(special_vx, special_vy, obj_wall);

	// damage everything in reach every special_tick_time steps
	special_tick_timer -= 1;
	if (special_tick_timer <= 0) {
		special_tick_timer = special_tick_time;
		specialSpinHit();
	}

	// coloured afterimages, like the dash, so he leaves a whirl behind him
	special_ghost_timer -= 1;
	if (special_ghost_timer <= 0) {
		special_ghost_timer = special_ghost_gap;
		var _g = instance_create_depth(x, y, depth + 1, dash_afterimage_obj);
		_g.sprite_index = sprite_index;
		_g.image_index  = image_index;
		_g.image_xscale = image_xscale;
		_g.image_yscale = image_yscale;
		_g.image_alpha  = 0.5;
		_g.start_alpha  = 0.5;
		_g.ghost_colour = special_ghost_colour[(special_spin_timer div special_ghost_gap) mod array_length(special_ghost_colour)];
		_g.fade_time    = 10;
		_g.hold         = 0;
	}

	// done: back to normal and the heavy cooldown starts
	special_spin_timer -= 1;
	if (special_spin_timer <= 0) {
	    audio_stop_sound(snd_spin);
		state = PlayerState.NORMAL;
		image_speed = 1;
		special_cooldown = special_cooldown_t;

		// he skids out of it: hand his speed over to the knockback push, which fades it out
		push_x = special_vx;
		push_y = special_vy;
		special_vx = 0;
		special_vy = 0;
	}
}

/// one damage tick of the tornado: hits every enemy within special_radius of his middle
function specialSpinHit(){
	var _list = ds_list_create();
	var _n = collision_circle_list(x, y - 14, special_radius, Enemy_base_obj, false, true, _list, false);

	for (var i = 0; i < _n; i++) {
		var _e = _list[| i];
		if (_e.state == ENEMY_STATE.DEAD) continue;

		_e.hp -= special_damage;

		// flung outward, away from the middle of the tornado
		var _kb_dir = point_direction(x, y, _e.x, _e.y);
		_e.kb_x = lengthdir_x(special_knockback, _kb_dir);
		_e.kb_y = lengthdir_y(special_knockback, _kb_dir);
		with (_e) enemy_change_state(ENEMY_STATE.HURT);

		damagePopupAdd(_e, special_damage, false);
	}

	ds_list_destroy(_list);
}

/// the wind swirling round him while he spins (Draw, after the player)
function specialSpinRingDraw(){
	var _r  = special_radius;
	var _cy = y - 14;   // around his middle

	gpu_set_blendmode(bm_add);
	draw_set_colour(special_fx_colour);

	// three arcs chasing each other round, squashed like the charge circle so it looks flat on the ground
	for (var a = 0; a < 3; a++) {
		var _start = special_spin_angle + a * 120;
		var _px = x + lengthdir_x(_r, _start);
		var _py = _cy + lengthdir_y(_r, _start) * 0.45;
		for (var s = 1; s <= 8; s++) {
			var _ang = _start + s * 9;
			var _nx = x + lengthdir_x(_r, _ang);
			var _ny = _cy + lengthdir_y(_r, _ang) * 0.45;
			draw_set_alpha(0.15 + 0.6 * s / 8);   // fades in toward the leading edge
			draw_line_width(_px, _py, _nx, _ny, 2);
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

*/