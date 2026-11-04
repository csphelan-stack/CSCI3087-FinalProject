// ============================================================
// BUTTERFLY EFFECT (SpecialState.BUTTERFLY)
// ============================================================
// press S -> a 10 second window starts and he's straight back in control (he stays in NORMAL, not SPECIAL).
//            a burst of butterflies flies out from where he's standing, and butterflies gather round the edges of the screen
// the window -> his hits do NO damage. the first hit on each enemy TAGS it (bf_hits = 1, bf_stored = that hit's damage);
//               an enemy can only be tagged once (see the hitbox's Collision event), so it pays to hit lots of them.
//               he swings faster, his hitboxes are bigger and reach further, knockback is halved and he
//               runs 1.5x faster (attackState, Other_7, Movement_MC_script and the hitbox ask butterflyOn()).
//               every swing shows as a big glowing butterfly, every hit lets little butterflies loose.
//               meanwhile it RECORDS where he and every enemy are (butterfly_rec)
// the rewind -> when the window ends, time freezes and the recording plays backwards: he and the enemies slide
//               back to where they were when he pressed S (positions only, not health)
// the choice -> time stays frozen. every tag turns into butterfly_sends_per_tag butterflies to send.
//               they can only go to enemies he tagged. the arrow keys jump to the next tagged enemy that way,
//               anywhere in the room, and the camera pans to it
//               (cam_target, see Room_controller_object Step). the attack key places a butterfly on it.
//               pile them on one enemy or spread them out. once the last one's placed, they all go by themselves
// the release -> time starts again and the camera comes back to him. every tagged enemy takes its saved hit (most crit),
//                then the butterflies fly to their enemies and each one lands a massive hit
// the numbers are in the player's Create, under "Butterfly Effect"
// ============================================================

/// is the window on right now? (the attack, movement and hitbox code ask this)
function butterflyOn(){
	return butterfly_timer > 0;
}

/// is any part of the Butterfly Effect still going? (the window, the rewind or the choosing)
/// the special cooldown waits while this is true
function butterflyBusy(){
	return butterfly_timer > 0 || butterfly_phase != "";
}

/// runs ONCE when S is pressed (called by startSpecial)
function startButterfly(){
	butterfly_timer = butterfly_time;
	butterfly_rec = [];
	butterfly_rec_timer = 0;

	// the cooldown is set now (so S can't be pressed again), but it stays full and doesn't
	// count down until the butterflies are sent (see butterflyBusy and the player's Step)
	special_cooldown = butterfly_cooldown_t;

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

		// record where everyone is, for the rewind
		butterfly_rec_timer -= 1;
		if (butterfly_rec_timer <= 0) {
			butterfly_rec_timer = butterfly_rec_gap;
			butterflyRecord();
		}

		if (butterfly_timer <= 0) {
			if (state == PlayerState.DEAD) endButterfly();   // he died mid-window: no rewind, the hits just land
			else startButterflyRewind();
		}
	}

	// the butterflies in the air (they keep flying after the window is over)
	butterfliesStep();
	butterflyFxStep();
	butterflyScreenStep();
}

/// saves where he and every enemy are right now (one snapshot)
function butterflyRecord(){
	var _enemies = [];
	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD) array_push(_enemies, [id, x, y, sprite_index, image_index]);
	}
	array_push(butterfly_rec, { x: x, y: y, spr: sprite_index, img: image_index, en: _enemies });
}


// ============================================================
// THE REWIND, THE CHOICE AND THE RELEASE (he's in PlayerState.SPECIAL for these)
// ============================================================

/// runs EVERY step while he's in the rewind or the choice (called by specialStateMC)
function butterflyPhaseStep(){
	if (global.gameIsPaused) return;
	invuln = max(invuln, 2);   // time is frozen, nothing can hurt him

	switch (butterfly_phase) {
		case "rewind": butterflyRewindStep(); break;
		case "choose": butterflyChooseStep(); break;
		default:       state = PlayerState.NORMAL; break;
	}
}

/// the window is over: freeze time and start rewinding
function startButterflyRewind(){
	state = PlayerState.SPECIAL;
	butterfly_phase = "rewind";
	butterfly_rewind_t = 0;

	// freeze every enemy, animation and all (their Step lets the animation go again when time restarts)
	global.enemy_time_scale = 0;
	with (Enemy_base_obj) image_speed = 0;
	image_speed = 0;

	// nothing recorded (shouldn't happen): straight to the choice
	if (array_length(butterfly_rec) == 0) startButterflyChoose();
}

/// the recording plays backwards: everyone slides back to where they were when he pressed S
function butterflyRewindStep(){
	butterfly_rewind_t += 1;

	// eased: slow to start, fast in the middle, slow to stop
	var _p = min(1, butterfly_rewind_t / butterfly_rewind_time);
	_p = _p * _p * (3 - 2 * _p);

	// from the newest snapshot back to the oldest
	var _n = array_length(butterfly_rec);
	var _s = butterfly_rec[round((1 - _p) * (_n - 1))];

	x = _s.x;
	y = _s.y;
	sprite_index = _s.spr;
	image_index = _s.img;

	// enemies that are still around go back too (any that showed up during the window just stay where they are)
	for (var i = 0; i < array_length(_s.en); i++) {
		var _e = _s.en[i];
		var _inst = _e[0];
		if (instance_exists(_inst) && _inst.state != ENEMY_STATE.DEAD) {
			_inst.x = _e[1];
			_inst.y = _e[2];
			_inst.sprite_index = _e[3];
			_inst.image_index = _e[4];
		}
	}

	// a trail of coloured afterimages as he's pulled back
	if (butterfly_rewind_t mod 3 == 0) {
		var _g = instance_create_depth(x, y, depth + 1, dash_afterimage_obj);
		_g.sprite_index = sprite_index;
		_g.image_index  = image_index;
		_g.image_xscale = image_xscale;
		_g.image_yscale = image_yscale;
		_g.ghost_colour = butterflyColour();
		_g.image_alpha  = 0.5;
		_g.start_alpha  = 0.5;
		_g.fade_time    = 20;
	}

	if (butterfly_rewind_t >= butterfly_rewind_time) startButterflyChoose();
}

/// back at the start: every tag turns into butterflies to send, and he picks where they go
function startButterflyChoose(){
	butterfly_rec = [];
	butterfly_phase = "choose";
	butterfly_choose_t = 0;
	sprite_index = idle_spr[round(facing / 90) mod 4];
	image_speed = 0.5;

	// how many he gets to send: butterfly_sends_per_tag for every enemy he tagged
	var _tags = 0;
	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD && bf_hits > 0) _tags += 1;
	}
	butterfly_budget = min(butterfly_send_max, _tags * butterfly_sends_per_tag);
	butterfly_left = butterfly_budget;

	// the enemies he can send them to: only the ones he tagged
	butterfly_choices = [];
	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD && bf_hits > 0) array_push(other.butterfly_choices, id);
	}
	butterfly_sends = array_create(array_length(butterfly_choices), 0);

	// he didn't tag anyone: straight on to the release
	if (array_length(butterfly_choices) == 0 || butterfly_budget <= 0) {
		butterflyRelease();
		return;
	}

	// start on the closest tagged enemy
	butterfly_sel = 0;
	var _best = infinity;
	for (var i = 0; i < array_length(butterfly_choices); i++) {
		var _e = butterfly_choices[i];
		var _d = point_distance(x, y, _e.x, _e.y);
		if (_d < _best) {
			_best = _d;
			butterfly_sel = i;
		}
	}
	cam_target = butterfly_choices[butterfly_sel];   // the camera pans to it
}

/// the enemy to jump to from the one he's picking, for an arrow key (_dir: 0 right, 90 up, 180 left, 270 down):
/// the closest one roughly that way, anywhere in the room. its place in butterfly_choices, or -1 if nobody's that way
function butterflyPickInDirection(_dir){
	var _from = butterfly_choices[butterfly_sel];
	if (!instance_exists(_from)) return -1;

	var _best = -1;
	var _best_score = infinity;
	for (var i = 0; i < array_length(butterfly_choices); i++) {
		if (i == butterfly_sel) continue;
		var _e = butterfly_choices[i];
		if (!instance_exists(_e)) continue;

		var _off = abs(angle_difference(point_direction(_from.x, _from.y, _e.x, _e.y), _dir));
		if (_off > 80) continue;   // not that way

		// closest first, but ones straight that way beat ones off to the side
		var _score = point_distance(_from.x, _from.y, _e.x, _e.y) * (1 + _off / 45);
		if (_score < _best_score) {
			_best_score = _score;
			_best = i;
		}
	}
	return _best;
}

/// time is frozen: the arrows pick a tagged enemy and the attack key places a butterfly on it.
/// once every butterfly is placed they all go by themselves
function butterflyChooseStep(){
	butterfly_choose_t += 1;

	// all placed: a short beat so you can see where they all are, then they go
	if (butterfly_left <= 0) {
		butterfly_go_delay -= 1;
		if (butterfly_go_delay <= 0) butterflyRelease();
		return;
	}

	// time's up (if there's a limit): any left over go on the enemy he's picking
	if (butterfly_choose_limit > 0 && butterfly_choose_t >= butterfly_choose_limit) {
		butterfly_sends[butterfly_sel] += butterfly_left;
		butterfly_left = 0;
		butterfly_go_delay = butterfly_go_wait;
		return;
	}

	// pick an enemy: jump to the next one in the direction pressed
	var _dir = -1;
	if (keyboard_check_pressed(global.right_button))     _dir = 0;
	else if (keyboard_check_pressed(global.up_button))   _dir = 90;
	else if (keyboard_check_pressed(global.left_button)) _dir = 180;
	else if (keyboard_check_pressed(global.down_button)) _dir = 270;
	if (_dir != -1) {
		var _next = butterflyPickInDirection(_dir);
		if (_next != -1) butterfly_sel = _next;
	}

	var _t = butterfly_choices[butterfly_sel];
	cam_target = _t;   // the camera follows the one he's picking, so he can look all round the room

	// place one on it
	if (keyboard_check_pressed(global.attack_button)) {
		butterfly_sends[butterfly_sel] += 1;
		butterfly_left -= 1;
		if (instance_exists(_t)) butterflyPuff(_t.x, _t.y - 14, 3, 0.5, 1.5);

		// that was the last one: they all go after a short beat
		if (butterfly_left <= 0) butterfly_go_delay = butterfly_go_wait;
	}
}

/// time starts again: the camera comes back to him, the tags land, then the butterflies he sent fly out
function butterflyRelease(){
	butterfly_phase = "";
	state = PlayerState.NORMAL;
	image_speed = 1;
	invuln = max(invuln, 30);   // a moment's grace as time comes back
	global.enemy_time_scale = 1;
	cam_target = noone;

	// 1. every tagged enemy takes its saved hit
	endButterfly();

	// 2. the butterflies he sent fly to their enemies (if one's already gone, they find another)
	for (var i = 0; i < array_length(butterfly_choices); i++) {
		repeat (butterfly_sends[i]) {
			butterflySendTo(butterfly_choices[i]);
		}
	}

	butterfly_choices = [];
	butterfly_sends = [];
	butterfly_budget = 0;
	butterfly_left = 0;
}

/// every enemy takes all its stored hits at once, most of them crits, with a burst of butterflies
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

			// a burst of butterflies and a ring out of it
			var _ex = x;
			var _ey = y - 14;
			var _ring_col = _player.butterfly_colours[irandom(array_length(_player.butterfly_colours) - 1)];
			with (_player) butterflyPuff(_ex, _ey, 8, 1.5, 3.5);
			fxShockwaveBurst(_ring_col, 6, 40);
		}

		// fresh start for the next window
		bf_hits = 0;
		bf_stored = 0;
	}
}

/// one of the butterflies he sent: flies from him to _target and lands a big hit (sometimes a crit)
function butterflySendTo(_target){
	var _crit = random(1) < butterfly_crit_chance;
	var _dmg = round(player_damage * butterfly_send_mult * (_crit ? butterfly_crit_mult : 1));

	array_push(butterflies, {
		x: x + random_range(-10, 10),
		y: y - 20 + random_range(-10, 10),
		target: _target,
		age: -irandom(12),          // they don't all leave at the same moment
		wobble: random(360),        // so they don't all flutter in step
		col: butterflyColour(),
		dmg: _dmg,
		crit: _crit,
	});
}

/// the closest living enemy to (_x, _y) (for a butterfly whose enemy is already gone), or noone
function butterflyFindTarget(_x, _y){
	var _nearest = noone;
	var _nearest_d = infinity;
	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD) {
			var _d = point_distance(_x, _y, x, y);
			if (_d < _nearest_d) {
				_nearest_d = _d;
				_nearest = id;
			}
		}
	}
	return _nearest;
}

/// every step: each butterfly he sent flutters toward its enemy and hits it when it gets there
function butterfliesStep(){
	// go backwards so removing one doesn't skip the next
	for (var i = array_length(butterflies) - 1; i >= 0; i--) {
		var _bf = butterflies[i];
		_bf.age += 1;
		if (_bf.age < 0) continue;   // still waiting to leave

		// its enemy died or vanished: go for the closest one instead
		if (!instance_exists(_bf.target) || _bf.target.state == ENEMY_STATE.DEAD) {
			_bf.target = butterflyFindTarget(_bf.x, _bf.y);
		}

		// nobody left to hit, or it's been flying too long: it flies off
		if (_bf.target == noone || _bf.age > butterfly_life) {
			array_delete(butterflies, i, 1);
			continue;
		}

		// fly toward the enemy's middle, weaving from side to side like a butterfly
		var _tx = _bf.target.x;
		var _ty = _bf.target.y - 20;
		var _dir = point_direction(_bf.x, _bf.y, _tx, _ty) + dsin(_bf.age * 12 + _bf.wobble) * 40;
		_bf.x += lengthdir_x(butterfly_speed, _dir);
		_bf.y += lengthdir_y(butterfly_speed, _dir);

		// got there: the big hit
		if (point_distance(_bf.x, _bf.y, _tx, _ty) < 10) {
			var _t = _bf.target;
			_t.hp -= _bf.dmg;
			with (_t) enemy_change_state(ENEMY_STATE.HURT);
			damagePopupAdd(_t, _bf.dmg, _bf.crit);
			butterflyPuff(_tx, _ty, _bf.crit ? 6 : 3, 1, 3);
			var _col = _bf.col;
			with (_t) fxShockwaveBurst(_col, 4, 28);
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
/// (while time is frozen in the rewind and the choice, they hang in the air)
function butterflyFxStep(){
	if (butterfly_phase != "") return;

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
// they drift slowly round, bobbing in and out, and fade in when the window starts and out once it's all over.
// in the rewind they race backwards round the edge

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
	var _busy = butterflyOn() || butterfly_phase != "";
	butterfly_screen_alpha = lerp(butterfly_screen_alpha, _busy ? 1 : 0, 0.05);

	if (butterfly_screen_alpha < 0.01 && !_busy) {
		butterfly_screen = [];
		return;
	}

	var _perimeter = 2 * (display_get_gui_width() + display_get_gui_height());
	var _dir = (butterfly_phase == "rewind") ? -6 : 1;   // racing backwards in the rewind
	for (var i = 0; i < array_length(butterfly_screen); i++) {
		var _b = butterfly_screen[i];
		_b.p = (_b.p + _b.spd * _dir + _perimeter) mod _perimeter;
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

/// Draw GUI: the rewind's tint and lines, and the choice's instructions (drawn over the HUD)
function butterflyPhaseHudDraw(){
	if (butterfly_phase == "") exit;

	var _w = display_get_gui_width();
	var _h = display_get_gui_height();

	if (butterfly_phase == "rewind") {
		// a violet tint with lines rolling up the screen, like a tape rewinding
		draw_set_alpha(0.22);
		draw_set_colour(butterfly_colours[1]);
		draw_rectangle(0, 0, _w, _h, false);
		draw_set_alpha(0.1);
		draw_set_colour(c_white);
		var _roll = (butterfly_rewind_t * 6) mod 8;
		for (var ly = -_roll; ly < _h; ly += 8) {
			draw_rectangle(0, ly, _w, ly + 1, false);
		}
		draw_set_alpha(0.6 + 0.4 * abs(dsin(butterfly_rewind_t * 12)));
		draw_menu_text(_w / 2, 40, "REWIND", c_white, 3, fa_center);
		draw_set_alpha(1);
	}
	else if (butterfly_phase == "choose") {
		// a faint tint so it's clear time is stopped
		draw_set_alpha(0.12);
		draw_set_colour(butterfly_colours[1]);
		draw_rectangle(0, 0, _w, _h, false);
		draw_set_alpha(1);

		// how many are left to place, and the keys
		draw_menu_text(_w / 2, 36, "BUTTERFLIES: " + string(butterfly_left), butterfly_colours[0], 2, fa_center);
		draw_menu_text(_w / 2, _h - 30, "Arrows choose   " + key_name(global.attack_button) + " place a butterfly", c_white, 1, fa_center);

		// a time limit, if there is one (hidden once they're all placed)
		if (butterfly_choose_limit > 0 && butterfly_left > 0) {
			var _secs = ceil((butterfly_choose_limit - butterfly_choose_t) / 60);
			draw_menu_text(_w / 2, 60, string(_secs), c_white, 1, fa_center);
		}
	}

	draw_set_colour(c_white);
}

/// Draw (room space, from the player's Draw): the little butterflies, the hit counters on the enemies,
/// the choice's marker and the butterflies waiting on each enemy, then the butterflies in flight
function butterfliesDraw(){
	butterflyFxDraw();

	// a glowing butterfly over every tagged enemy, through the window and the choice
	if (butterflyOn() || butterfly_phase != "") {
		var _col = butterfly_colours[0];
		with (Enemy_base_obj) {
			if (bf_hits > 0 && state != ENEMY_STATE.DEAD) {
				var _bob = dsin(current_time / 4) * 1.5;
				var _frame = (current_time div 120) mod 3;
				gpu_set_blendmode(bm_add);
				butterflyDrawAt(x, bbox_top - 10 + _bob, _frame, 1.3, _col, 0.4);
				gpu_set_blendmode(bm_normal);
				butterflyDrawAt(x, bbox_top - 10 + _bob, _frame, 0.9, _col, 1);
			}
		}
	}

	// the choice: a ring on the enemy he's picking, and the butterflies he's sent circling each enemy
	if (butterfly_phase == "choose") {
		for (var i = 0; i < array_length(butterfly_choices); i++) {
			var _e = butterfly_choices[i];
			if (!instance_exists(_e)) continue;
			var _ex = _e.x;
			var _ey = _e.y - 14;

			// the marker
			if (i == butterfly_sel) {
				gpu_set_blendmode(bm_add);
				draw_set_colour(butterfly_colours[0]);
				draw_set_alpha(0.9);
				var _pulse = 18 + dsin(current_time / 3) * 2;
				draw_circle(_ex, _ey, _pulse, true);
				draw_circle(_ex, _ey, _pulse + 1, true);
				var _spin = current_time / 8;
				for (var t = 0; t < 4; t++) {
					var _ta = _spin + t * 90;
					draw_line_width(_ex + lengthdir_x(_pulse + 3, _ta), _ey + lengthdir_y(_pulse + 3, _ta),
					                _ex + lengthdir_x(_pulse + 8, _ta), _ey + lengthdir_y(_pulse + 8, _ta), 2);
				}
				draw_set_alpha(1);
				draw_set_colour(c_white);
				gpu_set_blendmode(bm_normal);
			}

			// the butterflies waiting to go to it, circling it
			var _k = butterfly_sends[i];
			for (var b = 0; b < _k; b++) {
				var _a = current_time / 6 + b * 360 / _k;
				var _frame = ((current_time div 100) + b) mod sprite_get_number(butterfly_gif_spr);
				butterflyDrawAt(_ex + lengthdir_x(14, _a), _ey + lengthdir_y(8, _a), _frame, 0.8, butterfly_colours[b mod array_length(butterfly_colours)], 1);
			}
			if (_k > 0) draw_menu_text(_ex, _ey + 20, string(_k), c_white, 1, fa_center);
		}
	}

	// the butterflies in flight: a glow in their colour behind each one
	for (var i = 0; i < array_length(butterflies); i++) {
		var _bf = butterflies[i];
		if (_bf.age < 0) continue;   // not left yet
		var _frame = (_bf.age div 4) mod sprite_get_number(butterfly_gif_spr);   // wings flapping
		gpu_set_blendmode(bm_add);
		butterflyDrawAt(_bf.x, _bf.y, _frame, butterfly_scale * 1.4, _bf.col, 0.5);
		gpu_set_blendmode(bm_normal);
		butterflyDrawAt(_bf.x, _bf.y, _frame, butterfly_scale, -1, 1);
	}
}
