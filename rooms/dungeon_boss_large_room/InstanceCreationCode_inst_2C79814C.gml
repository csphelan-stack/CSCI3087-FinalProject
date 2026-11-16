// creation code for this room's door (village_door_to_next_room_obj).
// runs right after the door's Create, so these replace the defaults set there.
sprite_index =noone;                    // no sprite: the door is invisible
next_room = dungeon_medium_boss_room;   // where it takes you
sprite_open = true;                     // allowed to open (Step checks this)

// note: with no sprite there's no opening animation, so the door's Animation End never happens
// and pressing D here won't take you anywhere. give it a sprite (e.g. fortress_gate_spr) to make it work
