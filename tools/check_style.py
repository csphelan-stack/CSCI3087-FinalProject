#!/usr/bin/env python3
"""Checks Team 1's GML style rules and exits with code 1 if any are broken.

Rules (Section 2 of the testing plan):
  naming          asset folders start with their prefix (obj_, scr_, spr_, rm_, snd_)
  header          every script starts with a comment saying what it does
  hardcoded-stat  stat variables are not set to number literals in GML;
                  stat values come from the JSON data files
  debug-output    no show_debug_message / show_message outside test assets
  test-room       no code outside test assets refers to a test room (rm_test*),
                  and the game does not start in a test room
  whitespace      no trailing spaces or tabs at the end of a line
  indentation     each file indents with tabs or with spaces, not both

Test assets (names starting with scr_test, obj_test or rm_test) may use debug
output, refer to test rooms and set stats directly.

Usage:
  python tools/check_style.py
  python tools/check_style.py --project-dir path/to/project
  python tools/check_style.py --fix-whitespace   # strip trailing whitespace first
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gm_project import Problem, find_project_dir, is_skipped, report  # noqa: E402

# --- Settings the team can change ---------------------------------------------

ASSET_PREFIXES = {
    "objects": "obj_",
    "scripts": "scr_",
    "sprites": "spr_",
    "rooms": "rm_",
    "sounds": "snd_",
}

TEST_ASSET_PREFIXES = ("scr_test", "obj_test", "rm_test")

# Variables that hold a gameplay stat. Setting one of these to a number literal
# (other than 0) in GML counts as a hardcoded stat.
STAT_NAMES = (
    "hp", "max_hp", "hp_max",
    "damage", "attack_damage", "contact_damage",
    "move_speed", "walk_speed", "dash_speed", "dash_distance",
    "attack_cooldown", "dash_cooldown",
    "iframes", "iframe_frames", "invuln_frames",
    "knockback", "spawn_count", "enemy_count",
)

# Assets whose names contain one of these may set stats directly, because they
# are where JSON values are loaded or defaulted.
STAT_LOADER_HINTS = ("load", "data", "config")

DEBUG_FUNCTIONS = ("show_debug_message", "show_message", "show_message_async")

# --- Implementation ----------------------------------------------------------------

STAT_PATTERN = re.compile(
    r"\b(?P<name>" + "|".join(sorted(STAT_NAMES, key=len, reverse=True)) + r")\b"
    r"\s*(?:=(?!=)|:)\s*(?P<value>-?\d+(?:\.\d+)?)(?![\w.])"
)
DEBUG_PATTERN = re.compile(r"\b(?P<fn>" + "|".join(DEBUG_FUNCTIONS) + r")\s*\(")
TEST_ROOM_PATTERN = re.compile(r"\brm_test\w*")
FIRST_ROOM_PATTERN = re.compile(r'"RoomOrderNodes"\s*:\s*\[\s*\{.*?"name"\s*:\s*"(?P<name>[^"]+)"', re.S)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def strip_comments_and_strings(text: str) -> str:
    """Blank out comments and string literals, keeping line breaks, so code
    patterns never match inside a comment or a string."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if c == "/" and nxt == "/":
            while i < n and text[i] != "\n":
                out.append(" ")
                i += 1
        elif c == "/" and nxt == "*":
            out.append("  ")
            i += 2
            while i < n and not (text[i] == "*" and i + 1 < n and text[i + 1] == "/"):
                out.append("\n" if text[i] == "\n" else " ")
                i += 1
            if i < n:
                out.append("  ")
                i += 2
        elif c in "\"'":
            quote = c
            out.append(" ")
            i += 1
            while i < n and text[i] != quote and text[i] != "\n":
                if text[i] == "\\" and i + 1 < n and text[i + 1] != "\n":
                    out.append("  ")
                    i += 2
                    continue
                out.append(" ")
                i += 1
            if i < n and text[i] == quote:
                out.append(" ")
                i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def line_of(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def asset_name(path: Path, project_dir: Path) -> str:
    parts = path.relative_to(project_dir).parts
    if len(parts) >= 3 and parts[0] in ("objects", "scripts", "rooms"):
        return parts[1]
    return path.stem


def is_test_asset(name: str) -> bool:
    return name.startswith(TEST_ASSET_PREFIXES)


def gml_files(project_dir: Path) -> list[Path]:
    return sorted(p for p in project_dir.rglob("*.gml") if not is_skipped(p, project_dir))


def check_naming(project_dir: Path) -> list[Problem]:
    problems = []
    for folder, prefix in ASSET_PREFIXES.items():
        base = project_dir / folder
        if not base.is_dir():
            continue
        for asset in sorted(d for d in base.iterdir() if d.is_dir()):
            if not asset.name.startswith(prefix):
                problems.append(Problem(asset, None, "naming",
                                        f"{folder[:-1]} '{asset.name}' should start with '{prefix}'"))
    return problems


def check_header(path: Path, text: str, project_dir: Path) -> list[Problem]:
    if path.relative_to(project_dir).parts[0] != "scripts":
        return []
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith(("//", "/*")):
            return []
        return [Problem(path, number, "header",
                        "script must start with a comment saying what it does and what it takes in")]
    return [Problem(path, 1, "header", "script is empty")]


def check_hardcoded_stats(path: Path, code: str, name: str) -> list[Problem]:
    if is_test_asset(name) or any(h in name.lower() for h in STAT_LOADER_HINTS):
        return []
    problems = []
    for m in STAT_PATTERN.finditer(code):
        if float(m.group("value")) == 0:
            continue
        problems.append(Problem(path, line_of(code, m.start()), "hardcoded-stat",
                                f"'{m.group('name')}' is set to {m.group('value')}; load it from the JSON data instead"))
    return problems


def check_debug_output(path: Path, code: str, name: str) -> list[Problem]:
    if is_test_asset(name):
        return []
    return [Problem(path, line_of(code, m.start()), "debug-output",
                    f"remove {m.group('fn')}() or move it into a test asset")
            for m in DEBUG_PATTERN.finditer(code)]


def check_test_room_refs(path: Path, code: str, name: str) -> list[Problem]:
    if is_test_asset(name):
        return []
    return [Problem(path, line_of(code, m.start()), "test-room",
                    f"'{m.group(0)}' is a test room and must not be reachable from game code")
            for m in TEST_ROOM_PATTERN.finditer(code)]


def check_first_room(project_dir: Path) -> list[Problem]:
    problems = []
    for yyp in project_dir.glob("*.yyp"):
        m = FIRST_ROOM_PATTERN.search(read_text(yyp))
        if m and m.group("name").startswith("rm_test"):
            problems.append(Problem(yyp, None, "test-room",
                                    f"the game starts in test room '{m.group('name')}'; move a real room to the top of the room order"))
    return problems


def check_whitespace(path: Path, text: str) -> list[Problem]:
    bad = [i for i, line in enumerate(text.splitlines(), start=1) if line != line.rstrip(" \t")]
    if not bad:
        return []
    return [Problem(path, bad[0], "whitespace",
                    f"{len(bad)} line(s) end with spaces or tabs (first at line {bad[0]}); run with --fix-whitespace")]


def check_indentation(path: Path, text: str) -> list[Problem]:
    tab_lines, space_lines = [], []
    for number, line in enumerate(text.splitlines(), start=1):
        body = line.lstrip(" \t")
        if not body or line == body or body.startswith("*"):
            continue
        (tab_lines if line[0] == "\t" else space_lines).append(number)
    if tab_lines and space_lines:
        minority = tab_lines if len(tab_lines) < len(space_lines) else space_lines
        return [Problem(path, minority[0], "indentation",
                        f"file indents {len(tab_lines)} line(s) with tabs and {len(space_lines)} with spaces; pick one")]
    return []


def fix_whitespace(path: Path) -> bool:
    raw = path.read_bytes()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig", errors="replace")
    newline = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    fixed = newline.join(line.rstrip(" \t") for line in lines)
    if text.endswith(("\n", "\r")):
        fixed += newline
    if fixed == text:
        return False
    path.write_bytes((b"\xef\xbb\xbf" if bom else b"") + fixed.encode("utf-8"))
    return True


def check_project(project_dir: Path) -> list[Problem]:
    problems = check_naming(project_dir) + check_first_room(project_dir)
    for path in gml_files(project_dir):
        text = read_text(path)
        code = strip_comments_and_strings(text)
        name = asset_name(path, project_dir)
        problems += check_header(path, text, project_dir)
        problems += check_hardcoded_stats(path, code, name)
        problems += check_debug_output(path, code, name)
        problems += check_test_room_refs(path, code, name)
        problems += check_whitespace(path, text)
        problems += check_indentation(path, text)
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project-dir", type=Path, help="folder containing the .yyp file")
    parser.add_argument("--fix-whitespace", action="store_true", help="strip trailing whitespace before checking")
    args = parser.parse_args(argv)

    repo_root = Path.cwd()
    project_dir = args.project_dir or find_project_dir(repo_root)

    if args.fix_whitespace:
        changed = [p for p in gml_files(project_dir) if fix_whitespace(p)]
        print(f"Removed trailing whitespace from {len(changed)} file(s).")

    problems = check_project(project_dir)
    if problems:
        report(problems, "Style", repo_root)
        print(f"\nStyle check failed: {len(problems)} problem(s).")
        return 1
    print(f"Style check passed ({len(gml_files(project_dir))} GML files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
