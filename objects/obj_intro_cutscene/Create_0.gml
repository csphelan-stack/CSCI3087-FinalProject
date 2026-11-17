state = 0;          // 0 short wait, 1 pan to NPC, 2 talking, 3 pan back, 4 done
timer = 30;         // frames to wait so the normal camera has set itself up
pan_speed = 0.06;   // higher = faster pan
cam = view_camera[0];
npc = instance_find(obj_interior_npc, 0);
hold_x = 0;
hold_y = 0;

// where the camera's top-left should be to centre an instance on screen
get_cam_target = function(_inst) {
    var _vw = camera_get_view_width(cam);
    var _vh = camera_get_view_height(cam);
   var _cx = _inst.x;
	var _cy = _inst.y;
	if (_inst.sprite_index != -1) {
		_cx += _inst.sprite_width / 2 - sprite_get_xoffset(_inst.sprite_index) * _inst.image_xscale;
		_cy += _inst.sprite_height / 2 - sprite_get_yoffset(_inst.sprite_index) * _inst.image_yscale;
		
}
// manual offsets for panning camera
_cx += 0;    // positive = camera looks further right
_cy += 0;    // positive = camera looks further down
    return {
        x : clamp(_cx - _vw / 2, 0, max(0, room_width  - _vw)),
        y : clamp(_cy - _vh / 2, 0, max(0, room_height - _vh))
    };
}

// manual override 
depth = -10000;   // runs its End Step after other objects, so it wins over the follow code
cur_x = 0;        // the cutscene's own camera position
cur_y = 0;

// return to player after initial pan
home_x = 0;   // where the normal camera was before the pan
home_y = 0;