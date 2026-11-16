// ROOM START: nothing here any more.
//
// this used to move the player onto the spawn points, but the spawn points do that themselves now
// (spawn_obj = the blue normal one, spawn_exit_interior_obj = the yellow one after the interior room),
// in their own Room Start. that way every room works the same way, even rooms with no doors in them,
// and only one thing ever moves the player when a room starts.
//
// (the old version also had two bugs: it set the player's x twice, "x = spawn_obj.y", so his y never changed,
//  and it compared global.prev_room to the text "interior_room", but Room End stores the room itself,
//  not its name, so they were never equal and the yellow spawn point was never used.)
