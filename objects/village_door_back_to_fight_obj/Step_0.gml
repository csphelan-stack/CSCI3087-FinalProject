// count the wait down after D was pressed
if(wait_time >0){
	wait_time--;
}

// D was pressed this step, and the player is within "radius" pixels of the door
if(keyboard_check_pressed(door_open_button)) && collision_circle(x,y,radius,main_character_Obj,false,false){
	wait_time =30;             // wait 30 steps (half a second at 60 fps) before leaving
	door_was_pressed = true;
}

// the wait is over: go back to the fight room we came in from.
// global.prev_room is that room (its door set it as we left it). this door's own Room End then sets
// prev_room to interior_room, so the yellow spawn point is used when we get there.
// (this is here because the door has no sprite, so Animation End never happens)
if (door_was_pressed && wait_time <= 0) {
	room_goto(global.prev_room);
}
