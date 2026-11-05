/// scr_tests_framework_selftest
/// Tests for the test framework itself. Every assertion must pass on good input
/// and fail on bad input; if an assertion could never fail, every test that
/// uses it would pass no matter how broken the game was. These also give the
/// pipeline real tests to run before our game-logic tests are written.

/// @function __selftest_expect_failure(func)
/// Passes only if func raises a test failure (not a crash, not nothing).
function __selftest_expect_failure(_func) {
    try {
        _func();
    } catch (_e) {
        if (__test_is_failure(_e)) {
            return;
        }
        __test_fail("expected an assertion failure but got a crash: " + __test_describe_exception(_e));
    }
    __test_fail("expected the assertion to fail on bad input, but it passed");
}

// --- assert_true / assert_false ---------------------------------------------

test_case("selftest: assert_true passes on true and 1", function () {
    assert_true(true);
    assert_true(1);
});

test_case("selftest: assert_true fails on false", function () {
    __selftest_expect_failure(function () { assert_true(false); });
});

test_case("selftest: assert_true fails on undefined", function () {
    __selftest_expect_failure(function () { assert_true(undefined); });
});

test_case("selftest: assert_true fails on a string", function () {
    __selftest_expect_failure(function () { assert_true("true"); });
});

test_case("selftest: assert_false passes on false and 0", function () {
    assert_false(false);
    assert_false(0);
});

test_case("selftest: assert_false fails on true", function () {
    __selftest_expect_failure(function () { assert_false(true); });
});

test_case("selftest: assert_false fails on undefined", function () {
    __selftest_expect_failure(function () { assert_false(undefined); });
});

// --- assert_equal -------------------------------------------------------------

test_case("selftest: assert_equal passes on equal numbers, strings and arrays", function () {
    assert_equal(3, 3);
    assert_equal("wave", "wave");
    assert_equal([1, 2, 3], [1, 2, 3]);
    assert_equal(undefined, undefined);
});

test_case("selftest: assert_equal fails on different numbers", function () {
    __selftest_expect_failure(function () { assert_equal(1, 2); });
});

test_case("selftest: assert_equal fails on a number vs the same digits as a string", function () {
    __selftest_expect_failure(function () { assert_equal(1, "1"); });
});

test_case("selftest: assert_equal fails on arrays of different length", function () {
    __selftest_expect_failure(function () { assert_equal([1, 2], [1, 2, 3]); });
});

test_case("selftest: assert_equal fails on arrays with one different element", function () {
    __selftest_expect_failure(function () { assert_equal([1, 2, 3], [1, 9, 3]); });
});

test_case("selftest: assert_equal fails on undefined vs 0", function () {
    __selftest_expect_failure(function () { assert_equal(undefined, 0); });
});

test_case("selftest: assert_equal fails on NaN vs NaN", function () {
    __selftest_expect_failure(function () { assert_equal(NaN, NaN); });
});

test_case("selftest: assert_not_equal fails on equal values", function () {
    assert_not_equal(1, 2);
    __selftest_expect_failure(function () { assert_not_equal(5, 5); });
});

// --- assert_near ----------------------------------------------------------------

test_case("selftest: assert_near passes within tolerance", function () {
    assert_near(0.1 + 0.2, 0.3, 0.0001);
    assert_near(sqrt(2) / 2, 0.7071, 0.001);
});

test_case("selftest: assert_near fails outside tolerance", function () {
    __selftest_expect_failure(function () { assert_near(1, 1.1, 0.01); });
});

test_case("selftest: assert_near fails on NaN", function () {
    __selftest_expect_failure(function () { assert_near(NaN, 0, 1000); });
});

// --- assert_in_range ------------------------------------------------------------

test_case("selftest: assert_in_range is inclusive at both ends", function () {
    assert_in_range(0, 0, 100);
    assert_in_range(100, 0, 100);
    assert_in_range(50, 0, 100);
});

test_case("selftest: assert_in_range fails just below the minimum", function () {
    __selftest_expect_failure(function () { assert_in_range(-1, 0, 100); });
});

test_case("selftest: assert_in_range fails just above the maximum", function () {
    __selftest_expect_failure(function () { assert_in_range(101, 0, 100); });
});

test_case("selftest: assert_in_range fails on NaN and undefined", function () {
    __selftest_expect_failure(function () { assert_in_range(NaN, 0, 100); });
    __selftest_expect_failure(function () { assert_in_range(undefined, 0, 100); });
});

// --- assert_finite --------------------------------------------------------------

test_case("selftest: assert_finite passes on ordinary numbers", function () {
    assert_finite(0);
    assert_finite(-42.5);
});

test_case("selftest: assert_finite fails on infinity, NaN and undefined", function () {
    __selftest_expect_failure(function () { assert_finite(infinity); });
    __selftest_expect_failure(function () { assert_finite(-infinity); });
    __selftest_expect_failure(function () { assert_finite(NaN); });
    __selftest_expect_failure(function () { assert_finite(undefined); });
});

// --- assert_throws / assert_no_throw ---------------------------------------------

test_case("selftest: assert_throws passes when the function throws", function () {
    assert_throws(function () { throw "boom"; });
});

test_case("selftest: assert_throws fails when nothing is thrown", function () {
    __selftest_expect_failure(function () { assert_throws(function () { }); });
});

test_case("selftest: assert_no_throw fails when the function throws", function () {
    assert_no_throw(function () { });
    __selftest_expect_failure(function () { assert_no_throw(function () { throw "boom"; }); });
});

// --- fail and seeding -----------------------------------------------------------

test_case("selftest: fail always fails", function () {
    __selftest_expect_failure(function () { fail("on purpose"); });
});

test_case("selftest: each test starts from the same random seed", function () {
    // The runner calls random_set_seed(TEST_SEED) before every test, so the
    // first random number in any test is always the same.
    var _first = irandom(1000000);
    random_set_seed(TEST_SEED);
    assert_equal(irandom(1000000), _first, "first irandom after reseeding");
});
