draw_self();

if (health_steal_line_timer > 0 && instance_exists(main_character_Obj)) {

	// start: where the knife stuck in the enemy
	var _sx = x;
	var _sy = y;

	// end: the middle of the player's body (not his feet)
	var _ex = main_character_Obj.x;
	var _ey = (main_character_Obj.bbox_top + main_character_Obj.bbox_bottom) / 2;

	// how far along the flight it is: 0 at the hit, 1 when it reaches you
	var _t = 1 - health_steal_line_timer / drain_fly_time;
	var _ease = _t * _t;   // starts slow, then speeds up into you

	// where it is right now
	var _dx = lerp(_sx, _ex, _ease);
	var _dy = lerp(_sy, _ey, _ease);

	// thick end leads toward you, the tendrils trail back toward the enemy
	var _ang = point_direction(_ex, _ey, _sx, _sy);

	// fades out over the last quarter of the flight
	var _alpha = 0.9;
	if (_t > 0.75) _alpha = 0.9 * (1 - _t) / 0.25;

	// animation keeps playing while it flies
	var _frame = floor((drain_fly_time - health_steal_line_timer) * 0.5) mod sprite_get_number(red_aura_spr);

	draw_sprite_ext(red_aura_spr, _frame, _dx, _dy, 1, 1, _ang, c_white, _alpha);
}