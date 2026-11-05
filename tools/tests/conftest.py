"""Shared fixtures: a tiny fake GameMaker project that passes every rule.
Each test breaks one thing and checks that the right rule catches it."""

import sys
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
sys.path.insert(0, str(TOOLS / "ci"))

CLEAN_SCRIPT = (
    "/// scr_player_damage\n"
    "/// Applies damage to the player. Takes the amount of damage.\n"
    "function player_take_damage(_amount) {\n"
    "    hp = max(0, hp - _amount);\n"
    "}\n"
)

CLEAN_YYP = (
    '{\n  "RoomOrderNodes":[\n'
    '    {"roomId":{"name":"title_room","path":"rooms/title_room/title_room.yy",},},\n'
    '    {"roomId":{"name":"arena_room","path":"rooms/arena_room/arena_room.yy",},},\n'
    '  ],\n}\n'
)


def write(path: Path, text: str, newline: str = "\n") -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.replace("\n", newline).encode("utf-8"))
    return path


@pytest.fixture
def project(tmp_path: Path) -> Path:
    root = tmp_path / "game"
    write(root / "Game.yyp", CLEAN_YYP)
    write(root / "scripts/scr_player_damage/scr_player_damage.gml", CLEAN_SCRIPT)
    write(root / "objects/player_obj/Create_0.gml",
          "/// Player setup: stats come from the loaded JSON.\n"
          "hp = 0;\n"
          "max_hp = global.stats.player.max_hp;\n")
    for folder in ("sprites/player_spr", "rooms/title_room", "rooms/arena_room", "sounds/snd_swing"):
        (root / folder).mkdir(parents=True)
    return root
