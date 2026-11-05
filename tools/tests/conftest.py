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
    '    {"roomId":{"name":"rm_title","path":"rooms/rm_title/rm_title.yy",},},\n'
    '    {"roomId":{"name":"rm_arena","path":"rooms/rm_arena/rm_arena.yy",},},\n'
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
    write(root / "objects/obj_player/Create_0.gml",
          "/// Player setup: stats come from the loaded JSON.\n"
          "hp = 0;\n"
          "max_hp = global.stats.player.max_hp;\n")
    for folder in ("sprites/spr_player", "rooms/rm_title", "rooms/rm_arena", "sounds/snd_swing"):
        (root / folder).mkdir(parents=True)
    return root
