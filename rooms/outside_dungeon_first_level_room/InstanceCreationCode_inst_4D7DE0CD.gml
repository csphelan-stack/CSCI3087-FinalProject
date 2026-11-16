// creation code for the outside room's gate (village_door_to_next_room_obj).
// runs right after the door's Create, so these replace the defaults set there.
sprite_index =fortress_gate_spr;                 // what the gate looks like (closed on frame 0, open on the last)
next_room = inside_dugeon_walls_first_boss_room;   // where it takes you
sprite_open = true;                              // allowed to open (Step checks this)

// note: inside_dugeon_walls_first_boss_room is a child of this room, and its bottom gate (inst_2A919711)
// inherits this creation code, so that gate leads into inside_dugeon_walls_first_boss_room itself
