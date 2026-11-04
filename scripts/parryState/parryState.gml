// ============================================================
// PARRY: block + perfect parry
// ============================================================
// press parry  -> guard goes up straight away
// hit in the first parry_perfect_window steps -> PERFECT PARRY: no damage, enemy staggered, auto counter
// hit after that -> BLOCKED: no damage, but it drains the guard meter (parry_exhaust_timer)
// a hit that empties the meter -> GUARD BREAK: he takes the hit, gets stunned, long cooldown
// holding until the meter runs out -> EXHAUSTED: guard drops, long cooldown (he blinks first as a warning)
// letting go -> short recovery so you can't spam taps for perfect parries
// the meter refills on its own while he isn't guarding (see Step)
// ============================================================

function startParryState(){

    // runs ONCE when the parry button is pressed
    state = PlayerState.PARRY;

	parry_dir = facing;
	parry_dir4 = round(parry_dir/90) mod 4;

	parry_perfect_timer = parry_perfect_window;   // the perfect-parry window starts right now

	// guard straight up: the looping block animation, no charge-up
	sprite_index = parry_block_spr[parry_dir4];
	image_index = 0;
	image_speed = 1;
}

function parryStateMC(){

	// let go of the parry key -> drop the guard, short recovery before the next parry
	if(!keyboard_check(global.parry_button)){
		parryEnd();
		parry_cooldown = parry_recover_time;
		return;
	}

	if(parry_perfect_timer > 0){
		parry_perfect_timer -= 1;
	}

	// holding the guard drains the meter -> empty = exhausted: guard drops and the long cooldown starts
	// (Draw makes him blink for the last parry_blink_time steps as a warning)
	parry_exhaust_timer -= 1;
	if(parry_exhaust_timer <= 0){
		parry_exhaust_timer = 0;
		parryEnd();
		parry_cooldown = parry_cooldown_t;
		return;
	}
}

/// drops the guard
function parryEnd(){
	state = PlayerState.NORMAL;
	parry_perfect_timer = 0;
}

/// hit inside the perfect window: knock the enemy back, stun them, and swing straight back at them
function parrySuccess(_attacker){

	parryEnd();

	// a good parry gives some guard back
	parry_exhaust_timer = min(parry_exhaust_time, parry_exhaust_timer + parry_perfect_refund);

	// white ring so you can see the parry landed
	var _w = instance_create_depth(x, y, depth + 1, parry_shockwave_obj);
	_w.colour     = c_white;
	_w.radius     = parry_circle_radius * 0.5;
	_w.max_radius = parry_circle_radius * 1.5;

	if(instance_exists(_attacker)){
		// turn to face whoever hit us so the counter swings at them
		facing = point_direction(x, y, _attacker.x, _attacker.y);

		with(_attacker){
			// inside here we are the ENEMY, so the player's variables are other.something
			enemy_change_state(ENEMY_STATE.HURT);
			state_timer = other.parry_stagger_time;   // stunned longer than a normal hit

			var _kb_dir = point_direction(other.x, other.y, x, y);
			kb_x = lengthdir_x(knockback_power, _kb_dir);
			kb_y = lengthdir_y(knockback_power, _kb_dir);
		}
	}

	// the counter attack: swaps him straight from the guard into a swing
	startAttackPlayer(true);
}

/// hit while guarding, but too late for a perfect parry: no damage, guard meter pays for it
/// returns false if the hit emptied the meter (guard break - the caller lets the damage through)
function parryBlock(_damage, _attacker){

	parry_exhaust_timer -= _damage * parry_hit_cost;
	if(parry_exhaust_timer <= 0){
		parry_exhaust_timer = 0;
		return false;
	}
	
	audio_play_sound(snd_block, 25, false);


	block_flash = block_flash_time;

	// a small shove back from the blow
	if(instance_exists(_attacker)){
		var _kb_dir = point_direction(_attacker.x, _attacker.y, x, y);
		push_x = lengthdir_x(hit_knockback * 0.5, _kb_dir);
		push_y = lengthdir_y(hit_knockback * 0.5, _kb_dir);
	}
	return true;
}

/// the guard got smashed: he's stunned, and the parry goes on the long cooldown
function parryGuardBreak(){
	parryEnd();
	parry_cooldown = parry_cooldown_t;
	startStun();
}

/// runs ONCE when he gets stunned
function startStun(){
	state = PlayerState.STUNNED;
	stun_timer = stun_time;

	var dir4 = round(facing / 90) mod 4;
	sprite_index = hurt_spr[dir4];   // plays his hurt animation (Draw flashes him red too)
	image_index = 0;
	image_speed = 1;
}

/// runs EVERY step while stunned: can't move or act until the timer runs out
function stunStateMC(){
	stun_timer -= 1;
	if(stun_timer <= 0){
		state = PlayerState.NORMAL;
	}
}



// ============================================================
// SHOCKWAVE / SPECIAL ATTACK VISUALS
// ============================================================
// these were the old charge-up parry's effects - the Bladed Tsunami special uses them now
// (see the SPECIAL ATTACK section of attackState, and the player's Draw event).
// they run as the player (they use his sword_* / u_* / parry_circle_radius variables from Create).
//
// how the special uses them:
//   Step (while charging):  _charge goes 0 -> 1, then fxRainbowSwordStep() once it's full
//   Draw (before draw_self): fxChargeCircleDraw(_charge, _charge >= 1)
//   Draw (the player):       if full fxRainbowSwordDraw() else draw_self(), then fxChargeGlowDraw(_charge)
//   when full / on release:  fxShockwaveBurst(...)
// ============================================================

/// the circle on the ground that fills up as it charges. _charge = 0 (empty) to 1 (full)
function fxChargeCircleDraw(_charge, _full){
    var _R = parry_circle_radius;

    gpu_set_blendmode(bm_add);
    draw_set_colour(tsunami_colour);

    // the outline: full size from the start, so you can see what's being filled
    draw_set_alpha(0.5);
    for (var i = 0; i < 2; i++) {
        var _o = _R - i;
        draw_ellipse(x - _o, y - _o * 0.4, x + _o, y + _o * 0.4, true);
    }

    // the fill: grows from the middle out to the outline as it charges
    var _r = _R * _charge;
    draw_set_alpha(_full ? 0.2 : 0.35);   // softer once full
    if (_r > 1) {
        draw_ellipse(x - _r, y - _r * 0.4, x + _r, y + _r * 0.4, false);
    }

    draw_set_alpha(1);
    draw_set_colour(c_white);
    gpu_set_blendmode(bm_normal);
}

/// draws the player with the palette colours sweeping up his sword (use INSTEAD of draw_self)
function fxRainbowSwordDraw(){
    shader_set(parryShader);

    var _uvs = sprite_get_uvs(sprite_index, image_index);
    shader_set_uniform_f(u_uvs, _uvs[0], _uvs[1], _uvs[2], _uvs[3]);
    shader_set_uniform_f(u_sweep, sword_sweep);
    shader_set_uniform_f(u_band, sword_band);
    shader_set_uniform_f(u_trail_len, sword_trail_len);
    shader_set_uniform_f(u_colours, sword_colours);
    shader_set_uniform_f(u_hue, sword_hue);
    shader_set_uniform_f(u_saturation, sword_saturation);
    shader_set_uniform_f(u_trail,
        colour_get_red(sword_trail_colour)   / 255,
        colour_get_green(sword_trail_colour) / 255,
        colour_get_blue(sword_trail_colour)  / 255);
    sword_palette_set(u_pal0, sword_palette[0]);
    sword_palette_set(u_pal1, sword_palette[1]);
    sword_palette_set(u_pal2, sword_palette[2]);

    draw_self();
    shader_reset();
}

/// hands one colour to the sword shader as red, green, blue from 0 to 1
function sword_palette_set(_uniform, _colour){
    shader_set_uniform_f(_uniform,
        colour_get_red(_colour)   / 255,
        colour_get_green(_colour) / 255,
        colour_get_blue(_colour)  / 255);
}

/// moves the colour band up the sword - call every step while it's showing
/// (set sword_sweep = 0 and sword_hue = 0 when it starts so it begins at the bottom on the first colours)
function fxRainbowSwordStep(){
	sword_sweep += sword_sweep_speed;
	if (sword_sweep > 1 + sword_band + sword_trail_len) {
		sword_sweep = 0;
		sword_hue = (sword_hue + sword_colours) mod array_length(sword_palette);   // next pass = the next colours in sword_palette
	}
}

/// he glows in the fx colour while charging, stronger as _charge goes 0 -> 1 (draw AFTER him)
function fxChargeGlowDraw(_charge){
    gpu_set_fog(true, tsunami_colour, 0, 0);
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, c_white, 0.6 * _charge);
    gpu_set_fog(false, c_white, 0, 0);
}

/// the ring that bursts outward (parry_shockwave_obj)
function fxShockwaveBurst(_colour, _radius, _max_radius){
	var _w = instance_create_depth(x, y, depth + 1, parry_shockwave_obj);
	_w.colour     = _colour;
	_w.radius     = _radius;
	_w.max_radius = _max_radius;
	return _w;
}
