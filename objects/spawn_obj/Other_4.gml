// ============================================================
// THE ROOM'S NORMAL (BLUE) SPAWN POINT
// ============================================================
// put one of these in every room where the player should appear.
// it's invisible in the game (Visible is unticked); the blue square only shows in the room editor.
//
// ROOM START runs once when the room begins, after every instance's Create and creation code.
// this is where the player gets put in the room: the doors don't move him any more.
//
// global.prev_room is the room we just walked out of. every door sets it in its Room End
// (the event that runs as we leave a room), so by the time we get here it holds the old room.
//
// we use THIS spawn point every time, except when we've just come out of the interior (upgrade) room.
// in that case the yellow one (spawn_exit_interior_obj) is used instead, so he comes out in front
// of the interior door rather than back at the start of the room.
// ============================================================

if (global.prev_room != interior_room) {
	if (!instance_exists(main_character_Obj)) {
		// there's no player yet (e.g. the very start of the game), so make him right here.
		// "layer" = this spawn point's own layer, so it always exists in this room
		instance_create_layer(x, y, layer, main_character_Obj);
	}
	else {
		// the player is persistent, so he's been carried over from the last room still standing
		// where he was in it. move him onto this spawn point
		main_character_Obj.x = x;
		main_character_Obj.y = y;
	}
}
