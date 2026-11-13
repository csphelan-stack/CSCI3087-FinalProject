// check whether the game is paused
if (global.gameIsPaused){
    // freeze the enemy's animation
    image_speed = 0;
    exit;
}

// ff the enemy has no HP and is not already dead...
if (hp <= 0 && state != ENEMY_STATE.DEAD) {
    // Change to the DEAD state.
    enemy_change_state(ENEMY_STATE.DEAD);
}


//if the circle obj has touched the enemy it changed to the push state

if (instance_exists(circle_push_obj) && state != ENEMY_STATE.PUSHSA3) {
	var _c = instance_nearest(x, y, circle_push_obj);

	if (point_distance(_c.x, _c.y, x, y) <= _c.radius) {
		enemy_change_state(ENEMY_STATE.PUSHSA3);	
	}
}

// ---- slow motion (the Dance of Dragons lowers global.enemy_time_scale while he dances) ----
// each frame he earns that much of a step. at 0.25 he gets a full step 1 frame out of 4,
// so his thinking, moving, timers, attacks and burning all run at a quarter speed
slow_acc += global.enemy_time_scale;
if (slow_acc < 1) exit;   // not his turn this frame
slow_acc -= 1;

//This step allows us to spin the enemy 
//I want to spin the enemy along their y axis
// whenever the wave is pushing them along 
// and then to stun them after.
if(spin_speed_sa3 > 0.5){
	spin_angle_sa3 = (spin_angle_sa3 +spin_speed_sa3 )mod 360;	
	spin_speed_sa3 *=0.2;
}
else{
	spin_speed_sa3 = 0;
	spin_angle_sa3 += angle_difference(0,spin_angle_sa3) * 0.2;
	
}


// burning (the Dance of Dragons and its dragon set burn_timer): a little damage every burn_tick_time steps until it runs out
// each tick does somewhere from burn_damage to burn_damage_max
if (burn_timer > 0 && state != ENEMY_STATE.DEAD) {
	burn_timer -= 1;
	burn_tick_timer -= 1;
	if (burn_tick_timer <= 0) {
		burn_tick_timer = burn_tick_time;
		var _dmg = irandom_range(burn_damage, max(burn_damage, burn_damage_max));
		hp -= _dmg;

		// the damage number (damagePopupAdd runs as the player)
		var _me = id;
		with (main_character_Obj) damagePopupAdd(_me, _dmg, false);
	}
}

// if the attack cooldown is active...
if (attack_cooldown > 0){
    // count it down by one frame
    attack_cooldown--;
}


// ============================================================
// BOSS
// ============================================================

// Bosses count their attack cooldowns and watch their health here.
if (boss_enabled)
{
    enemy_boss_tick();
}

// reset normal movement each frame
// individual states enable movement when necessary
move_spd = 0;


// ============================================================
// ENEMY STATE MACHINE  (state logic: enemy_state_logic)
// ============================================================

switch (state) {
    case ENEMY_STATE.IDLE:   enemy_state_idle();   break;
    case ENEMY_STATE.WANDER: enemy_state_wander(); break;
    case ENEMY_STATE.CHASE:  enemy_state_chase();  break;
    case ENEMY_STATE.ATTACK: enemy_state_attack(); break;
    case ENEMY_STATE.SEARCH: enemy_state_search(); break;
    case ENEMY_STATE.HURT:   enemy_state_hurt();   break;
	case ENEMY_STATE.PUSHSA3: enemy_push_state(); break;
	case ENEMY_STATE.STUN: enemy_stun_state(); break;
    case ENEMY_STATE.DEAD:
        // keep the death animation playing, then skip everything below
        enemy_state_dead();
        exit;
}


// ============================================================
// MOVEMENT + ANIMATION  (enemy_movement / enemy_animation)
// ============================================================


// turn move_spd / move_dir into velocity
enemy_update_velocity();

// pick the sprite and animation speed
enemy_update_animation();
image_speed *= global.enemy_time_scale;   // slow motion: animations slow down too (the engine plays them every frame)

// move, stopping at walls
enemy_apply_movement();

