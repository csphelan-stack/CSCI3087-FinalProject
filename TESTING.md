# Testing and CI

Every push to any branch, and every pull request into `main`, runs `.github/workflows/ci.yml`:

| Job | Runs on | What it does | Fails when |
| --- | --- | --- | --- |
| Style and data checks | Ubuntu | Tests the checkers themselves (pytest), checks for a CREDITS file, validates the JSON data, checks style rules | A checker test fails, CREDITS is missing, a data file is broken, or a style rule is broken |
| Game rule tests (fast, Node.js) | Ubuntu, alongside the first job | Runs the GML test framework, rule scripts and their tests in Node.js with stand-ins for GameMaker built-ins | Any GML test fails or crashes, or no tests ran |
| Build game and run GML tests | Windows, after both jobs pass | Builds the game with Igor, starts it with `--run-tests`, reads `test_results.json` | The build fails, any GML test fails or crashes, no tests ran, or the game does not close within 5 minutes |

## What is in this folder

| Path | Purpose |
| --- | --- |
| `.github/workflows/ci.yml` | The pipeline: triggers, jobs and steps |
| `tools/gml/scr_test_framework.gml` | GML test framework: `test_case()`, assertions, the runner |
| `tools/gml/scr_tests_framework_selftest.gml` | 29 tests proving every assertion fails on bad input |
| `tools/gml/scr_rules_combat.gml` | Health, damage, healing, potions, cooldowns, melee attack, dash i-frames |
| `tools/gml/scr_rules_arena.gml` | Movement, arena edges, stuck enemies, waves, spawning, game states, restarts, quips, footsteps, sound caps |
| `tools/gml/scr_rules_data.gml` | Loads `enemies.json` and `waves.json`, skipping bad entries |
| `tools/gml/scr_tests_rules_*.gml` | 99 game-rule tests (42 combat, 40 arena, 17 data) |
| `tools/gml_node/run.js` | Runs the GML tests in Node.js |
| `tools/gml_node/check_mutations.py` | Plants 38 bugs one at a time and checks a test catches each |
| `tools/check_style.py` | Our style rules |
| `tools/validate_data.py` | JSON data checks |
| `tools/ci/run-gml-tests.ps1` | On Windows: unzips the build, runs the game in test mode, collects the results |
| `tools/ci/check_test_results.py` | Turns `test_results.json` into pass or fail |
| `tools/tests/` | 125 pytest cases for the Python checkers and the Node harness, plus 13 broken JSON files |
| `docs/ai-prompts.md` | Template for the team's AI prompt log |

## One-time setup

1. **Copy these files into the repo root** (the folder with `.github`, next to or above the `.yyp`).
2. **Add the eight GML scripts to the GameMaker project.** GameMaker only loads scripts listed in the `.yyp`, so a `.gml` file dropped into a folder is ignored. In the IDE, create Script assets with exactly these names, replace each one's contents with the matching file from `tools/gml/`, and save:
   `scr_test_framework`, `scr_tests_framework_selftest`, `scr_rules_combat`, `scr_rules_arena`, `scr_rules_data`, `scr_tests_rules_combat`, `scr_tests_rules_arena`, `scr_tests_rules_data`.
   Then delete `tools/gml/`; from now on the scripts live in the project.
3. **Wire the rules into the objects.** The tests check the rule functions, so the game must use them. For example, in the player's collision with an enemy attack: `player_take_hit(id, dash, other.damage)` instead of `hp -= other.damage`. Units need `hp`, `max_hp` and `is_dead` variables; enemies need `stuck_frames = 0` in their Create event.
4. **Put the data in the loader's layout** in Included Files: `enemies.json` as `{"enemies": [{"type": "slime", "hp": 10, "damage": 2, "move_speed": 1.5}]}` and `waves.json` as `{"waves": [{"spawns": [{"type": "slime", "count": 3}]}]}`. If our files use other names or keys, change `scr_rules_data` and the settings at the top of `tools/validate_data.py` together.
5. **Add the GameMaker access key.** One teammate signs in at gamemaker.io, opens Account > Access Keys, and generates a key. In GitHub, open Settings > Secrets and variables > Actions, add a secret named `ACCESS_KEY`, and paste the key. Never commit the key.
6. **Add a `CREDITS` file** listing every third-party asset and its license.
7. **Turn on branch protection** for `main` (Settings > Branches): require a pull request, one approval, and the status checks "Style and data checks", "Game rule tests (fast, Node.js)" and "Build game and run GML tests".

The first run will probably flag existing code (default names like `Room1`, scripts without a header comment, stray `show_debug_message` calls). Fix those in one commit. `python tools/check_style.py --fix-whitespace` strips trailing whitespace automatically.

## Writing a GML test

Rule functions go in a script named `scr_rules_*`; their tests go in `scr_tests_rules_*`. Name every test `feature / kind / what it checks`, where kind is `normal`, `boundary`, `invalid` or `adversarial`:

```gml
/// scr_tests_rules_example
/// Shows the four kinds of test for one rule.

test_case("health / boundary / damage equal to hp leaves 0 hp and kills", function () {
    var _unit = health_create(10);
    assert_true(health_apply_damage(_unit, 10), "the killing hit returns true");
    assert_equal(_unit.hp, 0);
});

test_case("health / adversarial / 5000 random hits and heals keep hp between 0 and max", function () {
    var _unit = health_create(50);
    for (var _i = 0; _i < 5000; _i++) {
        if (irandom(1) == 0) {
            health_apply_damage(_unit, irandom_range(-20, 60));
        } else {
            health_apply_heal(_unit, irandom_range(-20, 60));
        }
        assert_in_range(_unit.hp, 0, _unit.max_hp, "hp after step " + string(_i));
    }
});
```

Assertions: `assert_true`, `assert_false`, `assert_equal`, `assert_not_equal`, `assert_near` (decimals), `assert_in_range` (inclusive), `assert_finite` (no NaN or infinity), `assert_throws`, `assert_no_throw`, and `fail`.

Rules that keep tests reliable and runnable in both places:

- **Test both sides of every boundary:** N-1, N and N+1 (for example 299, 300 and 301 frames).
- **Count frames, never real time.**
- **Randomness is repeatable:** the runner resets the seed to 12345 before every test.
- **Join text with text only:** `"step " + string(_i)`, never `"step " + _i` (GameMaker stops with an error).
- **Rule and rule-test scripts must run in Node too:** use `for` loops instead of `repeat`, and avoid `with`, `self`, `other` and instances. Tests that need rooms or instances go in a script named `scr_tests_engine_*`; those run only in the Windows job.
- **A function inside a test cannot see the test's `var` variables** (GML has no closures). Use `method({ unit: _unit }, function () { ... })` to pass data in.
- **Break the code on purpose before merging a new test**, or run `check_mutations.py`. A test that cannot fail proves nothing.

## Running the checks on your own computer

```bash
pip install -r tools/requirements-dev.txt
python -m pytest tools/tests -q                 # the checkers' own tests
python tools/validate_data.py                   # JSON data
python tools/check_style.py                     # style rules
node tools/gml_node/run.js                      # GML rule tests in Node.js
python tools/ci/check_test_results.py test-output-node/test_results.json
python tools/gml_node/check_mutations.py        # plant 38 bugs, check each is caught
```

To run the GML tests inside GameMaker, build the game (Build > Create Executable, zip), unzip it, and run `YourGame.exe --run-tests`. The results go to `%LOCALAPPDATA%\<game name>\test_results.json`; check them with `python tools/ci/check_test_results.py <that file>`.

## When the pipeline fails

Open the run in the Actions tab and find the first red step. Failing tests and style problems also appear as annotations on the changed files, and the run's summary page has a table of test results. The `test-output` and `test-output-node` artifacts contain `test_results.json` and (for Windows) `game-log.txt`.

| Red step | Usual cause | What to do |
| --- | --- | --- |
| Test the checkers | Someone changed a checker and broke it | Run `python -m pytest tools/tests` locally and fix the checker |
| Check that a CREDITS file exists | File deleted or renamed | Restore `CREDITS` |
| Validate JSON data files | Broken JSON, duplicate key, stat out of range, unknown enemy | The message names the file and field; fix the data |
| Check style rules | Code breaks a style rule | The message names the file, line and rule; fix it, or change the rule for the whole team |
| Run the GML rule tests in Node.js | Unsupported GML in a rule or rule-test script, or a syntax error | The message names the file and line; see the rules above |
| Check test results (either job) | A test failed or crashed | Reproduce with `node tools/gml_node/run.js`; decide whether the code or the test is wrong |
| Check that the ACCESS_KEY secret is set / Install GameMaker build tools | Secret missing or expired; runtime download failed | Regenerate the key and update the secret; re-run the job |
| Build Windows game | Compile error, or a script not registered in the `.yyp` | Read the Igor output in the step log; build locally to reproduce |
| Run the game in test mode | The game did not close within 5 minutes | A test is stuck in a loop or the game never reached the runner; read `game-log.txt` |
