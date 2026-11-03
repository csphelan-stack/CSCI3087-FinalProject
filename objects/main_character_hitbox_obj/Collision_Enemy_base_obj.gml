if(array_contains(hit_list,other.id)) exit;

if (other.state == ENEMY_STATE.DEAD) exit;

array_push(hit_list,other.id);

if (bf_store) {
	// Butterfly Effect window: no damage now, the hit is saved and lands when the window ends (endButterfly)
	other.bf_hits += 1;
	other.bf_stored += damage;

	// a couple of little butterflies come loose from it
	var _bx = other.x;
	var _by = other.y - 14;
	if (instance_exists(owner)) with (owner) butterflyPuff(_bx, _by, 2, 1, 2.5);
} else {
	other.hp -= damage;
}

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
	if (!bf_store) with (owner) damagePopupAdd(_enemy, _dmg, _crit);   // stored hits show as "x12" instead (butterfliesDraw)
}

with(other){
	
enemy_change_state(ENEMY_STATE.HURT);	
	
}