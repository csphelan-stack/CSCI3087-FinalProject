

//CONVERT FACING ANGLE INTO 4 DIRECTIONS
//returns: 0 = right 1 = backward/up 2 = left 3 = forward/down
function enemy_dir4() {
    return round(facing / 90) mod 4;
}

// PICK SPRITE + ANIMATION SPEED
// called every frame 
// priority: attack > hurt > run > idle.
function enemy_update_animation() {
    // Defensive default for older/inherited enemy instances missing this value.
    if (!variable_instance_exists(id, "attack_anim_spd")) attack_anim_spd = 1.0;

    var _d = enemy_dir4();

    // if the enemy is attacking...
    if (state == ENEMY_STATE.ATTACK){
        if (magic_enabled) {
            // Spellcasters hold their idle pose; the orb and rune show the attack.
            sprite_index = spr_idle[_d];
            image_speed = idle_anim_spd;
        } else {
            // Select the usual attack sprite for melee enemies.
            sprite_index = spr_attack[_d];
            image_speed = attack_anim_spd;
        }
    }else if (state == ENEMY_STATE.HURT){// if the enemy is hurt...
        // hurt sprite for the current direction
        sprite_index = spr_hurt[_d];

        // play hurt animation.
        image_speed = hurt_anim_spd;
    }else if (move_spd > 0){// if the enemy is moving...
        // use the running sprite for current direction
        sprite_index = spr_run[_d];

        // play running animation.
        image_speed = run_anim_spd;
    }else{
        // idle sprite for current direction
        sprite_index = spr_idle[_d];

        // play idle animation.
        image_speed = idle_anim_spd;
    }
}
