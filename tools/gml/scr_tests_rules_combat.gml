/// scr_tests_rules_combat
/// Tests for scr_rules_combat: health, cooldowns, melee attack and dash.
/// Names read "feature / kind / what it checks", where kind is:
///   normal       the expected everyday case
///   boundary     the exact edge: N-1, N and N+1
///   invalid      bad input from data or code must be ignored without a crash
///   adversarial  thousands of random actions; a rule must hold after every one
/// Numbers in these tests are test data, not game stats.

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

test_case("health / normal / damage lowers hp by the amount", function () {
    var _unit = health_create(10);
    assert_false(health_apply_damage(_unit, 3), "3 damage does not kill");
    assert_equal(_unit.hp, 7);
});

test_case("health / boundary / damage of hp-1 leaves exactly 1 hp and the unit alive", function () {
    var _unit = health_create(10);
    assert_false(health_apply_damage(_unit, 9));
    assert_equal(_unit.hp, 1);
    assert_false(_unit.is_dead);
});

test_case("health / boundary / damage equal to hp leaves 0 hp and kills", function () {
    var _unit = health_create(10);
    assert_true(health_apply_damage(_unit, 10), "the killing hit returns true");
    assert_equal(_unit.hp, 0);
    assert_true(_unit.is_dead);
});

test_case("health / boundary / damage of hp+1 leaves 0 hp, never -1", function () {
    var _unit = health_create(10);
    assert_true(health_apply_damage(_unit, 11));
    assert_equal(_unit.hp, 0);
});

test_case("health / boundary / overkill of 1000000 leaves 0 hp", function () {
    var _unit = health_create(10);
    health_apply_damage(_unit, 1000000);
    assert_equal(_unit.hp, 0);
});

test_case("health / boundary / decimal damage of 0.5 is applied, not rounded away", function () {
    var _unit = health_create(10);
    health_apply_damage(_unit, 0.5);
    assert_near(_unit.hp, 9.5, 0.0001);
});

test_case("health / invalid / zero, negative, NaN, infinite, missing, text and true damage change nothing", function () {
    var _bad = [0, -0.5, -1, -1000, NaN, infinity, -infinity, undefined, "5", true];
    for (var _i = 0; _i < array_length(_bad); _i++) {
        var _unit = health_create(10);
        assert_false(health_apply_damage(_unit, _bad[_i]), "damage " + string(_bad[_i]) + " must not kill");
        assert_equal(_unit.hp, 10, "damage " + string(_bad[_i]) + " must be ignored");
    }
});

test_case("health / boundary / two lethal hits on the same frame cause exactly one death", function () {
    var _unit = health_create(10);
    assert_true(health_apply_damage(_unit, 10), "first hit kills");
    assert_false(health_apply_damage(_unit, 10), "second hit must not kill again");
    assert_equal(_unit.hp, 0);
});

test_case("health / boundary / a dead unit takes no more damage", function () {
    var _unit = health_create(10);
    health_apply_damage(_unit, 10);
    health_apply_damage(_unit, 5);
    assert_equal(_unit.hp, 0);
    assert_true(_unit.is_dead);
});

test_case("health / boundary / heal that reaches exactly max hp", function () {
    var _unit = health_create(10);
    health_apply_damage(_unit, 4);
    assert_equal(health_apply_heal(_unit, 4), 4, "restores 4");
    assert_equal(_unit.hp, 10);
});

test_case("health / boundary / heal past max hp stops at max", function () {
    var _unit = health_create(10);
    health_apply_damage(_unit, 4);
    assert_equal(health_apply_heal(_unit, 5), 4, "only 4 of the 5 is restored");
    assert_equal(_unit.hp, 10);
});

test_case("health / boundary / heal at full health restores 0", function () {
    var _unit = health_create(10);
    assert_equal(health_apply_heal(_unit, 3), 0);
    assert_equal(_unit.hp, 10);
});

test_case("health / invalid / zero, negative, NaN, infinite and text heals change nothing", function () {
    var _bad = [0, -0.5, -5, NaN, infinity, "3", undefined];
    for (var _i = 0; _i < array_length(_bad); _i++) {
        var _unit = health_create(10);
        health_apply_damage(_unit, 6);
        assert_equal(health_apply_heal(_unit, _bad[_i]), 0, "heal " + string(_bad[_i]));
        assert_equal(_unit.hp, 4, "heal " + string(_bad[_i]) + " must be ignored");
    }
});

test_case("health / boundary / a dead unit cannot be healed back to life", function () {
    var _unit = health_create(10);
    health_apply_damage(_unit, 10);
    assert_equal(health_apply_heal(_unit, 10), 0);
    assert_equal(_unit.hp, 0);
    assert_true(_unit.is_dead);
});

test_case("health / normal / a potion is used only when it restores health", function () {
    var _unit = health_create(10);
    assert_false(health_try_potion(_unit, 5), "not used at full health");
    health_apply_damage(_unit, 1);
    assert_true(health_try_potion(_unit, 5), "used when 1 hp is missing");
    assert_equal(_unit.hp, 10);
});

test_case("health / boundary / health bar is 1 at full, 0.5 at half and 0 when dead", function () {
    var _unit = health_create(10);
    assert_equal(health_fraction(_unit), 1);
    health_apply_damage(_unit, 5);
    assert_near(health_fraction(_unit), 0.5, 0.0001);
    health_apply_damage(_unit, 5);
    assert_equal(health_fraction(_unit), 0);
});

test_case("health / invalid / health bar is 0 when max hp is 0 or negative, not a divide-by-zero", function () {
    assert_equal(health_fraction({ hp: 0, max_hp: 0, is_dead: false }), 0);
    assert_equal(health_fraction({ hp: 5, max_hp: -5, is_dead: false }), 0);
    assert_finite(health_fraction({ hp: 5, max_hp: 0, is_dead: false }));
});

test_case("health / invalid / bad max hp from data falls back to 1, decimals round down", function () {
    var _bad = [0, -10, NaN, infinity, "100", undefined, true, 0.5];
    for (var _i = 0; _i < array_length(_bad); _i++) {
        var _unit = health_create(_bad[_i]);
        assert_equal(_unit.max_hp, 1, "max hp " + string(_bad[_i]));
        assert_equal(_unit.hp, 1);
        assert_false(_unit.is_dead);
    }
    assert_equal(health_create(7.9).max_hp, 7);
});

test_case("health / adversarial / 5000 random hits and heals keep hp between 0 and max", function () {
    var _unit = health_create(50);
    var _deaths = 0;
    for (var _i = 0; _i < 5000; _i++) {
        var _amount = irandom_range(-20, 60);
        if (irandom(9) == 0) {
            _amount = 1000000;
        }
        if (irandom(1) == 0) {
            if (health_apply_damage(_unit, _amount)) {
                _deaths += 1;
            }
        } else {
            health_apply_heal(_unit, _amount);
        }
        assert_in_range(_unit.hp, 0, _unit.max_hp, "hp after step " + string(_i));
        if (_unit.is_dead) {
            assert_equal(_unit.hp, 0, "a dead unit has 0 hp");
        }
    }
    assert_true(_deaths <= 1, "a unit can only die once, died " + string(_deaths) + " times");
});

// ---------------------------------------------------------------------------
// Cooldowns
// ---------------------------------------------------------------------------

test_case("cooldown / normal / starts ready, and is not ready right after use", function () {
    var _cooldown = cooldown_create(30);
    assert_true(cooldown_ready(_cooldown));
    assert_true(cooldown_try_use(_cooldown));
    assert_false(cooldown_ready(_cooldown));
});

test_case("cooldown / boundary / not ready after 29 of 30 frames, ready after exactly 30", function () {
    var _cooldown = cooldown_create(30);
    cooldown_try_use(_cooldown);
    for (var _i = 0; _i < 29; _i++) {
        cooldown_tick(_cooldown);
    }
    assert_false(cooldown_ready(_cooldown), "frame 29");
    cooldown_tick(_cooldown);
    assert_true(cooldown_ready(_cooldown), "frame 30");
});

test_case("cooldown / boundary / pressing every frame while cooling does not restart or extend it", function () {
    var _cooldown = cooldown_create(30);
    cooldown_try_use(_cooldown);
    for (var _i = 1; _i < 30; _i++) {
        cooldown_tick(_cooldown);
        assert_false(cooldown_try_use(_cooldown), "press on frame " + string(_i));
    }
    cooldown_tick(_cooldown);
    assert_true(cooldown_try_use(_cooldown), "press on frame 30 works");
});

test_case("cooldown / boundary / a 0-frame cooldown can be used every frame", function () {
    var _cooldown = cooldown_create(0);
    for (var _i = 0; _i < 5; _i++) {
        assert_true(cooldown_try_use(_cooldown), "use " + string(_i));
        cooldown_tick(_cooldown);
    }
});

test_case("cooldown / boundary / a 1-frame cooldown can be used every other frame", function () {
    var _cooldown = cooldown_create(1);
    assert_true(cooldown_try_use(_cooldown));
    assert_false(cooldown_try_use(_cooldown), "same frame");
    cooldown_tick(_cooldown);
    assert_true(cooldown_try_use(_cooldown), "next frame");
});

test_case("cooldown / invalid / negative, NaN, infinite and text lengths count as 0", function () {
    var _bad = [-1, -30, NaN, infinity, "30", undefined];
    for (var _i = 0; _i < array_length(_bad); _i++) {
        var _cooldown = cooldown_create(_bad[_i]);
        assert_equal(_cooldown.length_frames, 0, "length " + string(_bad[_i]));
        assert_true(cooldown_try_use(_cooldown));
        assert_true(cooldown_ready(_cooldown), "still ready after use");
    }
});

test_case("cooldown / boundary / cooldown bar is 0 right after use, 0.5 halfway and 1 when ready", function () {
    var _cooldown = cooldown_create(10);
    assert_equal(cooldown_fraction(_cooldown), 1);
    cooldown_try_use(_cooldown);
    assert_equal(cooldown_fraction(_cooldown), 0);
    for (var _i = 0; _i < 5; _i++) {
        cooldown_tick(_cooldown);
    }
    assert_near(cooldown_fraction(_cooldown), 0.5, 0.0001);
    assert_equal(cooldown_fraction(cooldown_create(0)), 1, "0-frame cooldown bar is always full");
});

test_case("cooldown / boundary / ticking a ready cooldown 1000 times never goes below 0", function () {
    var _cooldown = cooldown_create(30);
    for (var _i = 0; _i < 1000; _i++) {
        cooldown_tick(_cooldown);
    }
    assert_equal(_cooldown.remaining, 0);
});

// ---------------------------------------------------------------------------
// Melee attack
// ---------------------------------------------------------------------------

test_case("attack / normal / a swing damages an enemy by the attack damage", function () {
    var _attack = attack_create(4, 20);
    var _enemy = health_create(10);
    assert_true(attack_try_start(_attack));
    assert_true(attack_try_hit(_attack, _enemy));
    assert_equal(_enemy.hp, 6);
});

test_case("attack / boundary / one swing hits the same enemy only once", function () {
    var _attack = attack_create(4, 20);
    var _enemy = health_create(10);
    attack_try_start(_attack);
    attack_try_hit(_attack, _enemy);
    assert_false(attack_try_hit(_attack, _enemy), "second overlap in the same swing");
    assert_false(attack_try_hit(_attack, _enemy), "third overlap in the same swing");
    assert_equal(_enemy.hp, 6);
});

test_case("attack / normal / one swing hits several different enemies once each", function () {
    var _attack = attack_create(4, 20);
    var _a = health_create(10);
    var _b = health_create(10);
    attack_try_start(_attack);
    assert_true(attack_try_hit(_attack, _a));
    assert_true(attack_try_hit(_attack, _b));
    assert_false(attack_try_hit(_attack, _a));
    assert_equal(_a.hp, 6);
    assert_equal(_b.hp, 6);
});

test_case("attack / boundary / spamming attack during the cooldown is blocked", function () {
    var _attack = attack_create(4, 20);
    attack_try_start(_attack);
    for (var _i = 1; _i < 20; _i++) {
        cooldown_tick(_attack.cooldown);
        assert_false(attack_try_start(_attack), "attack pressed on frame " + string(_i));
    }
});

test_case("attack / boundary / attack is allowed on the exact frame the cooldown ends", function () {
    var _attack = attack_create(4, 20);
    attack_try_start(_attack);
    for (var _i = 0; _i < 20; _i++) {
        cooldown_tick(_attack.cooldown);
    }
    assert_true(attack_try_start(_attack), "frame 20");
});

test_case("attack / normal / a new swing can hit the same enemy again", function () {
    var _attack = attack_create(4, 0);
    var _enemy = health_create(10);
    attack_try_start(_attack);
    attack_try_hit(_attack, _enemy);
    attack_end(_attack);
    attack_try_start(_attack);
    assert_true(attack_try_hit(_attack, _enemy), "second swing");
    assert_equal(_enemy.hp, 2);
});

test_case("attack / invalid / touching an enemy when no swing is active does nothing", function () {
    var _attack = attack_create(4, 20);
    var _enemy = health_create(10);
    assert_false(attack_try_hit(_attack, _enemy), "before any swing");
    attack_try_start(_attack);
    attack_end(_attack);
    assert_false(attack_try_hit(_attack, _enemy), "after the swing ended");
    assert_equal(_enemy.hp, 10);
});

test_case("attack / adversarial / 3000 frames of random button mashing never swings faster than the cooldown", function () {
    var _attack = attack_create(4, 20);
    var _last_swing = -1000;
    var _swings = 0;
    for (var _frame = 0; _frame < 3000; _frame++) {
        if (irandom(2) == 0 && attack_try_start(_attack)) {
            assert_true(_frame - _last_swing >= 20, "swings on frames " + string(_last_swing) + " and " + string(_frame));
            _last_swing = _frame;
            _swings += 1;
        }
        cooldown_tick(_attack.cooldown);
    }
    assert_true(_swings > 50, "mashing should still swing often, swung " + string(_swings) + " times");
});

// ---------------------------------------------------------------------------
// Dash and i-frames
// ---------------------------------------------------------------------------

test_case("dash / boundary / a hit on the first i-frame does no damage", function () {
    var _player = health_create(10);
    var _dash = dash_create(12, 60);
    dash_try_start(_dash);
    assert_false(player_take_hit(_player, _dash, 5));
    assert_equal(_player.hp, 10);
});

test_case("dash / boundary / a hit on the last i-frame (frame 12 of 12) does no damage", function () {
    var _player = health_create(10);
    var _dash = dash_create(12, 60);
    dash_try_start(_dash);
    for (var _i = 0; _i < 11; _i++) {
        dash_tick(_dash);
    }
    player_take_hit(_player, _dash, 5);
    assert_equal(_player.hp, 10);
});

test_case("dash / boundary / a hit one frame after the i-frames end does damage", function () {
    var _player = health_create(10);
    var _dash = dash_create(12, 60);
    dash_try_start(_dash);
    for (var _i = 0; _i < 12; _i++) {
        dash_tick(_dash);
    }
    player_take_hit(_player, _dash, 5);
    assert_equal(_player.hp, 5);
});

test_case("dash / boundary / a second dash is blocked until the cooldown ends, then allowed on that frame", function () {
    var _dash = dash_create(12, 60);
    assert_true(dash_try_start(_dash));
    for (var _i = 1; _i < 60; _i++) {
        dash_tick(_dash);
        assert_false(dash_try_start(_dash), "dash pressed on frame " + string(_i));
    }
    dash_tick(_dash);
    assert_true(dash_try_start(_dash), "frame 60");
});

test_case("dash / boundary / zero i-frames from data means no invulnerability", function () {
    var _player = health_create(10);
    var _dash = dash_create(0, 60);
    dash_try_start(_dash);
    assert_false(dash_is_invulnerable(_dash));
    player_take_hit(_player, _dash, 5);
    assert_equal(_player.hp, 5);
});

test_case("dash / boundary / a lethal hit during i-frames does not kill", function () {
    var _player = health_create(10);
    var _dash = dash_create(12, 60);
    dash_try_start(_dash);
    assert_false(player_take_hit(_player, _dash, 1000));
    assert_false(_player.is_dead);
});

test_case("dash / adversarial / 5000 frames of random dashing and hits: no damage ever lands during i-frames", function () {
    var _player = health_create(1000000);
    var _dash = dash_create(12, 60);
    var _blocked = 0;
    for (var _frame = 0; _frame < 5000; _frame++) {
        if (irandom(3) == 0) {
            dash_try_start(_dash);
        }
        if (irandom(1) == 0) {
            var _before = _player.hp;
            var _invulnerable = dash_is_invulnerable(_dash);
            player_take_hit(_player, _dash, irandom_range(1, 10));
            if (_invulnerable) {
                assert_equal(_player.hp, _before, "hit landed during i-frames on frame " + string(_frame));
                _blocked += 1;
            }
        }
        dash_tick(_dash);
    }
    assert_true(_blocked > 0, "the random run never hit during a dash, so it proved nothing");
});
