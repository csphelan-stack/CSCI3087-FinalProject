// ============================================================
// DANCE OF DRAGONS (SpecialState.DANCE)
// ============================================================
// press S -> he goes straight away (dance_windup_time = 0). if you give it a wind-up, he stands still while an
//            orange-red circle fills under him, and getting hit then cancels it (see Enemy_damage_applying)
// the dash -> he dashes to the closest enemy within dance_range without stopping
// the QTE -> as he gets there, a glowing ring closes in on the small ring round the enemy, with your attack key
//            in the middle. press it when the rings meet. graded by how close to the moment he arrives you pressed:
//            PERFECT (within dance_perfect_frames) = a crit, a bigger burst, a burst of sparks, a tiny hit-stop,
//                                                     and the chain can go 1 further
//            GOOD    (within dance_good_frames)    = a normal strike (dance_hit_radius, much bigger than the sword)
//            MISS    (too early, too late, never)  = a weak strike. the first MISS is forgiven,
//                                                     the dance ends after dance_miss_limit (2) of them
//            then he circles the enemy and dashes on to the next closest one he hasn't hit yet,
//            up to dance_targets_max (5) in a row (+1 for every PERFECT). it ends early if nobody's left nearby
// slow motion -> enemies run at dance_enemy_scale (a quarter speed) the whole time he dances
//                (global.enemy_time_scale, see the slow motion in Enemy_base_obj Step)
// the trail -> an orange and red trail follows the path he dances. any enemy it touches takes a little
//              damage and catches fire too (danceTrailStep / danceTrailDraw)
// he can't be hurt while dancing
// the finisher -> when the chain is over (if he struck anyone), time slows even further (dance_finale_scale),
//                 a ring grows round him while he slowly spins and the dragon climbs then dives into the ground,
//                 exploding into flames as a blast (INFERNO!) damages and flings
//                 every enemy within dance_finale_radius, and they drift away in slow motion before time comes back
// the end -> every enemy a strike, the trail or the finisher touched starts burning (see the burn in Enemy_base_obj Step),
//            and the dance_cooldown_t (10 second) cooldown starts
// the dragon -> while the Dance is equipped a small dragon circles him, follows him when he dances,
//               and bites enemies it touches when he isn't dancing (see THE DRAGON COMPANION at the bottom)
// the numbers are in the player's Create, under "Dance of Dragons"
// ============================================================

/// runs ONCE when S is pressed (called by startSpecial)
function startDance(){
	dance_phase = "windup";
	dance_timer = dance_windup_time;
	dance_route = [];
	dance_index = 0;
	dance_hit_list = [];
	dance_trail = [];
	dance_trail_hits = [];
	dance_chain_max = dance_targets_max;
	dance_end_after = false;
	dance_misses = 0;
	dance_hitstop = 0;

	// slow the world down while he dances (danceFinish puts it back)
	global.enemy_time_scale = dance_enemy_scale;

	// no wind-up: straight off to the first enemy
	if (dance_windup_time <= 0) {
		danceNextTarget();   // ends straight away (with no cooldown) if nobody's in range
		return;
	}

	// wind-up: stands still facing the way he was
	sprite_index = idle_spr[round(facing / 90) mod 4];
	image_speed = 0.5;
}

/// runs EVERY step while dancing (called by specialStateMC)
function danceStateMC(){
	if (global.gameIsPaused) return;

	// hit-stop: after a PERFECT he freezes for a few frames, so it lands with a punch
	if (dance_hitstop > 0) {
		dance_hitstop -= 1;
		invuln = max(invuln, 2);
		return;
	}

	switch (dance_phase) {
		case "windup": danceWindupStep(); break;
		case "dash":   danceDashStep();   break;
		case "strike": danceStrikeStep(); break;
		case "finale": danceFinaleStep(); break;
	}
}

/// the wind-up: stand still, then go for the first enemy
function danceWindupStep(){
	dance_timer -= 1;
	if (dance_timer > 0) return;

	danceNextTarget();   // ends straight away (with no cooldown) if nobody's in range
}

/// is this enemy still there to dance to?
function danceTargetAlive(_e){
	return instance_exists(_e) && _e.state != ENEMY_STATE.DEAD;
}

/// the closest living enemy within dance_range of where he is NOW that he hasn't danced to yet (noone if none)
function danceFindNext(){
	var _best = noone;
	var _best_d = infinity;
	var _px = x;
	var _py = y;
	var _range = dance_range;
	var _done = dance_route;

	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD && !array_contains(_done, id)) {
			var _d = point_distance(_px, _py, x, y);
			if (_d <= _range && _d < _best_d) {
				_best_d = _d;
				_best = id;
			}
		}
	}
	return _best;
}

/// dashes off to the next closest enemy, or ends the dance
function danceNextTarget(){
	// done as many as the chain allows
	if (array_length(dance_route) >= dance_chain_max) {
		danceEnd(true);
		return;
	}

	var _next = danceFindNext();

	// nobody left nearby: the dance ends (no finisher or cooldown if he never got to anyone)
	if (_next == noone) {
		danceEnd(array_length(dance_route) > 0);
		return;
	}

	array_push(dance_route, _next);
	dance_index = array_length(dance_route) - 1;
	dance_phase = "dash";
	dance_timer = dance_leg_time_max;
	dance_pressed = false;   // a new strike to time
	audio_play_sound(snd_dash, 15, false);
}

/// the spot beside the enemy he's dashing to (on his side of it)
function danceDashGoal(_t){
	var _side = point_direction(_t.x, _t.y, x, y);
	return [_t.x + lengthdir_x(dance_orbit_radius, _side), _t.y + lengthdir_y(dance_orbit_radius, _side)];
}

/// how many frames until he arrives (used for the timing and the closing ring)
function danceFramesToArrive(){
	if (dance_phase != "dash" || dance_index >= array_length(dance_route)) return 0;
	var _t = dance_route[dance_index];
	if (!danceTargetAlive(_t)) return 0;
	var _goal = danceDashGoal(_t);
	return point_distance(x, y, _goal[0], _goal[1]) / dance_dash_speed;
}

/// dashing to the next enemy (the key can be pressed a little early, just before he gets there)
function danceDashStep(){
	invuln = max(invuln, 2);   // can't be hurt while dancing

	var _t = dance_route[dance_index];
	if (!danceTargetAlive(_t)) {
		// it died before he got there: it doesn't count, find another one nearby
		array_delete(dance_route, dance_index, 1);
		danceNextTarget();
		return;
	}

	// pressed on the way in: graded by how many frames early it was
	if (!dance_pressed && keyboard_check_pressed(global.attack_button)) {
		dance_pressed = true;
		dance_press_grade = danceGrade(danceFramesToArrive());
	}

	var _goal = danceDashGoal(_t);
	var _dir = point_direction(x, y, _goal[0], _goal[1]);
	var _step = min(dance_dash_speed, point_distance(x, y, _goal[0], _goal[1]));
	move_and_collide(lengthdir_x(_step, _dir), lengthdir_y(_step, _dir), wall_obj);

	// mid-dash pose, facing where he's going
	facing = _dir;
	sprite_index = dash_spr[round(_dir / 90) mod 4];
	image_speed = 0;
	image_index = image_number div 2;
	danceGhost();

	// got there: start circling it (the strike lands now if the key was pressed in time, or when it is)
	if (point_distance(x, y, _goal[0], _goal[1]) < 2) {
		danceStartStrike(_t);
		return;
	}

	// couldn't get there (a wall in the way): skip this one (it stays on the list so he doesn't try it again)
	dance_timer -= 1;
	if (dance_timer <= 0) {
		danceNextTarget();
	}
}

/// "perfect", "good" or "miss" for a press _frames away from the moment he arrived
function danceGrade(_frames){
	var _off = abs(_frames);
	if (_off <= dance_perfect_frames) return "perfect";
	if (_off <= dance_good_frames) return "good";
	return "miss";
}

/// arrived: he starts circling it
function danceStartStrike(_t){
	dance_phase = "strike";
	dance_timer = dance_orbit_time;
	dance_cx = _t.x;
	dance_cy = _t.y;
	dance_orbit_start = point_direction(dance_cx, dance_cy, x, y);
	dance_angle = dance_orbit_start;
	dance_orbit_dir = choose(-1, 1);   // circles one way or the other, so it looks like a dance
	dance_late = 0;                    // frames since he arrived (for a late press)
	dance_resolved = false;

	// swing pose, facing it
	sprite_index = attack_spr[round(point_direction(x, y, dance_cx, dance_cy) / 90) mod 4];
	image_index = 0;
	image_speed = 1.5;

	// the key was already pressed on the way in: the strike lands right away
	if (dance_pressed) danceResolve(dance_press_grade);
}

/// the strike lands, as strong as the timing was
function danceResolve(_grade){
	dance_resolved = true;

	var _dmg    = round(player_damage * dance_damage_mult);
	var _radius = dance_hit_radius;
	var _crit   = false;
	var _colour = dance_colour;
	var _sparks = 8;

	switch (_grade) {
		case "perfect":
			_dmg    = round(_dmg * dance_perfect_mult);
			_radius = dance_hit_radius * dance_perfect_radius;
			_crit   = true;
			_colour = dance_trail_head;   // brighter burst
			_sparks = 16;
			dance_hitstop = dance_perfect_hitstop;
			dance_chain_max = min(dance_chain_cap, dance_chain_max + 1);   // the chain can go one further
			break;
		case "miss":
			_dmg    = max(1, round(_dmg * dance_miss_mult));
			_radius = dance_hit_radius * 0.6;
			_sparks = 3;
			// the first miss is forgiven. too many and the dance ends once he's done circling this one
			dance_misses += 1;
			if (dance_misses >= dance_miss_limit) dance_end_after = true;
			break;
	}

	danceHit(dance_cx, dance_cy - 14, _radius, _dmg, _crit);

	var _t = dance_route[dance_index];
	if (instance_exists(_t)) {
		with (_t) {
			fxShockwaveBurst(_colour, 8, _radius);                            // the ring bursting out of it
			if (_grade == "perfect") fxShockwaveBurst(c_white, 4, _radius * 0.6);   // and a white flash inside it
		}
	}
	danceSparks(dance_cx, dance_cy - 14, _sparks, _grade == "perfect");
	audio_play_sound(snd_sword, 20, false);

	// "PERFECT!" / "GOOD" / "MISS" pops up above it
	dance_grade_text  = (_grade == "perfect") ? "PERFECT!" : ((_grade == "good") ? "GOOD" : "MISS");
	dance_grade_timer = dance_grade_time;
	dance_grade_x     = dance_cx;
	dance_grade_y     = dance_cy - 44;
}

/// damages every enemy within _radius of (_cx, _cy), and remembers them for the burn
function danceHit(_cx, _cy, _radius, _dmg, _crit){
	var _list = ds_list_create();
	var _n = collision_circle_list(_cx, _cy, _radius, Enemy_base_obj, false, true, _list, false);

	for (var i = 0; i < _n; i++) {
		var _e = _list[| i];
		if (_e.state == ENEMY_STATE.DEAD) continue;

		_e.hp -= _dmg;

		// knocked out from the middle of the strike
		var _kb_dir = point_direction(_cx, _cy, _e.x, _e.y);
		_e.kb_x = lengthdir_x(dance_knockback, _kb_dir);
		_e.kb_y = lengthdir_y(dance_knockback, _kb_dir);
		with (_e) enemy_change_state(ENEMY_STATE.HURT);

		damagePopupAdd(_e, _dmg, _crit);

		// it'll burn at the end of the dance
		if (!array_contains(dance_hit_list, _e)) array_push(dance_hit_list, _e);
	}

	ds_list_destroy(_list);
}

/// circling the enemy he just reached (the key can still be pressed a little late)
function danceStrikeStep(){
	invuln = max(invuln, 2);

	// follow it if it's still there (the strike knocks it back a little)
	var _t = dance_route[dance_index];
	if (danceTargetAlive(_t)) {
		dance_cx = _t.x;
		dance_cy = _t.y;
	}

	// ---- timing: a late press, or no press at all ----
	if (!dance_resolved) {
		dance_late += 1;
		if (keyboard_check_pressed(global.attack_button)) {
			danceResolve(danceGrade(dance_late));
		}
		else if (dance_late > dance_good_frames) {
			danceResolve("miss");   // never pressed
		}
	}

	// ---- circling round it ----
	// partway round: 0 at the start, 1 when he's gone the whole dance_orbit_turn
	var _progress = 1 - dance_timer / dance_orbit_time;
	dance_angle = dance_orbit_start + dance_orbit_dir * dance_orbit_turn * _progress;
	var _gx = dance_cx + lengthdir_x(dance_orbit_radius, dance_angle);
	var _gy = dance_cy + lengthdir_y(dance_orbit_radius, dance_angle);
	move_and_collide(_gx - x, _gy - y, wall_obj);

	facing = point_direction(x, y, dance_cx, dance_cy);   // keeps facing it while he goes round
	danceGhost();

	// done circling: on to the next enemy, unless there were too many misses
	dance_timer -= 1;
	if (dance_timer <= 0) {
		if (!dance_resolved) danceResolve("miss");   // safety: the strike always lands
		if (dance_end_after) danceEnd(true);
		else danceNextTarget();
	}
}

/// the chain is over: the finisher if he got to anyone, otherwise straight back to normal
function danceEnd(_used){
	if (_used) danceStartFinale();
	else danceFinish(false);
}


// ============================================================
// THE FINISHER: time slows even further, he winds up in place, then a big blast all round him
// ============================================================

/// starts the finisher (called by danceEnd)
function danceStartFinale(){
	dance_phase = "finale";
	dance_timer = dance_finale_time;
	global.enemy_time_scale = dance_finale_scale;   // even slower than the dance

	// a slow spin in place
	sprite_index = attack_spr[round(facing / 90) mod 4];
	image_index = 0;
	image_speed = 0.3;
}

/// the finisher: winds up, the blast goes off dance_finale_hit_at frames before the end,
/// and the last few frames let the knockback play out in slow motion
function danceFinaleStep(){
	invuln = max(invuln, 2);

	// turn slowly through the four directions while winding up
	if (dance_timer > dance_finale_hit_at && dance_timer mod 6 == 0) {
		facing = (facing + 90) mod 360;
		sprite_index = attack_spr[round(facing / 90) mod 4];
	}

	dance_timer -= 1;
	if (dance_timer == dance_finale_hit_at) danceFinaleBlast();
	if (dance_timer <= 0) danceFinish(true);
}

/// the big blast: damages and flings every enemy within dance_finale_radius of him
function danceFinaleBlast(){
	var _cx = x;
	var _cy = y - 14;
	var _dmg = round(player_damage * dance_finale_mult);

	var _list = ds_list_create();
	var _n = collision_circle_list(_cx, _cy, dance_finale_radius, Enemy_base_obj, false, true, _list, false);
	for (var i = 0; i < _n; i++) {
		var _e = _list[| i];
		if (_e.state == ENEMY_STATE.DEAD) continue;

		_e.hp -= _dmg;
		var _kb_dir = point_direction(_cx, _cy, _e.x, _e.y);
		_e.kb_x = lengthdir_x(dance_finale_knockback, _kb_dir);
		_e.kb_y = lengthdir_y(dance_finale_knockback, _kb_dir);
		with (_e) enemy_change_state(ENEMY_STATE.HURT);
		damagePopupAdd(_e, _dmg, true);

		if (!array_contains(dance_hit_list, _e)) array_push(dance_hit_list, _e);   // it burns too
	}
	ds_list_destroy(_list);

	// the look: the dragon (diving into the ground right here) explodes into flames, with a ring and a white flash
	dragonExplode(x, y);
	fxShockwaveBurst(dance_colour, 8, dance_finale_radius);
	fxShockwaveBurst(c_white, 4, dance_finale_radius * 0.4);
	danceSparks(_cx, _cy, 20, true);
	audio_play_sound(snd_sword, 20, false);

	dance_grade_text  = "INFERNO!";
	dance_grade_timer = dance_grade_time;
	dance_grade_x     = _cx;
	dance_grade_y     = _cy - 40;
}

/// a fiery afterimage every couple of steps (the same shadows the dash leaves)
function danceGhost(){
	dance_ghost_timer -= 1;
	if (dance_ghost_timer > 0) return;
	dance_ghost_timer = 2;

	var _g = instance_create_depth(x, y, depth + 1, dash_afterimage_obj);
	_g.sprite_index = sprite_index;
	_g.image_index  = image_index;
	_g.image_xscale = image_xscale;
	_g.image_yscale = image_yscale;
	_g.ghost_colour = dance_ghost_colour[irandom(array_length(dance_ghost_colour) - 1)];
	_g.image_alpha  = 0.6;
	_g.start_alpha  = 0.6;
	_g.hold         = 2;
	_g.fade_time    = 14;
}

/// the dance is over. _used = false if nobody was in range (then there's no cooldown and nothing burns)
function danceFinish(_used){
	state = PlayerState.NORMAL;
	image_speed = 1;
	global.enemy_time_scale = 1;   // the world back to normal speed

	if (_used) {
		special_cooldown = dance_cooldown_t;

		// every enemy a strike or the trail touched starts burning (Enemy_base_obj Step does the damage)
		for (var i = 0; i < array_length(dance_hit_list); i++) {
			var _e = dance_hit_list[i];
			if (danceTargetAlive(_e)) {
				_e.burn_timer      = dance_burn_time;
				_e.burn_tick_time  = dance_burn_tick;
				_e.burn_tick_timer = dance_burn_tick;
				_e.burn_damage     = dance_burn_damage;
				_e.burn_damage_max = dance_burn_damage;
			}
		}
	}

	dance_route = [];
	dance_hit_list = [];
}


// ============================================================
// SPARKS: fly out of a strike (more and brighter on a PERFECT)
// ============================================================

/// throws _count sparks out from (_x, _y)
function danceSparks(_x, _y, _count, _bright){
	repeat (_count) {
		array_push(dance_sparks, {
			x: _x,
			y: _y,
			dir: random(360),
			spd: random_range(2, _bright ? 6 : 4),
			life: irandom_range(12, 22),
			col: _bright ? choose(c_white, dance_trail_head, dance_trail_head) : choose(dance_trail_head, dance_colour, dance_trail_tail),
		});
	}
}

/// moves the sparks: they fly out, slow down and burn out
function danceSparksStep(){
	for (var i = array_length(dance_sparks) - 1; i >= 0; i--) {
		var _s = dance_sparks[i];
		_s.x += lengthdir_x(_s.spd, _s.dir);
		_s.y += lengthdir_y(_s.spd, _s.dir);
		_s.spd *= 0.88;
		_s.life -= 1;
		if (_s.life <= 0) array_delete(dance_sparks, i, 1);
	}
}


// ============================================================
// THE TRAIL: orange and red, following the path he dances, and it burns what it touches
// ============================================================
// the trail is his last dance_trail_len positions (dance_trail, newest first).
// each step while he dances, his new position goes on the front and the oldest drops off the end

/// runs EVERY step from the player's Step (also after the dance, so the trail, sparks and grade can finish)
function danceTrailStep(){
	if (global.gameIsPaused) return;

	var _dancing = (state == PlayerState.SPECIAL && special_equipped == SpecialState.DANCE && dance_phase != "windup");

	if (_dancing) {
		// his middle (not his feet) goes on the front of the trail (it holds still during a hit-stop)
		if (dance_hitstop <= 0) {
			array_insert(dance_trail, 0, { x: x, y: y - 16 });
			if (array_length(dance_trail) > dance_trail_len) array_resize(dance_trail, dance_trail_len);
		}
		danceTrailBurn();
	}
	else if (array_length(dance_trail) > 0) {
		// the dance is over: the end catches up with the front and the trail is gone
		array_resize(dance_trail, max(0, array_length(dance_trail) - 2));
	}

	danceSparksStep();
	if (dance_grade_timer > 0) dance_grade_timer -= 1;
	dance_fx_age += 1;
}

/// any enemy touching the trail takes dance_trail_damage (once per dance) and will burn at the end
function danceTrailBurn(){
	var _trail = dance_trail;
	var _reach = dance_trail_width + 8;   // the trail's thickness plus a bit of the enemy's body
	var _hits = [];

	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD) {
			for (var i = 0; i < array_length(_trail); i++) {
				if (point_distance(x, y - 14, _trail[i].x, _trail[i].y) <= _reach) {
					array_push(_hits, id);
					break;
				}
			}
		}
	}

	for (var j = 0; j < array_length(_hits); j++) {
		var _e = _hits[j];
		if (array_contains(dance_trail_hits, _e)) continue;   // the trail only hurts each enemy once a dance
		array_push(dance_trail_hits, _e);

		_e.hp -= dance_trail_damage;
		damagePopupAdd(_e, dance_trail_damage, false);
		if (!array_contains(dance_hit_list, _e)) array_push(dance_hit_list, _e);   // it catches fire at the end
	}
}

/// Draw (room space, BEFORE the player so the trail is behind him)
function danceTrailDraw(){
	var _n = array_length(dance_trail);
	if (_n < 2) exit;

	gpu_set_blendmode(bm_add);   // glows where it overlaps

	// newest at the front: thick and orange. it thins and turns red toward the end, and fades out
	for (var i = _n - 1; i >= 1; i--) {
		var _a = dance_trail[i];
		var _b = dance_trail[i - 1];
		var _t = i / (dance_trail_len - 1);   // 0 at the front, 1 at the very end

		var _col = merge_colour(dance_trail_head, dance_trail_tail, _t);
		draw_set_colour(_col);
		draw_set_alpha(lerp(0.9, 0.15, _t));
		var _w = lerp(dance_trail_width * 2, 2, _t);
		draw_line_width(_a.x, _a.y, _b.x, _b.y, _w);
		draw_circle(_b.x, _b.y, _w / 2, false);   // rounds the joins so the bends don't look broken
	}

	draw_set_alpha(1);
	draw_set_colour(c_white);
	gpu_set_blendmode(bm_normal);
}


// ============================================================
// DRAWING the rest: the wind-up circle, the QTE rings, the strike swoosh, the sparks and the grade
// ============================================================

/// a smooth ring _w pixels thick (draw_circle's outline is only ever 1 pixel)
function danceDrawRing(_x, _y, _r, _w){
	if (_r <= 0) exit;
	var _seg = 32;
	for (var k = 0; k < _seg; k++) {
		var _a1 = k * 360 / _seg;
		var _a2 = (k + 1) * 360 / _seg;
		draw_line_width(_x + lengthdir_x(_r, _a1), _y + lengthdir_y(_r, _a1),
		                _x + lengthdir_x(_r, _a2), _y + lengthdir_y(_r, _a2), _w);
	}
}

/// Draw (room space, BEFORE the player so it's under him)
function danceDraw(){
	gpu_set_blendmode(bm_add);

	// ---- the sparks (they finish flying even after the dance ends) ----
	for (var i = 0; i < array_length(dance_sparks); i++) {
		var _s = dance_sparks[i];
		draw_set_colour(_s.col);
		draw_set_alpha(min(1, _s.life / 8));
		draw_line_width(_s.x, _s.y, _s.x - lengthdir_x(_s.spd * 2 + 1, _s.dir), _s.y - lengthdir_y(_s.spd * 2 + 1, _s.dir), 2);
	}

	if (state == PlayerState.SPECIAL && special_equipped == SpecialState.DANCE) {

		if (dance_phase == "windup") {
			// the circle under him fills up as the wind-up goes
			draw_set_colour(dance_colour);
			var _fill = 1 - dance_timer / max(1, dance_windup_time);
			var _R = dance_hit_radius * 0.8;
			draw_set_alpha(0.5);
			draw_ellipse(x - _R, y - _R * 0.4, x + _R, y + _R * 0.4, true);
			draw_set_alpha(0.35);
			var _r = _R * _fill;
			if (_r > 1) draw_ellipse(x - _r, y - _r * 0.4, x + _r, y + _r * 0.4, false);
		}
		else if (dance_phase == "finale") {
			// the finisher's wind-up: a ring grows out to the blast's reach, getting brighter, then the blast goes
			if (dance_timer > dance_finale_hit_at) {
				var _build = 1 - (dance_timer - dance_finale_hit_at) / (dance_finale_time - dance_finale_hit_at);   // 0 -> 1
				var _fr = dance_finale_radius * _build;
				draw_set_colour(dance_colour);
				draw_set_alpha(0.12 + 0.18 * _build);
				draw_circle(x, y - 14, _fr, false);
				draw_set_colour(merge_colour(dance_trail_head, c_white, _build * 0.6));
				draw_set_alpha(0.5 + 0.5 * _build);
				danceDrawRing(x, y - 14, _fr, 1 + 3 * _build);
				// the full reach, faintly, so you can see what it'll catch
				draw_set_alpha(0.25);
				danceDrawRing(x, y - 14, dance_finale_radius, 1);
			}
		}
		else if (dance_index < array_length(dance_route)) {
			var _e = dance_route[dance_index];

			// ---- the QTE rings round the enemy he's going to ----
			var _waiting = (dance_phase == "dash" && !dance_pressed) || (dance_phase == "strike" && !dance_resolved);
			if (_waiting && danceTargetAlive(_e)) {
				var _ex = _e.x;
				var _ey = _e.y - 14;
				var _frames  = (dance_phase == "dash") ? danceFramesToArrive() : -dance_late;   // + before he arrives, - after
				var _near    = clamp(1 - abs(_frames) / dance_good_frames, 0, 1);              // 0 = far off, 1 = right on time
				var _perfect = abs(_frames) <= dance_perfect_frames;
				var _closing = max(0, dance_ring_size + _frames * dance_ring_px);

				// the target: a soft glow, a crisp ring, and four ticks slowly turning round it
				draw_set_colour(dance_colour);
				draw_set_alpha(0.15 + 0.15 * _near);
				draw_circle(_ex, _ey, dance_ring_size + 3, false);
				draw_set_colour(_perfect ? c_white : dance_trail_head);
				draw_set_alpha(0.9);
				danceDrawRing(_ex, _ey, dance_ring_size, 2);
				var _spin = dance_fx_age * 3;
				for (var t = 0; t < 4; t++) {
					var _ta = _spin + t * 90;
					draw_line_width(_ex + lengthdir_x(dance_ring_size + 3, _ta), _ey + lengthdir_y(dance_ring_size + 3, _ta),
					                _ex + lengthdir_x(dance_ring_size + 8, _ta), _ey + lengthdir_y(dance_ring_size + 8, _ta), 2);
				}

				// the closing ring: red and thin while it's far, orange and thicker as it gets close,
				// bright white-gold in the PERFECT window
				var _ring_col = merge_colour(dance_trail_tail, dance_trail_head, _near);
				if (_perfect) _ring_col = merge_colour(dance_trail_head, c_white, 0.6);
				draw_set_colour(_ring_col);
				draw_set_alpha(0.4 + 0.6 * _near);
				danceDrawRing(_ex, _ey, _closing, 1 + 3 * _near);
			}

			if (dance_phase == "strike") {
				// ---- the swoosh following him round the enemy he's striking ----
				draw_set_colour(dance_colour);
				var _sr = dance_orbit_radius + 10;
				var _steps = 8;
				for (var s = 0; s < _steps; s++) {
					var _a1 = lerp(dance_orbit_start, dance_angle, s / _steps);
					var _a2 = lerp(dance_orbit_start, dance_angle, (s + 1) / _steps);
					draw_set_alpha(0.2 + 0.6 * (s + 1) / _steps);   // brighter toward where he is now
					draw_line_width(dance_cx + lengthdir_x(_sr, _a1), dance_cy - 14 + lengthdir_y(_sr, _a1) * 0.6,
					                dance_cx + lengthdir_x(_sr, _a2), dance_cy - 14 + lengthdir_y(_sr, _a2) * 0.6, 3);
				}
			}
		}
	}

	draw_set_alpha(1);
	draw_set_colour(c_white);
	gpu_set_blendmode(bm_normal);

	// ---- the key to press, in the middle of the target ring (normal blend so it stays readable) ----
	if (state == PlayerState.SPECIAL && special_equipped == SpecialState.DANCE && dance_phase != "windup"
	    && dance_index < array_length(dance_route)) {
		var _k = dance_route[dance_index];
		var _show = (dance_phase == "dash" && !dance_pressed) || (dance_phase == "strike" && !dance_resolved);
		if (_show && danceTargetAlive(_k)) {
			draw_menu_text(_k.x, _k.y - 14, key_name(global.attack_button), c_white, 1, fa_center);
		}
	}

	// ---- the grade pops up big, then settles and fades as it floats up ----
	if (dance_grade_timer > 0) {
		var _age = dance_grade_time - dance_grade_timer;    // frames since it appeared
		var _big = (dance_grade_text == "PERFECT!" || dance_grade_text == "INFERNO!");
		var _gcol = _big ? dance_trail_head : ((dance_grade_text == "GOOD") ? c_white : c_gray);
		var _gscale = (_big && _age < 6) ? 3 : 2;   // a PERFECT (or the finisher) pops in bigger
		if (dance_grade_text == "MISS") _gscale = 1;
		draw_set_alpha(min(1, dance_grade_timer / 10));
		draw_menu_text(dance_grade_x, dance_grade_y - _age * 0.5, dance_grade_text, _gcol, _gscale, fa_center);
		draw_set_alpha(1);
	}
}


// ============================================================
// THE DRAGON COMPANION: comes with the Dance of Dragons special
// ============================================================
// while the Dance is equipped, a small dragon circles him. when he starts dancing it follows right behind him.
// when he isn't dancing it bites any enemy its head touches (each one at most once every dragon_hit_cooldown steps),
// setting it on fire: the burn ticks for dragon_burn_min to dragon_burn_max damage (1-3) every dragon_burn_tick steps.
// in the finisher it rises above him and dives into the ground at his feet, exploding into flames as the blast
// goes off. it comes back once the special is ready again.
// its body is its own last dragon_len positions (dragon_body, head first), so it bends along the path its head took.
// it's drawn with shapes for now: thick and orange-red at the head, thin and gold at the tail, swinging as it flies.
// the numbers are in the player's Create, under "the dragon companion"

/// is the dragon out? (the Dance is equipped, it's switched on, it hasn't exploded, and he's not indoors)
function dragonActive(){
	return dragon_on && !dragon_gone && special_equipped == SpecialState.DANCE && !global.safeInside && state != PlayerState.DEAD;
}

/// runs EVERY step from the player's Step
function dragonStep(){
	if (global.gameIsPaused) return;

	dragonFlamesStep();   // flames keep burning out even when the dragon's gone

	// it exploded in the finisher: it comes back once the special is ready again
	if (dragon_gone && special_cooldown <= 0) {
		dragon_gone = false;
		dragon_x = x;
		dragon_y = y - 20;
	}

	// not out: the body shrinks away and it waits beside him
	if (!dragonActive()) {
		if (array_length(dragon_body) > 0) array_resize(dragon_body, max(0, array_length(dragon_body) - 2));
		if (!dragon_gone) {
			dragon_x = x;
			dragon_y = y - 20;
		}
		return;
	}

	dragon_age += 1;

	// where its head wants to be, and how quickly it gets there
	var _tx, _ty, _follow;
	var _dancing = (state == PlayerState.SPECIAL && special_equipped == SpecialState.DANCE && dance_phase != "windup");

	if (_dancing && dance_phase == "finale") {
		// the finisher: it rises high above him, then dives straight down into the ground at his feet
		var _build = 1 - (dance_timer - dance_finale_hit_at) / (dance_finale_time - dance_finale_hit_at);   // 0 -> 1
		_tx = x;
		if (_build < 0.6) {
			_ty = y - dragon_rise;
			_follow = 0.2;
		} else {
			_ty = y;
			_follow = 0.5;
			dragonFlames(dragon_x, dragon_y, 2, 1);   // a trail of fire as it dives
		}
	}
	else if (_dancing) {
		// dancing: right behind him (a quick catch-up, so it keeps up with the dashes)
		_tx = x;
		_ty = y - 20;
		_follow = 0.45;
	}
	else {
		// otherwise: circling him, bobbing up and down a little
		dragon_angle = (dragon_angle + dragon_orbit_speed) mod 360;
		_tx = x + lengthdir_x(dragon_orbit_radius, dragon_angle);
		_ty = y - 20 + lengthdir_y(dragon_orbit_radius * 0.6, dragon_angle) + dsin(dragon_age * 5) * 3;
		_follow = dragon_follow;
	}

	dragon_x = lerp(dragon_x, _tx, _follow);
	dragon_y = lerp(dragon_y, _ty, _follow);

	// the body follows the head's path
	array_insert(dragon_body, 0, { x: dragon_x, y: dragon_y });
	if (array_length(dragon_body) > dragon_len) array_resize(dragon_body, dragon_len);

	// passive bite (only when he isn't dancing)
	if (!_dancing) dragonBite();
}

/// bites every enemy its head is touching (if it hasn't bitten that one too recently) and sets it on fire
function dragonBite(){
	var _hx = dragon_x;
	var _hy = dragon_y;
	var _r = dragon_hit_radius;
	var _now = dragon_age;
	var _cd = dragon_hit_cooldown;
	var _bitten = [];

	with (Enemy_base_obj) {
		if (state != ENEMY_STATE.DEAD && _now >= dragon_hit_time
		    && point_distance(_hx, _hy, x, y - 14) <= _r + 8) {
			dragon_hit_time = _now + _cd;
			array_push(_bitten, id);
		}
	}

	for (var i = 0; i < array_length(_bitten); i++) {
		var _e = _bitten[i];

		// not burning yet: the first tick comes quickly
		if (_e.burn_timer <= 0) _e.burn_tick_timer = 10;

		// on fire (a bite tops the burn back up, it never shortens a longer one)
		_e.burn_timer      = max(_e.burn_timer, dragon_burn_time);
		_e.burn_tick_time  = dragon_burn_tick;
		_e.burn_damage     = dragon_burn_min;
		_e.burn_damage_max = dragon_burn_max;

		dragonFlames(_e.x, _e.y - 14, 5, 0.7);   // a puff of fire where it bit
	}
}

/// the finisher: the dragon bursts into flames all along its body, and a big burst of fire comes out of the ground at (_x, _y)
function dragonExplode(_x, _y){
	for (var i = 0; i < array_length(dragon_body); i++) {
		var _p = dragon_body[i];
		dragonFlames(_p.x, _p.y, 2, 1);
	}

	repeat (40) {
		var _a = random(360);
		var _s = random_range(1, 3.5);
		var _life = irandom_range(20, 40);
		array_push(dragon_flames, {
			x: _x + random_range(-4, 4),
			y: _y - 4,
			vx: lengthdir_x(_s, _a),
			vy: lengthdir_y(_s, _a) * 0.5 - random(1.5),   // spread flat along the ground, and up
			life: _life,
			life_max: _life,
			size: random_range(4, 8),
		});
	}

	dragon_body = [];
	dragon_gone = true;
}


// ---- flames: little blobs of fire that rise, shrink and cool from yellow to orange to red ----

/// adds _count flames at (_x, _y), _size_mult times the normal size
function dragonFlames(_x, _y, _count, _size_mult){
	repeat (_count) {
		var _life = irandom_range(14, 26);
		array_push(dragon_flames, {
			x: _x + random_range(-3, 3),
			y: _y + random_range(-3, 3),
			vx: random_range(-0.5, 0.5),
			vy: -random_range(0.3, 1.2),
			life: _life,
			life_max: _life,
			size: random_range(3, 6) * _size_mult,
		});
	}
}

/// every step: the flames drift, rise and burn out
function dragonFlamesStep(){
	for (var i = array_length(dragon_flames) - 1; i >= 0; i--) {
		var _f = dragon_flames[i];
		_f.x += _f.vx;
		_f.y += _f.vy;
		_f.vx *= 0.94;
		_f.vy -= 0.04;   // fire rises
		_f.life -= 1;
		if (_f.life <= 0) array_delete(dragon_flames, i, 1);
	}
}

/// draws the flames (glowing, so they brighten where they overlap)
function dragonFlamesDraw(){
	if (array_length(dragon_flames) == 0) exit;

	gpu_set_blendmode(bm_add);
	for (var i = 0; i < array_length(dragon_flames); i++) {
		var _f = dragon_flames[i];
		var _t = 1 - _f.life / _f.life_max;   // 0 = just lit, 1 = burnt out

		// yellow-white when it's new, orange, then red as it dies
		var _col = (_t < 0.35) ? merge_colour(dragon_flame_core, dragon_flame_mid, _t / 0.35)
		                       : merge_colour(dragon_flame_mid, dragon_flame_outer, (_t - 0.35) / 0.65);
		draw_set_alpha(1 - _t);
		draw_circle_colour(_f.x, _f.y, max(1, _f.size * (1 - _t * 0.7)), _col, _col, false);
	}
	draw_set_alpha(1);
	gpu_set_blendmode(bm_normal);
}

/// Draw (room space, AFTER the player so it flies over him)
function dragonDraw(){
	dragonFlamesDraw();

	var _n = array_length(dragon_body);
	if (_n < 2) exit;

	// ---- the body, drawn tail first so the head ends up on top ----
	for (var i = _n - 1; i >= 1; i--) {
		var _p = dragon_body[i];
		var _t = i / (dragon_len - 1);   // 0 at the head, 1 at the very end of the tail

		// which way the body is going here (from the bit behind toward the bit in front)
		var _front = dragon_body[i - 1];
		var _dir = point_direction(_p.x, _p.y, _front.x, _front.y);

		// flowing: a wave travels down the body, swinging the tail more than the neck
		var _wave = dsin(dragon_age * 12 - i * 28) * dragon_wave * _t;
		var _bx = _p.x + lengthdir_x(_wave, _dir + 90);
		var _by = _p.y + lengthdir_y(_wave, _dir + 90);

		var _r = lerp(dragon_width, 1, _t);   // thick at the neck, thin at the tail
		var _col = merge_colour(dragon_head_col, dragon_tail_col, _t);

		draw_set_alpha(lerp(1, 0.5, _t));
		draw_circle_colour(_bx, _by, _r, _col, _col, false);

		// the ridge down its back: a bright spike every few segments
		if (i mod 3 == 0) {
			draw_circle_colour(_bx + lengthdir_x(_r * 0.7, _dir + 90), _by + lengthdir_y(_r * 0.7, _dir + 90),
			                   max(1, _r * 0.4), dragon_trim_col, dragon_trim_col, false);
		}
	}

	// ---- the head, facing the way it's flying ----
	var _h = dragon_body[0];
	var _hdir = point_direction(dragon_body[1].x, dragon_body[1].y, _h.x, _h.y);
	var _hr = dragon_width * 1.3;
	draw_set_alpha(1);

	// horns sweeping back
	draw_set_colour(dragon_trim_col);
	draw_line_width(_h.x, _h.y, _h.x + lengthdir_x(_hr * 2, _hdir + 150), _h.y + lengthdir_y(_hr * 2, _hdir + 150), 1.5);
	draw_line_width(_h.x, _h.y, _h.x + lengthdir_x(_hr * 2, _hdir - 150), _h.y + lengthdir_y(_hr * 2, _hdir - 150), 1.5);

	// head and snout
	draw_circle_colour(_h.x, _h.y, _hr, dragon_head_col, dragon_head_col, false);
	var _sx = _h.x + lengthdir_x(_hr * 0.9, _hdir);
	var _sy = _h.y + lengthdir_y(_hr * 0.9, _hdir);
	draw_circle_colour(_sx, _sy, _hr * 0.6, dragon_head_col, dragon_head_col, false);

	// whiskers trailing back from the snout, rippling
	draw_set_colour(dragon_trim_col);
	draw_set_alpha(0.8);
	for (var w = -1; w <= 1; w += 2) {
		var _wx = _sx;
		var _wy = _sy;
		for (var s = 1; s <= 4; s++) {
			var _wa = _hdir + 180 + w * (25 + dsin(dragon_age * 15 + s * 40) * 15);
			var _nx = _wx + lengthdir_x(3, _wa);
			var _ny = _wy + lengthdir_y(3, _wa);
			draw_line(_wx, _wy, _nx, _ny);
			_wx = _nx;
			_wy = _ny;
		}
	}

	// a bright eye
	draw_set_alpha(1);
	draw_circle_colour(_h.x + lengthdir_x(_hr * 0.4, _hdir + 50), _h.y + lengthdir_y(_hr * 0.4, _hdir + 50),
	                   1, c_white, c_white, false);

	draw_set_colour(c_white);
}
