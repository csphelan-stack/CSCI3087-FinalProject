function draw_buttons_settings(){

if(!global.gameIsPaused){
	
	window_set_cursor(cr_none);
	
	main_character_Obj.can_move=true;
	
	for(var r =0; r< btn_num; r++){

		var inst = instance_destroy(settingsA[r].obj);
		
	}
	
	
	
}
else{
	
	
	if (global.gameIsPaused)
    {
		
        with (all)
        {
            if (object_index == Settings_Obj) continue;

            // Save and stop built-in movement
            p_hspd  = hspeed;
            p_vspd  = vspeed;
            p_grav  = gravity;
            p_path  = path_speed;
            hspeed = 0; vspeed = 0; gravity = 0; path_speed = 0;

            // Save and freeze alarms
            for (var i = 0; i < 12; i++)
            {
                p_alarm[i] = alarm[i];
                alarm[i] = -1;
            }
        }
    }
    else
    {
        with (all)
        {
            if (object_index == Settings_Obj) continue;

            hspeed = p_hspd;
            vspeed = p_vspd;
            gravity = p_grav;
            path_speed = p_path;

            for (var i = 0; i < 12; i++) alarm[i] = p_alarm[i];
        }
    }
	
	
	for(var r =0; r< btn_num; r++){
		
		var bx = startx+spaced;
		var by = starty+r*spaced;
		
		var inst = instance_create_depth(bx,by,-200,settingsA[r].obj);
		
		
		inst.sprite_index = settingsA[r].spr;
		inst.button_w = sprite_get_width(settingsA[r].spr)*2;
		inst.button_h = sprite_get_height(settingsA[r].spr)*2;
		inst.label = settingsA[r].label;
		
		
		
	}
	
	
}





}