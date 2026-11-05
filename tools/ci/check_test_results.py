#!/usr/bin/env python3
"""Decides whether the GML test run passed, from the test_results.json the game wrote.

Fails (exit code 1) when:
  - the results file is missing (the game crashed before or during the run)
  - the run did not complete, or an error happened outside any test
  - no tests ran at all (the test scripts were not loaded)
  - any test failed or crashed

Inside GitHub Actions it also adds an error annotation per failing test and a
results table to the run's summary page.

Usage:
  python tools/ci/check_test_results.py test-output/test_results.json
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def escape(text: str) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")


def summarize(results: dict) -> tuple[bool, list[str]]:
    """Return (passed, lines to print)."""
    lines: list[str] = []
    tests = results.get("tests") or []
    status = results.get("status")
    failing = [t for t in tests if t.get("status") != "passed"]

    lines.append(f"Tests: {results.get('total', len(tests))} total, {results.get('passed', 0)} passed, "
                 f"{results.get('failed', 0)} failed, {results.get('crashed', 0)} crashed "
                 f"(random seed {results.get('seed', 'unknown')})")
    for t in failing:
        lines.append(f"  {str(t.get('status', '?')).upper()}: {t.get('name')} -- {t.get('message', '')}")

    if status != "completed":
        lines.append(f"The test run did not complete (status: {status}). Read game-log.txt in the test-output artifact.")
        return False, lines
    if not tests:
        lines.append("No tests ran. Check that the test scripts are in the GameMaker project, not only in tools/gml.")
        return False, lines
    return not failing, lines


def write_github_outputs(results: dict, passed: bool) -> None:
    if os.environ.get("GITHUB_ACTIONS") != "true":
        return
    for t in results.get("tests") or []:
        if t.get("status") != "passed":
            print(f"::error title=GML test {t.get('status')}: {escape(t.get('name'))}::{escape(t.get('message', ''))}")
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    rows = [
        "## GML test results",
        "",
        f"**{'Passed' if passed else 'Failed'}**: {results.get('passed', 0)} passed, "
        f"{results.get('failed', 0)} failed, {results.get('crashed', 0)} crashed, seed {results.get('seed', '?')}",
        "",
        "| Result | Test | Message |",
        "| --- | --- | --- |",
    ]
    tests = sorted(results.get("tests") or [], key=lambda t: t.get("status") == "passed")
    for t in tests:
        rows.append(f"| {t.get('status')} | {escape(t.get('name'))} | {escape(t.get('message', ''))} |")
    with open(summary_path, "a", encoding="utf-8") as fh:
        fh.write("\n".join(rows) + "\n")


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 1:
        print(__doc__)
        return 2
    path = Path(argv[0])
    if not path.is_file():
        print(f"No results file at {path}. The game crashed or never reached the test runner; "
              "read game-log.txt in the test-output artifact.")
        return 1
    try:
        results = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as e:
        print(f"{path} is not valid JSON ({e}); the game may have crashed while writing it.")
        return 1

    passed, lines = summarize(results)
    print("\n".join(lines))
    write_github_outputs(results, passed)
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
