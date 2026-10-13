//pauses every enemy that inherits from this
if (global.gameIsPaused) { image_speed = 0; exit; }

// ANY state -> DEAD
if (hp <= 0 && state != ENEMY_STATE.DEAD) enemy_change_state(ENEMY_STATE.DEAD);

move_spd = 0; // states set this if they want to walk this step

// ======================= STATE MACHINE =======================
switch (state) {

    case ENEMY_STATE.IDLE:
        if (enemy_can_see_player(sight_range, true)) { enemy_change_state(ENEMY_STATE.CHASE); break; }

        state_timer--;
        if (state_timer <= 0) enemy_change_state(ENEMY_STATE.WANDER);
    break;

    case ENEMY_STATE.WANDER:
        if (enemy_can_see_player(sight_range, true)) { enemy_change_state(ENEMY_STATE.CHASE); break; }

        state_timer--;
        if (enemy_walk_to(wander_x, wander_y, wander_spd) || state_timer <= 0) {
            enemy_change_state(ENEMY_STATE.IDLE);
        }
    break;

    case ENEMY_STATE.CHASE:
        if (!enemy_can_see_player(lose_range, false)) { enemy_change_state(ENEMY_STATE.SEARCH); break; }

        last_x = target.x;
        last_y = target.y;

        if (point_distance(x, y, target.x, target.y) > stop_range) {
            enemy_walk_to(target.x, target.y, movespd);
        } else {
            facing = point_direction(x, y, target.x, target.y);
            // an ATTACK state would go here later: enemy_change_state(ENEMY_STATE.ATTACK);
        }
    break;

    case ENEMY_STATE.SEARCH:
        // he's alert now, so no view cone needed to re-spot you
        if (enemy_can_see_player(sight_range, false)) { enemy_change_state(ENEMY_STATE.CHASE); break; }

        state_timer--;
        var _arrived = enemy_walk_to(last_x, last_y, movespd);

        // once at the last known spot, look around
        if (_arrived && state_timer mod 40 == 0) facing = (facing + 90) mod 360;

        if (state_timer <= 0) {
            home_x = x; // wander around wherever he gave up
            home_y = y;
            enemy_change_state(ENEMY_STATE.IDLE);
        }
    break;

    case ENEMY_STATE.HURT:
        kb_x *= kb_friction;
        kb_y *= kb_friction;

        state_timer--;
        if (state_timer <= 0) {
            kb_x = 0;
            kb_y = 0;
            enemy_change_state(ENEMY_STATE.CHASE); // getting hit makes him aggro
        }
    break;

    case ENEMY_STATE.DEAD:
        image_speed = death_anim_spd;
        exit; // Animation End event destroys him
}

// ======================= MOVEMENT + ANIMATION =======================
if (state != ENEMY_STATE.HURT) {
    kb_x = lengthdir_x(move_spd, move_dir);
    kb_y = lengthdir_y(move_spd, move_dir);
    if (move_spd > 0) facing = move_dir;
}

var _d = enemy_dir4();
if (move_spd > 0) {
    sprite_index = spr_run[_d];
    image_speed  = run_anim_spd;
} else {
    sprite_index = spr_idle[_d];
    image_speed  = idle_anim_spd;
}

x += kb_x;
y += kb_y
