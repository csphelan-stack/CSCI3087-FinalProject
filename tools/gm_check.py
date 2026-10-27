"""Helpers for validating GameMaker project files."""
import json
import re
import sys
from pathlib import Path


def parse_gm_json(text):
    """Parse GameMaker JSON, which allows trailing commas."""
    cleaned = re.sub(r",(\s*[}\]])", r"\1", text)
    return json.loads(cleaned)


def check_project(root):
    """Return a list of error strings for unparseable .yy/.yyp files."""
    errors = []
    for path in Path(root).rglob("*.yy*"):
        if path.suffix not in (".yy", ".yyp"):
            continue
        try:
            parse_gm_json(path.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError as exc:
            errors.append(f"{path}: {exc}")
    return errors


if __name__ == "__main__":
    problems = check_project(sys.argv[1] if len(sys.argv) > 1 else ".")
    for problem in problems:
        print(problem)
    sys.exit(1 if problems else 0)
