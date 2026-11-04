// runs as the PLAYER (enemy_attack_hit calls it inside with(main_character_Obj))
// _damage = how hard the enemy hits, _attacker = the enemy that swung
// returns true if the hit hurt him, false if it was parried or ignored
function Enemy_damage_applying(_damage,_attacker){

	// just got hit: still in his invulnerable frames, ignore it
	if(invuln > 0){
		return false;
	}

	// ---- hit while charging the Bladed Tsunami: the charge is lost (and the hit lands below) ----
	// (once the tsunami's going he keeps going - he still gets hurt, but it doesn't stop it)
	if(state == PlayerState.SPECIAL && special_equipped == SpecialState.TSUNAMI && !tsunami_charged){
		audio_stop_sound(snd_charge);   // the charge-up sound loops, so stop it too
		state = PlayerState.NORMAL;
		tsunami_charged = false;
		image_speed = 1;
		special_cooldown = tsunami_interrupt_cd;
	}

	// ---- hit during the Dance of Dragons wind-up: the dance is cancelled (and the hit lands below) ----
	// (once he's dancing he can't be hurt, see special_dance_attack_script)
	if(state == PlayerState.SPECIAL && special_equipped == SpecialState.DANCE && dance_phase == "windup"){
		state = PlayerState.NORMAL;
		image_speed = 1;
		special_cooldown = dance_interrupt_cd;
		global.enemy_time_scale = 1;   // the slow motion stops too
	}

	if(state == PlayerState.PARRY){

		// ---- right as the guard went up: perfect parry, no damage, auto counter ----
		if(parry_perfect_timer > 0 && perfect_p_unlocked){
			parrySuccess(_attacker);
			return false;
		}

		// ---- guard was already up: blocked, no damage, costs guard meter ----
		if(parryBlock(_damage, _attacker)){
			return false;
		}

		// ---- that hit emptied the meter: guard break (and the hit still lands below) ----
		parryGuardBreak();
	}

	// ---- take the hit ----
    hp -= _damage;

    // prevent player HP from going below zero and crashing
    hp = max(hp, 0);
	audio_stop_sound(snd_charge);
    audio_stop_sound(snd_spin);
	audio_play_sound(snd_hurt, 30, false);

	invuln = invuln_time;
	startHurtFlinch();   // plays the hurt animation if he was just walking around (see playerHurtDeath)

	// knocked back, away from whoever hit him
	if(instance_exists(_attacker)){
		var _kb_dir = point_direction(_attacker.x, _attacker.y, x, y);
		push_x = lengthdir_x(hit_knockback, _kb_dir);
		push_y = lengthdir_y(hit_knockback, _kb_dir);
	}

	return true;
}
