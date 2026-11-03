function attackStatePlayer(){


    // has the swing reached the hit frame, and have we NOT made a hitbox yet this swing?
    if (image_index >= attack_hit_frame && !attack_hit_spawned) {

        attack_hit_spawned = true;  // only ever make one per swing

        // which way is he facing? snapped to exactly 0, 90, 180 or 270
        var dir4 = round(facing / 90) mod 4;
       
        var _dir = dir4 * 90;
		
		//tracks the opposite of the swing direction so we can apply knockback
		opp_swing_dir = dir4*90+180;

        // Butterfly Effect: a bigger hitbox that reaches further (1 = normal)
        var _range = butterflyOn() ? butterfly_range_mult : 1;

        // half the hitbox's size, so we can line up its EDGE instead of its centre
        var _half_w = sprite_get_width(main_character_hitbox_spr) / 2 * _range;
        var _half_h = sprite_get_height(main_character_hitbox_spr) / 2 * _range;

        // start at the peak of the swing, then step back toward him by half the box,
        // so the far edge of the box sits right on the peak
        // (the peaks are in sprite pixels, so they grow with his size)
        var _hx = x + attack_peak_x[dir4] * char_scale * _range - lengthdir_x(_half_w, _dir);
        var _hy = y + attack_peak_y[dir4] * char_scale * _range - lengthdir_y(_half_h, _dir);

        var _hb = instance_create_layer(_hx, _hy, layer, main_character_hitbox_obj);
		_hb.image_xscale = _range;
		_hb.image_yscale = _range;

		// counters (from a parry) hit harder than a normal swing
		_hb.damage = attack_is_countered ? counter_damage : player_damage;
		_hb.is_crit = attack_is_countered;   // counters show "Crit!" above the enemy they hit

		// Butterfly Effect: the hit is stored on the enemy instead of doing damage, and knocks back half as hard
		if (butterflyOn()) {
			_hb.bf_store = true;
			_hb.knockback *= butterfly_kb_mult;

			// and the swing shows as a big glowing butterfly instead of the hitbox square
			_hb.image_alpha = 0;
			butterflySlash(_hx, _hy, _range);
		}

		
        _hb.owner = id;   //telling the hitbox who made it
		}
}

// _counter = true when the swing comes from a successful parry (see parrySuccess), normal attacks leave it out
function startAttackPlayer(_counter = false){
    // runs ONCE when Z is pressed
    state = PlayerState.ATTACK;

    // same direction math as the movement code: 0 = right, 1 = up, 2 = left, 3 = down
    var dir4 = round(facing / 90) mod 4;
    sprite_index = attack_spr[dir4];   // set in Create
    image_index = 0;   // start the swing from the first frame
    image_speed = 1.2;   // play at the sprite's normal speed
	if (butterflyOn()) image_speed *= butterfly_attack_mult;   // Butterfly Effect: much faster swings

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

