"""Proves check_test_results.py fails the pipeline for every kind of bad test run."""

import json
from pathlib import Path

import pytest

import check_test_results


def results_file(tmp_path: Path, **overrides) -> Path:
    data = {
        "status": "completed", "seed": 12345, "total": 2, "passed": 2, "failed": 0, "crashed": 0,
        "tests": [
            {"name": "damage exactly lethal sets hp to 0", "status": "passed", "message": ""},
            {"name": "heal never exceeds max hp", "status": "passed", "message": ""},
        ],
    }
    data.update(overrides)
    path = tmp_path / "test_results.json"
    path.write_text(json.dumps(data))
    return path


def test_all_passed(tmp_path):
    assert check_test_results.main([str(results_file(tmp_path))]) == 0


def test_a_failed_test_fails_the_run(tmp_path, capsys):
    tests = [{"name": "overkill leaves hp at 0", "status": "failed", "message": "expected 0 but got -5"}]
    path = results_file(tmp_path, total=1, passed=0, failed=1, tests=tests)
    assert check_test_results.main([str(path)]) == 1
    out = capsys.readouterr().out
    assert "FAILED: overkill leaves hp at 0 -- expected 0 but got -5" in out


def test_a_crashed_test_fails_the_run(tmp_path):
    tests = [{"name": "load missing file", "status": "crashed", "message": "variable not set"}]
    path = results_file(tmp_path, total=1, passed=0, crashed=1, tests=tests)
    assert check_test_results.main([str(path)]) == 1


def test_crash_outside_any_test_fails_the_run(tmp_path, capsys):
    tests = [{"name": "game startup (outside any test)", "status": "crashed", "message": "obj_title Create: audio error"}]
    path = results_file(tmp_path, status="crashed", total=0, passed=0, crashed=1, tests=tests)
    assert check_test_results.main([str(path)]) == 1
    assert "did not complete" in capsys.readouterr().out


def test_zero_tests_fails_the_run(tmp_path, capsys):
    path = results_file(tmp_path, total=0, passed=0, tests=[])
    assert check_test_results.main([str(path)]) == 1
    assert "No tests ran" in capsys.readouterr().out


def test_missing_results_file_fails_the_run(tmp_path, capsys):
    assert check_test_results.main([str(tmp_path / "nope.json")]) == 1
    assert "No results file" in capsys.readouterr().out


@pytest.mark.parametrize("content", ["", '{"status": "completed", "tests": [', "not json"])
def test_truncated_results_file_fails_the_run(tmp_path, content):
    path = tmp_path / "test_results.json"
    path.write_text(content)
    assert check_test_results.main([str(path)]) == 1


def test_wrong_arguments(capsys):
    assert check_test_results.main([]) == 2


def test_github_annotations_and_summary(tmp_path, monkeypatch, capsys):
    summary = tmp_path / "summary.md"
    monkeypatch.setenv("GITHUB_ACTIONS", "true")
    monkeypatch.setenv("GITHUB_STEP_SUMMARY", str(summary))
    tests = [
        {"name": "dash | i-frames", "status": "failed", "message": "hit on last i-frame\nwas counted"},
        {"name": "heal never exceeds max hp", "status": "passed", "message": ""},
    ]
    path = results_file(tmp_path, total=2, passed=1, failed=1, tests=tests)
    assert check_test_results.main([str(path)]) == 1
    out = capsys.readouterr().out
    assert "::error title=GML test failed: dash \\| i-frames::hit on last i-frame was counted" in out
    table = summary.read_text()
    assert "| failed | dash \\| i-frames | hit on last i-frame was counted |" in table
    assert table.index("| failed |") < table.index("| passed |")
