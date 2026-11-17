// ANIMATION END: the door's animation has reached its last frame (it's fully open).
// only change rooms if D was pressed (Step sets door_was_pressed when it starts the animation)
if(door_was_pressed){
	if(next_room != noone){
		// this door has a room set in its creation code: go there
		room_goto(next_room);
	}
	else{
		// no room set: go to the next room in the project's room order
		room_goto_next();
	}
}
