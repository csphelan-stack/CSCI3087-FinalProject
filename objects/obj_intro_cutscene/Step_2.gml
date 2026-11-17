if (!instance_exists(main_character_Obj) || npc == noone || !instance_exists(Dialogue_Obj)) {
    instance_destroy();
    exit;
}

switch (state) {

    case 0:
        main_character_Obj.can_move = false;
        timer--;
        if (timer <= 0) {
            cur_x = camera_get_view_x(cam);   // start from wherever the normal camera is
            cur_y = camera_get_view_y(cam);
			home_x = cur_x;
            home_y = cur_y;
            state = 1;
        }
        break;

    case 1: // pan to the NPC
        var _t = get_cam_target(npc);
        cur_x = lerp(cur_x, _t.x, pan_speed);
        cur_y = lerp(cur_y, _t.y, pan_speed);
        camera_set_view_pos(cam, cur_x, cur_y);

        if (point_distance(cur_x, cur_y, _t.x, _t.y) < 2) {
            hold_x = _t.x;
            hold_y = _t.y;
            state = 2;
			//temp 
			show_debug_message(npc.portrait_crop);
			show_debug_message(sprite_get_name(npc.sprite_index));
			//temp end
            Dialogue_Obj.start_dialogue(
    "Old Smith",
    ["Ahh, the player. Come over and talk to me for a minute."],
    npc.sprite_index,
    function() { main_character_Obj.can_move = false; state = 3; },
    npc.portrait_crop
);
        }
        break;

    case 2: // hold on the NPC while the box is up
        camera_set_view_pos(cam, hold_x, hold_y);
        break;

    case 3: // pan back to where the camera started
        cur_x = lerp(cur_x, home_x, pan_speed);
        cur_y = lerp(cur_y, home_y, pan_speed);
        camera_set_view_pos(cam, cur_x, cur_y);

        if (point_distance(cur_x, cur_y, home_x, home_y) < 2) {
            main_character_Obj.can_move = true;
			npc.talk_cooldown = 20;
            state = 4;
        }
        break;

    case 4:
        instance_destroy();
        break;
}