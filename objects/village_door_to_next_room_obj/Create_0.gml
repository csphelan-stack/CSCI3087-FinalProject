// ============================================================
// DOOR TO THE NEXT ROOM (the fortress gates between the fight rooms)
// ============================================================
// HOW TO USE IT
// place it in a room, then in its Creation Code (double-click the instance in the room editor) set:
//   sprite_index = fortress_gate_spr;   // what it looks like (an animation: closed on frame 0, open on the last frame)
//   next_room = dungeon_medium_room;    // where it goes. leave it as noone to go to the next room in the room order
//   sprite_open = true;                 // lets it be opened (Step won't open it while this is false)
//
// WHAT HAPPENS
// Step:          walk up to it and press D -> its opening animation starts playing
// Animation End: the animation has finished -> go to next_room
// Room End:      as we leave the room, remember it in global.prev_room
// Draw:          draws the door, and "Press D to open the door" when you're close
// Room Start:    nothing any more. where the player appears in the new room is decided by the
//                spawn points (spawn_obj = blue, spawn_exit_interior_obj = yellow), in their own Room Start.
// ============================================================

// don't play the animation until the door is opened (Step sets image_speed to 1)
image_speed=0;
image_index = 0;   // start on frame 0 = closed
solid =false;      // don't let it stop the player like a solid object (the movement code only stops at wall_obj)
start_done = false;   // not used anywhere at the moment
radius = 40;          // how close (in pixels) the player has to be to see the prompt and press D
sprite_closing = false;   // not used anywhere at the moment
sprite_open = false;      // has to be true before Step lets the door open (each door sets it to true in its creation code)

wave_completed = false;   // not used anywhere at the moment (global.waves_complete is what the interior door checks)

door_open_button = ord("D");   // the key that opens the door
next_room = noone;             // where the door goes (set in each door's creation code)
path_finished = false;         // not used anywhere at the moment
door_was_pressed = false;      // becomes true when D is pressed, so Animation End knows to change rooms

visible = true;   // drawn (the Draw event below does the drawing)
