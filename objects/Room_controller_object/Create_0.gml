window_set_cursor(cr_none);
window_set_cursor(gui_cursor_spr);



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



global.safeInside = false;



// swap in whatever keys the player picked on the pause menu's Settings page last time
controls_load();






/* NOTE: fullscreen commented out for switch to rm_start as first room (title screen)
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


//parralax background
// sky parallax layers, farthest first
sky_sprites = [sky_day_layer1_spr, sky_day_layer2_spr, sky_day_layer3_spr];
sky_follow  = [1.0, 0.97, 0.95];  // 1 = stuck to the screen (far away); lower = shifts more as the camera moves
sky_drift   = [0, -0.01, -0.05];  // clouds drifting on their own, pixels per step
sky_scale   = 360 / 324;          // sky images are 576x324, the view is 640x360
sky_offset  = array_create(array_length(sky_sprites), 0);
sky_layers  = [];
for (var i = 0; i < array_length(sky_sprites); i++) {
    var lay = layer_create(10000 - i);                  // deep = drawn behind everything
    var bg  = layer_background_create(lay, sky_sprites[i]);
    layer_background_htiled(bg, true);
    layer_background_xscale(bg, sky_scale);
    layer_background_yscale(bg, sky_scale);
    sky_layers[i] = lay;
}



