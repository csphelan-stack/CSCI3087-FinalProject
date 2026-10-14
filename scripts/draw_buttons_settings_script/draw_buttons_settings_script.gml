function draw_buttons_settings(){

if(!global.gameIsPaused){
	
	window_set_cursor(cr_none);
	
	main_character_Obj.can_move=true;
	
	for(var r =0; r< btn_num; r++){

		var inst = instance_destroy(settingsA[r].obj);
		
	}
	
	
	
}
else{
	
	
	if (global.gameIsPaused)
    {
		
        with (all)
        {
            if (object_index == Settings_Obj) continue;

            // Save and stop built-in movement
            p_hspd  = hspeed;
            p_vspd  = vspeed;
            p_grav  = gravity;
            p_path  = path_speed;
            hspeed = 0; vspeed = 0; gravity = 0; path_speed = 0;

            // Save and freeze alarms
            for (var i = 0; i < 12; i++)
            {
                p_alarm[i] = alarm[i];
                alarm[i] = -1;
            }
        }
    }
    else
    {
        with (all)
        {
            if (object_index == Settings_Obj) continue;

            hspeed = p_hspd;
            vspeed = p_vspd;
            gravity = p_grav;
            path_speed = p_path;

            for (var i = 0; i < 12; i++) alarm[i] = p_alarm[i];
        }
    }
	
	
	// the Settings / Options pages draw their own stuff, so the main buttons go away while one is open
	if (menu_page != "main") {
		for (var r = 0; r < btn_num; r++) instance_destroy(settingsA[r].obj);
		return;
	}

	// the normal buttons sit in one row centered in the frame, the exit X goes in the top-right corner
	var row_count = btn_num - 1;
	var row_w = row_count * btn_size + (row_count - 1) * btn_gap;
	var row_x = startx_b + (width_settings_background - row_w) / 2;
	var row_y = starty_b + (height_settings_background - btn_size) / 2 + 16;

	for(var r =0; r< btn_num; r++){

		var obj = settingsA[r].obj;

		// only make each button once, this runs every frame while paused
		var inst = instance_exists(obj) ? instance_find(obj, 0) : instance_create_depth(0,0,-200,obj);

		inst.sprite_index = settingsA[r].spr;
		inst.label = settingsA[r].label;
		inst.label_scale = label_scale;

		if (obj == exit_btn_obj) {
			inst.button_w = close_w;
			inst.button_h = close_h;
			inst.gui_x = startx_b + width_settings_background - close_inset_x - close_w;
			inst.gui_y = starty_b + close_inset_y +20;
		}
		else {
			inst.button_w = btn_size;
			inst.button_h = btn_size;
			inst.gui_x = row_x + r * (btn_size + btn_gap);
			inst.gui_y = row_y;
		}

	}


}





}


// draws a button's text centered on top of it, with a dark shadow so it reads on any button colour
function draw_button_label(_x, _y, _w, _h, _text, _col, _scale){
	draw_menu_text(_x + _w / 2, _y + _h / 2, _text, _col, _scale, fa_center);
}


// draws text in the medieval font with a dark shadow. _y is the middle of the text, _halign is fa_left / fa_center / fa_right
function draw_menu_text(_x, _y, _text, _col, _scale, _halign){

	_y += _scale;	// nudge down a font pixel, the font's height includes room for g/p/y tails

	var old_font = draw_get_font();
	draw_set_font(global.font_medieval);

	draw_set_halign(_halign);
	draw_set_valign(fa_middle);

	draw_set_colour(c_black);
	draw_text_transformed(_x + _scale, _y + _scale, _text, _scale, _scale, 0);	// shadow, one font pixel down-right
	draw_set_colour(_col);
	draw_text_transformed(_x, _y, _text, _scale, _scale, 0);

	draw_set_font(old_font);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
}


// how wide _text is in the medieval font at scale 1
function menu_text_width(_text){
	var old_font = draw_get_font();
	draw_set_font(global.font_medieval);
	var w = string_width(_text);
	draw_set_font(old_font);
	return w;
}



// ---------------- controls ----------------

// every control the Settings page can change: the label it shows, and the global variable that holds the key
function controls_list(){
	return [
		{label:"Forward",  name:"up_button"},
		{label:"Backward", name:"down_button"},
		{label:"Left",     name:"left_button"},
		{label:"Right",    name:"right_button"},
		{label:"Attack",   name:"attack_button"},
		{label:"Dash",     name:"dash_button"},
		{label:"Parry",    name:"parry_button"},
	];
}


// gives control number _index the key _key. if another control already used that key the two swap,
// so two actions never end up on the same key
function controls_rebind(_index, _key){
	var list = controls_list();
	var old_key = variable_global_get(list[_index].name);

	for (var i = 0; i < array_length(list); i++) {
		if (i != _index && variable_global_get(list[i].name) == _key) {
			variable_global_set(list[i].name, old_key);
		}
	}
	variable_global_set(list[_index].name, _key);

	controls_save();
}


// keys are saved in controls.ini so they stay changed next time the game starts
function controls_save(){
	var list = controls_list();
	ini_open("controls.ini");
	for (var i = 0; i < array_length(list); i++) {
		ini_write_real("controls", list[i].name, variable_global_get(list[i].name));
	}
	ini_close();
}


// call after the default keys are set, it replaces them with the saved ones (if there are any)
function controls_load(){
	var list = controls_list();
	ini_open("controls.ini");
	for (var i = 0; i < array_length(list); i++) {
		var name = list[i].name;
		variable_global_set(name, ini_read_real("controls", name, variable_global_get(name)));
	}
	ini_close();
}


// turns a key code into the text shown on the Settings page
function key_name(_key){
	if (_key >= ord("A") && _key <= ord("Z")) return chr(_key);
	if (_key >= ord("0") && _key <= ord("9")) return chr(_key);
	if (_key >= vk_numpad0 && _key <= vk_numpad9) return "Num " + string(_key - vk_numpad0);
	if (_key >= vk_f1 && _key <= vk_f12) return "F" + string(_key - vk_f1 + 1);

	switch (_key) {
		case vk_left:      return "Left";
		case vk_right:     return "Right";
		case vk_up:        return "Up";
		case vk_down:      return "Down";
		case vk_space:     return "Space";
		case vk_enter:     return "Enter";
		case vk_tab:       return "Tab";
		case vk_backspace: return "Backspace";
		case vk_shift:   case vk_lshift:   case vk_rshift:   return "Shift";
		case vk_control: case vk_lcontrol: case vk_rcontrol: return "Ctrl";
		case vk_alt:     case vk_lalt:     case vk_ralt:     return "Alt";
		case vk_insert:    return "Insert";
		case vk_delete:    return "Delete";
		case vk_home:      return "Home";
		case vk_end:       return "End";
		case vk_pageup:    return "Page Up";
		case vk_pagedown:  return "Page Down";
		case 186: return ";";
		case 188: return ",";
		case 189: return "-";
		case 190: return ".";
		case 191: return "/";
		case 222: return "'";
	}
	return "Key " + string(_key);
}



// ---------------- pause menu pages ----------------
// these run inside Settings_Obj, so they use its layout variables (see its Create event)

// handles clicks and key presses on the Settings / Options pages. the main page uses the button objects instead
function pause_menu_step(){

	// skip a couple of steps after switching page so the click that opened it doesn't also click something on it
	if (input_delay > 0) {
		input_delay--;
		return;
	}
	if (menu_page == "main") return;

	// waiting for a new key: the next key pressed becomes the control (Esc is handled in the Step event, it cancels)
	if (waiting_for_key != -1 && keyboard_check_pressed(vk_anykey)) {
		// look for which key it was (lowest code first, so left/right Shift, Ctrl and Alt come out as plain Shift/Ctrl/Alt)
		for (var key = 8; key < 256; key++) {
			if (key != global.pauseGameBtn && keyboard_check_pressed(key)) {
				controls_rebind(waiting_for_key, key);
				waiting_for_key = -1;
				break;
			}
		}
	}

	if (mouse_check_button_pressed(mb_left)) {

		if (back_button_hovered()) {
			open_page("main");
			return;
		}

		if (menu_page == "settings") {
			var mx = device_mouse_x_to_gui(0);
			var my = device_mouse_y_to_gui(0);

			waiting_for_key = -1;	// clicking somewhere else cancels
			for (var i = 0; i < array_length(controls); i++) {
				var r = ctrl_rows[i];
				if (point_in_rectangle(mx, my, r.x, r.y, r.x + ctrl_row_w, r.y + ctrl_row_h)) {
					waiting_for_key = i;
				}
			}
		}
	}
}


// Settings page: "Settings" in the top left, movement keys on the left, attack / dash / parry on the right
function draw_settings_page(){

	draw_menu_text(page_title_x, page_title_y, "Settings", c_white, 3, fa_left);

	var gold = make_colour_rgb(230, 190, 90);
	draw_menu_text(ctrl_col_x[0] + ctrl_row_w / 2, ctrl_header_y, "Movement", gold, 2, fa_center);
	draw_menu_text(ctrl_col_x[1] + ctrl_row_w / 2, ctrl_header_y, "Actions", gold, 2, fa_center);

	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);

	for (var i = 0; i < array_length(controls); i++) {
		var r = ctrl_rows[i];
		var listening = (waiting_for_key == i);
		var hover = point_in_rectangle(mx, my, r.x, r.y, r.x + ctrl_row_w, r.y + ctrl_row_h);
		var col = (hover || listening) ? global.hover_color : c_white;

		// name of the control on the left of the row
		draw_menu_text(r.x, r.y + ctrl_row_h / 2, controls[i].label, col, 2, fa_left);

		// the key it's set to, in a little box on the right of the row
		var bx = r.x + ctrl_row_w - ctrl_box_w;
		draw_sprite_stretched_ext(gui_dark_button_black_spr, 0, bx, r.y, ctrl_box_w, ctrl_row_h, listening ? global.hover_color : c_white, 1);

		var key_text = listening ? "Press a key" : key_name(variable_global_get(controls[i].name));
		var key_scale = (menu_text_width(key_text) * 2 <= ctrl_box_w - 16) ? 2 : 1;	// long names drop to small text so they fit
		draw_menu_text(bx + ctrl_box_w / 2, r.y + ctrl_row_h / 2, key_text, col, key_scale, fa_center);
	}

	var hint = (waiting_for_key == -1)
		? "Click a control, then press a key. Esc: back"
		: "Press a key for " + controls[waiting_for_key].label + ". Esc: cancel";
	draw_menu_text(hint_x, hint_y, hint, c_ltgray, 1, fa_left);

	draw_back_button();
}


// Options page: empty for now, ready for whatever goes here later
function draw_options_page(){
	draw_menu_text(page_title_x, page_title_y, "Options", c_white, 3, fa_left);
	draw_menu_text(startx_b + width_settings_background / 2, starty_b + height_settings_background / 2, "Nothing here yet", c_ltgray, 2, fa_center);
	draw_back_button();
}


function back_button_hovered(){
	return point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), back_x, back_y, back_x + back_w, back_y + back_h);
}


function draw_back_button(){
	var col = back_button_hovered() ? global.hover_color : c_white;
	draw_sprite_stretched_ext(gui_dark_button_grey_spr, 0, back_x, back_y, back_w, back_h, col, 1);
	draw_button_label(back_x, back_y, back_w, back_h, "Back", col, 2);
}
