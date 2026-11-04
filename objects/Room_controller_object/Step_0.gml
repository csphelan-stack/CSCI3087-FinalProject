
if (instance_exists(main_character_Obj)) {

    var cam = view_camera[0];

    // Camera view size (base resolution)
    var vw = camera_get_view_width(cam);
    var vh = camera_get_view_height(cam);

    // Sprite info
    var spr = main_character_Obj.sprite_index;
    var origin_y = sprite_get_yoffset(spr);
    var spr_h = sprite_get_height(spr);

    // Zeke's visual center (independent of origin, and scaled along with the character)
    var visual_center_y = main_character_Obj.y + (spr_h * 0.5 - origin_y) * main_character_Obj.image_yscale;

    // Target camera position
    var target_x = main_character_Obj.x - vw * 0.5;
    var target_y = visual_center_y - vh * 0.5;

    // something else to look at instead of him (the Butterfly Effect's choice pans to the enemy being picked)
    var focus = main_character_Obj.cam_target;
    if (instance_exists(focus)) {
        target_x = focus.x - vw * 0.5;
        target_y = focus.y - 20 - vh * 0.5;
    }

    // Smooth follow
    var cx = camera_get_view_x(cam);
    var cy = camera_get_view_y(cam);

    camera_set_view_pos(cam, lerp(cx, target_x, 0.12), lerp(cy, target_y, 0.12));
	
	
	if(room == interior_room){
		characterInside_script();
		
	}else{
		characterOutside_script();
	}
	

	
}



	
