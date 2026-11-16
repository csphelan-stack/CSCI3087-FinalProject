window_set_cursor(cr_none);
window_set_cursor(gui_cursor_spr);

// ---------- DOORS ----------
//whether or not we gave enetered the upgrade room
// if yes then make it transport us to the red spawn spot not the blue.
// else go to blue
// (not used anywhere at the moment: the spawn points check global.prev_room instead, see below)
global.door_entered_interior = false;

// global.prev_room = the room we just walked out of. every door sets it in its Room End as we leave a room.
// the spawn points read it in their Room Start: if we just left interior_room, the yellow spawn point
// (spawn_exit_interior_obj) is used, otherwise the normal blue one (spawn_obj).
// the interior room's door also uses it to send us back to the fight room we came in from.
// noone = we haven't come through a door yet (start of the game).
// it's only set the first time: this controller is persistent, but there's another one placed in
// interior_room, and if GameMaker makes that copy when we walk in, its Create would otherwise wipe out
// prev_room and the door back to the fight wouldn't know where to go.
if (!variable_global_exists("prev_room")) {
	global.prev_room = noone;
}
// obj_controller: Create

global.BASE_W = 640;
global.BASE_H = 360;

// medieval pixel font, made once for the whole game. use it with draw_set_font(global.font_medieval)
// it's white so draw_set_colour tints it, and it looks crispest at whole-number scales (1, 2, 3)
if (!variable_global_exists("font_medieval")) {
    global.font_medieval = font_add_sprite_ext(gui_font_medieval_spr, " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,!?:;-+'\"()/%&*_", true, 1);
}

// Window scale (2 = 1280×720)


// GUI scaling
gui_scaling = 1.2;

global.left_button = vk_left;
global.right_button = vk_right;
global.up_button = vk_up;
global.down_button = vk_down;
global.attack_button = ord("Z");
global.dash_button = ord("C");
global.parry_button = ord("X");
global.special_button = ord("S");   // press for the equipped special (hold it to charge the Bladed Tsunami)

// how fast enemies run: 1 = normal, 0.25 = a quarter speed (the Dance of Dragons slows them while he dances)
// set here so every restart begins at normal speed
global.enemy_time_scale = 1;

global.safeInside = false;






// swap in whatever keys the player picked on the pause menu's Settings page last time
controls_load();



global.coming_from_door = false;


/* NOTE: fullscreen commented out for switch to start_room as first room (title screen)
// Default to fullscreen (also set as the project's Windows "start fullscreen"
// option, but forcing it here too so it's honored during IDE test-runs as well)
if (!window_get_fullscreen()) {
    window_set_fullscreen(true);
}
*/

// Crisp pixels
gpu_set_texfilter(false);

// Enable views
view_enabled = true;
view_visible[0] = true;

// Create camera at BASE resolution
cam = camera_create_view(0, 0, global.BASE_W, global.BASE_H, 0, noone, 0, 0, 0, 0);
view_camera[0] = cam;

// Resize application surface once
if (application_surface != -1) {
    surface_resize(application_surface, global.BASE_W, global.BASE_H);
}

// GUI size
display_set_gui_size(global.BASE_W * gui_scaling, global.BASE_H * gui_scaling);






