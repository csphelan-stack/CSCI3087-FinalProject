import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from gm_check import check_project, parse_gm_json  # noqa: E402


def test_parse_handles_nested_trailing_commas():
    source = '{"objects": [{"name": "obj_player",},],}'
    assert parse_gm_json(source) == {"objects": [{"name": "obj_player"}]}


def test_parse_rejects_malformed_json():
    import json

    try:
        parse_gm_json('{"name": }')
    except json.JSONDecodeError:
        pass
    else:
        raise AssertionError("Malformed JSON should raise JSONDecodeError")


def test_check_project_scans_nested_resource_files(tmp_path):
    nested = tmp_path / "objects" / "obj_player"
    nested.mkdir(parents=True)
    (nested / "obj_player.yy").write_text('{"name": "obj_player",}', encoding="utf-8")
    assert check_project(tmp_path) == []


def test_check_project_ignores_non_gamemaker_files(tmp_path):
    (tmp_path / "notes.txt").write_text("not GameMaker JSON", encoding="utf-8")
    (tmp_path / "data.json").write_text("not GameMaker JSON", encoding="utf-8")
    assert check_project(tmp_path) == []


def test_check_project_reports_multiple_broken_resource_files(tmp_path):
    (tmp_path / "broken_object.yy").write_text('{"name": }', encoding="utf-8")
    (tmp_path / "broken_project.yyp").write_text('{"resources": [}', encoding="utf-8")
    errors = check_project(tmp_path)
    assert len(errors) == 2
    assert any("broken_object.yy" in error for error in errors)
    assert any("broken_project.yyp" in error for error in errors)
