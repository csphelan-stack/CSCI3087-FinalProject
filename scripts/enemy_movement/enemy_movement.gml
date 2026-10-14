// tells the enemy where it should move for current frame
function enemy_walk_to(_tx, _ty, _spd){
    // Check whether the enemy is already close enough to the destination.
    if (point_distance(x, y, _tx, _ty) <= _spd){
        return true;
    }

    // Calculate the direction toward the destination.
    move_dir = point_direction(x, y, _tx, _ty);

    // Set the movement speed for this frame.
    move_spd = _spd;

    // The destination has not been reached yet.
    return false;
}

function enemy_update_velocity(){
    // Normal movement is disabled during the hurt state.
    if (state != ENEMY_STATE.HURT){
        // Calculate horizontal movement.
        kb_x = lengthdir_x(move_spd, move_dir);

        // Calculate vertical movement.
        kb_y = lengthdir_y(move_spd, move_dir);

        // If the enemy is actually moving...
        if (move_spd > 0){
            // Face the direction in which the enemy is moving.
            facing = move_dir;
        }
    }
}

function enemy_apply_movement(){
    // calculate next X position.=
    var _next_x = x + kb_x;

    // check for wall
    if (!place_meeting(_next_x, y, obj_wall)){
        // move horizontally
        x = _next_x;
    }


    // calculate next Y position
    var _next_y = y + kb_y;

    // check for wall
    if (!place_meeting(x, _next_y, obj_wall)){
        // move vertically
        y = _next_y;
    }
}
