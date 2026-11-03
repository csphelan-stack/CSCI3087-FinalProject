// ============================================================
// BUTTERFLY EFFECT (SpecialState.BUTTERFLY)
// ============================================================
// press S -> a 10 second window starts and he's straight back in control (he stays in NORMAL, not SPECIAL).
//            a burst of butterflies flies out from where he's standing, and butterflies gather round the edges of the screen
// during the window -> his hits do NO damage. each one is stored on the enemy it hit instead (bf_hits / bf_stored).
//                      he swings faster, his hitboxes are bigger and reach further, knockback is halved and he
//                      runs 1.5x faster (attackState, Other_7, Movement_MC_script and the hitbox ask butterflyOn()).
//                      every swing shows as a big glowing butterfly instead of the hitbox, every hit lets a couple of
//                      little butterflies loose, and little butterflies flutter up behind him as he moves
// when it ends -> every enemy takes all its stored hits at once, most of them crits (capped so the number stays sane),
//                 with a burst of butterflies and a ring, and butterflies (butterfly_gif_spr) fly out of it to hit
//                 the enemies around it
// the numbers are in the player's Create, under "Butterfly Effect"
// ============================================================

/// is the window on right now? (the attack, movement and hitbox code ask this)
function butterflyOn(){
	return butterfly_timer > 0;
}

/// runs ONCE when S is pressed (called by startSpecial)
function startButterfly(){
	butterfly_timer = butterfly_time;

	// the cooldown starts now and covers the window too, so S can't be pressed again mid-window
	special_cooldown = butterfly_time + butterfly_cooldown_t;

	// a burst of butterflies out of where he's standing, and a soft ring
	butterflyPuff(x, y - 16, butterfly_burst_count, 2, 4.5);
	fxShockwaveBurst(butterflyColour(), 8, 70);

	// butterflies gather round the edges of the screen
	butterflyScreenFill();

	// he isn't locked into anything: straight back to normal control
	state = PlayerState.NORMAL;
}

/// runs EVERY step from the player's Step (outside the state switch, because he's in NORMAL during the window)
function butterflyStep(){
	if (global.gameIsPaused) return;

	// the window counting down
	if (butterfly_timer > 0) {
		butterfly_timer -= 1;

		// little butterflies flutter up behind him as he moves
		butterfly_trail_timer -= 1;
		if (butterfly_trail_timer <= 0) {
			butterfly_trail_timer = 6;
			butterflyPuff(x, y - 10, 1, 0.3, 1);
		}

		if (butterfly_timer <= 0) endButterfly();
	}

	// the butterflies in the air (they keep flying after the window is over)
	butterfliesStep();
	butterflyFxStep();
	butterflyScreenStep();
}

/// the window is over: every enemy takes its stored hits at once, and butterflies fly out of it
function endButterfly(){
	var _player = id;

	with (Enemy_base_obj) {
		if (bf_hits > 0 && state != ENEMY_STATE.DEAD) {

			// each stored hit rolls its own crit
			var _per_hit = bf_stored / bf_hits;
			var _total = 0;
			var _crit = false;
			for (var i = 0; i < bf_hits; i++) {
				if (random(1) < _player.butterfly_crit_chance) {
					_total += _per_hit * _player.butterfly_crit_mult;
					_crit = true;
				} else {
					_total += _per_hit;
				}
			}

			// cap it so the number stays readable
			_total = round(min(_total, total_hp * _player.butterfly_cap_mult));

			hp -= _total;
			enemy_change_state(ENEMY_STATE.HURT);

			// the big number above it (damagePopupAdd runs as the player)
			var _me = id;
			with (_player) damagePopupAdd(_me, _total, _crit);

			// the payoff look: a burst of butterflies and a ring out of it
			var _ex = x;
			var _ey = y - 14;
			var _ring_col = _player.butterfly_colours[irandom(array_length(_player.butterfly_colours) - 1)];
			with (_player) butterflyPuff(_ex, _ey, 8, 1.5, 3.5);
			fxShockwaveBurst(_ring_col, 6, 40);

			// butterflies fly out of it: one per butterfly_hits_each hits, at least 1, at most butterfly_max_each
			var _count = min(_player.butterfly_max_each, max(1, bf_hits div _player.butterfly_hits_each));
			repeat (_count) {
				with (_player) butterflySpawn(_me);
			}
		}

		// fresh start for the next window
		bf_hits = 0;
		bf_stored = 0;
	}
}

/// one butterfly flies out of the middle of _source
function butterflySpawn(_source){
	var _target = butterfly_hit_others ? butterflyFindTarget(_source.x, _source.y, _source) : _source;

	array_push(butterflies, {
		x: _source.x + random_range(-8, 8),
		y: _source.y - 20 + random_range(-8, 8),   // out of its middle, not its feet
		target: _target,
		age: 0,
		wobble: random(360),                       // so they don't all flutter in step
		col: butterflyColour(),
	});
}

/// picks a living enemy near (_x, _y) to fly at: a random one within butterfly_seek_range that isn't _skip,
/// or the nearest one anywhere if none are close, or _skip itself if it's the only one left
function butterflyFindTarget(_x, _y, _skip){
	var _close = [];
	var _nearest = noone;
	var _nearest_d = infinity;
	var _range = butterfly_seek_range;

	with (Enemy_base_obj) {
		if (id != _skip && state != ENEMY_STATE.DEAD) {
			var _d = point_distance(_x, _y, x, y);
			if (_d <= _range) array_push(_close, id);
			if (_d < _nearest_d) {
				_nearest_d = _d;
				_nearest = id;
			}
		}
	}

	if (array_length(_close) > 0) return _close[irandom(array_length(_close) - 1)];
	if (_nearest != noone) return _nearest;
	if (instance_exists(_skip) && _skip.state != ENEMY_STATE.DEAD) return _skip;
	return noone;
}

/// every step: each butterfly flutters toward its target and hits it when it gets there
function butterfliesStep(){
	// go backwards so removing one doesn't skip the next
	for (var i = array_length(butterflies) - 1; i >= 0; i--) {
		var _bf = butterflies[i];
		_bf.age += 1;

		// its target died or vanished: pick a new one near where it is
		if (!instance_exists(_bf.target) || _bf.target.state == ENEMY_STATE.DEAD) {
			_bf.target = butterflyFindTarget(_bf.x, _bf.y, noone);
		}

		// nobody left to hit, or it's been flying too long: it flies off
		if (_bf.target == noone || _bf.age > butterfly_life) {
			array_delete(butterflies, i, 1);
			continue;
		}

		// fly toward the target's middle, weaving from side to side like a butterfly
		var _tx = _bf.target.x;
		var _ty = _bf.target.y - 20;
		var _dir = point_direction(_bf.x, _bf.y, _tx, _ty) + dsin(_bf.age * 12 + _bf.wobble) * 50;
		_bf.x += lengthdir_x(butterfly_speed, _dir);
		_bf.y += lengthdir_y(butterfly_speed, _dir);

		// got there: hit it
		if (point_distance(_bf.x, _bf.y, _tx, _ty) < 10) {
			var _t = _bf.target;
			_t.hp -= butterfly_damage;
			with (_t) enemy_change_state(ENEMY_STATE.HURT);
			damagePopupAdd(_t, butterfly_damage, false);
			butterflyPuff(_tx, _ty, 3, 1, 2.5);
			array_delete(butterflies, i, 1);
		}
	}
}


// ============================================================
// THE LOOK: colours, little butterflies, the sword's butterfly shapes, and the butterflies round the screen
// ============================================================

/// a random colour from butterfly_colours
function butterflyColour(){
	return butterfly_colours[irandom(array_length(butterfly_colours) - 1)];
}

/// draws butterfly_gif_spr centred on (_x, _y). _col = -1 keeps its own colours, any other colour recolours it
/// (the butterfly sits at about (11.5, 18.5) inside its 23x35 frame, so that's the point that goes on (_x, _y))
function butterflyDrawAt(_x, _y, _frame, _scale, _col, _alpha){
	if (_col != -1) gpu_set_fog(true, _col, 0, 0);
	draw_sprite_ext(butterfly_gif_spr, _frame, _x - 11.5 * _scale, _y - 18.5 * _scale, _scale, _scale, 0, c_white, _alpha);
	if (_col != -1) gpu_set_fog(false, c_white, 0, 0);
}

/// lets _count little butterflies loose from (_x, _y), flying outward at _spd_min to _spd_max
function butterflyPuff(_x, _y, _count, _spd_min, _spd_max){
	repeat (_count) {
		var _a = random(360);
		var _s = random_range(_spd_min, _spd_max);
		var _life = irandom_range(40, 70);
		array_push(butterfly_fx, {
			kind: "flutter",
			x: _x,
			y: _y,
			vx: lengthdir_x(_s, _a),
			vy: lengthdir_y(_s, _a),
			life: _life,
			life_max: _life,
			scale: random_range(0.6, 1.2),
			col: butterflyColour(),
			wobble: random(360),
		});
	}
}

/// a sword swing during the window: a big glowing butterfly where the hitbox is, _size times the normal size
function butterflySlash(_x, _y, _size){
	array_push(butterfly_fx, {
		kind: "slash",
		x: _x,
		y: _y,
		vx: 0,
		vy: 0,
		life: 18,
		life_max: 18,
		scale: butterfly_slash_scale * _size,
		col: butterflyColour(),
		wobble: 0,
	});
	butterflyPuff(_x, _y, 2, 1, 2.5);
}

/// every step: the little butterflies flutter along and slow down, drifting upward; the slashes just fade
function butterflyFxStep(){
	for (var i = array_length(butterfly_fx) - 1; i >= 0; i--) {
		var _f = butterfly_fx[i];
		_f.life -= 1;

		if (_f.kind == "flutter") {
			// weave from side to side as they go
			var _spd = point_distance(0, 0, _f.vx, _f.vy);
			var _dir = point_direction(0, 0, _f.vx, _f.vy) + dsin((_f.life_max - _f.life) * 14 + _f.wobble) * 35;
			_f.x += lengthdir_x(_spd, _dir);
			_f.y += lengthdir_y(_spd, _dir);
			_f.vx *= 0.97;
			_f.vy = _f.vy * 0.97 - 0.02;   // and drift upward
		}

		if (_f.life <= 0) array_delete(butterfly_fx, i, 1);
	}
}

/// Draw (room): the little butterflies and the sword's butterfly shapes
function butterflyFxDraw(){
	for (var i = 0; i < array_length(butterfly_fx); i++) {
		var _f = butterfly_fx[i];
		var _age = _f.life_max - _f.life;
		var _frame = (_age div 3) mod sprite_get_number(butterfly_gif_spr);   // wings flapping

		if (_f.kind == "slash") {
			// pops out quickly, then fades: a soft glow behind, the crisp shape in front
			var _t = _age / _f.life_max;
			var _s = _f.scale * (0.7 + 0.4 * min(1, _t * 3));
			gpu_set_blendmode(bm_add);
			butterflyDrawAt(_f.x, _f.y, _frame, _s * 1.25, _f.col, 0.35 * (1 - _t));
			gpu_set_blendmode(bm_normal);
			butterflyDrawAt(_f.x, _f.y, _frame, _s, _f.col, 0.85 * (1 - _t));
		} else {
			butterflyDrawAt(_f.x, _f.y, _frame, _f.scale, _f.col, min(1, _f.life / 15));
		}
	}
}


// ---- the butterflies round the edges of the screen (Draw GUI) ----
// each one has a spot along the edge of the screen (p, going clockwise round it) and a distance in from the edge (d).
// they drift slowly round, bobbing in and out, and fade in when the window starts and out when it ends

/// fills the screen edges with butterflies (when the window starts)
function butterflyScreenFill(){
	var _w = display_get_gui_width();
	var _h = display_get_gui_height();
	var _perimeter = 2 * (_w + _h);

	butterfly_screen = [];
	for (var i = 0; i < butterfly_screen_count; i++) {
		array_push(butterfly_screen, {
			p: _perimeter * i / butterfly_screen_count + random(20),   // spread evenly round the edge
			d: random(butterfly_screen_band),
			spd: random_range(0.2, 0.6),
			phase: random(360),
			col: butterflyColour(),
			scale: random_range(1, 2),
		});
	}
}

/// every step: they drift round the edge, and fade in or out with the window
function butterflyScreenStep(){
	butterfly_screen_alpha = lerp(butterfly_screen_alpha, butterflyOn() ? 1 : 0, 0.05);

	if (butterfly_screen_alpha < 0.01 && !butterflyOn()) {
		butterfly_screen = [];
		return;
	}

	var _perimeter = 2 * (display_get_gui_width() + display_get_gui_height());
	for (var i = 0; i < array_length(butterfly_screen); i++) {
		var _b = butterfly_screen[i];
		_b.p = (_b.p + _b.spd) mod _perimeter;
		_b.phase += 4;
	}
}

/// a point _p of the way clockwise round the screen's edge, _d pixels in from it (returns [x, y])
function butterflyScreenPoint(_p, _d){
	var _w = display_get_gui_width();
	var _h = display_get_gui_height();
	if (_p < _w) return [_p, _d];                                   // along the top
	_p -= _w;
	if (_p < _h) return [_w - _d, _p];                              // down the right
	_p -= _h;
	if (_p < _w) return [_w - _p, _h - _d];                         // along the bottom
	_p -= _w;
	return [_d, _h - _p];                                           // up the left
}

/// Draw GUI: a soft glowing frame and the butterflies round the edges of the screen
function butterflyScreenDraw(){
	if (butterfly_screen_alpha < 0.01) exit;

	var _w = display_get_gui_width();
	var _h = display_get_gui_height();

	// a soft glow round the edge, brightest at the very edge
	gpu_set_blendmode(bm_add);
	draw_set_colour(butterfly_colours[0]);
	for (var k = 0; k < 12; k++) {
		draw_set_alpha(butterfly_screen_alpha * 0.12 * (1 - k / 12));
		draw_rectangle(k * 3, k * 3, _w - 1 - k * 3, _h - 1 - k * 3, true);
		draw_rectangle(k * 3 + 1, k * 3 + 1, _w - 2 - k * 3, _h - 2 - k * 3, true);
	}
	draw_set_alpha(1);
	draw_set_colour(c_white);
	gpu_set_blendmode(bm_normal);

	// the butterflies, bobbing in and out from the edge
	for (var i = 0; i < array_length(butterfly_screen); i++) {
		var _b = butterfly_screen[i];
		var _pt = butterflyScreenPoint(_b.p, _b.d + dsin(_b.phase) * 6);
		var _frame = ((_b.phase div 12) + i) mod sprite_get_number(butterfly_gif_spr);
		butterflyDrawAt(_pt[0], _pt[1], _frame, _b.scale, _b.col, butterfly_screen_alpha * 0.75);
	}
}

/// Draw (room space, from the player's Draw): the hit counters on the enemies, the little butterflies,
/// the sword's butterfly shapes, then the attacking butterflies
function butterfliesDraw(){
	butterflyFxDraw();

	// during the window: how many hits are stored on each enemy, with a little butterfly ("x12")
	if (butterflyOn()) {
		var _col = butterfly_colours[0];
		with (Enemy_base_obj) {
			if (bf_hits > 0 && state != ENEMY_STATE.DEAD) {
				var _bob = dsin(current_time / 4) * 1.5;
				butterflyDrawAt(x - 12, bbox_top - 8 + _bob, (current_time div 120) mod 3, 0.6, _col, 1);
				draw_menu_text(x + 4, bbox_top - 8, "x" + string(bf_hits), _col, 1, fa_center);
			}
		}
	}

	// the butterflies attacking the enemies: a glow in their colour behind each one
	for (var i = 0; i < array_length(butterflies); i++) {
		var _bf = butterflies[i];
		var _frame = (_bf.age div 4) mod sprite_get_number(butterfly_gif_spr);   // wings flapping
		gpu_set_blendmode(bm_add);
		butterflyDrawAt(_bf.x, _bf.y, _frame, butterfly_scale * 1.4, _bf.col, 0.5);
		gpu_set_blendmode(bm_normal);
		butterflyDrawAt(_bf.x, _bf.y, _frame, butterfly_scale, -1, 1);
	}
}
