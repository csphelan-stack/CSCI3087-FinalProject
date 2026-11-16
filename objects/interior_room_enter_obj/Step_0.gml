// the door is hidden and can't be used until every wave in this room has been beaten.
// the wave manager sets global.waves_complete to true after its last wave
// (and its Create sets it back to false in each room that has a wave manager).
// in a room with no wave manager it stays as it was in the last room.

// visible while the waves are done, hidden while they aren't.
// hidden = its Draw event doesn't run, so no door and no "Press D" prompt
visible = global.waves_complete;

// and while the waves aren't done, everything below is skipped, so D does nothing
if(global.waves_complete){
	// the waves are done, so get rid of the wave manager
	instance_destroy(enemy_wave_manager_obj);

	solid = true;

	// D was pressed this step, and the player is within "radius" pixels of the door
	if(keyboard_check_pressed(door_open_button) && collision_circle(x,y,radius,main_character_Obj,false,false)){

		if(sprite_open){
			image_speed =1;            // start playing the opening animation
			door_was_pressed = true;   // so Animation End goes to the interior room when it finishes
		}
	}
}

// (removed: global.prev_room = room_get_name(room); it turned prev_room into the room's name as text
//  every step. Room End sets it to the room itself as we leave, which is what everything else expects.)
