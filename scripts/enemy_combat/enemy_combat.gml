// ============================================================
// ENEMY DAMAGE
// ============================================================

// damages this enemy
// this function is intended to be called by the player's attack
function enemy_take_damage(_damage, _source_x, _source_y){
    if (state == ENEMY_STATE.DEAD){
        return;//ignore damage since dead
    }

    if (_damage <= 0){
        return;// ignore negative damage
    }

    hp -= _damage;

    // prevents HP from going below zero
    hp = max(hp, 0);

    // calculate the direction the knockback should travel
    var _kb_direction = point_direction(_source_x, _source_y, x, y);

    // apply horizontal knockback
    kb_x = lengthdir_x(knockback_power, _kb_direction);

    // apply vertical knockback
    kb_y = lengthdir_y(knockback_power, _kb_direction);

    if (hp <= 0){
        enemy_change_state(ENEMY_STATE.DEAD);
        return;
    }

    // if none else, put the enemy into the hurt state
    //need to make the sprite turn red =====================================================
    enemy_change_state(ENEMY_STATE.HURT);
}


// ============================================================
// ENEMY ATTACK
// ============================================================

// attempts to damage the current player target
function enemy_attack_hit(){
    if (target == noone){
        return false;
    }

    // check if target still exists
    if (!instance_exists(target)){
        return false;
    }

    // check if player is still close enough
    if (point_distance(x, y, target.x, target.y) > attack_range){
        return false;
    }

    // check for wall between enemy and player
    if (collision_line(x, y, target.x, target.y, obj_wall, false, true) != noone){
        return false;
    }

    // check player has HP
    if (!variable_instance_exists(target, "hp")){
        return false;
    }

//changed to running from the main character objects perspective
//this helps me to be able to implement a parry mechanism

	var _hurt = false;   // did the hit actually hurt him? (false if he parried it)
	with(main_character_Obj){
			_hurt = Enemy_damage_applying(other.attack_damage,other.id);
	}

	return _hurt;
}
