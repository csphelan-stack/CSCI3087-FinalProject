// ANIMATION END: would send us back to the fight room once the door's animation finished.
// this door has no sprite, so it has no animation and this never runs: Step does the room change instead.
// (if you give it a sprite in its creation code later, this will work too)
if(door_was_pressed && wait_time<=0){
	room_goto(global.prev_room);
}
