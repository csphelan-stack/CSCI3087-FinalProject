// ============================================================
// DOOR TO THE INTERIOR (UPGRADE) ROOM
// ============================================================
// HOW TO USE IT
// place one in each fight room that should have a way into the upgrade hall,
// and put a yellow spawn point (spawn_exit_interior_obj) just in front of it:
// that's where the player comes out when he leaves the upgrade hall and comes back to this room.
// it doesn't need any creation code: everything it needs is set below.
//
// WHAT HAPPENS
// Step:          the door is hidden and can't be used until this room's waves are all beaten
//                (global.waves_complete). then it shows up, and pressing D close to it starts its opening animation
// Animation End: the animation has finished -> go to the interior room
// Room End:      as we leave the room, remember it in global.prev_room
//                (the interior room's door uses it to send us back here, and the yellow spawn point uses it)
// Draw:          draws the door, and "Press D to travel to the upgrade hall" when you're close
// Room Start:    if we've just come back out of the interior room, the door destroys itself,
//                so each room's upgrade hall can only be visited once
// ============================================================

// don't play the animation until the door is opened (Step sets image_speed to 1)
image_speed=0;
image_index = 0;   // start on frame 0 = closed
solid =false;      // not solid to start with (Step turns it on once the waves are done)
radius = 40;       // how close (in pixels) the player has to be to see the prompt and press D

wave_completed = false;   // not used anywhere at the moment (Step checks global.waves_complete instead)

door_open_button = ord("D");   // the key that opens the door
door_was_pressed = false;      // becomes true when D is pressed, so Animation End knows to change rooms

// start hidden: an invisible instance skips its Draw event, so neither the door nor its
// "Press D" prompt shows. Step makes it visible once the waves are done.
// (this replaces hiding the "door_upgrade" layer, which only the outside room had, so the door
//  showed from the start in every other room. hiding the door itself works in every room.)
visible = false;
sprite_index =village_door_panel_opening_front_spr;   // closed on frame 0, open on the last frame
next_room = interior_room;                            // where this door always goes
sprite_open = true;                                   // has to be true before Step lets the door open
solid = false;
