import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

from gm_check import read_gml_assignments, gml_number  # noqa: E402

# Change this to where your parent object's Create event really lives
ENEMY_CREATE = Path("objects/obj_enemy_parent/Create_0.gml")


@pytest.fixture
def enemy():
    if not ENEMY_CREATE.exists():
        pytest.skip("enemy Create event not found at expected path")
    return read_gml_assignments(ENEMY_CREATE)


def test_hp_starts_at_total_hp(enemy):
    assert enemy["hp"][-1] == "total_hp"


def test_total_hp_is_positive(enemy):
    assert gml_number(enemy, "total_hp") > 0


def test_chase_is_faster_than_wander(enemy):
    assert gml_number(enemy, "movespd") > gml_number(enemy, "wander_spd")


def test_stop_range_inside_attack_range(enemy):
    assert gml_number(enemy, "stop_range") <= gml_number(enemy, "attack_range")


def test_lose_range_at_least_sight_range(enemy):
    assert gml_number(enemy, "lose_range") >= gml_number(enemy, "sight_range")


def test_view_angle_is_valid(enemy):
    assert 0 < gml_number(enemy, "view_angle") <= 360


def test_idle_min_not_above_idle_max(enemy):
    assert gml_number(enemy, "idle_min") <= gml_number(enemy, "idle_max")


def test_attack_hits_before_attack_ends(enemy):
    assert gml_number(enemy, "attack_windup") < gml_number(enemy, "attack_duration")


def test_cooldown_starts_at_zero(enemy):
    assert gml_number(enemy, "attack_cooldown") == 0


def test_no_variable_defined_twice(enemy):
    duplicates = [name for name, vals in enemy.items() if len(vals) > 1]
    assert duplicates == []
