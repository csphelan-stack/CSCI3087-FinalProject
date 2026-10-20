//spawn the next enemy in the active wave
function enemy_wave_spawn_next(){
    //stop if queue has no enemies remaining
    if (spawned_this_wave >= array_length(wave_queue)){
        return;
    }

    //get next enemy object
    var _enemy_obj = wave_queue[spawned_this_wave];

    //start with default spawn coordinates.
    var _spawn_x = 64;
    var _spawn_y = 64;

    //track whether a safe spawn location was found as in no walls, outside of bounds, etc.
    var _found_position = false;

    //find the player so enemies do not spawn on him or her[=p
    var _player = instance_find(main_character_Obj, 0);

    //try up to          x   random locations
    for (var i = 0; i < 30; i++){
        var _try_x = irandom_range(64, room_width - 64);

        var _try_y = irandom_range(64, room_height - 64);

        var _blocked = collision_rectangle(
            _try_x - 16,
            _try_y - 16,
            _try_x + 16,
            _try_y + 16,
            obj_wall,false,true
        ) != noone;

        //used to check enemy position to mc position (default to F)
        var _too_close = false;

        //check player distance
        if (_player != noone){
            _too_close =
                point_distance(
                    _try_x,
                    _try_y,
                    _player.x,
                    _player.y
                ) < 250;
        }

        //spawing if everything checks out
        if (!_blocked && !_too_close){
            //save the accepted X
            _spawn_x = _try_x;

            //save the accepted Y
            _spawn_y = _try_y;

            //record that spot
            _found_position = true;

            //stop searching
            break;
        }
    }

    if (!_found_position){
        return;
    }

    //create the enemy in the room's instance layer
    var _new_enemy = instance_create_layer(
        _spawn_x,
        _spawn_y,
        "Instances",
        _enemy_obj
    );

    array_push(wave_enemy_ids, _new_enemy);
    
    spawned_this_wave++;
}