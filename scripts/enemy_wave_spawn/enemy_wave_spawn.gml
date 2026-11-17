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

    //enemies only appear where the player could walk to (see enemy_wave_spot_ok)
    //if no spot has been found for a while, that rule is dropped so the wave can't get stuck
    if (!variable_instance_exists(id, "wave_spawn_fails")) wave_spawn_fails = 0;
    var _use_reach = (wave_spawn_fails < 60);

    //is there a spawn zone in this room? then enemies appear inside it and nowhere else
    var _zone_mode = instance_exists(enemy_spawn_zone_obj);

    //try up to          x   random locations
    for (var i = 0; i < 30; i++){
        var _try_x;
        var _try_y;

        if (_zone_mode){
            //pick one of the zones, then a random spot inside it (kept 16px from its edge
            //so the whole enemy is inside; a zone smaller than that uses its middle)
            var _z = instance_find(enemy_spawn_zone_obj, irandom(instance_number(enemy_spawn_zone_obj) - 1));

            var _l = _z.bbox_left + 16;
            var _r = _z.bbox_right - 16;
            var _t = _z.bbox_top + 16;
            var _b = _z.bbox_bottom - 16;

            if (_r < _l){ _l = (_z.bbox_left + _z.bbox_right) / 2; _r = _l; }
            if (_b < _t){ _t = (_z.bbox_top + _z.bbox_bottom) / 2; _b = _t; }

            _try_x = random_range(_l, _r);
            _try_y = random_range(_t, _b);
        } else {
            _try_x = irandom_range(64, room_width - 64);
            _try_y = irandom_range(64, room_height - 64);
        }

        //blocked = on a wall object, or (no zone) somewhere the player can never get to
        var _blocked = !enemy_wave_spot_ok(_try_x, _try_y, _use_reach && !_zone_mode);

        //used to check enemy position to mc position (default to F)
        var _too_close = false;

        //check player distance (not in a zone: the zone is small, so it can't keep its distance)
        if (_player != noone && !_zone_mode){
            _too_close =
                point_distance(
                    _try_x,
                    _try_y,
                    _player.x,
                    _player.y
                ) < wave_spawn_min_dist;
        }

        //in a zone, don't stack enemies on top of each other
        //(dropped after a while if the zone is too crowded, so the wave can't get stuck)
        var _crowded = false;
        if (_zone_mode && _use_reach){
            _crowded = collision_circle(_try_x, _try_y, 20, Enemy_base_obj, false, true) != noone;
        }

        //spawing if everything checks out
        if (!_blocked && !_too_close && !_crowded){
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
        wave_spawn_fails++;
        return;
    }

    wave_spawn_fails = 0;

    //create the enemy in the room's instance layer
    //use the wave layer if the room has it, otherwise the wave object's own layer
    var _layer = layer_exists(wave_layer) ? wave_layer : layer;

    var _new_enemy = instance_create_layer(
        _spawn_x,
        _spawn_y,
        _layer,
        _enemy_obj
    );

    array_push(wave_enemy_ids, _new_enemy);

    spawned_this_wave++;
}


// ============================================================
// IS THIS SPOT OK FOR AN ENEMY TO APPEAR?
// ============================================================
// the walls in these rooms are invisible wall_obj blocks around the playable area.
// the tile layers can't be trusted for this (some rooms paint the inside with "wall" tiles).
// so: the first time a spawn is needed in a room, a map is made of every spot the PLAYER
// could walk to (flood fill from the player, stopping at wall_obj). a spot is ok when a
// 32x32 box around it is entirely inside that map. anything outside the wall blocks, or
// sealed off behind them, is never used.
// ============================================================

function enemy_wave_reach_ready()
{
    var _cs = 16;   // size of one map cell in pixels

    if (!variable_global_exists("wave_reach_grid"))
    {
        global.wave_reach_grid = -1;
        global.wave_reach_room = -1;
    }

    // already made for this room
    if (global.wave_reach_room == room && global.wave_reach_grid != -1 && ds_exists(global.wave_reach_grid, ds_type_grid))
    {
        return true;
    }

    // old map from another room: throw it away
    if (global.wave_reach_grid != -1 && ds_exists(global.wave_reach_grid, ds_type_grid))
    {
        ds_grid_destroy(global.wave_reach_grid);
    }
    global.wave_reach_grid = -1;
    global.wave_reach_room = -1;

    // the flood starts at the player, so one must exist
    var _p = instance_find(main_character_Obj, 0);
    if (_p == noone) return false;

    var _w = ceil(room_width / _cs);
    var _h = ceil(room_height / _cs);

    // 0 = not checked, 1 = wall, 2 = the player can get here
    var _g = ds_grid_create(_w, _h);
    ds_grid_clear(_g, 0);

    for (var cx = 0; cx < _w; cx++)
    {
        for (var cy = 0; cy < _h; cy++)
        {
            if (collision_rectangle(cx * _cs, cy * _cs, cx * _cs + _cs - 1, cy * _cs + _cs - 1, wall_obj, false, true) != noone)
            {
                ds_grid_set(_g, cx, cy, 1);
            }
        }
    }

    // start cell = the player's cell (or the closest open one if the player touches a wall)
    var _sx = clamp(floor(_p.x / _cs), 0, _w - 1);
    var _sy = clamp(floor(_p.y / _cs), 0, _h - 1);
    var _found = (ds_grid_get(_g, _sx, _sy) == 0);

    for (var r = 1; r <= 4 && !_found; r++)
    {
        for (var ox = -r; ox <= r && !_found; ox++)
        {
            for (var oy = -r; oy <= r && !_found; oy++)
            {
                var _nx = _sx + ox;
                var _ny = _sy + oy;

                if (_nx >= 0 && _ny >= 0 && _nx < _w && _ny < _h && ds_grid_get(_g, _nx, _ny) == 0)
                {
                    _sx = _nx;
                    _sy = _ny;
                    _found = true;
                }
            }
        }
    }

    // the player is somewhere odd: give up on this rule (walls are still checked)
    if (!_found)
    {
        ds_grid_destroy(_g);
        return false;
    }

    // flood fill (4 directions)
    var _stack = [[_sx, _sy]];
    ds_grid_set(_g, _sx, _sy, 2);

    var _dx = [1, -1, 0, 0];
    var _dy = [0, 0, 1, -1];

    while (array_length(_stack) > 0)
    {
        var _c = array_pop(_stack);

        for (var d = 0; d < 4; d++)
        {
            var _ax = _c[0] + _dx[d];
            var _ay = _c[1] + _dy[d];

            if (_ax >= 0 && _ay >= 0 && _ax < _w && _ay < _h && ds_grid_get(_g, _ax, _ay) == 0)
            {
                ds_grid_set(_g, _ax, _ay, 2);
                array_push(_stack, [_ax, _ay]);
            }
        }
    }

    global.wave_reach_grid = _g;
    global.wave_reach_room = room;
    return true;
}


// _use_reach = false skips the "player can walk here" rule (only the wall check is used)
function enemy_wave_spot_ok(_x, _y, _use_reach)
{
    // touching a wall object
    if (collision_rectangle(_x - 16, _y - 16, _x + 16, _y + 16, wall_obj, false, true) != noone)
    {
        return false;
    }

    if (_use_reach && enemy_wave_reach_ready())
    {
        var _g = global.wave_reach_grid;

        // the 4 corners and the center of the box must all be places the player can walk to
        var _px = [_x - 16, _x + 16, _x - 16, _x + 16, _x];
        var _py = [_y - 16, _y - 16, _y + 16, _y + 16, _y];

        for (var p = 0; p < 5; p++)
        {
            var _cx = floor(_px[p] / 16);
            var _cy = floor(_py[p] / 16);

            if (_cx < 0 || _cy < 0 || _cx >= ds_grid_width(_g) || _cy >= ds_grid_height(_g)) return false;

            if (ds_grid_get(_g, _cx, _cy) != 2) return false;
        }
    }

    return true;
}
