// enemy_helper_scripts: shared enemy AI. Defines the ENEMY_STATE enum and helpers that
// enemy events call: enemy_change_state(new_state), enemy_dir4() (facing as 0-3),
// enemy_can_see_player(range, use_cone) and enemy_walk_to(target_x, target_y, speed).
enum ENEMY_STATE {
    IDLE,    // standing around
    WANDER,  // strolling to a random spot near home
    CHASE,   // can see the player, running at them
    SEARCH,  // lost sight, checking last known position
    HURT,    // knocked back, can't act
    DEAD     // playing death animation
}

/// Switch to a new state and run its one-time "enter" setup
function enemy_change_state(_new_state) {
    if (state == ENEMY_STATE.DEAD) return; // nothing leaves DEAD

    state_prev  = state;
    state       = _new_state;
    state_timer = 0;

    switch (_new_state) {
        case ENEMY_STATE.IDLE:
            state_timer = irandom_range(idle_min, idle_max);
        break;

        case ENEMY_STATE.WANDER:
            var _a = random(360);
            var _r = random_range(wander_radius * 0.3, wander_radius);
            wander_x = home_x + lengthdir_x(_r, _a);
            wander_y = home_y + lengthdir_y(_r, _a);
            state_timer = wander_give_up;
        break;

        case ENEMY_STATE.CHASE:
        break;

        case ENEMY_STATE.SEARCH:
            state_timer = search_time;
        break;

        case ENEMY_STATE.HURT:
            state_timer = hurt_time;
            // getting hit tells him where the player is
            var _p = instance_nearest(x, y, main_character_Obj);
            if (_p != noone) { target = _p; last_x = _p.x; last_y = _p.y; }
        break;

        case ENEMY_STATE.DEAD:
            kb_x = 0;
            kb_y = 0;
            image_index  = 0;
            sprite_index = spr_death[enemy_dir4()];
            image_speed  = death_anim_spd;
        break;
    }
}

/// 0 = right, 1 = up, 2 = left, 3 = down
function enemy_dir4() {
    return round(facing / 90) mod 4;
}

/// True if the player is in range (and in the view cone if _use_cone), with no wall in the way
function enemy_can_see_player(_range, _use_cone) {
    var _p = instance_nearest(x, y, main_character_Obj);
    if (_p == noone) return false;

    if (point_distance(x, y, _p.x, _p.y) > _range) return false;

    if (_use_cone) {
        var _pdir = point_direction(x, y, _p.x, _p.y);
        if (abs(angle_difference(facing, _pdir)) > view_angle * 0.5) return false;
    }

    if (collision_line(x, y, _p.x, _p.y, wall_obj, false, true) != noone) return false;

    target = _p;
    return true;
}

/// Sets this step's movement toward a point. Returns true once he's arrived.
function enemy_walk_to(_tx, _ty, _spd) {
    if (point_distance(x, y, _tx, _ty) <= _spd) return true;
    move_dir = point_direction(x, y, _tx, _ty);
    move_spd = _spd;
    return false;
}