/// scr_rules_data
/// Loads enemy and wave definitions from JSON text. Bad data never crashes the
/// game: broken files load nothing and report an error, and bad entries are
/// skipped with an error while the good entries still load.
///
/// Expected files (in the project's Included Files):
///   enemies.json  { "enemies": [ { "type": "slime", "hp": 10, "damage": 2, "move_speed": 1.5 } ] }
///   waves.json    { "waves": [ { "spawns": [ { "type": "slime", "count": 3 } ] } ] }
/// tools/validate_data.py checks the same layout before the game is built.

/// @function data_read_file(filename)
/// The file's text, or "" if it does not exist, so a missing file is handled
/// like an empty one.
function data_read_file(_filename) {
    if (!file_exists(_filename)) {
        return "";
    }
    var _buffer = buffer_load(_filename);
    var _text = buffer_read(_buffer, buffer_string);
    buffer_delete(_buffer);
    return _text;
}

/// @function data_parse_json(text, errors)
/// Parses JSON text whose top level must be an object. On failure adds a
/// message to errors and returns undefined.
function data_parse_json(_text, _errors) {
    if (!is_string(_text) || string_length(_text) == 0) {
        array_push(_errors, "file is missing or empty");
        return undefined;
    }
    var _data = undefined;
    try {
        _data = json_parse(_text);
    } catch (_e) {
        array_push(_errors, "file is not valid JSON");
        return undefined;
    }
    if (!is_struct(_data)) {
        array_push(_errors, "the top level must be a JSON object");
        return undefined;
    }
    return _data;
}

/// @function data_is_number_at_least(value, minimum)
/// True for a finite number (not true/false) that is at least minimum.
function data_is_number_at_least(_value, _minimum) {
    return is_numeric(_value) && !is_bool(_value) && !is_nan(_value) && !is_infinity(_value) && _value >= _minimum;
}

/// @function data_parse_enemies(json_text)
/// Returns { enemies, errors }. enemies is a struct keyed by type, so
/// enemies.slime.hp is the slime's hp. An entry is skipped with an error if
/// its type is missing or already used, hp is not above 0, or damage or
/// move_speed is negative or not a number.
function data_parse_enemies(_json_text) {
    var _result = { enemies: {}, errors: [] };
    var _data = data_parse_json(_json_text, _result.errors);
    if (is_undefined(_data)) {
        return _result;
    }
    var _list = variable_struct_get(_data, "enemies");
    if (!is_array(_list)) {
        array_push(_result.errors, "missing an \"enemies\" list");
        return _result;
    }
    for (var _i = 0; _i < array_length(_list); _i++) {
        var _entry = _list[_i];
        var _where = "enemy " + string(_i + 1);
        if (!is_struct(_entry)) {
            array_push(_result.errors, _where + " is not an object");
            continue;
        }
        var _type = variable_struct_get(_entry, "type");
        var _hp = variable_struct_get(_entry, "hp");
        var _damage = variable_struct_get(_entry, "damage");
        var _speed = variable_struct_get(_entry, "move_speed");
        if (!is_string(_type) || string_length(_type) == 0) {
            array_push(_result.errors, _where + " has no type");
        } else if (variable_struct_exists(_result.enemies, _type)) {
            array_push(_result.errors, _where + " repeats type \"" + _type + "\"; the first one is kept");
        } else if (!data_is_number_at_least(_hp, 0) || _hp <= 0) {
            array_push(_result.errors, _where + " (" + _type + ") needs hp above 0");
        } else if (!data_is_number_at_least(_damage, 0)) {
            array_push(_result.errors, _where + " (" + _type + ") needs damage of 0 or more");
        } else if (!data_is_number_at_least(_speed, 0)) {
            array_push(_result.errors, _where + " (" + _type + ") needs move_speed of 0 or more");
        } else {
            variable_struct_set(_result.enemies, _type, { hp: _hp, damage: _damage, move_speed: _speed });
        }
    }
    return _result;
}

/// @function data_parse_waves(json_text, enemies)
/// Returns { waves, errors }. Each wave is { spawns: [ { type, count } ] }.
/// A spawn is skipped with an error if its type is not in enemies (types are
/// case-sensitive) or its count is not a whole number of 0 or more; the rest
/// of the wave still loads. A wave with no valid spawns stays as an empty wave.
function data_parse_waves(_json_text, _enemies) {
    var _result = { waves: [], errors: [] };
    var _data = data_parse_json(_json_text, _result.errors);
    if (is_undefined(_data)) {
        return _result;
    }
    var _list = variable_struct_get(_data, "waves");
    if (!is_array(_list)) {
        array_push(_result.errors, "missing a \"waves\" list");
        return _result;
    }
    for (var _w = 0; _w < array_length(_list); _w++) {
        var _wave = { spawns: [] };
        var _spawns = is_struct(_list[_w]) ? variable_struct_get(_list[_w], "spawns") : undefined;
        if (!is_array(_spawns)) {
            array_push(_result.errors, "wave " + string(_w + 1) + " has no \"spawns\" list");
        } else {
            for (var _s = 0; _s < array_length(_spawns); _s++) {
                var _spawn = _spawns[_s];
                var _where = "wave " + string(_w + 1) + " spawn " + string(_s + 1);
                if (!is_struct(_spawn)) {
                    array_push(_result.errors, _where + " is not an object");
                    continue;
                }
                var _type = variable_struct_get(_spawn, "type");
                var _count = variable_struct_get(_spawn, "count");
                if (!is_string(_type) || !variable_struct_exists(_enemies, _type)) {
                    array_push(_result.errors, _where + " uses unknown enemy type " + string(_type));
                } else if (!data_is_number_at_least(_count, 0) || _count != floor(_count)) {
                    array_push(_result.errors, _where + " needs a whole-number count of 0 or more, not " + string(_count));
                } else {
                    array_push(_wave.spawns, { type: _type, count: _count });
                }
            }
        }
        array_push(_result.waves, _wave);
    }
    return _result;
}
