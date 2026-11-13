var _enemy = instance_place(x,y,Enemy_base_obj);

if(instance_exists(_enemy)){

var _kb_dir = point_direction(self.x,self.y,_enemy.x,_enemy.y);
_enemy.kb_x = lengthdir_x(knockback+10,_kb_dir);
_enemy.kb_y = lengthdir_y(knockback+10,_kb_dir);

_enemy.hp -= damage;
}

if(instance_exists(main_character_Obj)){
with(main_character_Obj){
	sa3_cooldown_time = sa3_cooldown_time_o;
	switch_weapon_to_sa3 =false;
}
}



instance_destroy(circle_push_obj);
instance_destroy();
