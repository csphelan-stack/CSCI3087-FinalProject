// ============================================================
// THE INTERIOR (UPGRADE) ROOM'S DOOR BACK TO THE FIGHT
// ============================================================
// there's one of these in interior_room. it takes you back to whichever fight room you came in from:
// global.prev_room still holds that room while you're in here (the door you came in through set it
// in its Room End), so Step sends you there with room_goto(global.prev_room).
// back in that room, the yellow spawn point (spawn_exit_interior_obj) puts you in front of the interior door.
//
// WHAT HAPPENS
// Step:          press D close to it -> wait 30 steps -> go back to global.prev_room
// Animation End: would also go back, but this door has no sprite, so it never happens (see Step)
// Room End:      as we leave, set global.prev_room to interior_room, so the yellow spawn point gets used
// Draw:          "Press D to re-enter the fight" when you're close
// Room Start:    nothing any more (the blue spawn point in this room places the player)
// ============================================================

// no animation playing to start with
image_speed=0;
image_index = 0;

start_done = false;   // not used anywhere at the moment
radius = 50;          // how close (in pixels) the player has to be to see the prompt and press D

wait_time=0;   // counts down after D is pressed; at 0 we leave (a short pause before the room changes)

door_open_button = ord("D");   // the key that uses the door

path_finished = false;      // not used anywhere at the moment
door_was_pressed = false;   // becomes true when D is pressed
