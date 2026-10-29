import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from gm_check import check_project, parse_gm_json  # noqa: E402


def test_parse_handles_trailing_commas():
    assert parse_gm_json('{"a": [1, 2,],}') == {"a": [1, 2]}


def test_check_project_flags_broken_file(tmp_path):
    (tmp_path / "bad.yy").write_text('{"name": }')
    assert len(check_project(tmp_path)) == 1


def test_check_project_passes_valid_file(tmp_path):
    (tmp_path / "good.yy").write_text('{"name": "obj_player",}')
    assert check_project(tmp_path) == []
