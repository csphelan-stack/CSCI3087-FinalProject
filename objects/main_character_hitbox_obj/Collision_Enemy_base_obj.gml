if(array_contains(hit_list,other.id)) exit;

if (other.state == ENEMY_STATE.DEAD) exit;

array_push(hit_list,other.id);

other.hp -= damage;

var _kb_dir = point_direction(owner.x,owner.y,other.x,other.y);
other.kb_x = lengthdir_x(knockback,_kb_dir);
other.kb_y = lengthdir_y(knockback,_kb_dir);

// recoil: the swing pushes the player back too, the opposite way
if (instance_exists(owner)) {
	owner.push_x = lengthdir_x(owner.attack_recoil, _kb_dir + 180);
	owner.push_y = lengthdir_y(owner.attack_recoil, _kb_dir + 180);

	// damage number above the enemy (inside with(owner), "other" would be this hitbox, so grab them first)
	var _enemy = other.id;
	var _dmg = damage;
	var _crit = is_crit;
	with (owner) damagePopupAdd(_enemy, _dmg, _crit);
}

with(other){
	
enemy_change_state(ENEMY_STATE.HURT);	
	
}