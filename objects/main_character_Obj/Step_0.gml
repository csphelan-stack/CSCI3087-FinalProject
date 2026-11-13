// out of hp: play the death animation, then restart (see playerHurtDeath)
if (hp <= 0 && state != PlayerState.DEAD){
	startDeath();
}

if(house_of_cards_unlock){
	house_of_cards();
}





if(knife_throw_cooldown >0){
knife_throw_cooldown--;	
}

if(cooldown_HOC >0){	
cooldown_HOC-=1;
}

// hurt flinch counts down (attacking, dashing etc. cut it short)
if (hurt_timer > 0) {
	hurt_timer -= 1;
	if (state != PlayerState.NORMAL) {
		hurt_timer = 0;
	}
}

if(combo_timer_period >0){
	combo_timer_period-=1;
}
if(combo_timer_period <=0){
	swung_dir = true;
}
if(sa3_cooldown_time >0){
	sa3_cooldown_time--;	
}

if(attack_cooldown >0){
attack_cooldown-=1;	
}
if(	dash_double_wait_time>0){
	dash_double_wait_time-=1;	
}
if(dash_cooldown>0){
dash_cooldown-=1;	
}

if(throwing_knfe_cooldown>0){
	throwing_knfe_cooldown-=1;	
}

if(health_steal_knives_unlocked){
	//NEED TO ADD EITHER A COOLDOWN OR A KILL COUNT BEFORE ACTIVATION
	if(keyboard_check_pressed(global.weapon_change_btn) && throwing_knfe_cooldown<=0){
		switch_weapon_to_vpk =!switch_weapon_to_vpk;
	}
}
else if(flood_formation_unlock){
		if(keyboard_check_pressed(global.weapon_change_btn) && sa3_cooldown_time <=0){
		switch_weapon_to_sa3 =!switch_weapon_to_sa3;
	}
}




if(invuln > 0){
invuln -= 1;
}

if(parry_cooldown>0){
parry_cooldown-=1;
}

// (it waits while the Butterfly Effect is still going, so it only starts once the butterflies are sent)
if (special_cooldown > 0 && !global.gameIsPaused && !butterflyBusy()) {
	special_cooldown -= 1;
}

// Butterfly Effect: the 10 second window and the butterflies (runs whatever state he's in)
butterflyStep();

// Bladed Tsunami: the water droplets (keep moving after the tsunami so they can fall and fade)
tsunamiDropsStep();

// Dance of Dragons: the trail following his path (keeps running after the dance so it can shrink away)
danceTrailStep();

// the dragon companion: circles him while the Dance is equipped, follows him when he dances, bites enemies otherwise
dragonStep();

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

///////////////////////////////////////////////////
//
//UPGRADE SYSTEM START: RN IT IS JUST A BUTTON PRESS NEEDS TO BE AN EVENT TRIGGER
//
//////////////////////////////////////////////////
if(keyboard_check_pressed(global.temp_upgrade_btn)){
	event_go_upgrade = !event_go_upgrade
}
if(event_go_upgrade){
	//only make one (this runs every step)
	if(!instance_exists(Upgrade_system_obj)){
		instance_create_depth(x,y,-100,Upgrade_system_obj);
		
	} 
	
	
	
}
else{
	if(instance_exists(Upgrade_system_obj)){
		instance_destroy(Upgrade_system_obj);	
		instance_destroy(upgrade_card_obj);
	}
}
		


	
switch (state){
	
	case PlayerState.NORMAL:
		applyMovement();
		break;
	case PlayerState.ATTACK:
			if(switch_weapon_to_vpk){
				sword_art_2();
			}
			else if(switch_weapon_to_sa3){
				sword_art_3_script();
			}
			else{
				attackStatePlayer();
			}
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
	case PlayerState.SPECIAL:
		specialStateMC();   //runs whichever special is equipped
		break;
	case PlayerState.DEAD:
		deathStateMC();
		break;
}