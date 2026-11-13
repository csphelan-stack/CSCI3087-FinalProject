function enemy_stun_state(){
	
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