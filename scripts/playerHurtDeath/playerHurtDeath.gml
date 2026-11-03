// ============================================================
// HURT FLINCH + DEATH for the player
// ============================================================
// hurt: getting hit while walking around plays the hurt animation for hurt_flinch_time steps.
//       it's only a look - he can still move, and attacking/dashing/parrying cuts it short.
// death: when his hp hits 0 he plays the death animation, lies there for death_hold_time steps,
//        then the game goes to the death screen (rm_death)
// these run as the player.
// ============================================================

/// runs ONCE when an enemy's hit lands (called from Enemy_damage_applying)
function startHurtFlinch(){
	if (state != PlayerState.NORMAL) return;

	hurt_timer = hurt_flinch_time;
	sprite_index = hurt_spr[round(facing / 90) mod 4];
	image_index = 0;   // start the flinch from its first frame
	image_speed = 1;
}

/// runs ONCE when his hp hits 0
function startDeath(){
	// no death animation: go straight to the death screen
	if (is_undefined(death_spr)) {
		room_goto(rm_death);
		return;
	}

	state = PlayerState.DEAD;
	hurt_timer = 0;
	image_blend = c_white;   // in case he died mid-dash (the dash tints him gold)
	invuln = 999999;         // enemies can't keep hitting the body

	sprite_index = death_spr[round(facing / 90) mod 4];
	image_index = 0;
	image_speed = 1;

	death_hold_timer = -1;   // starts when the animation finishes (Animation End event)
}

/// runs EVERY step while dead
function deathStateMC(){
	kb_x = 0;
	kb_y = 0;

	// the animation is over and he's lying there: count down to the death screen
	if (death_hold_timer > 0) {
		death_hold_timer -= 1;
		if (death_hold_timer <= 0) {
			room_goto(rm_death);
		}
	}
}