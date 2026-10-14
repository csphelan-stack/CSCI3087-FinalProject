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
    // Check whether the target still exists.
    if (target == noone || !instance_exists(target))
    {
        // Try to find the player again.
        if (!enemy_can_see_player(sight_range, false))
        {
            // No player found, so start searching.
            enemy_change_state(ENEMY_STATE.SEARCH);

            // Stop processing CHASE.
            return;
        }
    }

    // Make sure the player is still within the enemy's
    // maximum chase range and has line of sight.
    if (!enemy_can_see_player(lose_range, false))
    {
        // Remember where the player was.
        enemy_change_state(ENEMY_STATE.SEARCH);

        // Stop processing CHASE.
        return;
    }

    // Store the player's current X position.
    last_x = target.x;

    // Store the player's current Y position.
    last_y = target.y;


    // Calculate the distance from enemy to player.
    var _distance = point_distance(x, y, target.x, target.y);


    // Check whether the enemy is close enough to attack.
    if (_distance <= attack_range)
    {
        // Face the player.
        facing = point_direction(x, y, target.x, target.y);

        // Only attack if the cooldown has finished.
        if (attack_cooldown <= 0)
        {
            // Enter the attack state.
            enemy_change_state(ENEMY_STATE.ATTACK);
        }
    }
    else
    {
        // Continue chasing the player.
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
    // Do not move normally while attacking.
    move_spd = 0;

    // Make sure the target still exists.
    if (target != noone && instance_exists(target))
    {
        // Keep facing toward the player.
        facing = point_direction(x, y, target.x, target.y);
    }

    // Count the attack timer down.
    state_timer--;


    // Determine whether the attack has reached its hit frame.
    if (!attack_hit_done &&
        state_timer <= attack_duration - attack_windup)
    {
        // Attempt to damage the player.
        enemy_attack_hit();

        // Mark this attack as already having hit.
        attack_hit_done = true;
    }


    // Check whether the attack has finished.
    if (state_timer <= 0)
    {
        // Start the attack cooldown.
        attack_cooldown = attack_cooldown_max;

        // Resume chasing.
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
