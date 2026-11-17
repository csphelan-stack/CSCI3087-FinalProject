// while the card screen is up the box stays hidden; when it closes, say goodbye
if (waiting_for_upgrade) {
    main_character_Obj.can_move = false;
    if (instance_exists(Upgrade_system_obj)) {
        saw_upgrade = true;
    } else if (saw_upgrade) {
        waiting_for_upgrade = false;
        saw_upgrade = false;
        start_dialogue(speaker, ["Ahh, time to return to battle."], portrait_spr, undefined, portrait_crop);
    }
    exit;
}

if (!dialogue_in_progress) exit;

if (input_delay > 0) { input_delay--; exit; }

var _len = string_length(lines[index]);
shown = min(shown + type_speed, _len);

if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_space) || mouse_check_button_pressed(mb_left)) {
    if (shown < _len) {
        shown = _len;                      // finish the line
    } else {
        index++;
        shown = 0;
        if (index >= array_length(lines)) {
            dialogue_in_progress = false;
            main_character_Obj.can_move = true;
            if (is_callable(done_callback)) done_callback();
        }
    }
}