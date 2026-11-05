/// scr_tests_rules_arena
/// Tests for scr_rules_arena: movement, stuck enemies, waves and spawning,
/// game states and restarts, quips, footsteps and sound limits.
/// Names read "feature / kind / what it checks" (kinds: normal, boundary,
/// invalid, adversarial). Numbers in these tests are test data, not game stats.

// ---------------------------------------------------------------------------
// Movement
// ---------------------------------------------------------------------------

test_case("movement / normal / holding right moves exactly move_speed to the right", function () {
    var _step = movement_vector(true, false, false, false, 4);
    assert_equal(_step.x, 4);
    assert_equal(_step.y, 0);
});

test_case("movement / boundary / a diagonal is no faster than a straight move", function () {
    var _step = movement_vector(true, false, true, false, 4);
    assert_near(sqrt(_step.x * _step.x + _step.y * _step.y), 4, 0.0001, "diagonal speed");
    assert_near(_step.x, _step.y, 0.0001, "45 degrees");
});

test_case("movement / boundary / all eight directions move at the same speed", function () {
    var _keys = [
        [true, false, false, false], [false, true, false, false], [false, false, true, false], [false, false, false, true],
        [true, false, true, false], [true, false, false, true], [false, true, true, false], [false, true, false, true]
    ];
    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _k = _keys[_i];
        var _step = movement_vector(_k[0], _k[1], _k[2], _k[3], 3);
        assert_near(sqrt(_step.x * _step.x + _step.y * _step.y), 3, 0.0001, "direction " + string(_i));
    }
});

test_case("movement / boundary / opposite keys cancel out", function () {
    var _lr = movement_vector(true, true, false, false, 4);
    var _ud = movement_vector(false, false, true, true, 4);
    var _all = movement_vector(true, true, true, true, 4);
    assert_equal([_lr.x, _lr.y], [0, 0], "left and right");
    assert_equal([_ud.x, _ud.y], [0, 0], "up and down");
    assert_equal([_all.x, _all.y], [0, 0], "all four keys");
});

test_case("movement / boundary / left+right+down moves straight down at full speed", function () {
    var _step = movement_vector(true, true, true, false, 4);
    assert_equal(_step.x, 0);
    assert_equal(_step.y, 4);
});

test_case("movement / invalid / zero, negative, NaN, infinite and text speeds do not move", function () {
    var _bad = [0, -4, NaN, infinity, "4", undefined];
    for (var _i = 0; _i < array_length(_bad); _i++) {
        var _step = movement_vector(true, false, true, false, _bad[_i]);
        assert_equal([_step.x, _step.y], [0, 0], "speed " + string(_bad[_i]));
    }
});

test_case("movement / boundary / a position exactly on the arena edge stays put", function () {
    var _pos = movement_clamp_to_arena(0, 600, 0, 0, 800, 600);
    assert_equal([_pos.x, _pos.y], [0, 600]);
});

test_case("movement / boundary / one pixel outside the arena is pulled back to the edge", function () {
    var _left = movement_clamp_to_arena(-1, 300, 0, 0, 800, 600);
    var _right = movement_clamp_to_arena(801, 300, 0, 0, 800, 600);
    var _corner = movement_clamp_to_arena(-1, 601, 0, 0, 800, 600);
    assert_equal(_left.x, 0);
    assert_equal(_right.x, 800);
    assert_equal([_corner.x, _corner.y], [0, 600], "both axes at once");
});

test_case("movement / adversarial / a dash aimed far past the wall stops at the wall", function () {
    var _pos = movement_clamp_to_arena(1000000, -1000000, 0, 0, 800, 600);
    assert_equal([_pos.x, _pos.y], [800, 0]);
});

test_case("movement / adversarial / 10000 frames of random keys and dashes never leave the arena", function () {
    var _x = 400;
    var _y = 300;
    for (var _i = 0; _i < 10000; _i++) {
        var _speed = (irandom(9) == 0) ? 120 : 4;
        var _step = movement_vector(irandom(1) == 0, irandom(1) == 0, irandom(1) == 0, irandom(1) == 0, _speed);
        var _pos = movement_clamp_to_arena(_x + _step.x, _y + _step.y, 0, 0, 800, 600);
        _x = _pos.x;
        _y = _pos.y;
        assert_in_range(_x, 0, 800, "x on frame " + string(_i));
        assert_in_range(_y, 0, 600, "y on frame " + string(_i));
    }
});

// ---------------------------------------------------------------------------
// Stuck enemies (limit 300 frames = 5 seconds at 60 FPS)
// ---------------------------------------------------------------------------

test_case("enemy stuck / boundary / 300 frames without moving is not yet too long", function () {
    var _enemy = { stuck_frames: 0 };
    for (var _i = 1; _i <= 300; _i++) {
        assert_false(enemy_stuck_update(_enemy, 0, 300), "frame " + string(_i));
    }
    assert_equal(_enemy.stuck_frames, 300);
});

test_case("enemy stuck / boundary / frame 301 sends the enemy back and resets the count", function () {
    var _enemy = { stuck_frames: 0 };
    for (var _i = 1; _i <= 300; _i++) {
        enemy_stuck_update(_enemy, 0, 300);
    }
    assert_true(enemy_stuck_update(_enemy, 0, 300), "frame 301");
    assert_equal(_enemy.stuck_frames, 0);
});

test_case("enemy stuck / normal / moving even once resets the count", function () {
    var _enemy = { stuck_frames: 0 };
    for (var _i = 0; _i < 299; _i++) {
        enemy_stuck_update(_enemy, 0, 300);
    }
    enemy_stuck_update(_enemy, 2, 300);
    assert_equal(_enemy.stuck_frames, 0);
    for (var _j = 0; _j < 300; _j++) {
        assert_false(enemy_stuck_update(_enemy, 0, 300), "frame " + string(_j) + " after moving");
    }
});

test_case("enemy stuck / boundary / jittering less than 0.01 pixels still counts as stuck", function () {
    var _enemy = { stuck_frames: 0 };
    enemy_stuck_update(_enemy, 0.01, 300);
    enemy_stuck_update(_enemy, 0.005, 300);
    enemy_stuck_update(_enemy, 0.02, 300);
    assert_equal(_enemy.stuck_frames, 0, "0.02 is real movement and resets the count");
    enemy_stuck_update(_enemy, 0.01, 300);
    assert_equal(_enemy.stuck_frames, 1, "0.01 is not movement");
});

test_case("enemy stuck / invalid / NaN or missing distance counts as stuck, not as moving", function () {
    var _enemy = { stuck_frames: 0 };
    enemy_stuck_update(_enemy, NaN, 300);
    enemy_stuck_update(_enemy, undefined, 300);
    enemy_stuck_update(_enemy, "far", 300);
    assert_equal(_enemy.stuck_frames, 3);
});

// ---------------------------------------------------------------------------
// Waves and spawning
// ---------------------------------------------------------------------------

test_case("waves / normal / total enemies is the sum of the spawn counts", function () {
    var _wave = { spawns: [{ type: "slime", count: 3 }, { type: "bat", count: 2 }] };
    assert_equal(wave_total_enemies(_wave), 5);
});

test_case("waves / boundary / an empty wave has 0 enemies and clears immediately", function () {
    var _wave = { spawns: [] };
    assert_equal(wave_total_enemies(_wave), 0);
    assert_equal(wave_resolve_frame(false, 0, wave_total_enemies(_wave)), "wave_cleared");
});

test_case("waves / boundary / a wave whose spawns all have count 0 clears immediately", function () {
    var _wave = { spawns: [{ type: "slime", count: 0 }, { type: "bat", count: 0 }] };
    assert_equal(wave_resolve_frame(false, 0, wave_total_enemies(_wave)), "wave_cleared");
});

test_case("waves / boundary / player and last enemy dying on the same frame is a game over", function () {
    assert_equal(wave_resolve_frame(true, 0, 0), "game_over");
});

test_case("waves / boundary / one enemy alive, or one still to spawn, keeps the wave going", function () {
    assert_equal(wave_resolve_frame(false, 1, 0), "in_progress", "1 alive");
    assert_equal(wave_resolve_frame(false, 0, 1), "in_progress", "1 left to spawn");
    assert_equal(wave_resolve_frame(true, 5, 5), "game_over", "player death wins mid-wave");
});

test_case("spawning / boundary / exactly the minimum distance is safe, one pixel closer is not", function () {
    assert_true(spawn_point_is_safe(100, 0, 0, 0, 100), "100 px away");
    assert_false(spawn_point_is_safe(99, 0, 0, 0, 100), "99 px away");
    assert_false(spawn_point_is_safe(0, 0, 0, 0, 100), "on top of the player");
});

test_case("spawning / adversarial / 1000 picks never choose a point near the player", function () {
    var _points = [{ x: 0, y: 0 }, { x: 50, y: 0 }, { x: 300, y: 0 }, { x: 0, y: 300 }];
    var _seen_far = 0;
    for (var _i = 0; _i < 1000; _i++) {
        var _p = spawn_pick_point(_points, 0, 0, 100);
        assert_true(spawn_point_is_safe(_p.x, _p.y, 0, 0, 100), "pick " + string(_i));
        if (_p.x == 300) {
            _seen_far += 1;
        }
    }
    assert_true(_seen_far > 0 && _seen_far < 1000, "both safe points should be used");
});

test_case("spawning / boundary / when no point is safe it returns undefined instead of spawning on the player", function () {
    var _points = [{ x: 10, y: 0 }, { x: 0, y: 10 }];
    assert_equal(spawn_pick_point(_points, 0, 0, 100), undefined);
});

test_case("spawning / invalid / an empty spawn-point list returns undefined", function () {
    assert_equal(spawn_pick_point([], 0, 0, 100), undefined);
});

// ---------------------------------------------------------------------------
// Game states and restarts
// ---------------------------------------------------------------------------

test_case("game state / boundary / pressing Play twice loads the arena only once", function () {
    var _state = game_state_next("title", "play");
    assert_equal(_state, "loading");
    assert_equal(game_state_next(_state, "play"), "loading", "second Play is ignored");
});

test_case("game state / normal / a full run: title, play, pause, die, game over, restart", function () {
    var _events = ["play", "loaded", "pause", "unpause", "player_died", "fade_done", "restart", "loaded"];
    var _expected = ["loading", "playing", "paused", "playing", "dying", "game_over", "loading", "playing"];
    var _state = "title";
    for (var _i = 0; _i < array_length(_events); _i++) {
        _state = game_state_next(_state, _events[_i]);
        assert_equal(_state, _expected[_i], "after " + _events[_i]);
    }
});

test_case("game state / boundary / pause and every other input during the death fade are ignored", function () {
    var _events = ["pause", "unpause", "play", "player_died", "restart", "quit_to_title", "loaded"];
    for (var _i = 0; _i < array_length(_events); _i++) {
        assert_equal(game_state_next("dying", _events[_i]), "dying", _events[_i]);
    }
});

test_case("game state / boundary / the player cannot die while the game is paused", function () {
    assert_equal(game_state_next("paused", "player_died"), "paused");
});

test_case("game state / invalid / unknown events and states are ignored without a crash", function () {
    assert_equal(game_state_next("playing", "PAUSE"), "playing", "events are case-sensitive");
    assert_equal(game_state_next("playing", ""), "playing");
    assert_equal(game_state_next("playing", undefined), "playing");
    assert_equal(game_state_next("playing", 5), "playing");
    assert_equal(game_state_next("credits", "play"), "credits", "unknown state");
});

test_case("game state / adversarial / 10000 random events: always a known state, game over only after the fade", function () {
    var _states = ["title", "loading", "playing", "paused", "dying", "game_over"];
    var _events = ["play", "loaded", "pause", "unpause", "player_died", "fade_done", "restart", "quit_to_title", "jump"];
    var _state = "title";
    for (var _i = 0; _i < 10000; _i++) {
        var _event = _events[irandom(array_length(_events) - 1)];
        var _next = game_state_next(_state, _event);
        var _known = false;
        for (var _s = 0; _s < array_length(_states); _s++) {
            if (_states[_s] == _next) {
                _known = true;
            }
        }
        assert_true(_known, "unknown state " + string(_next));
        if (_next == "game_over" && _state != "game_over") {
            assert_equal(_state, "dying", "game over entered from " + _state);
        }
        if (_next == "dying" && _state != "dying") {
            assert_equal(_state, "playing", "death entered from " + _state);
        }
        _state = _next;
    }
});

test_case("restart / boundary / restart gives a fresh run and leaves nothing from the old one", function () {
    var _old = run_create(20);
    _old.wave_number = 7;
    health_apply_damage(_old.player, 20);
    var _new = run_create(20);
    assert_equal(_new.wave_number, 1);
    assert_equal(_new.player.hp, 20);
    assert_false(_new.player.is_dead);
    assert_true(_new.player != _old.player, "the new run must not share the old player");
});

test_case("restart / adversarial / 10 restarts in a row each start clean", function () {
    var _run = run_create(20);
    for (var _i = 0; _i < 10; _i++) {
        _run.wave_number += irandom_range(1, 5);
        health_apply_damage(_run.player, irandom_range(1, 40));
        _run = run_create(20);
        assert_equal([_run.wave_number, _run.player.hp, _run.player.is_dead], [1, 20, false], "restart " + string(_i + 1));
    }
});

// ---------------------------------------------------------------------------
// Quips, footsteps and sound limits
// ---------------------------------------------------------------------------

test_case("quips / boundary / the same quip never plays twice in a row over 5000 picks", function () {
    var _last = -1;
    for (var _i = 0; _i < 5000; _i++) {
        var _pick = quip_pick(5, _last);
        assert_in_range(_pick, 0, 4, "pick " + string(_i));
        assert_not_equal(_pick, _last, "pick " + string(_i) + " repeated");
        _last = _pick;
    }
});

test_case("quips / boundary / with exactly two quips they alternate", function () {
    var _last = 0;
    for (var _i = 0; _i < 20; _i++) {
        var _pick = quip_pick(2, _last);
        assert_equal(_pick, 1 - _last);
        _last = _pick;
    }
});

test_case("quips / boundary / one quip always gives 0, none or a bad count gives -1", function () {
    assert_equal(quip_pick(1, 0), 0, "one quip may repeat because it is the only one");
    assert_equal(quip_pick(0, -1), -1);
    assert_equal(quip_pick(-3, -1), -1);
    assert_equal(quip_pick(NaN, -1), -1);
    assert_equal(quip_pick("5", -1), -1);
});

test_case("quips / adversarial / every quip still gets picked, even after a bad last index", function () {
    var _bad_last = [-1, 99, 2.5, undefined];
    for (var _b = 0; _b < array_length(_bad_last); _b++) {
        var _counts = [0, 0, 0, 0, 0];
        for (var _i = 0; _i < 2000; _i++) {
            var _pick = quip_pick(5, _bad_last[_b]);
            assert_in_range(_pick, 0, 4);
            _counts[_pick] += 1;
        }
        for (var _q = 0; _q < 5; _q++) {
            assert_true(_counts[_q] > 0, "quip " + string(_q) + " never picked with last index " + string(_bad_last[_b]));
        }
    }
});

test_case("footsteps / boundary / holding a key for 600 frames at a 15-frame interval plays exactly 40 steps, evenly", function () {
    var _steps = { frames_until_step: 0 };
    var _played = 0;
    var _last = -15;
    for (var _frame = 0; _frame < 600; _frame++) {
        if (footstep_tick(_steps, true, 15)) {
            assert_equal(_frame - _last, 15, "gap before the step on frame " + string(_frame));
            _last = _frame;
            _played += 1;
        }
    }
    assert_equal(_played, 40);
});

test_case("footsteps / adversarial / tapping a key on random frames never plays faster than the interval", function () {
    var _steps = { frames_until_step: 0 };
    var _last = -1000;
    for (var _frame = 0; _frame < 3000; _frame++) {
        if (footstep_tick(_steps, irandom(1) == 0, 15)) {
            assert_true(_frame - _last >= 15, "steps on frames " + string(_last) + " and " + string(_frame));
            _last = _frame;
        }
    }
});

test_case("footsteps / normal / standing still plays no footsteps", function () {
    var _steps = { frames_until_step: 0 };
    for (var _frame = 0; _frame < 300; _frame++) {
        assert_false(footstep_tick(_steps, false, 15));
    }
});

test_case("sfx / boundary / a sound may start at cap-1 copies, is refused at the cap, and a cap of 0 plays nothing", function () {
    assert_true(sfx_can_play(3, 4), "3 playing, cap 4");
    assert_false(sfx_can_play(4, 4), "4 playing, cap 4");
    assert_false(sfx_can_play(0, 0), "cap 0");
});
