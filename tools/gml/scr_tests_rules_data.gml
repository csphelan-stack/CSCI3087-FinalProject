/// scr_tests_rules_data
/// Tests for scr_rules_data: loading enemies and waves from JSON text.
/// The rule for data: a bad file or bad entry is reported and skipped, the
/// good entries still load, and nothing ever crashes the game.
/// Names read "feature / kind / what it checks" (kinds: normal, boundary,
/// invalid, adversarial).

#macro TEST_ENEMIES_JSON "{\"enemies\":[{\"type\":\"slime\",\"hp\":10,\"damage\":2,\"move_speed\":1.5},{\"type\":\"bat\",\"hp\":4,\"damage\":1,\"move_speed\":3}]}"
#macro TEST_WAVES_JSON "{\"waves\":[{\"spawns\":[{\"type\":\"slime\",\"count\":3},{\"type\":\"bat\",\"count\":1}]},{\"spawns\":[{\"type\":\"bat\",\"count\":5}]}]}"

/// @function __test_data_enemies()
/// The enemies parsed from TEST_ENEMIES_JSON, used by the wave tests.
function __test_data_enemies() {
    return data_parse_enemies(TEST_ENEMIES_JSON).enemies;
}

test_case("data / normal / a valid enemy file loads every enemy and its stats", function () {
    var _result = data_parse_enemies(TEST_ENEMIES_JSON);
    assert_equal(array_length(_result.errors), 0, "errors: " + string(_result.errors));
    assert_equal(_result.enemies.slime.hp, 10);
    assert_equal(_result.enemies.slime.damage, 2);
    assert_near(_result.enemies.slime.move_speed, 1.5, 0.0001);
    assert_equal(_result.enemies.bat.hp, 4);
});

test_case("data / normal / a valid wave file loads every wave and spawn", function () {
    var _result = data_parse_waves(TEST_WAVES_JSON, __test_data_enemies());
    assert_equal(array_length(_result.errors), 0, "errors: " + string(_result.errors));
    assert_equal(array_length(_result.waves), 2);
    assert_equal(wave_total_enemies(_result.waves[0]), 4);
    assert_equal(wave_total_enemies(_result.waves[1]), 5);
});

test_case("data / invalid / a missing file is reported, not a crash", function () {
    var _text = data_read_file("this_file_does_not_exist_for_tests.json");
    var _result = data_parse_waves(_text, __test_data_enemies());
    assert_equal(array_length(_result.waves), 0);
    assert_equal(array_length(_result.errors), 1);
});

test_case("data / invalid / an empty file is reported", function () {
    var _result = data_parse_enemies("");
    assert_equal(array_length(_result.errors), 1);
    assert_false(variable_struct_exists(_result.enemies, "slime"), "nothing loads");
});

test_case("data / invalid / broken JSON is reported for every kind of damage", function () {
    var _broken = [
        "   ",
        "{",
        "{\"enemies\":[",
        "{\"enemies\":[{\"type\":\"slime\",\"hp\":10}",
        "not json at all"
    ];
    for (var _i = 0; _i < array_length(_broken); _i++) {
        var _result = data_parse_enemies(_broken[_i]);
        assert_true(array_length(_result.errors) >= 1, "broken file " + string(_i) + " was accepted");
    }
});

test_case("data / invalid / a top level that is a list, number or text is reported", function () {
    var _wrong = ["[1, 2, 3]", "42", "\"enemies\"", "null"];
    for (var _i = 0; _i < array_length(_wrong); _i++) {
        var _result = data_parse_enemies(_wrong[_i]);
        assert_equal(array_length(_result.errors), 1, _wrong[_i]);
    }
});

test_case("data / invalid / a file without the expected list is reported", function () {
    assert_equal(array_length(data_parse_enemies("{\"monsters\":[]}").errors), 1, "enemies");
    assert_equal(array_length(data_parse_waves("{\"wave\":[]}", __test_data_enemies()).errors), 1, "waves");
});

test_case("data / invalid / an unknown enemy type is skipped and the rest of the wave still loads", function () {
    var _json = "{\"waves\":[{\"spawns\":[{\"type\":\"dragon\",\"count\":1},{\"type\":\"slime\",\"count\":2}]}]}";
    var _result = data_parse_waves(_json, __test_data_enemies());
    assert_equal(array_length(_result.errors), 1);
    assert_equal(array_length(_result.waves[0].spawns), 1);
    assert_equal(_result.waves[0].spawns[0].type, "slime");
});

test_case("data / boundary / enemy types are case-sensitive: Slime is not slime", function () {
    var _json = "{\"waves\":[{\"spawns\":[{\"type\":\"Slime\",\"count\":1}]}]}";
    var _result = data_parse_waves(_json, __test_data_enemies());
    assert_equal(array_length(_result.errors), 1);
    assert_equal(array_length(_result.waves[0].spawns), 0);
});

test_case("data / invalid / negative, decimal, text and missing spawn counts are skipped", function () {
    var _counts = ["-1", "2.5", "\"3\"", "null", "true"];
    for (var _i = 0; _i < array_length(_counts); _i++) {
        var _json = "{\"waves\":[{\"spawns\":[{\"type\":\"slime\",\"count\":" + _counts[_i] + "}]}]}";
        var _result = data_parse_waves(_json, __test_data_enemies());
        assert_equal(array_length(_result.waves[0].spawns), 0, "count " + _counts[_i] + " was accepted");
        assert_equal(array_length(_result.errors), 1, "count " + _counts[_i]);
    }
    var _missing = data_parse_waves("{\"waves\":[{\"spawns\":[{\"type\":\"slime\"}]}]}", __test_data_enemies());
    assert_equal(array_length(_missing.waves[0].spawns), 0, "missing count");
});

test_case("data / boundary / spawn counts of 0 and 1 are both allowed", function () {
    var _json = "{\"waves\":[{\"spawns\":[{\"type\":\"slime\",\"count\":0},{\"type\":\"bat\",\"count\":1}]}]}";
    var _result = data_parse_waves(_json, __test_data_enemies());
    assert_equal(array_length(_result.errors), 0);
    assert_equal(wave_total_enemies(_result.waves[0]), 1);
});

test_case("data / boundary / a wave left with no valid spawns loads as an empty wave that clears at once", function () {
    var _json = "{\"waves\":[{\"spawns\":[{\"type\":\"dragon\",\"count\":4}]},{\"spawns\":[]}]}";
    var _result = data_parse_waves(_json, __test_data_enemies());
    assert_equal(array_length(_result.waves), 2, "both waves still exist, so the wave counter stays in order");
    assert_equal(wave_resolve_frame(false, 0, wave_total_enemies(_result.waves[0])), "wave_cleared");
});

test_case("data / invalid / a wave without a spawns list loads as an empty wave with an error", function () {
    var _result = data_parse_waves("{\"waves\":[{\"enemies\":[]}, 7]}", __test_data_enemies());
    assert_equal(array_length(_result.waves), 2);
    assert_equal(array_length(_result.errors), 2);
});

test_case("data / invalid / enemies with hp 0, negative damage, text speed or no type are skipped, others load", function () {
    var _json = "{\"enemies\":["
        + "{\"type\":\"ghost\",\"hp\":0,\"damage\":1,\"move_speed\":1},"
        + "{\"type\":\"imp\",\"hp\":5,\"damage\":-1,\"move_speed\":1},"
        + "{\"type\":\"orc\",\"hp\":5,\"damage\":1,\"move_speed\":\"fast\"},"
        + "{\"hp\":5,\"damage\":1,\"move_speed\":1},"
        + "{\"type\":\"slime\",\"hp\":10,\"damage\":2,\"move_speed\":1.5}"
        + "]}";
    var _result = data_parse_enemies(_json);
    assert_equal(array_length(_result.errors), 4);
    assert_true(variable_struct_exists(_result.enemies, "slime"), "slime loads");
    assert_false(variable_struct_exists(_result.enemies, "ghost"), "ghost has hp 0");
    assert_false(variable_struct_exists(_result.enemies, "imp"), "imp has negative damage");
    assert_false(variable_struct_exists(_result.enemies, "orc"), "orc has text speed");
});

test_case("data / boundary / hp of 1 and damage and speed of 0 are allowed", function () {
    var _result = data_parse_enemies("{\"enemies\":[{\"type\":\"dummy\",\"hp\":1,\"damage\":0,\"move_speed\":0}]}");
    assert_equal(array_length(_result.errors), 0);
    assert_equal(_result.enemies.dummy.hp, 1);
});

test_case("data / invalid / a repeated enemy type keeps the first definition and reports the second", function () {
    var _json = "{\"enemies\":[{\"type\":\"slime\",\"hp\":10,\"damage\":2,\"move_speed\":1},{\"type\":\"slime\",\"hp\":99,\"damage\":9,\"move_speed\":9}]}";
    var _result = data_parse_enemies(_json);
    assert_equal(array_length(_result.errors), 1);
    assert_equal(_result.enemies.slime.hp, 10);
});

test_case("data / adversarial / 500 randomly corrupted wave files never crash the loader", function () {
    var _enemies = __test_data_enemies();
    var _chars = "{}[]\":,0123456789-.e abcslimebat";
    var _loaded_spawns = 0;
    for (var _i = 0; _i < 500; _i++) {
        var _text = TEST_WAVES_JSON;
        var _edits = irandom_range(1, 4);
        for (var _e = 0; _e < _edits; _e++) {
            var _pos = irandom_range(1, string_length(_text));
            if (irandom(1) == 0) {
                _text = string_delete(_text, _pos, irandom_range(1, 3));
            } else {
                _text = string_insert(string_char_at(_chars, irandom_range(1, string_length(_chars))), _text, _pos);
            }
        }
        var _result = data_parse_waves(_text, _enemies);
        assert_true(is_array(_result.waves) && is_array(_result.errors), "file " + string(_i));
        // Whatever loaded must still follow the rules: a known type and a whole count of 0 or more.
        for (var _w = 0; _w < array_length(_result.waves); _w++) {
            var _spawns = _result.waves[_w].spawns;
            for (var _s = 0; _s < array_length(_spawns); _s++) {
                assert_true(variable_struct_exists(_enemies, _spawns[_s].type), "unknown type loaded from file " + string(_i));
                assert_true(_spawns[_s].count >= 0 && _spawns[_s].count == floor(_spawns[_s].count), "bad count loaded from file " + string(_i));
                _loaded_spawns += 1;
            }
        }
    }
    assert_true(_loaded_spawns > 0, "no corrupted file loaded anything, so the invariant was never checked");
});
