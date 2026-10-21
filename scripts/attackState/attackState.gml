function attackStatePlayer(){


    // has the swing reached the hit frame, and have we NOT made a hitbox yet this swing?
    if (image_index >= attack_hit_frame && !attack_hit_spawned) {

        attack_hit_spawned = true;  // only ever make one per swing

        // which way is he facing? snapped to exactly 0, 90, 180 or 270
        var dir4 = round(facing / 90) mod 4;
       
        var _dir = dir4 * 90;
		
		//tracks the opposite of the swing direction so we can apply knockback
		opp_swing_dir = dir4*90+180;

        // half the hitbox's size, so we can line up its EDGE instead of its centre
        var _half_w = sprite_get_width(main_character_hitbox_spr) / 2;
        var _half_h = sprite_get_height(main_character_hitbox_spr) / 2;

        // start at the peak of the swing, then step back toward him by half the box,
        // so the far edge of the box sits right on the peak
        var _hx = x + attack_peak_x[dir4] - lengthdir_x(_half_w, _dir);
        var _hy = y + attack_peak_y[dir4] - lengthdir_y(_half_h, _dir);

        var _hb = instance_create_layer(_hx, _hy, layer, main_character_hitbox_obj);
		
		// counters (from a parry) hit harder than a normal swing
		_hb.damage = attack_is_countered ? counter_damage : player_damage;
		_hb.is_crit = attack_is_countered;   // counters show "Crit!" above the enemy they hit

		
        _hb.owner = id;   //telling the hitbox who made it
		}
}

// _counter = true when the swing comes from a successful parry (see parrySuccess), normal attacks leave it out
function startAttackPlayer(_counter = false){
    // runs ONCE when Z is pressed
    state = PlayerState.ATTACK;

    // same direction math as the movement code: 0 = right, 1 = up, 2 = left, 3 = down
    var dir4 = round(facing / 90) mod 4;
    switch (dir4) {
        case 0: sprite_index = skull_knight_attack_right_spr;    break;
        case 1: sprite_index = skull_knight_attack_backward_spr; break;
        case 2: sprite_index = skull_knight_attack_left_spr;     break;
        case 3: sprite_index = skull_knight_attack_forward_spr;  break;
    }
    image_index = 0;   // start the swing from the first frame
    image_speed = 1.2;   // play at the sprite's normal speed
	
	attack_is_countered = _counter;   // reset every swing, so only the parry's swing is a counter
	
	
	attack_hit_spawned = false;  //new swing, so it hasn't made a hitbox yet
}



// ============================================================
// DAMAGE COUNTER: the number above an enemy when you hit it
// ============================================================
// each enemy you hit gets one counter. keep hitting it and the number counts up your total,
// every hit makes it hop up and drop straight back. stop for dmg_combo_time steps and it
// drops down out of sight while it fades. counters (crits) add a red "Crit!" on top.
// these run as the player: the hitbox calls damagePopupAdd, Step calls damagePopupsStep,
// Draw GUI calls damagePopupsDraw (drawn on the GUI so the pixel font stays crisp and on top)
// ============================================================

/// a sword hit just did _damage to _enemy
function damagePopupAdd(_enemy, _damage, _crit){

	// already counting on this enemy? add to it and make it hop again
	for (var i = 0; i < array_length(dmg_popups); i++) {
		var _p = dmg_popups[i];
		if (_p.target == _enemy) {
			_p.total += _damage;
			_p.life = dmg_combo_time;
			_p.vy = -dmg_hop_speed;
			if (_crit) _p.crit = dmg_crit_time;
			return;
		}
	}

	// first hit: start a new counter
	array_push(dmg_popups, {
		target: _enemy,
		x: _enemy.bbox_left,                 // top-left corner of the enemy's hitbox
		y: _enemy.bbox_top,
		total: _damage,
		life: dmg_combo_time,                // counts down, resets on every hit
		oy: 0,                               // hop height (room pixels, negative = up)
		vy: -dmg_hop_speed,                  // hop speed: starts going up, gravity pulls it back
		crit: _crit ? dmg_crit_time : 0,     // how long "Crit!" stays up
	});
}

/// every step: follow the enemies, count down, remove finished counters
function damagePopupsStep(){
	for (var i = array_length(dmg_popups) - 1; i >= 0; i--) {
		var _p = dmg_popups[i];

		// stays at the top-left of the enemy's hitbox, beside their head (if it died, it stays where it last was)
		if (instance_exists(_p.target)) {
			_p.x = _p.target.bbox_left;
			_p.y = _p.target.bbox_top;
		}

		// the hop: up fast, gravity drops it straight back to where it sits
		if (_p.vy != 0 || _p.oy < 0) {
			_p.oy += _p.vy;
			_p.vy += dmg_hop_gravity;
			if (_p.oy >= 0) {
				_p.oy = 0;
				_p.vy = 0;
			}
		}

		_p.life -= 1;
		if (_p.crit > 0) _p.crit -= 1;

		if (_p.life <= 0) array_delete(dmg_popups, i, 1);
	}
}

/// Draw GUI: turns each counter's room position into a GUI position and draws it
function damagePopupsDraw(){
	var _cam = view_camera[0];
	var _cx = camera_get_view_x(_cam);
	var _cy = camera_get_view_y(_cam);
	var _sx = display_get_gui_width()  / camera_get_view_width(_cam);
	var _sy = display_get_gui_height() / camera_get_view_height(_cam);

	for (var i = 0; i < array_length(dmg_popups); i++) {
		var _p = dmg_popups[i];

		var _fade = min(1, _p.life / dmg_fade_time);      // fades out at the end
		var _fall = (1 - _fade) * dmg_fall;               // and drops down fast while it fades
		var _gx = (_p.x - 2 - _cx) * _sx;                 // just left of the hitbox's left edge
		var _gy = (_p.y + 3 + _p.oy + _fall - _cy) * _sy; // level with the top of their head, plus the hop

		// right-aligned, so the text sits to the LEFT of the head and grows leftward as the number gets bigger
		draw_set_alpha(_fade);
		if (_p.crit > 0) {
			draw_menu_text(_gx, _gy, string(_p.total), c_red, dmg_text_scale, fa_right);
			draw_menu_text(_gx, _gy - 11 * dmg_text_scale, "Crit!", c_red, dmg_text_scale, fa_right);
		}
		else {
			draw_menu_text(_gx, _gy, string(_p.total), c_white, dmg_text_scale, fa_right);
		}
		draw_set_alpha(1);
	}
}



// ============================================================
// SPECIAL ATTACK: hold S to charge, and the moment it's full he spins like a tornado
// ============================================================
// hold the special key -> charges for special_charge_time steps (charge circle + glow, he raises his guard)
// fully charged -> shockwave bursts out and he goes STRAIGHT into the SPIN (no need to let go):
//                  he whirls round for special_spin_time steps, hitting everything in special_radius
//                  every special_tick_time steps. you can still steer him slowly
// let go before it's full -> nothing happens (no cooldown)
// hit while charging -> the charge is lost (short cooldown, see Enemy_damage_applying)
// after the spin -> the heavy cooldown (special_cooldown_t)
// the visuals are the fx functions at the bottom of parryState
// ============================================================

/// runs ONCE when the special key is pressed
function startSpecialCharge(){
	state = PlayerState.SPECIAL_CHARGE;

	special_dir4 = round(facing / 90) mod 4;
	special_charge_timer = 0;
	special_charged = false;
	sword_sweep = 0;   // rainbow starts at the bottom
	sword_hue = 0;     // on red + yellow

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
		fxShockwaveBurst(parry_fx_colour, parry_circle_radius, parry_circle_radius * 3);
		startSpecialSpin();
	}
}

/// runs ONCE the moment the charge is full
function startSpecialSpin(){
	audio_stop_sound(snd_charge);
    audio_play_sound(snd_spin, 20, true);
	state = PlayerState.SPECIAL_SPIN;
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
		_g.ghost_colour = dash_ghost_colour[(special_spin_timer div special_ghost_gap) mod array_length(dash_ghost_colour)];
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

/// the wind swirling round him while he spins (Draw, after the knight)
function specialSpinRingDraw(){
	var _r  = special_radius;
	var _cy = y - 14;   // around his middle

	gpu_set_blendmode(bm_add);
	draw_set_colour(parry_fx_colour);

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

/// Draw GUI: "Special ready" or the seconds left on the cooldown, above the health bar
function specialHudDraw(){
	var _x = healthbar_x;
	var _y = healthbar_y - 24;
	if (special_cooldown > 0) {
		draw_menu_text(_x, _y, "Special " + string(ceil(special_cooldown / game_get_speed(gamespeed_fps))), c_gray, 1, fa_center);
	}
	else {
		draw_menu_text(_x, _y, "Special ready", make_colour_rgb(230, 190, 90), 1, fa_center);
	}
}
