
potrait_x = 30;
potrait_y = 290;

scale_potrait = 2;

dialogue_box_x = potrait_x + 140;
dialogue_box_y =  potrait_y;

//dialogue draw variables
dialogue_in_progress = false;

MCpotraitSpr = skull_knight_character_potrait_spr;

dialogue_spr = gui_dark_slot_grey_spr;

dialogue_width = 540;

dialogue_height = sprite_get_height(skull_knight_character_potrait_spr) * scale_potrait;

// ---- dialogue content ----
speaker = "";
lines = [];
index = 0;
shown = 0;            // letters showing (typewriter)
type_speed = 0.7;
input_delay = 0;
done_callback = undefined;
portrait_spr = MCpotraitSpr;

// the NPC (or anything) calls this to start a conversation
portrait_crop = undefined;   // undefined = draw the whole portrait sprite (the skull knight)
portrait_frame = 0;
start_dialogue = function(_speaker, _lines, _portrait, _callback, _crop = undefined) {
    speaker = _speaker;
    lines = _lines;
    portrait_spr = is_undefined(_portrait) ? MCpotraitSpr : _portrait;
    portrait_crop = _crop;
    done_callback = _callback;
    index = 0;
    shown = 0;
    input_delay = 5;
    dialogue_in_progress = true;
    main_character_Obj.can_move = false;
}

// turn off dialogue when selecting upgrades
waiting_for_upgrade = false;
saw_upgrade = false;