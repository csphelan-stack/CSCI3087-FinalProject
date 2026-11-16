// ROOM START: runs once when the room begins, after every instance's Create and creation code.

// ONE VISIT PER ROOM
// global.prev_room is the room we just walked out of (every door sets it in its Room End).
// if it's the interior room, we've just come back from the upgrade hall through this room's door,
// so this room's upgrade has been used: the door destroys itself and can't be used again.
// (the yellow spawn point still puts the player where the door was: it's a separate object)
//
// note: leaving a room throws away everything in it, and coming back makes everything again.
// so if you come back to this room some other way later (not straight out of the interior room),
// the door will be back.
if (global.prev_room == interior_room) {
	instance_destroy();
}

// (the player isn't placed here any more: the spawn points do that, see spawn_obj and spawn_exit_interior_obj.
//  this door used to move him onto the blue spawn point, and because it's the last thing created in each room
//  it ran last and undid the yellow spawn point. it also set his x twice, "x = spawn_obj.y", so y never changed.)
