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

// if the attack cooldown is active...
if (attack_cooldown > 0){
    // count it down by one frame
    attack_cooldown--;
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

// move, stopping at walls
enemy_apply_movement();