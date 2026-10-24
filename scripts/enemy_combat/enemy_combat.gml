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


// ============================================================
// ENEMY MAGIC ATTACK
// ============================================================
// Damages the player only if they are inside the spell's impact circle.
// The damage is applied through the player's normal handler, so parrying,
// invulnerability, hit reactions, knockback, and audio still work.
function enemy_magic_attack_hit()
{
    if (!magic_enabled) return false;

    var _p = instance_nearest(magic_target_x, magic_target_y, main_character_Obj);
    if (_p == noone || !instance_exists(_p)) return false;

    // A spell is an area strike centered on the marker, not a homing attack.
    if (point_distance(_p.x, _p.y, magic_target_x, magic_target_y) > magic_aoe_radius)
    {
        return false;
    }

    // Do not damage through a wall between the impact point and the player.
    if (collision_line(magic_target_x, magic_target_y, _p.x, _p.y, obj_wall, false, true) != noone)
    {
        return false;
    }

    if (!variable_instance_exists(_p, "hp")) return false;

    with (_p)
    {
        Enemy_damage_applying(other.attack_damage, other.id);
    }

    return true;
}
