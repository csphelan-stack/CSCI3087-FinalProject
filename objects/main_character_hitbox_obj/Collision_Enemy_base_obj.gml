if(array_contains(hit_list,other.id)) exit;

if (other.state == ENEMY_STATE.DEAD) exit;

array_push(hit_list,other.id);

other.hp -= damage;

var _kb_dir = point_direction(owner.x,owner.y,other.x,other.y);
other.kb_x = lengthdir_x(knockback,_kb_dir);
other.kb_y = lengthdir_y(knockback,_kb_dir);

with(other){
	
enemy_change_state(ENEMY_STATE.HURT);	
	
}