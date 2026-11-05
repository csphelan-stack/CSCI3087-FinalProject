"""Proves validate_data.py rejects broken data files and accepts good ones."""

import json
from pathlib import Path

import pytest

import validate_data
from conftest import write

INVALID_DIR = Path(__file__).parent / "data" / "invalid"

GOOD_ENEMIES = {
    "enemies": [
        {"type": "slime", "hp": 10, "max_hp": 10, "damage": 2, "move_speed": 1.5, "attack_cooldown": 30, "damage_type": "blunt"},
        {"type": "skeleton", "hp": 20, "damage": 4, "move_speed": 2, "attack_cooldown": 0},
    ]
}
GOOD_WAVES = {"waves": [{"enemy": "slime", "count": 3, "spawn_delay": 60}, {"enemy": "skeleton", "count": 0}]}


def problems_for(tmp_path: Path, content: str, name: str = "data.json"):
    path = write(tmp_path / name, content)
    return validate_data.check_files([path])[path]


def rules_for(tmp_path: Path, data) -> list[str]:
    return [p.rule for p in problems_for(tmp_path, json.dumps(data))]


def test_good_files_pass(tmp_path):
    assert rules_for(tmp_path, GOOD_ENEMIES) == []
    assert rules_for(tmp_path, GOOD_WAVES) == []


# --- parse and duplicate ------------------------------------------------------------------

@pytest.mark.parametrize("content", ["", "   \n", '{"hp": 1,}', '{"hp": NaN}', '{"hp": -Infinity}', "// note\n{}", '"text"', "42"])
def test_unparseable_or_wrong_shape_is_rejected(tmp_path, content):
    assert [p.rule for p in problems_for(tmp_path, content)] == ["parse"]


def test_invalid_json_reports_the_line(tmp_path):
    problems = problems_for(tmp_path, '{\n  "hp": 1,\n  "damage" 2\n}\n')
    assert problems[0].line == 3


def test_duplicate_key_is_rejected(tmp_path):
    problems = problems_for(tmp_path, '{"type": "slime", "hp": 10, "hp": 20}')
    assert [p.rule for p in problems] == ["duplicate"]
    assert "'hp'" in problems[0].message


def test_byte_order_mark_is_accepted(tmp_path):
    path = tmp_path / "bom.json"
    path.write_bytes(b"\xef\xbb\xbf" + json.dumps(GOOD_WAVES).encode())
    assert validate_data.check_files([path])[path] == []


# --- stat-range ---------------------------------------------------------------------------

@pytest.mark.parametrize("field, value", [
    ("count", -1), ("enemy_count", 2.5), ("count", "3"),
    ("hp", 0), ("hp", -10), ("max_hp", 0), ("maxHp", 0), ("health", -1),
    ("damage", -1), ("move_speed", -0.5), ("attack_cooldown", -30), ("spawn_delay", -1), ("iframe_frames", -1),
    ("damage", "lots"), ("move_speed", True), ("hp", None), ("damage", [1]),
])
def test_out_of_range_stats_are_rejected(tmp_path, field, value):
    assert rules_for(tmp_path, {"type": "x", field: value}) == ["stat-range"]


@pytest.mark.parametrize("field, value", [
    ("count", 0), ("count", 1), ("enemy_count", 1000), ("hp", 1), ("hp", 0.5),
    ("damage", 0), ("move_speed", 0), ("attack_cooldown", 0), ("hp_max", 999999),
])
def test_boundary_stats_are_accepted(tmp_path, field, value):
    assert rules_for(tmp_path, {"type": "x", field: value}) == []


@pytest.mark.parametrize("field", ["damage_type", "speed_label", "count_label", "type", "name", "hp_bar_color"])
def test_non_stat_fields_are_not_checked(tmp_path, field):
    assert rules_for(tmp_path, {field: "anything"}) == []


def test_nested_stat_error_names_its_location(tmp_path):
    problems = problems_for(tmp_path, json.dumps({"waves": [{"enemy": "slime", "count": 1}, {"enemy": "bat", "count": -2}]}))
    assert len(problems) == 1
    assert "waves[1].count" in problems[0].message


@pytest.mark.parametrize("key, word", [
    ("max_hp", "hp"), ("maxHp", "hp"), ("hp_max", "hp"), ("enemyCount", "count"),
    ("spawn_delay", "delay"), ("damage_type", None), ("max", None), ("", None),
])
def test_stat_word(key, word):
    assert validate_data.stat_word(key) == word


# --- enemy-ref (cross-reference between waves and enemies) -------------------------------

@pytest.fixture
def cross_ref(monkeypatch):
    monkeypatch.setattr(validate_data, "ENEMY_FILE_PATTERN", "enemies*.json")
    monkeypatch.setattr(validate_data, "ENEMY_ID_KEY", "type")
    monkeypatch.setattr(validate_data, "WAVE_FILE_PATTERN", "waves*.json")
    monkeypatch.setattr(validate_data, "WAVE_ENEMY_KEY", "enemy")


def test_cross_ref_can_be_turned_off(tmp_path, monkeypatch):
    monkeypatch.setattr(validate_data, "WAVE_ENEMY_KEY", None)
    enemies = write(tmp_path / "enemies.json", json.dumps(GOOD_ENEMIES))
    waves = write(tmp_path / "waves.json", json.dumps({"waves": [{"spawns": [{"type": "dragon", "count": 1}]}]}))
    results = validate_data.check_files([enemies, waves])
    assert results[waves] == []


def test_default_settings_match_the_game_loader_layout(tmp_path):
    """The defaults check the same layout scr_rules_data reads, with no monkeypatching."""
    enemies = write(tmp_path / "enemies.json", json.dumps(GOOD_ENEMIES))
    good = write(tmp_path / "waves.json", json.dumps({"waves": [{"spawns": [{"type": "slime", "count": 3}]}]}))
    bad = write(tmp_path / "waves_hard.json", json.dumps({"waves": [{"spawns": [{"type": "dragon", "count": 1}]}]}))
    results = validate_data.check_files([enemies, good, bad])
    assert results[good] == []
    assert [p.rule for p in results[bad]] == ["enemy-ref"]


def test_enemy_ids_come_only_from_enemy_files(tmp_path):
    """A "type" key in a wave file must not count as defining an enemy."""
    waves = write(tmp_path / "waves.json", json.dumps({"waves": [{"spawns": [{"type": "slime", "count": 1}]}]}))
    assert [p.rule for p in validate_data.check_files([waves])[waves]] == ["enemy-ref"]


def test_known_enemies_pass(tmp_path, cross_ref):
    enemies = write(tmp_path / "enemies.json", json.dumps(GOOD_ENEMIES))
    waves = write(tmp_path / "waves.json", json.dumps(GOOD_WAVES))
    results = validate_data.check_files([enemies, waves])
    assert results == {enemies: [], waves: []}


def test_unknown_enemy_in_wave_is_rejected(tmp_path, cross_ref):
    enemies = write(tmp_path / "enemies.json", json.dumps(GOOD_ENEMIES))
    waves = write(tmp_path / "waves.json", json.dumps({"waves": [{"enemy": "slime", "count": 1}, {"enemy": "Slime", "count": 1}]}))
    problems = validate_data.check_files([enemies, waves])[waves]
    assert [p.rule for p in problems] == ["enemy-ref"]
    assert '"Slime"' in problems[0].message


def test_non_text_enemy_reference_is_rejected(tmp_path, cross_ref):
    enemies = write(tmp_path / "enemies.json", json.dumps(GOOD_ENEMIES))
    waves = write(tmp_path / "waves.json", json.dumps({"waves": [{"enemy": 3, "count": 1}]}))
    assert [p.rule for p in validate_data.check_files([enemies, waves])[waves]] == ["enemy-ref"]


def test_enemy_file_keyed_by_type(tmp_path, cross_ref, monkeypatch):
    monkeypatch.setattr(validate_data, "ENEMY_ID_KEY", "__keys__")
    enemies = write(tmp_path / "enemies.json", json.dumps({"slime": {"hp": 5}, "bat": {"hp": 2}}))
    waves = write(tmp_path / "waves.json", json.dumps({"waves": [{"enemy": "bat", "count": 2}, {"enemy": "ghost", "count": 1}]}))
    problems = validate_data.check_files([enemies, waves])[waves]
    assert len(problems) == 1 and '"ghost"' in problems[0].message


# --- command line ----------------------------------------------------------------------------

def test_every_shipped_broken_file_is_rejected(tmp_path):
    """The files in tools/tests/data/invalid each contain one mistake; all must fail."""
    files = sorted(INVALID_DIR.glob("*.json"))
    assert len(files) >= 10
    results = validate_data.check_files(files)
    accepted = [p.name for p, problems in results.items() if not problems]
    assert accepted == []


def test_expect_invalid_mode(tmp_path):
    data_dir = tmp_path / "datafiles"
    data_dir.mkdir()
    assert validate_data.main(["--data-dir", str(data_dir), "--expect-invalid", str(INVALID_DIR)]) == 0

    mixed = tmp_path / "mixed"
    write(mixed / "broken.json", '{"hp": -1}')
    write(mixed / "fine.json", '{"hp": 5}')
    assert validate_data.main(["--data-dir", str(data_dir), "--expect-invalid", str(mixed)]) == 1


def test_main_exit_codes(project, capsys):
    write(project / "datafiles/enemies.json", json.dumps(GOOD_ENEMIES))
    assert validate_data.main(["--project-dir", str(project)]) == 0
    write(project / "datafiles/waves.json", '{"waves": [{"enemy": "slime", "count": -4}]}')
    assert validate_data.main(["--project-dir", str(project)]) == 1
    assert "[stat-range]" in capsys.readouterr().out


def test_no_data_files_is_a_warning_not_a_failure(project, capsys):
    assert validate_data.main(["--project-dir", str(project)]) == 0
    assert "No JSON data files" in capsys.readouterr().out
