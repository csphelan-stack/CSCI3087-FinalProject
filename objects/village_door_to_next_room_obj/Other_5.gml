// ROOM END: runs as we leave this room (for any reason: a door, dying, etc).
// remember which room we're leaving. "room" is the room itself (not its name as text).
// the spawn points in the next room read this in their Room Start: if we just left the interior room,
// the yellow spawn point is used, otherwise the normal blue one.
global.prev_room = room;
