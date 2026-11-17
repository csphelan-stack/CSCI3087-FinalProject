if (global.gameIsPaused) exit;

// refilling: the blood level rises over the cooldown
if (!is_full) {
	cooldown -= 1;
	if (cooldown <= 0) {
		cooldown = 0;
		is_full = true;
	}
}
image_index = is_full ? image_number - 1 : floor((1 - cooldown / cooldown_time) * (image_number - 1));

can_use = false;
if (instance_exists(main_character_Obj)) {
	var _p = instance_nearest(x, y, main_character_Obj);

	// draw order: in front of the player when he's above it, behind him when he's below it
	depth = (_p.bbox_bottom > bbox_bottom) ? _p.depth + 1 : _p.depth - 1;

	var _near = distance_to_object(main_character_Obj) <= heal_radius;
	can_use = _near && is_full && _p.state != PlayerState.DEAD && _p.hp < _p.total_hp;

	if (can_use && (auto_heal || keyboard_check_pressed(interact_key))) {
		_p.hp = min(_p.total_hp, _p.hp + heal_amount);
		is_full = false;
		cooldown = cooldown_time;
		// audio_play_sound(snd_heal, 20, false);
	}
}