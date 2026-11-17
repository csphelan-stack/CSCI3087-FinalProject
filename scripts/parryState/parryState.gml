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
	//stun time can be decreased or increased but right now its linked to the player so it isnt based on the enemy
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


