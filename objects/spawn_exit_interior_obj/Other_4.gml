// ============================================================
// THE YELLOW SPAWN POINT: where you come out after the interior (upgrade) room
// ============================================================
// put one of these in front of the interior door (interior_room_enter_obj) in every room that has one.
// it's invisible in the game (Visible is unticked); the yellow square only shows in the room editor.
//
// ROOM START runs once when the room begins, after every instance's Create and creation code.
// global.prev_room is the room we just walked out of (every door sets it in its Room End).
// if that was the interior room, we've just come back out of it, so put the player here,
// in front of the interior door, instead of at the room's normal (blue) spawn point (spawn_obj).
// the blue spawn point does the opposite check, so only one of the two ever moves him.
// ============================================================

if (global.prev_room == interior_room && instance_exists(main_character_Obj)) {
	main_character_Obj.x = x;
	main_character_Obj.y = y;
}
