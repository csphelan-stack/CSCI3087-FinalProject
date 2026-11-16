// ROOM END: runs as we leave the interior room.
// "room" is interior_room here, so global.prev_room = interior_room.
// in the fight room we go back to, the spawn points see that we just came out of the interior room,
// so the yellow one (spawn_exit_interior_obj) puts the player in front of the interior door.
global.prev_room = room;
