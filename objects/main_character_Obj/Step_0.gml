if (hp<=0){ 
	 game_restart();
	}
	
	
if(attack_cooldown >0){
attack_cooldown-=1;	
}
	
if(dash_cooldown>0){
dash_cooldown-=1;	
}

if(invuln > 0){
invuln -= 1;
}

if(parry_cooldown>0){
parry_cooldown-=1;
}

if (special_cooldown > 0 && !global.gameIsPaused) {
	special_cooldown -= 1;
}

// guard meter refills while he isn't guarding
if (state != PlayerState.PARRY && !global.gameIsPaused) {
	parry_exhaust_timer = min(parry_exhaust_time, parry_exhaust_timer + parry_guard_regen);
}

if (block_flash > 0) {
	block_flash -= 1;
}

// damage numbers above enemies count down and follow them
if (!global.gameIsPaused) {
	damagePopupsStep();
}

// knockback: slide him by the push (stopping at walls) and let it fade out
if (!global.gameIsPaused && (abs(push_x) > 0.1 || abs(push_y) > 0.1)) {
	move_and_collide(push_x, push_y, obj_wall);
	push_x *= push_friction;
	push_y *= push_friction;
}
else {
	push_x = 0;
	push_y = 0;
}

		


	
switch (state){
	
	case PlayerState.NORMAL:
		applyMovement();
		break;
	case PlayerState.ATTACK:
		attackStatePlayer();
		break;
	case PlayerState.DASH:
		dashStateMC();
		break;
	case PlayerState.PARRY:
		parryStateMC();
		break;
	case PlayerState.STUNNED:
		stunStateMC();
		break;
	case PlayerState.SPECIAL_CHARGE:
		specialChargeStateMC();
		break;
	case PlayerState.SPECIAL_SPIN:
		specialSpinStateMC();
		break;
}