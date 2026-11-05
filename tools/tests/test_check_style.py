"""Proves check_style.py catches each broken rule and leaves clean code alone."""

from pathlib import Path

import check_style
from conftest import write


def rules(project: Path) -> list[str]:
    return [p.rule for p in check_style.check_project(project)]


def test_clean_project_passes(project):
    assert check_style.check_project(project) == []


# --- naming ---------------------------------------------------------------------------

def test_object_without_suffix_is_flagged(project):
    (project / "objects/Player2").mkdir()
    problems = check_style.check_project(project)
    assert [p.rule for p in problems] == ["naming"]
    assert "_obj" in problems[0].message


def test_object_with_prefix_instead_of_suffix_is_flagged(project):
    (project / "objects/obj_wall").mkdir()
    assert rules(project) == ["naming"]


def test_object_suffix_ignores_case_and_allows_object(project):
    (project / "objects/Settings_Obj").mkdir()
    (project / "objects/Room_controller_object").mkdir()
    assert rules(project) == []


def test_sprite_with_text_after_suffix_is_flagged(project):
    (project / "sprites/gui_bar_spr_border").mkdir()
    assert rules(project) == ["naming"]


def test_default_room_name_is_flagged(project):
    (project / "rooms/Room1").mkdir()
    assert rules(project) == ["naming"]


def test_sound_without_prefix_is_flagged(project):
    (project / "sounds/swing").mkdir()
    assert rules(project) == ["naming"]


def test_script_names_are_not_checked(project):
    write(project / "scripts/parryState/parryState.gml", "/// Parry state for the player.\n")
    assert rules(project) == []


def test_test_assets_skip_the_naming_rule(project):
    (project / "objects/obj_test_runner").mkdir()
    (project / "rooms/rm_test_combat").mkdir()
    assert rules(project) == []


# --- header ---------------------------------------------------------------------------

def test_script_starting_with_code_is_flagged(project):
    write(project / "scripts/scr_wave/scr_wave.gml", "function wave_start() {\n}\n")
    assert rules(project) == ["header"]


def test_script_header_after_blank_lines_is_accepted(project):
    write(project / "scripts/scr_wave/scr_wave.gml", "\n\n/* Starts a wave. */\nfunction wave_start() {\n}\n")
    assert rules(project) == []


def test_empty_script_is_flagged(project):
    write(project / "scripts/scr_wave/scr_wave.gml", "\n\n")
    assert rules(project) == ["header"]


def test_header_rule_applies_only_to_scripts(project):
    write(project / "objects/enemy_obj/Step_0.gml", "x += 1;\n")
    assert rules(project) == []


# --- hardcoded-stat ---------------------------------------------------------------------

def test_stat_set_to_number_is_flagged(project):
    write(project / "objects/enemy_obj/Create_0.gml", "// Enemy setup\nhp = 100;\n")
    problems = check_style.check_project(project)
    assert [(p.rule, p.line) for p in problems] == [("hardcoded-stat", 2)]


def test_stat_in_struct_literal_is_flagged(project):
    write(project / "objects/enemy_obj/Create_0.gml", "attack = { damage: 5, name: \"bite\" };\n")
    assert rules(project) == ["hardcoded-stat"]


def test_negative_and_decimal_stats_are_flagged(project):
    write(project / "objects/enemy_obj/Create_0.gml", "move_speed = 2.5;\nknockback = -3;\n")
    assert rules(project) == ["hardcoded-stat", "hardcoded-stat"]


def test_stat_member_assignment_is_flagged(project):
    write(project / "objects/enemy_obj/Create_0.gml", "other.hp = 50;\n")
    assert rules(project) == ["hardcoded-stat"]


def test_stat_reset_to_zero_is_allowed(project):
    write(project / "objects/enemy_obj/Create_0.gml", "hp = 0;\nattack_cooldown = 0.0;\n")
    assert rules(project) == []


def test_stat_comparisons_are_not_assignments(project):
    write(project / "objects/enemy_obj/Step_0.gml",
          "if (hp == 100) { a = 1; }\nif (hp <= 10) { b = 1; }\nif (hp >= 10) { c = 1; }\nif (hp != 3) { d = 1; }\n")
    assert rules(project) == []


def test_stat_added_to_is_not_flagged(project):
    write(project / "objects/enemy_obj/Step_0.gml", "hp -= 1;\nhp += global.heal;\n")
    assert rules(project) == []


def test_similar_variable_names_are_not_stats(project):
    write(project / "objects/enemy_obj/Create_0.gml", "hp_bar_width = 64;\ndamage_flash = 10;\nmy_hp2 = 5;\n")
    assert rules(project) == []


def test_stats_in_comments_and_strings_are_ignored(project):
    write(project / "objects/enemy_obj/Create_0.gml",
          "// hp = 100;\n/* damage = 5;\n   move_speed = 3; */\nlabel = \"hp = 100\";\n")
    assert rules(project) == []


def test_loader_scripts_may_set_stats(project):
    write(project / "scripts/scr_load_stats/scr_load_stats.gml",
          "/// Loads stats from JSON, with defaults if a field is missing.\nhp = 10;\n")
    assert rules(project) == []


def test_test_assets_may_set_stats(project):
    write(project / "scripts/scr_tests_combat/scr_tests_combat.gml", "/// Combat tests\nhp = 10;\n")
    assert rules(project) == []


# --- debug-output -----------------------------------------------------------------------

def test_debug_message_in_game_code_is_flagged(project):
    write(project / "objects/enemy_obj/Step_0.gml", "x += 1;\nshow_debug_message(\"enemy moved\");\n")
    problems = check_style.check_project(project)
    assert [(p.rule, p.line) for p in problems] == [("debug-output", 2)]


def test_show_message_is_flagged(project):
    write(project / "objects/enemy_obj/Step_0.gml", "show_message (\"hi\");\n")
    assert rules(project) == ["debug-output"]


def test_debug_message_in_comment_is_ignored(project):
    write(project / "objects/enemy_obj/Step_0.gml", "// show_debug_message(\"old\");\n")
    assert rules(project) == []


def test_debug_message_in_test_asset_is_allowed(project):
    write(project / "objects/obj_test_runner/Create_0.gml", "show_debug_message(\"running\");\n")
    assert rules(project) == []


# --- test-room ----------------------------------------------------------------------------

def test_game_code_going_to_test_room_is_flagged(project):
    write(project / "objects/menu_obj/Step_0.gml", "if (keyboard_check_pressed(vk_f1)) room_goto(rm_test_combat);\n")
    assert rules(project) == ["test-room"]


def test_test_code_may_use_test_rooms(project):
    write(project / "objects/obj_test_runner/Create_0.gml", "room_goto(rm_test_combat);\n")
    (project / "rooms/rm_test_combat").mkdir()
    assert rules(project) == []


def test_game_starting_in_test_room_is_flagged(project):
    write(project / "Game.yyp", '{"RoomOrderNodes":[{"roomId":{"name":"rm_test_enemy","path":"x",},},],}')
    assert rules(project) == ["test-room"]


# --- whitespace -----------------------------------------------------------------------------

def test_trailing_whitespace_is_flagged_once_per_file(project):
    write(project / "objects/enemy_obj/Step_0.gml", "x += 1;\ny += 1;  \nz += 1;\t\n")
    problems = check_style.check_project(project)
    assert [(p.rule, p.line) for p in problems] == [("whitespace", 2)]
    assert "2 line(s)" in problems[0].message


def test_windows_line_endings_are_not_trailing_whitespace(project):
    write(project / "objects/enemy_obj/Step_0.gml", "// Moves the enemy\nx += 1;\n", newline="\r\n")
    assert rules(project) == []


def test_fix_whitespace_keeps_line_endings_and_bom(project):
    path = project / "objects/enemy_obj/Step_0.gml"
    path.parent.mkdir(parents=True)
    path.write_bytes(b"\xef\xbb\xbfx += 1;  \r\ny += 1;\r\n")
    assert check_style.fix_whitespace(path) is True
    assert path.read_bytes() == b"\xef\xbb\xbfx += 1;\r\ny += 1;\r\n"
    assert check_style.fix_whitespace(path) is False
    assert rules(project) == []


# --- indentation ------------------------------------------------------------------------------

def test_mixed_tabs_and_spaces_are_flagged(project):
    write(project / "objects/enemy_obj/Step_0.gml", "if (a) {\n    x += 1;\n    y += 1;\n\tz += 1;\n}\n")
    problems = check_style.check_project(project)
    assert [(p.rule, p.line) for p in problems] == [("indentation", 4)]


def test_tabs_only_is_fine(project):
    write(project / "objects/enemy_obj/Step_0.gml", "if (a) {\n\tx += 1;\n\t\ty += 1;\n}\n")
    assert rules(project) == []


def test_block_comment_star_lines_do_not_count_as_indentation(project):
    write(project / "objects/enemy_obj/Step_0.gml", "/*\n * Moves the enemy.\n */\nif (a) {\n\tx += 1;\n}\n")
    assert rules(project) == []


# --- scope and command line ---------------------------------------------------------------------

def test_tools_folder_and_extensions_are_skipped(project):
    write(project / "tools/gml/scr_x.gml", "show_debug_message(1);  \n")
    write(project / "extensions/ext_steam/ext.gml", "show_debug_message(1);\n")
    assert rules(project) == []


def test_main_exit_codes(project, capsys):
    assert check_style.main(["--project-dir", str(project)]) == 0
    write(project / "objects/enemy_obj/Step_0.gml", "show_debug_message(1);\n")
    assert check_style.main(["--project-dir", str(project)]) == 1
    assert "[debug-output]" in capsys.readouterr().out


def test_main_finds_the_project_from_the_repo_root(project, monkeypatch):
    monkeypatch.chdir(project.parent)
    assert check_style.main([]) == 0


def test_github_annotations_point_at_file_and_line(project, monkeypatch, capsys):
    monkeypatch.setenv("GITHUB_ACTIONS", "true")
    monkeypatch.chdir(project.parent)
    write(project / "objects/enemy_obj/Create_0.gml", "// Enemy\nhp = 100;\n")
    assert check_style.main([]) == 1
    out = capsys.readouterr().out
    assert "::error file=game/objects/enemy_obj/Create_0.gml,line=2,title=Style: hardcoded-stat::" in out
