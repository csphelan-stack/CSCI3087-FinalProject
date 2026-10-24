// ============================================================
// ENEMY STATE LOGIC
// ============================================================
// What each state does on every frame. Called from Enemy_base_obj's Step event.
// Changing state is done with enemy_change_state() (enemy_state_machine script).
//
// Every function here runs in the enemy instance's scope, so hp, state, target,
// etc. are the enemy's own variables.
// ============================================================

// ============================================================
// IDLE
// ============================================================
// Stand still, watch for the player, eventually wander.
// ============================================================

function enemy_state_idle()
{
    // Check whether the enemy can see the player.
    if (enemy_can_see_player(sight_range, true))
    {
        // Begin chasing the player.
        enemy_change_state(ENEMY_STATE.CHASE);

        // Stop processing the IDLE state this frame.
        return;
    }

    // Count down the idle timer.
    state_timer--;

    // When the timer reaches zero...
    if (state_timer <= 0)
    {
        // Begin wandering.
        enemy_change_state(ENEMY_STATE.WANDER);
    }
}


// ============================================================
// WANDER
// ============================================================
// Walk to a random point near home, watch for the player.
// ============================================================

function enemy_state_wander()
{
    // Check whether the player is visible.
    if (enemy_can_see_player(sight_range, true))
    {
        // Start chasing the player.
        enemy_change_state(ENEMY_STATE.CHASE);

        // Stop processing WANDER.
        return;
    }

    // Count down the wander timer.
    state_timer--;

    // Move toward the random wander destination.
    var _arrived = enemy_walk_to(wander_x, wander_y, wander_spd);

    // If the enemy reached its destination...
    if (_arrived || state_timer <= 0)
    {
        // Stop wandering and return to idle.
        enemy_change_state(ENEMY_STATE.IDLE);
    }
}


// ============================================================
// CHASE
// ============================================================
// Run at the player; attack when close enough.
// ============================================================

function enemy_state_chase()
{
    // If the stored player instance disappeared, try to find the player again.
    if (target == noone || !instance_exists(target))
    {
        if (!enemy_can_see_player(sight_range, false))
        {
            enemy_change_state(ENEMY_STATE.SEARCH);
            return;
        }
    }

    // Keep the existing chase/leash behavior. A wall or a player farther than
    // lose_range makes the enemy search the last position it knew.
    if (!enemy_can_see_player(lose_range, false))
    {
        enemy_change_state(ENEMY_STATE.SEARCH);
        return;
    }

    // Refresh the last known location while the player is visible.
    last_x = target.x;
    last_y = target.y;
    var _distance = point_distance(x, y, target.x, target.y);

    // Magical enemies stop to cast only when the player is visible and inside
    // the existing awareness radius. The target coordinates are snapshotted
    // once, so the spell does not home in on a moving player.
    if (magic_enabled)
    {
        var _spell_range = min(sight_range, magic_range);
        if (attack_cooldown <= 0 &&
            _distance <= _spell_range &&
            enemy_can_see_player(_spell_range, false))
        {
            // Re-snapshot the exact last-seen position at the moment of casting.
            last_x = target.x;
            last_y = target.y;
            magic_target_x = last_x;
            magic_target_y = last_y;
            magic_orb_timer = magic_orb_duration;
            magic_effect_timer = 0;
            facing = point_direction(x, y, target.x, target.y);
            enemy_change_state(ENEMY_STATE.ATTACK);
            return;
        }

        // Keep closing distance until the player is within the allowed spell range.
        enemy_walk_to(target.x, target.y, movespd);
        return;
    }

    // Ordinary enemies retain their original close-range melee attack.
    if (_distance <= attack_range)
    {
        facing = point_direction(x, y, target.x, target.y);
        if (attack_cooldown <= 0)
        {
            enemy_change_state(ENEMY_STATE.ATTACK);
        }
    }
    else
    {
        enemy_walk_to(target.x, target.y, movespd);
    }
}

// ============================================================
// ATTACK
// ============================================================
// Swing at the player; damage lands on the hit frame.
// ============================================================

function enemy_state_attack()
{
    // Stop normal movement while the enemy is attacking/casting.
    move_spd = 0;

    // Melee attackers track the live player. Spellcasters keep the aim point
    // captured when the cast started, even if the player moves afterward.
    if (!magic_enabled && target != noone && instance_exists(target))
    {
        facing = point_direction(x, y, target.x, target.y);
    }

    state_timer--;

    // When the hit frame arrives, melee enemies swing as before; magic users
    // detonate their spell at the fixed circle-and-star target marker.
    if (!attack_hit_done && state_timer <= attack_duration - attack_windup)
    {
        if (magic_enabled)
        {
            enemy_magic_attack_hit();
            magic_effect_timer = magic_effect_duration;
        }
        else
        {
            enemy_attack_hit();
        }
        attack_hit_done = true;
    }

    // End the attack and restart the usual cooldown.
    if (state_timer <= 0)
    {
        attack_cooldown = attack_cooldown_max;
        enemy_change_state(ENEMY_STATE.CHASE);
    }
}

// ============================================================
// SEARCH
// ============================================================
// Player was lost - walk to last known position and look around.
// ============================================================

function enemy_state_search()
{
    // Check whether the enemy sees the player again.
    if (enemy_can_see_player(sight_range, false))
    {
        // Return to CHASE.
        enemy_change_state(ENEMY_STATE.CHASE);

        // Stop processing SEARCH.
        return;
    }

    // Count down the search timer.
    state_timer--;

    // Walk toward the player's last known position.
    var _search_arrived = enemy_walk_to(last_x, last_y, movespd);

    // Once the enemy reaches the location...
    if (_search_arrived && state_timer mod 40 == 0)
    {
        // Rotate 90 degrees to look around.
        facing = (facing + 90) mod 360;
    }

    // If the search timer expires...
    if (state_timer <= 0)
    {
        // Set the current position as the new wandering home.
        home_x = x;
        home_y = y;

        // Stop searching.
        enemy_change_state(ENEMY_STATE.IDLE);
    }
}


// ============================================================
// HURT
// ============================================================
// Stunned and sliding from knockback.
// ============================================================

function enemy_state_hurt()
{
    // Reduce horizontal knockback over time.
    kb_x *= kb_friction;

    // Reduce vertical knockback over time.
    kb_y *= kb_friction;

    // Count down the hurt timer.
    state_timer--;

    // When the hurt timer expires...
    if (state_timer <= 0)
    {
        // Stop horizontal knockback.
        kb_x = 0;

        // Stop vertical knockback.
        kb_y = 0;

        // Return to chasing the player.
        enemy_change_state(ENEMY_STATE.CHASE);
    }
}


// ============================================================
// DEAD
// ============================================================
// Death animation is playing. Step_0 skips movement/animation afterwards.
// ============================================================

function enemy_state_dead()
{
    // Continue playing the death animation.
    image_speed = death_anim_spd;
}
