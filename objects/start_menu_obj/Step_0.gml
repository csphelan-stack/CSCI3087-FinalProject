var _count = array_length(menu_items);

// Keyboard / gamepad navigation
var _up   = keyboard_check_pressed(vk_up)   || keyboard_check_pressed(ord("W")) || gamepad_button_check_pressed(0, gp_padu);
var _down = keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")) || gamepad_button_check_pressed(0, gp_padd);
var _ok   = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);

if (_up)   selected = (selected <= 0) ? _count - 1 : selected - 1;
if (_down) selected = (selected + 1) mod _count;   // from -1 this lands on 0

// Mouse
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _mouse_moved = (_mx != prev_mx || _my != prev_my);
prev_mx = _mx;
prev_my = _my;

var _over = -1;
for (var i = 0; i < _count; i++) {
    var _cy = btn_start_y + i * (btn_h + btn_gap);
    if (point_in_rectangle(_mx, _my,
        display_get_gui_width()/2 - btn_w/2, _cy - btn_h/2,
        display_get_gui_width()/2 + btn_w/2, _cy + btn_h/2)) {
        _over = i;
    }
}

// Moving the mouse sets the highlight, and moving it off every button clears it
if (_mouse_moved) selected = _over;

if (_over != -1 && mouse_check_button_pressed(mb_left)) {
    activate_item(_over);
    exit;
}

if (_ok && selected != -1) activate_item(selected);