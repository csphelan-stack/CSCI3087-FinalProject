// creation code for this room's top gate (village_door_to_next_room_obj).
// runs right after the door's Create, so these replace the defaults set there.
sprite_index =fortress_gate_spr;   // what the gate looks like (closed on frame 0, open on the last)
next_room = dungeon_medium_room;   // where it takes you
sprite_open = true;                // allowed to open (Step checks this)
