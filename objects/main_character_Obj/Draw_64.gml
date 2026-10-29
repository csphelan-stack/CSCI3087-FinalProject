/// @desc Health Bar

healthbar_x = display_get_gui_width() / 2;
healthbar_y = display_get_gui_height() - 60;

var _left = healthbar_x - sprite_get_xoffset(gui_dark_bar_frame_gold_border_spr);
var _top  = healthbar_y - sprite_get_yoffset(gui_dark_bar_frame_gold_border_spr);

// where the red bar starts inside the 30px-tall frame (CHANGE THESE)
var _slot_x = 4;   // distance from frame's left edge
var _slot_y = 17;   // roughly (30 - 4) / 2, so it sits vertically centered
var _slot_w = 165;   // width of the slot when hp is full

var _pct = clamp(hp / total_hp, 0, 1);

draw_sprite(gui_dark_bar_frame_gold_background_spr, 0, healthbar_x, healthbar_y);

// if the healthbar sprite is exactly 4px tall with no transparent padding:
draw_sprite_part_ext(
    healthbar_spr, 0,
    0, 0, sprite_get_width(healthbar_spr) * _pct, sprite_get_height(healthbar_spr),
    _left + _slot_x, _top + _slot_y,
    _slot_w / sprite_get_width(healthbar_spr), 1,   // y scale is 1: no vertical stretching
    c_white, 1
);

draw_sprite(gui_dark_bar_frame_gold_border_spr, 0, healthbar_x, healthbar_y);