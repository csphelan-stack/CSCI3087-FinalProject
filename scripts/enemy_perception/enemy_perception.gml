// return true when the enemy can see the player
function enemy_can_see_player(_range, _use_cone){
    // find instance of player
    var _p = instance_nearest(x, y, main_character_Obj);

    if (_p == noone){
        return false;
    }

    // check if player is outside detection range
    if (point_distance(x, y, _p.x, _p.y) > _range){
        return false;
    }

    // vision cone check when requrested
    if (_use_cone){
        // calculate direction to player 
        var _pdir = point_direction(x, y, _p.x, _p.y);

        // calculate how far the player's direction is from
        // the direction the enemy is facing
        var _angle_difference = abs(angle_difference(facing, _pdir));

        // if the player is outside the vision cone, reject them
        if (_angle_difference > view_angle * 0.5){
            return false;
        }
    }

    // check if blocks the enemy's vision
    if (collision_line(x, y, _p.x, _p.y, obj_wall, false, true) != noone){
        return false;
    }

    // store the player as current target
    target = _p;

    return true;
}
