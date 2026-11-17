draw_self();

if (instance_exists(main_character_Obj) && instance_exists(Dialogue_Obj)
    && !Dialogue_Obj.dialogue_in_progress && !Dialogue_Obj.waiting_for_upgrade
    && distance_to_object(main_character_Obj) <= 48) {
    draw_menu_text(x, bbox_top - 12, "Press E to talk", c_white, 1, fa_center);
}