#!/usr/bin/env python3
"""Proves the GML rule tests can fail: plants one bug at a time in a copy of the
rule scripts, runs the tests in the Node harness, and reports which tests
caught each bug. A bug that no test catches means a test is missing.

Run it after changing the rules or the tests (needs Node.js):
  python tools/gml_node/check_mutations.py --scripts tools/gml
  python tools/gml_node/check_mutations.py            # finds <project>/scripts

Each mutation is (script name, exact code to find, what to replace it with,
what the bug means in the game). If a script changed and the code is no
longer found, that mutation is reported as "skipped" so it can be updated.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent

MUTATIONS = [
    ("scr_rules_combat", "_unit.hp = max(0, _unit.hp - _amount);", "_unit.hp = _unit.hp - _amount;",
     "health can go below 0"),
    ("scr_rules_combat", "if (_unit.hp <= 0) {", "if (_unit.hp < 0) {",
     "a hit of exactly the remaining hp does not kill"),
    ("scr_rules_combat", "if (_unit.is_dead || !rules_is_amount(_amount)) {\n        return false;",
     "if (!rules_is_amount(_amount)) {\n        return false;", "a dead unit can die again"),
    ("scr_rules_combat", "&& !is_infinity(_value) && _value > 0;", "&& !is_infinity(_value) && _value > -1;",
     "a small negative amount such as -0.5 is applied (damage would heal)"),
    ("scr_rules_combat", "!is_nan(_value) && !is_infinity(_value) && _value > 0;", "!is_nan(_value) && _value > 0;",
     "infinite damage or healing is applied"),
    ("scr_rules_combat", "_unit.hp = min(_unit.max_hp, _unit.hp + _amount);", "_unit.hp = _unit.hp + _amount;",
     "healing can go above max hp"),
    ("scr_rules_combat", "if (_unit.is_dead || !rules_is_amount(_amount)) {\n        return 0;",
     "if (!rules_is_amount(_amount)) {\n        return 0;", "a dead unit can be healed"),
    ("scr_rules_combat", "if (!is_numeric(_unit.max_hp) || _unit.max_hp <= 0) {", "if (!is_numeric(_unit.max_hp)) {",
     "the health bar divides by zero"),
    ("scr_rules_combat", "max(1, floor(_max_hp)) : 1;", "_max_hp : 1;", "decimal max hp is not rounded down"),
    ("scr_rules_combat", "return _cooldown.remaining <= 0;", "return _cooldown.remaining < 0;",
     "a cooldown is never ready again"),
    ("scr_rules_combat", "if (!cooldown_ready(_cooldown)) {\n        return false;\n    }\n", "",
     "pressing during a cooldown restarts it"),
    ("scr_rules_combat", "_cooldown.remaining = max(0, _cooldown.remaining - 1);", "_cooldown.remaining = _cooldown.remaining - 1;",
     "a cooldown counts below 0"),
    ("scr_rules_combat", "_cooldown.remaining = _cooldown.length_frames;", "_cooldown.remaining = _cooldown.length_frames + 1;",
     "cooldowns last one frame too long"),
    ("scr_rules_combat", "if (_attack.hit_targets[_i] == _target) {\n            return false;", "if (false) {\n            return false;",
     "one swing hits the same enemy many times"),
    ("scr_rules_combat", "if (!_attack.swinging) {\n        return false;", "if (false) {\n        return false;",
     "touching an enemy without swinging hurts it"),
    ("scr_rules_combat", "_attack.hit_targets = [];\n    return true;", "return true;",
     "a new swing cannot hit an enemy the last swing hit"),
    ("scr_rules_combat", "return _dash.iframes_left > 0;", "return _dash.iframes_left > 1;",
     "the last i-frame does not protect"),
    ("scr_rules_combat", "_dash.iframes_left = _dash.iframe_length;", "_dash.iframes_left = _dash.iframe_length + 1;",
     "i-frames last one frame too long"),
    ("scr_rules_combat", "if (dash_is_invulnerable(_dash)) {\n        return false;", "if (false) {\n        return false;",
     "dashing gives no protection"),
    ("scr_rules_arena", "var _length = sqrt(_dx * _dx + _dy * _dy);", "var _length = 1;",
     "diagonal movement is faster"),
    ("scr_rules_arena", "return { x: clamp(_px, _left, _right), y: clamp(_py, _top, _bottom) };",
     "return { x: _px, y: clamp(_py, _top, _bottom) };", "the player can leave the arena sideways"),
    ("scr_rules_arena", "if (_enemy.stuck_frames > _limit_frames) {", "if (_enemy.stuck_frames >= _limit_frames) {",
     "enemies are sent back one frame early"),
    ("scr_rules_arena", "_moved_distance > RULES_STUCK_EPSILON", "_moved_distance >= 0",
     "a jittering enemy is never treated as stuck"),
    ("scr_rules_arena", "if (_player_dead) {\n        return \"game_over\";\n    }\n", "",
     "killing the last enemy saves a dying player"),
    ("scr_rules_arena", "if (_enemies_alive <= 0 && _enemies_left_to_spawn <= 0) {", "if (_enemies_alive <= 0) {",
     "a wave clears before all its enemies spawn"),
    ("scr_rules_arena", "return point_distance(_sx, _sy, _px, _py) >= _min_distance;",
     "return point_distance(_sx, _sy, _px, _py) > _min_distance;", "the exact minimum distance counts as unsafe"),
    ("scr_rules_arena", "if (array_length(_safe) == 0) {\n        return undefined;\n    }\n    return _safe[irandom(array_length(_safe) - 1)];",
     "return _points[irandom(array_length(_points) - 1)];", "enemies can spawn on the player"),
    ("scr_rules_arena", "if (_event == \"play\") return \"loading\";\n            break;\n        case \"loading\":",
     "if (_event == \"play\") return \"loading\";\n            break;\n        case \"loading\":\n            if (_event == \"play\") return \"loading\";",
     "(control: changes nothing a player could see)"),
    ("scr_rules_arena", "case \"dying\":\n            if (_event == \"fade_done\") return \"game_over\";",
     "case \"dying\":\n            if (_event == \"pause\") return \"paused\";\n            if (_event == \"fade_done\") return \"game_over\";",
     "pausing works during the death fade"),
    ("scr_rules_arena", "if (_event == \"player_died\") return \"dying\";", "if (_event == \"player_died\") return \"game_over\";",
     "death skips the fade"),
    ("scr_rules_arena", "if (_pick >= _last_index) {\n        _pick += 1;\n    }", "",
     "the same quip can play twice in a row"),
    ("scr_rules_arena", "_steps.frames_until_step = max(0, _steps.frames_until_step - 1);",
     "_steps.frames_until_step = _is_moving ? max(0, _steps.frames_until_step - 1) : 0;",
     "tapping a key plays footsteps faster than holding it"),
    ("scr_rules_arena", "return _playing_count < _max_overlapping;", "return _playing_count <= _max_overlapping;",
     "one sound copy too many can overlap"),
    ("scr_rules_data", "} catch (_e) {\n        array_push(_errors, \"file is not valid JSON\");\n        return undefined;\n    }",
     "} catch (_e) {\n        throw _e;\n    }", "broken JSON crashes the game"),
    ("scr_rules_data", "if (!is_string(_type) || !variable_struct_exists(_enemies, _type)) {",
     "if (!is_string(_type)) {", "waves can spawn enemy types that do not exist"),
    ("scr_rules_data", "|| _count != floor(_count)) {", ") {", "decimal spawn counts load"),
    ("scr_rules_data", "} else if (!data_is_number_at_least(_hp, 0) || _hp <= 0) {",
     "} else if (!data_is_number_at_least(_hp, 0)) {", "enemies with 0 hp load"),
    ("scr_rules_data", "} else if (variable_struct_exists(_result.enemies, _type)) {",
     "} else if (false) {", "a repeated enemy type replaces the first one"),
    ("scr_rules_data", "if (!is_struct(_data)) {", "if (false) {", "a JSON list at the top level crashes the loader"),
]


def find_scripts_dir(start: Path) -> Path:
    skip = {".git", ".github", "tools", "node_modules", "extensions", "prefabs"}
    found = [p for p in start.rglob("*.yyp") if not any(part in skip for part in p.relative_to(start).parts)]
    if len(found) != 1:
        raise SystemExit(f"Expected one .yyp file, found {len(found)}. Pass --scripts.")
    return found[0].parent / "scripts"


def run_tests(scripts: Path, out: Path) -> dict | None:
    out.mkdir(parents=True, exist_ok=True)
    subprocess.run(["node", str(HERE / "run.js"), "--scripts", str(scripts), "--out", str(out)],
                   capture_output=True, text=True, check=False)
    results = out / "test_results.json"
    return json.loads(results.read_text()) if results.exists() else None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--scripts", type=Path, help="folder holding the GML scripts")
    parser.add_argument("--json", type=Path, help="also write the results to this JSON file")
    args = parser.parse_args(argv)
    scripts = args.scripts or find_scripts_dir(Path.cwd())

    rows, missed = [], 0
    with tempfile.TemporaryDirectory() as tmp:
        work, out = Path(tmp) / "scripts", Path(tmp) / "out"
        shutil.copytree(scripts, work)
        baseline = run_tests(work, out)
        if not baseline or baseline["failed"] or baseline["crashed"]:
            print("The tests must all pass before planting bugs. Fix them first.")
            return 1
        files = {p.stem: p for p in work.rglob("*.gml")}
        for script, find, replace, meaning in MUTATIONS:
            path = files.get(script)
            original = path.read_text(encoding="utf-8") if path else ""
            if not path or original.count(find) != 1:
                rows.append({"bug": meaning, "script": script, "result": "skipped", "caught_by": []})
                print(f"SKIPPED  {script}: {meaning} (code not found; update MUTATIONS)")
                continue
            path.write_text(original.replace(find, replace), encoding="utf-8")
            results = run_tests(work, out)
            path.write_text(original, encoding="utf-8")
            caught = [t["name"] for t in (results or {}).get("tests", []) if t["status"] != "passed"]
            if results is None:
                caught = ["(the scripts no longer load)"]
            control = meaning.startswith("(control")
            status = "control" if control else ("caught" if caught else "MISSED")
            if status == "MISSED":
                missed += 1
            rows.append({"bug": meaning, "script": script, "result": status, "caught_by": caught})
            print(f"{status.upper():8} {script}: {meaning}  ->  {len(caught)} test(s) failed")

    if args.json:
        args.json.write_text(json.dumps(rows, indent=2))
    real = [r for r in rows if r["result"] in ("caught", "MISSED")]
    print(f"\n{len(real) - missed} of {len(real)} planted bugs were caught by at least one test.")
    return 1 if missed else 0


if __name__ == "__main__":
    sys.exit(main())
