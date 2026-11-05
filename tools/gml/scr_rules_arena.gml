/// scr_rules_arena
/// Arena rules as plain functions: movement, stuck enemies, waves and spawning,
/// the game's state machine, restarts, quips, footsteps and sound limits.
/// Values such as move speed and the stuck limit are passed in from the JSON
/// data; nothing here hardcodes a stat.

#macro RULES_STUCK_EPSILON 0.01

// ---------------------------------------------------------------------------
// Movement
// ---------------------------------------------------------------------------

/// @function movement_vector(right, left, down, up, move_speed)
/// Turns key states into one frame of movement, returned as { x, y }.
/// Diagonals are scaled so they are no faster than straight moves, opposite
/// keys cancel out, and an invalid speed means no movement.
function movement_vector(_right, _left, _down, _up, _move_speed) {
    var _dx = (_right ? 1 : 0) - (_left ? 1 : 0);
    var _dy = (_down ? 1 : 0) - (_up ? 1 : 0);
    if ((_dx == 0 && _dy == 0) || !rules_is_amount(_move_speed)) {
        return { x: 0, y: 0 };
    }
    var _length = sqrt(_dx * _dx + _dy * _dy);
    return { x: _dx / _length * _move_speed, y: _dy / _length * _move_speed };
}

/// @function movement_clamp_to_arena(px, py, left, top, right, bottom)
/// Keeps a position inside the arena rectangle, edges included. Returns { x, y }.
/// Applied after every move and dash, so nothing can leave the arena.
function movement_clamp_to_arena(_px, _py, _left, _top, _right, _bottom) {
    return { x: clamp(_px, _left, _right), y: clamp(_py, _top, _bottom) };
}

// ---------------------------------------------------------------------------
// Enemies
// ---------------------------------------------------------------------------

/// @function enemy_stuck_update(enemy, moved_distance, limit_frames)
/// Call once per frame with how far the enemy moved. Counts frames in a row
/// without movement (enemy.stuck_frames must start at 0). Returns true on the
/// frame the count goes past limit_frames, meaning "send it back to a spawn
/// point", and resets the count. Any real movement resets the count.
function enemy_stuck_update(_enemy, _moved_distance, _limit_frames) {
    if (is_numeric(_moved_distance) && _moved_distance > RULES_STUCK_EPSILON) {
        _enemy.stuck_frames = 0;
        return false;
    }
    _enemy.stuck_frames += 1;
    if (_enemy.stuck_frames > _limit_frames) {
        _enemy.stuck_frames = 0;
        return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
// Waves and spawning
// ---------------------------------------------------------------------------

/// @function wave_total_enemies(wave)
/// How many enemies a wave spawns: the sum of its spawn counts (0 when empty).
function wave_total_enemies(_wave) {
    var _total = 0;
    for (var _i = 0; _i < array_length(_wave.spawns); _i++) {
        _total += _wave.spawns[_i].count;
    }
    return _total;
}

/// @function wave_resolve_frame(player_dead, enemies_alive, enemies_left_to_spawn)
/// What happens at the end of a frame:
///   "game_over"     the player is dead, even if the last enemy died that frame
///   "wave_cleared"  every enemy has spawned and none are alive
///   "in_progress"   otherwise
/// An empty wave clears at once instead of leaving the player stuck.
function wave_resolve_frame(_player_dead, _enemies_alive, _enemies_left_to_spawn) {
    if (_player_dead) {
        return "game_over";
    }
    if (_enemies_alive <= 0 && _enemies_left_to_spawn <= 0) {
        return "wave_cleared";
    }
    return "in_progress";
}

/// @function spawn_point_is_safe(sx, sy, px, py, min_distance)
/// True if the spawn point is at least min_distance from the player.
function spawn_point_is_safe(_sx, _sy, _px, _py, _min_distance) {
    return point_distance(_sx, _sy, _px, _py) >= _min_distance;
}

/// @function spawn_pick_point(points, px, py, min_distance)
/// Picks a random safe point from an array of { x, y } structs. Returns
/// undefined if none is safe, so the caller waits instead of spawning an enemy
/// on top of the player.
function spawn_pick_point(_points, _px, _py, _min_distance) {
    var _safe = [];
    for (var _i = 0; _i < array_length(_points); _i++) {
        var _point = _points[_i];
        if (spawn_point_is_safe(_point.x, _point.y, _px, _py, _min_distance)) {
            array_push(_safe, _point);
        }
    }
    if (array_length(_safe) == 0) {
        return undefined;
    }
    return _safe[irandom(array_length(_safe) - 1)];
}

// ---------------------------------------------------------------------------
// Game states and restarting
// ---------------------------------------------------------------------------

/// @function game_state_next(state, event)
/// The game's state machine.
///   States: "title", "loading", "playing", "paused", "dying", "game_over"
///   Events: "play", "loaded", "pause", "unpause", "player_died",
///           "fade_done", "restart", "quit_to_title"
/// An event that does not apply to the current state is ignored. That is what
/// stops a double-pressed Play from loading the arena twice, and stops pausing
/// or other input during the death fade.
function game_state_next(_state, _event) {
    if (!is_string(_state) || !is_string(_event)) {
        return _state;
    }
    switch (_state) {
        case "title":
            if (_event == "play") return "loading";
            break;
        case "loading":
            if (_event == "loaded") return "playing";
            break;
        case "playing":
            if (_event == "pause") return "paused";
            if (_event == "player_died") return "dying";
            break;
        case "paused":
            if (_event == "unpause") return "playing";
            if (_event == "quit_to_title") return "title";
            break;
        case "dying":
            if (_event == "fade_done") return "game_over";
            break;
        case "game_over":
            if (_event == "restart") return "loading";
            if (_event == "quit_to_title") return "title";
            break;
    }
    return _state;
}

/// @function run_create(player_max_hp)
/// A brand-new run: wave 1, full health, loading. Restart replaces the old run
/// with this, so nothing from the previous run carries over.
function run_create(_player_max_hp) {
    return { wave_number: 1, state: "loading", player: health_create(_player_max_hp) };
}

// ---------------------------------------------------------------------------
// Audio
// ---------------------------------------------------------------------------

/// @function quip_pick(quip_count, last_index)
/// A random quip index that is never last_index, so the same line never plays
/// twice in a row. Returns 0 with one quip and -1 with none.
function quip_pick(_quip_count, _last_index) {
    if (!is_numeric(_quip_count) || is_nan(_quip_count) || _quip_count < 1) {
        return -1;
    }
    var _count = floor(_quip_count);
    if (_count == 1) {
        return 0;
    }
    // A last index that is not a whole number in range cannot be repeated, so
    // any quip may play. (Skipping this check made one quip unreachable.)
    if (!is_numeric(_last_index) || is_nan(_last_index) || _last_index != floor(_last_index)
        || _last_index < 0 || _last_index >= _count) {
        return irandom(_count - 1);
    }
    var _pick = irandom(_count - 2);
    if (_pick >= _last_index) {
        _pick += 1;
    }
    return _pick;
}

/// @function footstep_tick(steps, is_moving, interval_frames)
/// Call once per frame. Returns true on frames where a footstep should play:
/// the first frame of movement, then every interval_frames while moving.
/// The countdown keeps running when the player stops, so tapping a key cannot
/// play footsteps faster than holding it. steps.frames_until_step starts at 0.
function footstep_tick(_steps, _is_moving, _interval_frames) {
    var _play = false;
    if (_is_moving && _steps.frames_until_step <= 0) {
        _play = true;
        _steps.frames_until_step = max(1, rules_frames(_interval_frames));
    }
    _steps.frames_until_step = max(0, _steps.frames_until_step - 1);
    return _play;
}

/// @function sfx_can_play(playing_count, max_overlapping)
/// True if one more copy of a sound may start, so overlapping copies are capped.
function sfx_can_play(_playing_count, _max_overlapping) {
    return _playing_count < _max_overlapping;
}
