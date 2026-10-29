# Testing and CI

Every push to any branch, and every pull request into `main`, runs `.github/workflows/ci.yml`:

| Job | Runs on | What it does | Fails when |
| --- | --- | --- | --- |
| Style and data checks | Ubuntu | Tests the checkers themselves (pytest), checks for a CREDITS file, validates the JSON data, checks style rules | A checker test fails, CREDITS is missing, a data file is broken, or a style rule is broken |
| Build game and run GML tests | Windows, only after the first job passes | Builds the game with Igor (GameMaker's command-line builder), starts it with `--run-tests`, reads `test_results.json` | The build fails, any GML test fails or crashes, no tests ran, or the game does not close within 5 minutes |
| Lint, unit tests and project files | Ubuntu, alongside the first job | flake8 on `tools/` and `tests/`, the pytest tests in `tests/`, and `tools/gm_check.py` on the `.yy`/`.yyp` files | A lint error, a failing test in `tests/`, or an unreadable project file |

## What is in this folder

| Path | Purpose |
| --- | --- |
| `.github/workflows/ci.yml` | The pipeline: triggers, jobs and steps |
| `scripts/scr_test_framework` | GML test framework: `test_case()`, assertions, the runner (in the IDE's Tests folder) |
| `scripts/scr_tests_framework_selftest` | 29 tests proving every assertion fails on bad input (in the IDE's Tests folder) |
| `scripts/player_attack_config` | Default damage and knockback for the player's sword hitbox |
| `tools/check_style.py` | Our style rules (naming, headers, hardcoded stats, debug output, test rooms, whitespace, indentation) |
| `tools/gm_check.py`, `tests/` | The first CI workflow's `.yy`/`.yyp` checker and its unit tests, including enemy default values |
| `.flake8` | flake8 settings for the lint step |
| `CREDITS` | Third-party assets and their licenses |
| `tools/validate_data.py` | JSON data checks (strict JSON, duplicate keys, stat ranges, unknown enemy types) |
| `tools/ci/run-gml-tests.ps1` | Unzips the build, runs the game in test mode, collects the results |
| `tools/ci/check_test_results.py` | Turns `test_results.json` into pass or fail, with annotations and a summary table |
| `tools/tests/` | 114 pytest tests for the three Python checkers, plus 13 intentionally broken JSON files |

## Naming rule

Objects end in `_obj` or `_object`, sprites in `_spr`, rooms in `_room`, and sounds start with `snd_`. Case is ignored, so `main_character_Obj` passes. Scripts have no naming rule because they are named after the functions inside them. Test assets (`scr_test*`, `obj_test*`, `rm_test*`) are exempt. To change a rule, edit `ASSET_NAMING` at the top of `tools/check_style.py`.

## One-time setup

Done: the files are in the repo, the two GML scripts are registered in the project, `CREDITS` exists, and the existing code passes the style check.

Still to do:

1. **Add the GameMaker access key.** One teammate signs in at gamemaker.io, opens Account > Access Keys, and generates a key. In GitHub, open Settings > Secrets and variables > Actions, add a secret named `ACCESS_KEY`, and paste in the key. Never commit the key.
2. **Fill in the TODOs in `CREDITS`**: author, source and license for each asset pack.
3. **Turn on branch protection** for `main` (Settings > Branches): require a pull request, require one approval, and require the status checks "Style and data checks", "Build game and run GML tests" and "Lint, unit tests and project files".
4. **When the game gets JSON data files**, put them in `datafiles/` and fill in the enemy-ref settings at the top of `tools/validate_data.py` so waves can only use enemy types that exist. Until then the validator has nothing to check and passes with a warning.

`python tools/check_style.py --fix-whitespace` strips trailing whitespace automatically.

## Writing a GML test

Put tests in a script whose name starts with `scr_tests_`. Each test is a `test_case` call at the top level of the script:

```gml
/// scr_tests_health
/// Boundary tests for player health: health never goes below 0 or above max.

test_case("damage of hp-1 leaves 1 hp", function () {
    var _player = { hp: 10, max_hp: 10 };
    health_apply_damage(_player, 9);      // example name: use our real function
    assert_equal(_player.hp, 1);
});

test_case("damage exactly equal to hp leaves 0 hp", function () {
    var _player = { hp: 10, max_hp: 10 };
    health_apply_damage(_player, 10);
    assert_equal(_player.hp, 0);
});

test_case("overkill damage never makes hp negative", function () {
    var _player = { hp: 10, max_hp: 10 };
    health_apply_damage(_player, 11);
    assert_equal(_player.hp, 0);
});

test_case("1000 random hits and heals keep hp between 0 and max", function () {
    var _player = { hp: 10, max_hp: 10 };
    repeat (1000) {
        if (irandom(1) == 0) health_apply_damage(_player, irandom_range(-5, 50));
        else health_apply_heal(_player, irandom_range(-5, 50));
        assert_in_range(_player.hp, 0, _player.max_hp);
    }
});
```

Assertions: `assert_true`, `assert_false`, `assert_equal`, `assert_not_equal`, `assert_near` (decimals, e.g. diagonal speed), `assert_in_range` (inclusive), `assert_finite` (no NaN or infinity), `assert_throws`, `assert_no_throw` (for "invalid input must not crash"), and `fail`.

Rules that keep tests reliable:

- **Test both sides of every boundary:** N−1, N and N+1 (for example 299, 300 and 301 frames).
- **Use frame counts, never real time.**
- **Randomness is repeatable:** the runner resets the seed to 12345 before every test, so a random-input failure happens the same way every run.
- **A function inside a test cannot see the test's `var` variables** (GML has no closures). Use `method({ player: _player }, function () { ... })` to pass data in.
- **Break the code on purpose before merging a new test.** Remove the clamp, flip the comparison, and confirm the test fails. A test that cannot fail proves nothing.

## Running the checks on your own computer

```bash
pip install -r tools/requirements-dev.txt
python -m pytest tools/tests -q        # the checkers' own tests
python tools/validate_data.py          # JSON data
python tools/check_style.py            # style rules
```

To run the GML tests locally, build the game (Build > Create Executable, zip), unzip it, and run `YourGame.exe --run-tests`. The results go to `%LOCALAPPDATA%\<game name>\test_results.json`; check them with `python tools/ci/check_test_results.py <that file>`.

## When the pipeline fails

Open the run in the Actions tab and find the first red step. Failing tests and style problems also appear as annotations on the changed files, and the run's summary page has a table of test results. The `test-output` artifact contains `test_results.json` and `game-log.txt`.

| Red step | Usual cause | What to do |
| --- | --- | --- |
| Test the checkers | Someone changed a checker and broke it | Run `python -m pytest tools/tests` locally and fix the checker |
| Check that a CREDITS file exists | File deleted or renamed | Restore `CREDITS` |
| Validate JSON data files | Broken JSON, duplicate key, stat out of range, unknown enemy | The message names the file and field; fix the data |
| Check style rules | Code breaks a style rule | The message names the file, line and rule; fix it, or change the rule for the whole team |
| Check that the ACCESS_KEY secret is set / Install GameMaker build tools | Secret missing or expired; runtime download failed | Regenerate the key and update the secret; re-run the job |
| Build Windows game | Compile error, or a GML file not registered in the `.yyp` | Read the Igor output in the step log; build locally to reproduce |
| Run the game in test mode | The game did not close within 5 minutes | A test is stuck in a loop or the game never reached the runner; read `game-log.txt` |
| Check test results | A test failed or crashed, or the game crashed at startup | Reproduce locally with `--run-tests`. Then decide whether the code or the test is wrong |
