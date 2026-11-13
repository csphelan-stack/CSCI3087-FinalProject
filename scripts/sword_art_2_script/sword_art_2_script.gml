//This entire method basically creates an instance for a throwing knife projectile
//then passies all information needed for it to function
//all variable are in the create
//and there are strict limits on everything.
//also there is a object it makes and that stores the sprite and takes in the variables given to make it functions
// need to add a better way to switch between

function sword_art_2(){
	
	
	
	if(image_index >= attack_vtk_hit_frame && knife_throw_cooldown<=0 && knife_throws_before_switching_back >0){
	
	var dir4 = round(facing / 90) mod 4;
	
	opp_swing_dir_vtk = dir4*90;
	
	
	 var _start_angle = facing - ((amount_of_knives - 1) * original_space_between) / 2;
	
		for( var i=0;i< amount_of_knives;i++){
			var _knife = instance_create_depth(x,y,-100,vampire_throwing_knife_obj);
	


			knife_throw_cooldown = knife_throw_cooldown_total;
	
			_knife.damage_vtk = damage_vtk;
			_knife.life_steal=life_steal;
			_knife.lifetime=lifetime_vtk;
			_knife.speed=speed_vtk;
			_knife.amount_of_knives=amount_of_knives;
			
			
			var _target_angle = _start_angle + (i * original_space_between);
			_knife.direction = (_target_angle + 360) mod 360; 
			_knife.image_angle = _knife.direction;
			_knife.image_speed = 0;
			
			
			
			//decided to just go the simple route wasted some time trying to make it look better but it just looked
			//worse
			
			with(_knife){
				
				var _dir = round(direction / 45) * 45;
			    if (_dir == 360) _dir = 0; // wrap 360 back to 0
				
				
			    switch (_dir) {
			        case 0:   sprite_index = knife_projectiles_forward;  image_angle  = -90; break;
			        case 45:  sprite_index = knife_projectiles_down_right;image_angle  = 0; break;
			        case 90:  sprite_index = knife_projectiles_forward; image_angle  = 0;break;
			        case 135: sprite_index = knife_projectiles_down_right;image_angle  = 90; break;
			        case 180: sprite_index = knife_projectiles_forward; image_angle  = 90;break;
			        case 225: sprite_index = knife_projectiles_down_right; image_angle  = 180;break;
			        case 270: sprite_index = knife_projectiles_forward;image_angle  = 180; break;
			        case 315: sprite_index = knife_projectiles_down_right; image_angle  = 270;break;
			    }	
				
			}
			
			
		}
		
		self.push_x = lengthdir_x(self.vtk_recoil, opp_swing_dir_vtk + 180);
		self.push_y = lengthdir_y(self.vtk_recoil, opp_swing_dir_vtk + 180);
		
	
	}
	else if (keyboard_check_pressed(global.weapon_change_btn)){
		switch_weapon_to_vpk = false;
		throwing_knfe_cooldown=throwing_knfe_cooldown_total
	}
	else if(knife_throws_before_switching_back <=0){
	//this is where we would switch back automatically
	knife_throws_before_switching_back = knife_throws_before_switching_back_o;
	switch_weapon_to_vpk = false;
	throwing_knfe_cooldown=throwing_knfe_cooldown_total
	}



}