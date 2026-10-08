function attackStatePlayer(){

    // has the swing reached the hit frame, and have we NOT made a hitbox yet this swing?
    if (image_index >= attack_hit_frame && !attack_hit_spawned) {

        attack_hit_spawned = true;  // only ever make one per swing

        // which way is he facing? snapped to exactly 0, 90, 180 or 270
        var dir4 = round(facing / 90) mod 4;
       
        var _dir = dir4 * 90;

        // half the hitbox's size, so we can line up its EDGE instead of its centre
        var _half_w = sprite_get_width(main_character_hitbox_spr) / 2;
        var _half_h = sprite_get_height(main_character_hitbox_spr) / 2;

        // start at the peak of the swing, then step back toward him by half the box,
        // so the far edge of the box sits right on the peak
        var _hx = x + attack_peak_x[dir4] - lengthdir_x(_half_w, _dir);
        var _hy = y + attack_peak_y[dir4] - lengthdir_y(_half_h, _dir);

        var _hb = instance_create_layer(_hx, _hy, layer, main_character_hitbox_obj);
        _hb.owner = id;   //telling the hitbox who made it
		}
}

function startAttackPlayer(){
    // runs ONCE when Z is pressed
    state = PlayerState.ATTACK;

    // same direction math as the movement code: 0 = right, 1 = up, 2 = left, 3 = down
    var dir4 = round(facing / 90) mod 4;
    switch (dir4) {
        case 0: sprite_index = skull_knight_attack_right_spr;    break;
        case 1: sprite_index = skull_knight_attack_backward_spr; break;
        case 2: sprite_index = skull_knight_attack_left_spr;     break;
        case 3: sprite_index = skull_knight_attack_forward_spr;  break;
    }
    image_index = 0;   // start the swing from the first frame
    image_speed = 1;   // play at the sprite's normal speed
	
	attack_hit_spawned = false;  //new swing, so it hasn't made a hitbox yet
}