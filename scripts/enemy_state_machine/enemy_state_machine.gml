// ============================================================
// ENEMY STATE MACHINE (enum + changing state)
// ============================================================
// enemy_change_state() runs the one-time setup for a state.
// The per-frame behavior of each state is in enemy_state_logic.
// ============================================================

// These are all of the states an enemy can be in.
enum ENEMY_STATE {
    IDLE,       // Enemy is standing still.
    WANDER,     // Enemy is moving around its home area.
    CHASE,      // Enemy is actively chasing the player.
    ATTACK,     // Enemy is attacking the player.
    SEARCH,     // Enemy lost the player and is searching.
    HURT,       // Enemy was damaged and is temporarily stunned.
    DEAD,       // Enemy is dead and playing its death animation.
    EXHAUSTED,  // A boss is worn out from attacking and stands still (the fatigue bar).
    STUN,       // ENEMY GETS STUNNED FOR X AMOUNT OF TIME
    PUSHSA3     // ENEMY GETS PUSHED BY A CIRCLIAR BARRIER
}


// ============================================================
// CHANGE ENEMY STATE
// ============================================================

// Changes the enemy from its current state to a new state.
function enemy_change_state(_new_state) {
    // A dead enemy cannot go back to another state.
    if (state == ENEMY_STATE.DEAD){
        return;
    }

    // Bosses have super armor: a normal hit (sword, spin attack) does not stun
    // them, it only makes them flash white. A perfect parry still staggers them
    // (enemy_boss_stagger lets that one through with boss_force_hurt).
    if (_new_state == ENEMY_STATE.HURT && boss_enabled && !boss_force_hurt)
    {
        boss_flash = 6;
        return;
    }
    // Remember what state the enemy was previously in.
    state_prev = state;
    // Change to the new state.
    state = _new_state;
    // Reset the timer used by the new state.
    state_timer = 0;
    // --------------------------------------------------------
    // State-specific setup.
    // --------------------------------------------------------

    switch (_new_state){
        // ====================================================
        // IDLE
        // ====================================================
        case ENEMY_STATE.IDLE:
            // Pick a random amount of time for the enemy to stand still.
            state_timer = irandom_range(idle_min, idle_max);
            // Reset the animation to its first frame.
            image_index = 0;
        break;
        // ====================================================
        // WANDER
        // ====================================================
        case ENEMY_STATE.WANDER:
            // Pick a random direction around the enemy's home.
            var _a = random(360);
            // Pick a random distance from the enemy's home.
            var _r = random_range(wander_radius * 0.3, wander_radius);
            // Calculate the X coordinate of the random wander destination.
            wander_x = home_x + lengthdir_x(_r, _a);
            // Calculate the Y coordinate of the random wander destination.
            wander_y = home_y + lengthdir_y(_r, _a);
            // Give the enemy a maximum amount of time to reach that point.
            state_timer = wander_give_up;
            // Reset the animation.
            image_index = 0;
        break;
        // ====================================================
        // CHASE
        // ====================================================
        case ENEMY_STATE.CHASE:
            // Reset the animation when entering chase.
            image_index = 0;
        break;
        // ====================================================
        // ATTACK
        // ====================================================
        case ENEMY_STATE.ATTACK:
            // Stop normal movement when the attack starts.
            move_spd = 0;
            // Reset the attack animation to its first frame.
            image_index = 0;
            // This attack has not hit the player yet.
            attack_hit_done = false;
            // Set how long this attack lasts.
            state_timer = attack_duration;
            // Magic users start their spell here (the orb and the magic circle appear).
            if (magic_enabled)
            {
                enemy_magic_begin();
            }
            // Bosses start the attack they chose (see the enemy_boss script).
            if (boss_enabled)
            {
                enemy_boss_begin();
            }
        break;
        // ====================================================
        // SEARCH
        // ====================================================
        case ENEMY_STATE.SEARCH:
            // Give the enemy a few seconds to search.
            state_timer = search_time;
            // Reset the animation.
            image_index = 0;
        break;
        // ====================================================
        // HURT
        // ====================================================
        case ENEMY_STATE.HURT:
            // Set how long the enemy stays hurt.
            state_timer = hurt_time;
            // Reset the animation.
            image_index = 0;
            // Find the closest player.
            var _p = instance_nearest(x, y, main_character_Obj);
            // Make sure a player actually exists.
            if (_p != noone){
                // Store that player as the current enemy target.
                target = _p;
                // Remember the player's last X position.
                last_x = _p.x;
                // Remember the player's last Y position.
                last_y = _p.y;
            }
        break;
        // ====================================================
        // EXHAUSTED (bosses only: the fatigue bar was full)
        // ====================================================
        case ENEMY_STATE.EXHAUSTED:
            // The boss is worn out: it stands still for a while.
            state_timer = boss_exhaust_time;
            // The fatigue bar starts over.
            boss_fatigue = 0;
            // Stop all movement.
            kb_x = 0;
            kb_y = 0;
            // Reset the animation.
            image_index = 0;
        break;
        // ====================================================
        // DEAD
        // ====================================================
        case ENEMY_STATE.DEAD:
		
			//tracks total kills
			//global.kill_counter +=1;
			//tracks current kill streak to apply abilities
			if(main_character_Obj.house_of_cards_unlock){
				main_character_Obj.kill_counter_current +=1;	
			}
		
            // Stop horizontal movement.
            kb_x = 0;
            // Stop vertical movement.
            kb_y = 0;
            // Start the death animation from the first frame.
            image_index = 0;
            // Select the correct death sprite for the direction
            // the enemy is facing.
            sprite_index = spr_death[enemy_dir4()];
            // Start the death animation.
            image_speed = death_anim_spd;
            // A boss cleans up its warning lane when it dies.
            if (boss_enabled)
            {
                enemy_boss_cleanup();
            }
        break;
		//added by louis to help with my sword arts.
		case ENEMY_STATE.PUSHSA3:
			image_index = 0;
			image_speed =1;

		break;
		case ENEMY_STATE.STUN:
			image_index = 0;
			image_speed =1;
			state_timer = state_timer_stun;
            // Find the closest player.
            var _p_1 = instance_nearest(x, y, main_character_Obj);
            // Make sure a player actually exists.
            if (_p_1 != noone){
                // Store that player as the current enemy target.
                target = _p_1;
                // Remember the player's last X position.
                last_x = _p_1.x;
                // Remember the player's last Y position.
                last_y = _p_1.y;
            }
			

		break;

    }
}
