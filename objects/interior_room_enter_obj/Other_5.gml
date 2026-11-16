// ROOM END: runs as we leave this room.
// remember which room we're leaving ("room" is the room itself, not its name as text).
// in the interior room, the door back to the fight uses this to send us back here (room_goto(global.prev_room)).
global.prev_room = room;
