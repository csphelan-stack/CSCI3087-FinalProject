"""Proves the Node.js harness (tools/gml_node/run.js) reports failures, crashes
and unsupported GML instead of passing them. Skipped if Node.js is missing."""

import json
import shutil
import subprocess
from pathlib import Path

import pytest

from conftest import write

TOOLS = Path(__file__).resolve().parents[1]
RUN_JS = TOOLS / "gml_node" / "run.js"

pytestmark = pytest.mark.skipif(shutil.which("node") is None, reason="Node.js is not installed")


def framework_source() -> Path:
    """The real test framework: in tools/gml before it is imported into
    GameMaker, in the project's scripts folder after."""
    staged = TOOLS / "gml" / "scr_test_framework.gml"
    if staged.exists():
        return staged
    return next(p for p in TOOLS.parent.rglob("scr_test_framework.gml") if ".git" not in p.parts)


def run(tmp_path: Path, tests: str, rules: str = "") -> tuple[int, dict | None, str]:
    scripts = tmp_path / "scripts"
    (scripts / "scr_test_framework").mkdir(parents=True)
    shutil.copy(framework_source(), scripts / "scr_test_framework" / "scr_test_framework.gml")
    write(scripts / "scr_tests_rules_demo/scr_tests_rules_demo.gml", tests)
    if rules:
        write(scripts / "scr_rules_demo/scr_rules_demo.gml", rules)
    out = tmp_path / "out"
    proc = subprocess.run(["node", str(RUN_JS), "--scripts", str(scripts), "--out", str(out)],
                          capture_output=True, text=True, check=False)
    results_file = out / "test_results.json"
    results = json.loads(results_file.read_text()) if results_file.exists() else None
    return proc.returncode, results, proc.stdout + proc.stderr


RULE = "/// demo rule\nfunction demo_clamp_hp(_hp) {\n    return max(0, _hp);\n}\n"


def test_passing_test_is_reported_as_passed(tmp_path):
    code, results, _ = run(tmp_path, 'test_case("demo", function () { assert_equal(demo_clamp_hp(-5), 0); });\n', RULE)
    assert code == 0
    assert (results["total"], results["passed"]) == (1, 1)


def test_failing_assertion_is_reported_as_failed(tmp_path):
    code, results, _ = run(tmp_path, 'test_case("demo", function () { assert_equal(demo_clamp_hp(-5), -5); });\n', RULE)
    assert code == 0
    assert results["failed"] == 1
    assert "expected -5 but got 0" in results["tests"][0]["message"]


def test_calling_a_missing_function_is_reported_as_crashed(tmp_path):
    _, results, _ = run(tmp_path, 'test_case("demo", function () { no_such_function(); });\n')
    assert results["crashed"] == 1


def test_wrong_type_to_a_builtin_crashes_like_gamemaker(tmp_path):
    _, results, _ = run(tmp_path, 'test_case("demo", function () { var _a = max(0, "5"); });\n')
    assert results["crashed"] == 1
    assert "number expected" in results["tests"][0]["message"]


def test_reading_a_struct_field_from_an_array_crashes_like_gamemaker(tmp_path):
    _, results, _ = run(tmp_path, 'test_case("demo", function () { var _v = variable_struct_get([1], "a"); });\n')
    assert results["crashed"] == 1


@pytest.mark.parametrize("code_line", [
    "repeat (3) { }",
    "with (obj_player) { }",
    "var _f = (a) => a;",
    "if (1 === 1) { }",
    "let _x = 1;",
    "var _n = [1, 2].length;",
])
def test_unsupported_gml_is_refused(tmp_path, code_line):
    code, results, output = run(tmp_path, f'test_case("demo", function () {{ {code_line} }});\n')
    assert code == 2
    assert results is None
    assert "cannot run in the Node harness" in output


def test_forbidden_words_inside_strings_and_comments_are_fine(tmp_path):
    tests = '// repeat with let\ntest_case("repeat with let in a name", function () { assert_true(true); });\n'
    code, results, _ = run(tmp_path, tests)
    assert code == 0 and results["passed"] == 1


def test_macros_from_one_script_work_in_another(tmp_path):
    rules = "/// demo\n#macro DEMO_LIMIT 300\nfunction demo_limit() {\n    return DEMO_LIMIT;\n}\n"
    _, results, _ = run(tmp_path, 'test_case("demo", function () { assert_equal(demo_limit(), 300); });\n', rules)
    assert results["passed"] == 1


def test_syntax_error_stops_the_run(tmp_path):
    code, results, output = run(tmp_path, 'test_case("demo", function () { var = ; });\n')
    assert code == 2 and results is None
    assert "Could not load the scripts" in output
