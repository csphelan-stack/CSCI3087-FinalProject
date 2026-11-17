// enemy_stun_state: runs every step while an enemy is in ENEMY_STATE.STUN.
// Slows its knockback slide (kb_x, kb_y) by kb_friction and counts state_timer down;
// when the timer runs out it stops sliding and goes back to ENEMY_STATE.CHASE.
// Called from Enemy_base_obj Step (runs as the enemy); takes nothing in.
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
		
		//robust way to deal with the two different sword arts that usew this stun
		main_character_Obj.stun_min = false;
			
        // Return to chasing the player.
        enemy_change_state(ENEMY_STATE.CHASE);
    }


}


