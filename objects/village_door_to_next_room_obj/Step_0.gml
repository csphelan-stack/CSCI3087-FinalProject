// D was pressed this step, and the player is within "radius" pixels of the door
if(keyboard_check_pressed(door_open_button) && collision_circle(x,y,radius,main_character_Obj,false,false)){

	// only doors with sprite_open = true (set in their creation code) can be opened
	if(sprite_open){
		image_speed =1;            // start playing the opening animation
		door_was_pressed = true;   // so Animation End changes rooms when the animation finishes
	}
}

// note: a door with no sprite (like the one in dungeon_boss_large_room, which sets sprite_index = noone)
// has no animation, so Animation End never happens and pressing D won't take you anywhere
