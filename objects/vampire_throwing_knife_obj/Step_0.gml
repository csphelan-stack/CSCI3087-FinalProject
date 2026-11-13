


var _enemy = instance_place(x,y,Enemy_base_obj);




if(end_of_draw){
			if(instance_exists(main_character_Obj)){
		if(main_character_Obj.hp <= main_character_Obj.total_hp - life_steal){
		main_character_Obj.hp += life_steal;
		}
	instance_destroy();
	}
}

if(health_steal_line_timer<=0 && has_hit_yet){
	
	end_of_draw = true;
}
else{
	end_of_draw = false;
}
if(	health_steal_line_timer>0){
	health_steal_line_timer--;
}

if(hit_enemy != noone){
	if(instance_exists(hit_enemy)){
	x = hit_enemy.x;
	y =  hit_enemy.y - lerp(5,10,.1);
	}
}



		if(_enemy != noone && !has_hit_yet){
			speed = 0;
			image_speed=0;
			hit_enemy = _enemy;
			has_hit_yet = true;
			health_steal_line_timer = drain_fly_time;

	
			_enemy.hp -= damage_vtk;
	
	

			}
	


lifetime--;

if(lifetime <=0 && end_of_draw){
	image_speed = 1;

}

if(lifetime <=0 && !instance_exists(hit_enemy) && !instance_exists(_enemy)){
	image_speed = 1;
	avert_this = true;

}
