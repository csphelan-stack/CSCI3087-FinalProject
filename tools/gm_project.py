"""Shared helpers for the repo's check scripts: finding the GameMaker project
and reporting problems so GitHub shows them on the right file and line."""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

# Folders that never contain our own game code or data.
SKIP_DIRS = {".git", ".github", "tools", "node_modules", "extensions", "prefabs"}


@dataclass(frozen=True)
class Problem:
    path: Path
    line: int | None
    rule: str
    message: str


def find_project_dir(start: Path) -> Path:
    """Return the folder holding the one .yyp file under `start`."""
    matches = [
        p for p in start.rglob("*.yyp")
        if not any(part in SKIP_DIRS for part in p.relative_to(start).parts)
    ]
    if not matches:
        raise SystemExit(f"No .yyp file found under {start}. Pass --project-dir.")
    if len(matches) > 1:
        listed = "\n  ".join(str(m) for m in matches)
        raise SystemExit(f"More than one .yyp file found; pass --project-dir:\n  {listed}")
    return matches[0].parent


def is_skipped(path: Path, root: Path) -> bool:
    return any(part in SKIP_DIRS for part in path.relative_to(root).parts)


def report(problems: list[Problem], title: str, repo_root: Path) -> None:
    """Print each problem; inside GitHub Actions also emit an annotation."""
    in_actions = os.environ.get("GITHUB_ACTIONS") == "true"
    for p in problems:
        try:
            shown = p.path.resolve().relative_to(repo_root.resolve())
        except ValueError:
            shown = p.path
        where = f"{shown}:{p.line}" if p.line else f"{shown}"
        print(f"{where}: [{p.rule}] {p.message}")
        if in_actions:
            line_part = f",line={p.line}" if p.line else ""
            print(f"::error file={Path(shown).as_posix()}{line_part},title={title}: {p.rule}::{p.message}")
    sys.stdout.flush()
