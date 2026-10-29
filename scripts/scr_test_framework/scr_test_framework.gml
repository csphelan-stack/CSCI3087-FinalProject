/// scr_test_framework
/// A small test framework that CI uses to run our GML tests.
///
/// How it works:
///   - Test scripts register tests with test_case(name, function).
///   - When the game is launched with the --run-tests flag, every registered
///     test runs two frames after startup, the results are written to
///     test_results.json in the game's save folder, and the game closes.
///   - Without --run-tests, nothing in this script does anything.
///
/// Each test runs with the random seed reset to TEST_SEED, so a test that uses
/// random numbers produces the same numbers on every run and every machine.
///
/// Important: GML functions do not capture local variables. A function passed
/// to assert_throws() or assert_no_throw() cannot see a "var" from the test
/// around it. Use literals, globals, or method({ ... }, function () { ... }).

#macro TEST_RUN_FLAG "--run-tests"
#macro TEST_RESULTS_FILE "test_results.json"
#macro TEST_SEED 12345

// ---------------------------------------------------------------------------
// Registering tests
// ---------------------------------------------------------------------------

/// @function test_case(name, func)
/// @param {String} name  What the test checks, e.g. "damage exactly lethal sets hp to 0".
/// @param {Function} func  The test body. It fails if an assertion fails or it throws.
function test_case(_name, _func) {
    __test_ensure_registry();
    array_push(global.__test_cases, { name: _name, func: _func });
}

function __test_ensure_registry() {
    if (!variable_global_exists("__test_cases")) {
        global.__test_cases = [];
    }
}

function __test_flag_present() {
    for (var _i = 1; _i <= parameter_count(); _i++) {
        if (parameter_string(_i) == TEST_RUN_FLAG) {
            return true;
        }
    }
    return false;
}

// ---------------------------------------------------------------------------
// Assertions. Each one throws a test failure when its check does not hold.
// ---------------------------------------------------------------------------

/// @function fail(message)
function fail(_message) {
    __test_fail(_message);
}

/// @function assert_true(condition, [message])
/// Only true (or a number GML treats as true) passes; undefined and strings fail.
function assert_true(_condition, _message = "") {
    if (!__test_is_boolish(_condition) || !_condition) {
        __test_fail(__test_prefix(_message) + "expected true but got " + __test_repr(_condition));
    }
}

/// @function assert_false(condition, [message])
/// Only false (or a number GML treats as false) passes; undefined and strings fail.
function assert_false(_condition, _message = "") {
    if (!__test_is_boolish(_condition) || _condition) {
        __test_fail(__test_prefix(_message) + "expected false but got " + __test_repr(_condition));
    }
}

/// @function assert_equal(actual, expected, [message])
/// Numbers, strings, undefined and arrays are compared by value; structs by reference.
function assert_equal(_actual, _expected, _message = "") {
    if (!__test_values_equal(_actual, _expected)) {
        __test_fail(__test_prefix(_message) + "expected " + __test_repr(_expected) + " but got " + __test_repr(_actual));
    }
}

/// @function assert_not_equal(actual, unexpected, [message])
function assert_not_equal(_actual, _unexpected, _message = "") {
    if (__test_values_equal(_actual, _unexpected)) {
        __test_fail(__test_prefix(_message) + "did not expect " + __test_repr(_unexpected));
    }
}

/// @function assert_near(actual, expected, tolerance, [message])
/// For decimal results, e.g. diagonal movement speed. NaN always fails.
function assert_near(_actual, _expected, _tolerance, _message = "") {
    if (!is_numeric(_actual) || is_nan(_actual) || abs(_actual - _expected) > _tolerance) {
        __test_fail(__test_prefix(_message) + "expected " + __test_repr(_expected) + " +/- " + string(_tolerance) + " but got " + __test_repr(_actual));
    }
}

/// @function assert_in_range(value, min, max, [message])
/// Inclusive on both ends. NaN and non-numbers always fail.
function assert_in_range(_value, _min, _max, _message = "") {
    if (!is_numeric(_value) || is_nan(_value) || _value < _min || _value > _max) {
        __test_fail(__test_prefix(_message) + "expected a value from " + string(_min) + " to " + string(_max) + " but got " + __test_repr(_value));
    }
}

/// @function assert_finite(value, [message])
/// Fails on NaN, infinity and anything that is not a number.
function assert_finite(_value, _message = "") {
    if (!is_numeric(_value) || is_nan(_value) || is_infinity(_value)) {
        __test_fail(__test_prefix(_message) + "expected a finite number but got " + __test_repr(_value));
    }
}

/// @function assert_throws(func, [message])
/// Passes only if func throws an error (an assertion failure inside func does not count).
function assert_throws(_func, _message = "") {
    try {
        _func();
    } catch (_e) {
        if (__test_is_failure(_e)) {
            throw _e;
        }
        return;
    }
    __test_fail(__test_prefix(_message) + "expected an error but none was thrown");
}

/// @function assert_no_throw(func, [message])
/// Use for invalid-input tests where the rule is "must not crash".
function assert_no_throw(_func, _message = "") {
    try {
        _func();
    } catch (_e) {
        if (__test_is_failure(_e)) {
            throw _e;
        }
        __test_fail(__test_prefix(_message) + "expected no error but got: " + __test_describe_exception(_e));
    }
}

// ---------------------------------------------------------------------------
// Running the tests (only when the game was launched with --run-tests)
// ---------------------------------------------------------------------------

/// @function tests_run_all()
/// Runs every registered test, writes test_results.json and ends the game.
function tests_run_all() {
    __test_ensure_registry();
    var _cases = global.__test_cases;
    var _count = array_length(_cases);
    var _results = [];
    var _passed = 0;
    var _failed = 0;
    var _crashed = 0;

    show_debug_message("[TEST] Running " + string(_count) + " tests");

    for (var _i = 0; _i < _count; _i++) {
        var _case = _cases[_i];
        var _status = "passed";
        var _message = "";

        random_set_seed(TEST_SEED);
        try {
            _case.func();
        } catch (_e) {
            if (__test_is_failure(_e)) {
                _status = "failed";
                _message = _e.message;
            } else {
                _status = "crashed";
                _message = __test_describe_exception(_e);
            }
        }

        if (_status == "passed") {
            _passed++;
        } else if (_status == "failed") {
            _failed++;
        } else {
            _crashed++;
        }

        array_push(_results, { name: _case.name, status: _status, message: _message });
        show_debug_message("[TEST] " + string_upper(_status) + ": " + _case.name + (_message == "" ? "" : " -- " + _message));
    }

    var _summary = {
        status: "completed",
        seed: TEST_SEED,
        total: _count,
        passed: _passed,
        failed: _failed,
        crashed: _crashed,
        tests: _results
    };

    __test_write_results(_summary);

    show_debug_message("[TEST] " + string(_passed) + " passed, " + string(_failed) + " failed, " + string(_crashed) + " crashed");
    show_debug_message("[TEST] Results written to " + game_save_id + TEST_RESULTS_FILE);
    game_end();
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function __test_fail(_message) {
    throw { __is_test_failure: true, message: _message };
}

function __test_is_failure(_e) {
    return is_struct(_e) && variable_struct_exists(_e, "__is_test_failure");
}

function __test_is_boolish(_value) {
    return is_bool(_value) || (is_numeric(_value) && !is_nan(_value));
}

function __test_write_results(_summary) {
    var _file = file_text_open_write(TEST_RESULTS_FILE);
    if (_file == -1) {
        show_debug_message("[TEST] Could not open " + TEST_RESULTS_FILE + " for writing");
        return;
    }
    file_text_write_string(_file, json_stringify(_summary));
    file_text_close(_file);
}

// Runs only in test mode. Without it, an error outside a test (for example in
// the title screen's objects) would open GameMaker's error dialog and the CI
// runner would sit there until it timed out. The return value is the exit code.
function __test_unhandled_error(_e) {
    var _message = __test_describe_exception(_e);
    show_debug_message("[TEST] Unhandled error outside a test: " + _message);
    if (is_struct(_e) && variable_struct_exists(_e, "longMessage")) {
        show_debug_message(string(_e.longMessage));
    }
    __test_write_results({
        status: "crashed",
        seed: TEST_SEED,
        total: 0,
        passed: 0,
        failed: 0,
        crashed: 1,
        tests: [{ name: "game startup (outside any test)", status: "crashed", message: _message }]
    });
    return 1;
}

function __test_prefix(_message) {
    return (_message == "") ? "" : _message + ": ";
}

function __test_repr(_value) {
    if (is_string(_value)) {
        return "\"" + _value + "\"";
    }
    return string(_value);
}

function __test_describe_exception(_e) {
    if (is_struct(_e) && variable_struct_exists(_e, "message")) {
        return string(_e.message);
    }
    return string(_e);
}

function __test_values_equal(_a, _b) {
    if (is_undefined(_a) || is_undefined(_b)) {
        return is_undefined(_a) && is_undefined(_b);
    }
    if (is_numeric(_a) && is_numeric(_b)) {
        return _a == _b;
    }
    if (is_string(_a) && is_string(_b)) {
        return _a == _b;
    }
    if (is_array(_a) && is_array(_b)) {
        if (array_length(_a) != array_length(_b)) {
            return false;
        }
        for (var _i = 0; _i < array_length(_a); _i++) {
            if (!__test_values_equal(_a[_i], _b[_i])) {
                return false;
            }
        }
        return true;
    }
    if (is_struct(_a) && is_struct(_b)) {
        return _a == _b;
    }
    return false;
}

// ---------------------------------------------------------------------------
// Startup: schedule the test run if the flag was passed.
// ---------------------------------------------------------------------------

__test_ensure_registry();
global.__test_run_requested = __test_flag_present();
if (global.__test_run_requested) {
    exception_unhandled_handler(__test_unhandled_error);
    global.__test_time_source = time_source_create(time_source_global, 2, time_source_units_frames, tests_run_all);
    time_source_start(global.__test_time_source);
}
