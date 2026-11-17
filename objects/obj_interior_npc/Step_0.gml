if (talk_cooldown > 0) talk_cooldown--;

event_inherited();





if (instance_exists(main_character_Obj) && instance_exists(Dialogue_Obj) && talk_cooldown <= 0 && !Dialogue_Obj.dialogue_in_progress && !Dialogue_Obj.waiting_for_upgrade) {
    if (distance_to_object(main_character_Obj) <= 48 && keyboard_check_pressed(ord("E"))) {

        if (!talked) {
            talked = true;
            Dialogue_Obj.start_dialogue(
                "Old Smith",
                [
                    "Well fought, warrior.",
                    "Your wounds are deep, but your spirit is stronger.",
                    "Let me help you grow stronger for what lies ahead."
                ],
                sprite_index,
                function() {
                    main_character_Obj.event_go_upgrade = true;
                    Dialogue_Obj.waiting_for_upgrade = true;
                },
                portrait_crop
            );
       } else {
    Dialogue_Obj.start_dialogue("Old Smith", ["Come back on the next go 'round."], sprite_index, undefined, portrait_crop);
}
    }
}