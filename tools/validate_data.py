#!/usr/bin/env python3
"""Checks the game's JSON data files and exits with code 1 if any are broken.

For every .json file in the data folder (GameMaker's datafiles folder by default):
  parse        the file is not empty and is strict JSON (no NaN, Infinity,
               comments or trailing commas)
  duplicate    no object repeats a key (the later value would silently win)
  stat-range   stat fields hold numbers in range:
                 *_count            whole number, 0 or more
                 hp, health         more than 0
                 damage, speed, cooldown, delay, ...   0 or more
  enemy-ref    every enemy type a wave uses is defined in an enemy file
               (runs once the settings below are filled in)

Field names are matched by their last word, so max_hp, enemyCount and
spawn_delay are all checked. A field such as damage_type is not a stat.

Usage:
  python tools/validate_data.py
  python tools/validate_data.py --data-dir path/to/datafiles
  python tools/validate_data.py --expect-invalid tools/tests/data/invalid
      Checks that every file in that folder is rejected. Use it to prove the
      validator catches broken data, with one intentionally broken file per case.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import math
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gm_project import Problem, find_project_dir, report  # noqa: E402

# --- Settings the team can change ---------------------------------------------

COUNT_WORDS = {"count"}
POSITIVE_WORDS = {"hp", "health"}
NON_NEGATIVE_WORDS = {
    "damage", "speed", "cooldown", "delay", "duration", "iframes", "frames",
    "range", "radius", "knockback", "interval", "heal", "weight", "time",
}

# Cross-reference between wave files and enemy files. Leave as None until the
# team fills these in to match our JSON layout. Example:
#   ENEMY_FILE_PATTERN = "enemies*.json"; ENEMY_ID_KEY = "type"
#   WAVE_FILE_PATTERN  = "waves*.json";   WAVE_ENEMY_KEY = "enemy"
# Set ENEMY_ID_KEY = "__keys__" if the enemy file is an object keyed by type,
# e.g. {"slime": {...}, "skeleton": {...}}.
ENEMY_FILE_PATTERN: str | None = None
ENEMY_ID_KEY: str | None = None
WAVE_FILE_PATTERN: str | None = None
WAVE_ENEMY_KEY: str | None = None

# --- Implementation ----------------------------------------------------------------


class _StrictParseError(ValueError):
    pass


def _reject_constant(name: str):
    raise _StrictParseError(f"{name} is not allowed in JSON")


def stat_word(key: str) -> str | None:
    """Return the stat word a field name ends with, or None if it is not a stat."""
    snake = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", key).lower()
    words = [w for w in re.split(r"[^a-z0-9]+", snake) if w]
    if not words:
        return None
    last = words[-1]
    if last in ("max", "min") and len(words) > 1:
        last = words[-2]
    if last in COUNT_WORDS | POSITIVE_WORDS | NON_NEGATIVE_WORDS:
        return last
    return None


def is_number(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def check_stat(path: Path, where: str, key: str, value) -> list[Problem]:
    word = stat_word(key)
    if word is None:
        return []
    label = f"{where}.{key}" if where else key
    if not is_number(value) or not math.isfinite(value):
        return [Problem(path, None, "stat-range", f"{label} should be a number but is {json.dumps(value)}")]
    if word in COUNT_WORDS:
        if value != int(value) or value < 0:
            return [Problem(path, None, "stat-range", f"{label} should be a whole number 0 or more but is {value}")]
    elif word in POSITIVE_WORDS:
        if value <= 0:
            return [Problem(path, None, "stat-range", f"{label} should be more than 0 but is {value}")]
    elif value < 0:
        return [Problem(path, None, "stat-range", f"{label} should be 0 or more but is {value}")]
    return []


def walk_stats(path: Path, node, where: str = "") -> list[Problem]:
    problems = []
    if isinstance(node, dict):
        for key, value in node.items():
            problems += check_stat(path, where, key, value)
            child = f"{where}.{key}" if where else key
            if isinstance(value, (dict, list)):
                problems += walk_stats(path, value, child)
    elif isinstance(node, list):
        for i, item in enumerate(node):
            problems += walk_stats(path, item, f"{where}[{i}]")
    return problems


def load_json(path: Path) -> tuple[object | None, list[Problem]]:
    problems: list[Problem] = []
    raw = path.read_text(encoding="utf-8-sig", errors="replace")
    if not raw.strip():
        return None, [Problem(path, None, "parse", "file is empty")]

    def no_duplicates(pairs):
        seen = set()
        for key, _ in pairs:
            if key in seen:
                problems.append(Problem(path, None, "duplicate", f"key '{key}' appears more than once in the same object"))
            seen.add(key)
        return dict(pairs)

    try:
        data = json.loads(raw, object_pairs_hook=no_duplicates, parse_constant=_reject_constant)
    except _StrictParseError as e:
        return None, [Problem(path, None, "parse", str(e))]
    except json.JSONDecodeError as e:
        return None, [Problem(path, e.lineno, "parse", f"invalid JSON: {e.msg} (column {e.colno})")]
    if not isinstance(data, (dict, list)):
        problems.append(Problem(path, None, "parse", "top level must be an object or an array"))
    return data, problems


def collect_values(node, key: str) -> list:
    found = []
    if isinstance(node, dict):
        for k, v in node.items():
            if k == key:
                found.append(v)
            found += collect_values(v, key)
    elif isinstance(node, list):
        for item in node:
            found += collect_values(item, key)
    return found


def cross_ref_configured() -> bool:
    return all([ENEMY_FILE_PATTERN, ENEMY_ID_KEY, WAVE_FILE_PATTERN, WAVE_ENEMY_KEY])


def enemy_ids(files: dict[Path, object]) -> set[str]:
    ids: set[str] = set()
    for path, data in files.items():
        if not fnmatch.fnmatch(path.name, ENEMY_FILE_PATTERN):
            continue
        if ENEMY_ID_KEY == "__keys__" and isinstance(data, dict):
            ids |= set(data.keys())
        else:
            ids |= {v for v in collect_values(data, ENEMY_ID_KEY) if isinstance(v, str)}
    return ids


def check_enemy_refs(path: Path, data, known: set[str]) -> list[Problem]:
    if not fnmatch.fnmatch(path.name, WAVE_FILE_PATTERN):
        return []
    problems = []
    for value in collect_values(data, WAVE_ENEMY_KEY):
        if not isinstance(value, str) or value not in known:
            problems.append(Problem(path, None, "enemy-ref",
                                    f"wave uses unknown enemy type {json.dumps(value)}; known types: {', '.join(sorted(known)) or 'none'}"))
    return problems


def check_files(paths: list[Path], known_enemies: set[str] | None = None) -> dict[Path, list[Problem]]:
    """Check each file. Returns problems per file (an empty list means the file passed)."""
    loaded: dict[Path, object] = {}
    results: dict[Path, list[Problem]] = {}
    for path in paths:
        data, problems = load_json(path)
        if data is not None:
            loaded[path] = data
            problems += walk_stats(path, data)
        results[path] = problems
    if cross_ref_configured():
        known = enemy_ids(loaded) | (known_enemies or set())
        for path, data in loaded.items():
            results[path] += check_enemy_refs(path, data, known)
    return results


def json_files(folder: Path) -> list[Path]:
    return sorted(p for p in folder.rglob("*.json") if p.is_file())


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project-dir", type=Path, help="folder containing the .yyp file")
    parser.add_argument("--data-dir", type=Path, help="folder with the JSON data (default: <project>/datafiles)")
    parser.add_argument("--expect-invalid", type=Path, metavar="DIR",
                        help="check that every JSON file in DIR is rejected")
    args = parser.parse_args(argv)

    repo_root = Path.cwd()
    data_dir = args.data_dir
    if data_dir is None:
        data_dir = (args.project_dir or find_project_dir(repo_root)) / "datafiles"

    files = json_files(data_dir) if data_dir.is_dir() else []

    if args.expect_invalid:
        known = enemy_ids({p: d for p in files for d, _ in [load_json(p)] if d is not None}) if cross_ref_configured() else None
        broken = json_files(args.expect_invalid)
        if not broken:
            print(f"No JSON files found in {args.expect_invalid}.")
            return 1
        accepted = [p for p, problems in check_files(broken, known).items() if not problems]
        for path in accepted:
            print(f"{path}: the validator accepted this file, but it is supposed to be invalid")
        if accepted:
            return 1
        print(f"Validator rejected all {len(broken)} intentionally broken file(s).")
        return 0

    if not files:
        print(f"::warning::No JSON data files found in {data_dir}; nothing to validate.")
        return 0

    if not cross_ref_configured():
        print("Note: the enemy-ref check is off until the settings at the top of validate_data.py are filled in.")

    problems = [p for file_problems in check_files(files).values() for p in file_problems]
    if problems:
        report(problems, "Data", repo_root)
        print(f"\nData validation failed: {len(problems)} problem(s) in {len(files)} file(s).")
        return 1
    print(f"Data validation passed ({len(files)} file(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
