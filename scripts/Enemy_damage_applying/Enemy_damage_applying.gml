// runs as the PLAYER (enemy_attack_hit calls it inside with(main_character_Obj))
// _damage = how hard the enemy hits, _attacker = the enemy that swung
// returns true if the hit hurt him, false if it was parried or ignored
function Enemy_damage_applying(_damage,_attacker){

	// just got hit: still in his invulnerable frames, ignore it
	if(invuln > 0){
		return false;
	}

	// ---- hit while charging the special: the charge is lost (and the hit lands below) ----
	// (while SPINNING he keeps going - he still gets hurt, but it doesn't stop the tornado)
	if(state == PlayerState.SPECIAL_CHARGE){
		state = PlayerState.NORMAL;
		special_charged = false;
		image_speed = 1;
		special_cooldown = special_interrupt_cd;
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
